# Dependencies
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout
const BarGeometry := preload("res://addons/tau-plot/plot/xy/bar/bar_geometry.gd").BarGeometry
const SeriesAxisAssignment := preload("res://addons/tau-plot/plot/xy/series_axis_assignment.gd").SeriesAxisAssignment
const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const Axis = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis
const VisualAttributes = preload("res://addons/tau-plot/plot/xy/visual_attributes.gd").VisualAttributes
const BarVisualAttributes := preload("res://addons/tau-plot/plot/xy/bar/bar_visual_attributes.gd").BarVisualAttributes
const BarHitRecord := preload("res://addons/tau-plot/plot/xy/bar/bar_hit_record.gd").BarHitRecord


# Draws bar overlays from a XYLayout + Dataset.
# This renderer reads all samples through the Dataset public API (no direct buffer/series access).
# Runtime validation:
# - NaN and Inf are always silently skipped
# - Logarithmic Y scales: y <= 0 are skipped
# - Logarithmic X scales: x <= 0 are skipped
# - STACKED mode: negative values are skipped (would produce misleading visualization)
# BarValidator is expected to enforce:
# - dataset shape constraints for the chosen mode,
# - length consistency in SHARED_X mode,
# - GROUPED/STACKED require SHARED_X,
# - CATEGORICAL requires SHARED_X,
# - STACKED requires SHARED y-axis and linear Y scale.
class BarRenderer extends Control:
	var _layout: XYLayout = null
	var _dataset: Dataset = null
	var _bar_config: TauBarConfig = null
	var _series_assignment: SeriesAxisAssignment = null
	var _visual_attributes: Array[BarVisualAttributes] = []

	# Pane index this renderer belongs to. Used for per-pane domain/layout queries.
	var _pane_index: int = 0

	# Bar-specific series list: only series mapped as BAR are iterated.
	# Must be provided at construction. Empty means this renderer has no series to draw.
	var _bar_series_ids: PackedInt64Array = PackedInt64Array()

	# Resolved style instances pushed by xy_plot. Treat as read-only.
	var _bar_style: TauBarStyle = null
	var _xy_style: TauXYStyle = null
	var _geometry_cache: BarGeometry = null

	const _MIN_BAR_WIDTH_PX: float = 1.0

	# Hover highlight state. When _highlight_active is true, every sample's color
	# is run through the hover color callback to dim non-hovered and brighten
	# hovered samples.
	# When _hover_group_mode is true, all bars at _hovered_sample_index are
	# treated as hovered regardless of series_id. Used by GROUPED bars in
	# X_ALIGNED hover mode to highlight the entire group at once.
	var _highlight_active: bool = false
	var _hovered_series_id: int = -1
	var _hovered_sample_index: int = -1
	var _hover_group_mode: bool = false
	var _hover_highlight_callback: Callable = Callable()

	# Working copy of the resolved StyleBox, duplicated from the current source
	# (cascade or callback) and reused across bars to avoid per-bar allocation.
	# Color, corners, and borders are written into this instance before each
	# draw_style_box() call.
	var _derived_style_box: StyleBox = null

	# Reference to the StyleBox that _derived_style_box was last duplicated from.
	# When the source changes (different callback return or new frame),
	# _derived_style_box is re-duplicated. Reset to null at the start of each
	# _draw() to pick up property mutations on the source between frames.
	var _derived_source_ref: StyleBox = null

	# One record per painted bar rect, rebuilt every _draw() so the cache
	# never drifts from what is on screen.
	var _hit_records: Array[BarHitRecord] = []


	func _init(p_layout: XYLayout,
				p_dataset: Dataset,
				p_bar_config: TauBarConfig,
				p_xy_style: TauXYStyle,
				p_series_assignment: SeriesAxisAssignment,
				p_pane_index: int = 0,
				p_visual_attributes: Array[BarVisualAttributes] = [],
				p_bar_series_ids: PackedInt64Array = PackedInt64Array()) -> void:
		theme_type_variation = &"TauBar"
		_layout = p_layout
		_dataset = p_dataset
		_bar_config = p_bar_config
		_series_assignment = p_series_assignment
		_pane_index = p_pane_index
		_visual_attributes = p_visual_attributes
		_bar_series_ids = p_bar_series_ids
		_bar_style = p_bar_config.style
		_xy_style = p_xy_style


	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()


	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_RESIZED:
				queue_redraw()

	func get_config() -> TauBarConfig:
		return _bar_config

	## Receives the resolved TauBarStyle from xy_plot after cascade resolution.
	func set_resolved_bar_style(p_style: TauBarStyle) -> void:
		_bar_style = p_style


	## Receives the resolved TauXYStyle from xy_plot after cascade resolution.
	func set_resolved_xy_style(p_style: TauXYStyle) -> void:
		_xy_style = p_style


	## Updates the hover highlight state. Called by HoverController when the
	## hovered sample changes or when highlight is activated/deactivated.
	func set_hover_state(p_active: bool, p_series_id: int, p_sample_index: int, p_color_callback: Callable) -> void:
		var changed := (p_active != _highlight_active or p_series_id != _hovered_series_id
			or p_sample_index != _hovered_sample_index or _hover_group_mode)
		_highlight_active = p_active
		_hovered_series_id = p_series_id
		_hovered_sample_index = p_sample_index
		_hover_group_mode = false
		_hover_highlight_callback = p_color_callback
		if changed:
			queue_redraw()


	## Highlights all bars at p_sample_index regardless of series.
	## Used for GROUPED bars in X_ALIGNED mode so that the entire group
	## is visually highlighted together.
	func set_hover_state_group(p_active: bool, p_sample_index: int, p_color_callback: Callable) -> void:
		var changed := (p_active != _highlight_active
			or p_sample_index != _hovered_sample_index or not _hover_group_mode)
		_highlight_active = p_active
		_hovered_series_id = -1
		_hovered_sample_index = p_sample_index
		_hover_group_mode = true
		_hover_highlight_callback = p_color_callback
		if changed:
			queue_redraw()


	## Creates a legend key Control for a bar overlay: a filled square with alpha.
	## Reads fill color and alpha from resolved styles on this renderer instance.
	## Does not set custom_minimum_size, so the legend applies its default key_size_px.
	func create_legend_key_control(p_series_index: int) -> Control:
		var global_index := p_series_index
		var color := _xy_style.get_series_color(global_index)
		var alpha := _xy_style.series_alpha
		color.a = clampf(alpha, 0.0, 1.0)
		var sb := _bar_style.style_box.duplicate()
		_set_style_box_color(sb, color)
		var key := _BarLegendKey.new(sb)
		return key

	####################################################################################################
	# Private
	####################################################################################################

	## Control that draws a StyleBox with color already set.
	## Shows the canonical (unremapped) StyleBox, matching what the user authored.
	class _BarLegendKey extends Control:
		var _style_box: StyleBox = null

		func _init(p_style_box: StyleBox) -> void:
			_style_box = p_style_box

		func _draw() -> void:
			if _style_box != null:
				draw_style_box(_style_box, Rect2(Vector2.ZERO, size))


	func _draw() -> void:
		# Cleared before any early-return so the cache cannot outlive the bars it describes.
		_hit_records.clear()

		if _bar_style == null or _bar_style.style_box == null:
			push_error("BarRenderer: resolved TauBarStyle.style_box is null. Every bar must be drawn with a StyleBox.")
			return

		if not (_bar_style.style_box is StyleBoxFlat or _bar_style.style_box is StyleBoxTexture):
			push_error("BarRenderer: style_box must be a StyleBoxFlat or StyleBoxTexture, got %s" % _bar_style.style_box.get_class())
			return

		var pane_rect := _layout.get_pane_rect(_pane_index)
		if pane_rect.size.x <= 0.0 or pane_rect.size.y <= 0.0:
			return

		# Force re-duplication on the first bar of each frame so that property
		# mutations on the source StyleBox between frames are picked up.
		_derived_source_ref = null

		_geometry_cache = BarGeometry.new(_layout, _dataset, _bar_config, _bar_style, _get_bar_series_count(), _pane_index, _get_x_axis_config())

		var series_count := _get_bar_series_count()

		match _bar_config.mode:
			TauBarConfig.BarMode.GROUPED:
				_draw_grouped_bars(pane_rect, series_count)

			TauBarConfig.BarMode.STACKED:
				_draw_stacked_bars(pane_rect, series_count)

			TauBarConfig.BarMode.INDEPENDENT:
				_draw_independent_bars(pane_rect, series_count)

			_:
				push_error("Unsupported bar mode %d" % _bar_config.mode)


	# Returns the number of series this renderer is responsible for.
	func _get_bar_series_count() -> int:
		return _bar_series_ids.size()


	# Returns the dataset series_id for a given bar-local series index.
	func _get_bar_series_id(p_bar_index: int) -> int:
		return _bar_series_ids[p_bar_index]


	# Returns the shared x axis config.
	func _get_x_axis_config() -> TauAxisConfig:
		return _layout.domain.config.x_axis


	# Returns the dataset-global series index for a given pane-local series index.
	func _get_global_series_index(p_local_index: int) -> int:
		return _dataset.get_series_index_by_id(_bar_series_ids[p_local_index])


	# ---- X axis helpers ----

	func _get_x_px_for_series_value(p_series_id: int, p_x_value: float) -> float:
		return _layout.map_x_to_px(_pane_index, p_x_value)


	func _get_x_category_center_px(p_series_id: int, p_category_index: int) -> float:
		return _layout.map_x_category_center_to_px(_pane_index, p_category_index)


	## Returns the number of pixels along the x axis direction within the pane rect.
	## When x is horizontal, this is the pane width. When x is vertical, this is the pane height.
	func _get_x_axis_extent_px(p_pane_rect: Rect2) -> float:
		return p_pane_rect.size.x if _layout._x_is_horizontal else p_pane_rect.size.y


	func _get_x_categories_for_series(p_series_id: int) -> PackedStringArray:
		return _layout.domain.x_categories


	func _get_bar_color(p_series_index: int, p_sample_index: int, p_x_value: Variant, p_y_value: float) -> Color:
		# Try per sample color (with VisualAttributes)
		if p_series_index >= 0 and p_series_index < _visual_attributes.size():
			var color_buffer: VisualAttributes.ColorBuffer = _visual_attributes[p_series_index].color_buffer
			if color_buffer != null and p_sample_index >= 0 and p_sample_index < color_buffer.size():
				var color = color_buffer.get_value(p_sample_index)
				if color != VisualAttributes.ColorBuffer.NO_COLOR:
					return color

		var global_series_index := _get_global_series_index(p_series_index)

		# Try per sample color (with VisualCallbacks)
		var vc = _bar_config.bar_visual_callbacks
		if vc != null and vc.color_callback.is_valid():
			return vc.color_callback.call(global_series_index, p_sample_index, p_x_value, p_y_value)

		# Use per series color from TauXYStyle (theme if set, otherwise default palette).
		return _xy_style.get_series_color(global_series_index)


	func _get_bar_alpha(p_series_index: int, p_sample_index: int, p_x_value: Variant, p_y_value: float) -> float:
		# Try per sample alpha (with VisualAttributes)
		if p_series_index >= 0 and p_series_index < _visual_attributes.size():
			var alpha_buffer: VisualAttributes.AlphaBuffer = _visual_attributes[p_series_index].alpha_buffer
			if alpha_buffer != null and p_sample_index >= 0 and p_sample_index < alpha_buffer.size():
				var alpha = alpha_buffer.get_value(p_sample_index)
				if alpha >= 0.0:
					return alpha

		# Try per sample alpha (with VisualCallbacks)
		var vc = _bar_config.bar_visual_callbacks
		if vc != null and vc.alpha_callback.is_valid():
			var alpha = vc.alpha_callback.call(_get_global_series_index(p_series_index), p_sample_index, p_x_value, p_y_value)
			if alpha >= 0.0:
				return alpha

		# Use series alpha from TauXYStyle (theme if set, otherwise default value).
		return _xy_style.series_alpha


	func _apply_alpha_override(p_color: Color, p_alpha: float) -> Color:
		var c := p_color
		c.a = clampf(p_alpha, 0.0, 1.0)
		return c


	## Applies the hover color callback (or the built-in default) to a sample's resolved color.
	func _apply_hover_color(p_color: Color, p_series_id: int, p_sample_index: int) -> Color:
		if not _highlight_active:
			return p_color
		var is_hovered: bool
		if _hover_group_mode:
			is_hovered = p_sample_index == _hovered_sample_index
		else:
			is_hovered = p_series_id == _hovered_series_id and p_sample_index == _hovered_sample_index
		if _hover_highlight_callback.is_valid():
			return _hover_highlight_callback.call(p_color, is_hovered)
		# Built-in default: brighten hovered, dim non-hovered.
		if is_hovered:
			return p_color.lightened(0.15)
		else:
			return Color(p_color, 0.5)


	## Resolves the StyleBox for a given bar sample. Checks the callback first,
	## falls back to the cascade-resolved TauBarStyle.style_box. Returns
	## _derived_style_box, a working copy that the caller can freely mutate.
	## The duplicate is only created when the source reference changes.
	func _get_style_box(p_series_index: int, p_sample_index: int, p_x_value: Variant, p_y_value: float) -> StyleBox:
		var source: StyleBox = _bar_style.style_box

		var vc = _bar_config.bar_visual_callbacks
		if vc != null and vc.style_box_callback.is_valid():
			var global_series_index := _get_global_series_index(p_series_index)
			var cb_result: StyleBox = vc.style_box_callback.call(global_series_index, p_sample_index, p_x_value, p_y_value)
			if cb_result != null:
				if not (cb_result is StyleBoxFlat or cb_result is StyleBoxTexture):
					push_error("BarRenderer: style_box_callback returned unsupported type %s, falling back to cascade" % cb_result.get_class())
				else:
					source = cb_result

		# Hovered style box override: applied after callback so the callback
		# still picks the base shape, but hover wins for the hovered bar(s).
		var series_id := _get_bar_series_id(p_series_index)
		var is_hovered_bar: bool
		if _hover_group_mode:
			is_hovered_bar = p_sample_index == _hovered_sample_index
		else:
			is_hovered_bar = series_id == _hovered_series_id and p_sample_index == _hovered_sample_index
		if _highlight_active and is_hovered_bar:
			if _bar_style.hovered_style_box != null:
				source = _bar_style.hovered_style_box

		if source != _derived_source_ref or _derived_style_box == null:
			_derived_style_box = source.duplicate()
			_derived_source_ref = source

		return _derived_style_box


	## Sets the fill color on the StyleBox according to its concrete type.
	## StyleBoxFlat uses bg_color, StyleBoxTexture uses modulate_color.
	func _set_style_box_color(p_sb: StyleBox, p_color: Color) -> void:
		if p_sb is StyleBoxFlat:
			(p_sb as StyleBoxFlat).bg_color = p_color
		elif p_sb is StyleBoxTexture:
			(p_sb as StyleBoxTexture).modulate_color = p_color


	## Remaps corners and borders from canonical orientation (user-authored
	## "bar grows upward from baseline") to the actual screen direction.
	## Reads canonical values from [param p_source] and writes the remapped
	## result into [param p_target].
	func _remap_corners_and_borders(p_target: StyleBoxFlat, p_source: StyleBoxFlat, p_x_horiz: bool, p_tip_at_min: bool) -> void:
		var corner_radius_top_left := p_source.corner_radius_top_left
		var corner_radius_top_right := p_source.corner_radius_top_right
		var corner_radius_bottom_left := p_source.corner_radius_bottom_left
		var corner_radius_bottom_right := p_source.corner_radius_bottom_right
		var border_width_top := p_source.border_width_top
		var border_width_bottom := p_source.border_width_bottom
		var border_width_left := p_source.border_width_left
		var border_width_right := p_source.border_width_right

		if p_x_horiz and p_tip_at_min:
			# Upward (identity): no remapping needed.
			p_target.corner_radius_top_left = corner_radius_top_left
			p_target.corner_radius_top_right = corner_radius_top_right
			p_target.corner_radius_bottom_left = corner_radius_bottom_left
			p_target.corner_radius_bottom_right = corner_radius_bottom_right
			p_target.border_width_top = border_width_top
			p_target.border_width_bottom = border_width_bottom
			p_target.border_width_left = border_width_left
			p_target.border_width_right = border_width_right
		elif p_x_horiz and not p_tip_at_min:
			# Downward (vertical flip): swap top with bottom.
			p_target.corner_radius_top_left = corner_radius_bottom_left
			p_target.corner_radius_top_right = corner_radius_bottom_right
			p_target.corner_radius_bottom_left = corner_radius_top_left
			p_target.corner_radius_bottom_right = corner_radius_top_right
			p_target.border_width_top = border_width_bottom
			p_target.border_width_bottom = border_width_top
			p_target.border_width_left = border_width_left
			p_target.border_width_right = border_width_right
		elif not p_x_horiz and not p_tip_at_min:
			# Rightward (CW 90).
			p_target.corner_radius_top_left = corner_radius_bottom_left
			p_target.corner_radius_top_right = corner_radius_top_left
			p_target.corner_radius_bottom_left = corner_radius_bottom_right
			p_target.corner_radius_bottom_right = corner_radius_top_right
			p_target.border_width_top = border_width_left
			p_target.border_width_bottom = border_width_right
			p_target.border_width_left = border_width_bottom
			p_target.border_width_right = border_width_top
		else:
			# Leftward (CCW 90): not x_horiz and tip_at_min.
			p_target.corner_radius_top_left = corner_radius_top_right
			p_target.corner_radius_top_right = corner_radius_bottom_right
			p_target.corner_radius_bottom_left = corner_radius_top_left
			p_target.corner_radius_bottom_right = corner_radius_bottom_left
			p_target.border_width_top = border_width_right
			p_target.border_width_bottom = border_width_left
			p_target.border_width_left = border_width_top
			p_target.border_width_right = border_width_bottom


	func _compute_series_offset_px(p_series_index: int, p_series_count: int, p_bar_width_px: float, p_gap_px: float) -> float:
		if p_series_count <= 1:
			return 0.0
		var stride := p_bar_width_px + p_gap_px
		var center_index := (float(p_series_count) - 1.0) * 0.5
		return (float(p_series_index) - center_index) * stride


	func _get_y_axis_id_for_series(p_series_id: int) -> AxisId:
		var axis_id: int = _series_assignment.get_y_axis_id_for_series(p_series_id, _pane_index)
		if axis_id != -1:
			return axis_id as AxisId
		# Fallback: should not happen if validation passed.
		push_error("BarRenderer: series %d not assigned to any y-axis in pane %d" % [p_series_id, _pane_index])
		return Axis.get_orthogonal_axes(_layout.domain.config.x_axis_id)[0]


	func _get_y_px_for_series_value(p_series_id: int, p_y_value: float) -> float:
		var axis_id := _get_y_axis_id_for_series(p_series_id)
		return _layout.map_y_to_px(_pane_index, p_y_value, axis_id)


	func _get_zero_px_for_series(p_series_id: int) -> float:
		var axis_id := _get_y_axis_id_for_series(p_series_id)
		var pane_domain := _layout.domain.get_pane_domain(_pane_index)
		var y_axis_domain := pane_domain.get_y_axis_domain(axis_id)
		if y_axis_domain != null and y_axis_domain.scale == TauAxisConfig.Scale.LOGARITHMIC:
			return _layout.map_y_to_px(_pane_index, y_axis_domain.min_val, axis_id)
		return _layout.get_y_zero_px(_pane_index, axis_id)


	func _is_y_value_valid_for_scale(p_series_id: int, p_y_value: float) -> bool:
		var axis_id := _get_y_axis_id_for_series(p_series_id)
		var pane_domain := _layout.domain.get_pane_domain(_pane_index)
		var y_axis_domain := pane_domain.get_y_axis_domain(axis_id)
		if y_axis_domain != null and y_axis_domain.scale == TauAxisConfig.Scale.LOGARITHMIC:
			return p_y_value > 0.0
		return true


	func _is_x_value_valid_for_scale(p_x_value: float) -> bool:
		return _layout.domain.config.x_axis.scale != TauAxisConfig.Scale.LOGARITHMIC or p_x_value > 0.0


	## Draws a single bar, orientation-aware, using a StyleBox.
	## Records a BarHitRecord for every bar that survives clipping.
	func _draw_bar(p_pane_rect: Rect2, p_x_screen: float, p_y_from_screen: float,
				   p_y_to_screen: float, p_thickness_px: float, p_color: Color,
				   p_series_index: int, p_sample_index: int,
				   p_x_value: Variant, p_y_value: float) -> void:
		var x_is_horizontal: bool = _layout._x_is_horizontal

		# TODO: replace the x_is_horizontal branches below with XYLayout.map_point_to_screen() once it exists.

		# Build the clipped screen rect.
		var rect: Rect2
		if x_is_horizontal:
			var left := p_x_screen - p_thickness_px * 0.5
			var right := left + p_thickness_px
			var clipped_left := max(left, p_pane_rect.position.x)
			var clipped_right := min(right, p_pane_rect.position.x + p_pane_rect.size.x)
			var w: float = clipped_right - clipped_left
			if w <= 0.0:
				return
			var top := min(p_y_from_screen, p_y_to_screen)
			var bottom := max(p_y_from_screen, p_y_to_screen)
			var clipped_top := max(top, p_pane_rect.position.y)
			var clipped_bottom := min(bottom, p_pane_rect.position.y + p_pane_rect.size.y)
			var h: float = clipped_bottom - clipped_top
			if h <= 0.0:
				return
			rect = Rect2(Vector2(clipped_left, clipped_top), Vector2(w, h))
		else:
			var top := p_x_screen - p_thickness_px * 0.5
			var bottom := top + p_thickness_px
			var clipped_top := max(top, p_pane_rect.position.y)
			var clipped_bottom := min(bottom, p_pane_rect.position.y + p_pane_rect.size.y)
			var h: float = clipped_bottom - clipped_top
			if h <= 0.0:
				return
			var left := min(p_y_from_screen, p_y_to_screen)
			var right := max(p_y_from_screen, p_y_to_screen)
			var clipped_left := max(left, p_pane_rect.position.x)
			var clipped_right := min(right, p_pane_rect.position.x + p_pane_rect.size.x)
			var w: float = clipped_right - clipped_left
			if w <= 0.0:
				return
			rect = Rect2(Vector2(clipped_left, clipped_top), Vector2(w, h))

		var style_box := _get_style_box(p_series_index, p_sample_index, p_x_value, p_y_value)
		var final_color := _apply_hover_color(p_color, _get_bar_series_id(p_series_index), p_sample_index)
		_set_style_box_color(style_box, final_color)

		if style_box is StyleBoxFlat:
			var tip_at_min: bool = (p_y_to_screen < p_y_from_screen)
			_remap_corners_and_borders(style_box as StyleBoxFlat, _derived_source_ref as StyleBoxFlat, x_is_horizontal, tip_at_min)

		draw_style_box(style_box, rect)

		# Tip-center in screen coords, un-clipped so the anchor stays on the data point
		# even when the bar is partly outside the pane.
		# TODO: use XYLayout.map_point_to_screen() once it exists.
		var anchor: Vector2
		if x_is_horizontal:
			anchor = Vector2(p_x_screen, p_y_to_screen)
		else:
			anchor = Vector2(p_y_to_screen, p_x_screen)

		var record := BarHitRecord.new()
		record.series_id = _get_bar_series_id(p_series_index)
		record.sample_index = p_sample_index
		record.x_value = p_x_value
		record.y_value = p_y_value
		record.rect = rect
		record.anchor = anchor
		_hit_records.append(record)


	## Returns the per-frame hit records cache. Treat as read-only.
	func get_hit_records() -> Array[BarHitRecord]:
		return _hit_records


	func _draw_grouped_bars(p_pane_rect: Rect2, p_series_count: int) -> void:
		if p_series_count <= 0:
			return

		var x_config := _get_x_axis_config()

		match x_config.type:
			TauAxisConfig.Type.CATEGORICAL:
				_draw_grouped_bars_categorical(p_pane_rect, p_series_count)
			TauAxisConfig.Type.CONTINUOUS:
				_draw_grouped_bars_continuous(p_pane_rect, p_series_count)
			_:
				push_error("Unexpected x-axis type %d" % int(x_config.type))


	func _draw_grouped_bars_categorical(p_pane_rect: Rect2, p_series_count: int) -> void:
		var categories := _layout.domain.x_categories
		var n := categories.size()
		if n <= 0:
			return

		var bar_width_px := _geometry_cache.compute_categorical_bar_width_px(p_pane_rect, n)
		bar_width_px = max(bar_width_px, _MIN_BAR_WIDTH_PX)

		# Draw series first (outer loop), then categories (inner loop)
		var draw_order := _get_series_draw_order(p_series_count)
		for series_index: int in draw_order:
			var series_id := _get_bar_series_id(series_index)

			for category_index in range(n):
				if category_index >= _dataset.get_series_sample_count(series_id):
					push_error("BarRenderer: category_index %d is out of range for series_index=%d. Please report this issue." % [category_index, series_index])
					continue

				var y_value := _dataset.get_series_y(series_id, category_index)
				if is_nan(y_value) or is_inf(y_value):
					continue
				if not _is_y_value_valid_for_scale(series_id, y_value):
					continue

				var group_center_px := _layout.map_x_category_center_to_px(_pane_index, category_index)
				var y_px := _get_y_px_for_series_value(series_id, y_value)
				var zero_px := _get_zero_px_for_series(series_id)

				var offset_px := _geometry_cache.compute_grouped_bar_center_offset_px(series_index, p_pane_rect, n)
				var center_px := group_center_px + offset_px

				var x_value: Variant = categories[category_index]
				var base_color := _get_bar_color(series_index, category_index, x_value, y_value)
				var alpha_override := _get_bar_alpha(series_index, category_index, x_value, y_value)
				var color := _apply_alpha_override(base_color, alpha_override)
				_draw_bar(p_pane_rect, center_px, zero_px, y_px, bar_width_px, color, series_index, category_index, x_value, y_value)


	func _draw_grouped_bars_continuous(p_pane_rect: Rect2, p_series_count: int) -> void:
		# Validator ensures: GROUPED requires SHARED_X
		_draw_grouped_bars_continuous_shared_x(p_pane_rect, p_series_count)


	func _draw_grouped_bars_continuous_shared_x(p_pane_rect: Rect2, p_series_count: int) -> void:
		var n := _dataset.get_shared_sample_count()
		if n <= 0:
			return

		var resolved_bar_width_policy := _geometry_cache.get_resolved_bar_width_policy()

		var draw_order := _get_series_draw_order(p_series_count)
		for series_index: int in draw_order:
			var series_id := _get_bar_series_id(series_index)

			for i in range(n):
				var x_value := float(_dataset.get_shared_x(i))
				if is_nan(x_value) or is_inf(x_value):
					continue
				if not _is_x_value_valid_for_scale(x_value):
					continue

				if i >= _dataset.get_series_sample_count(series_id):
					push_error("BarRenderer: sample index %d is out of range for series_index=%d. Please report this issue." % [i, series_index])
					continue

				var y_value := _dataset.get_series_y(series_id, i)
				if is_nan(y_value) or is_inf(y_value):
					continue
				if not _is_y_value_valid_for_scale(series_id, y_value):
					continue

				var group_center_px := _layout.map_x_to_px(_pane_index, x_value)

				var bar_width_px := 0.0
				var gap_px := 0.0

				match resolved_bar_width_policy:
					TauBarConfig.BarWidthPolicy.THEME, TauBarConfig.BarWidthPolicy.DATA_UNITS, TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION:
						bar_width_px = _geometry_cache.compute_bar_width_px_for_shared_x_index(i, n)
						gap_px = _geometry_cache.compute_group_gap_px_for_shared_x_index(i, n)

					_:
						push_error("BarRenderer: bar_width_policy %d is not supported for CONTINUOUS X axis type" % int(resolved_bar_width_policy))
						return

				var y_px := _get_y_px_for_series_value(series_id, y_value)
				var zero_px := _get_zero_px_for_series(series_id)

				var offset_px := _compute_series_offset_px(series_index, p_series_count, bar_width_px, gap_px)
				var center_px := group_center_px + offset_px

				var base_color := _get_bar_color(series_index, i, x_value, y_value)
				var alpha_override := _get_bar_alpha(series_index, i, x_value, y_value)
				var color := _apply_alpha_override(base_color, alpha_override)
				_draw_bar(p_pane_rect, center_px, zero_px, y_px, bar_width_px, color, series_index, i, x_value, y_value)


	func _draw_stacked_bars(p_pane_rect: Rect2, p_series_count: int) -> void:
		# Validator ensures: STACKED requires SHARED_X and SHARED y-axis
		if p_series_count <= 0:
			return

		var x_config := _get_x_axis_config()

		match x_config.type:
			TauAxisConfig.Type.CATEGORICAL:
				_draw_stacked_bars_categorical(p_pane_rect, p_series_count)
			TauAxisConfig.Type.CONTINUOUS:
				_draw_stacked_bars_continuous_shared_x(p_pane_rect, p_series_count)
			_:
				push_error("Unexpected x-axis type %d" % int(x_config.type))


	func _draw_stacked_bars_categorical(p_pane_rect: Rect2, p_series_count: int) -> void:
		var stacked_axis_id := _get_y_axis_id_for_series(_get_bar_series_id(0))
		var categories := _layout.domain.x_categories
		var n := categories.size()
		if n <= 0:
			return

		var bar_width_px := _geometry_cache.compute_categorical_bar_width_px(p_pane_rect, n)
		bar_width_px = max(bar_width_px, _MIN_BAR_WIDTH_PX)

		# First pass: compute all segments for all categories (in dataset order for stacking)
		var all_segments: Array = []  # Array of arrays, one per category. FIXME Godot 4.5 does not support nested typed collections.
		all_segments.resize(n)

		for category_index in range(n):
			var total := 0.0
			if _bar_config.stacked_normalization != TauBarConfig.StackedNormalization.NONE:
				for series_index in range(p_series_count):
					var series_id := _get_bar_series_id(series_index)
					var y_value := _dataset.get_series_y(series_id, category_index)
					if is_nan(y_value) or is_inf(y_value):
						continue
					if y_value < 0.0:
						continue  # STACKED: skip negative values for total calculation
					total += y_value

			var scale := 1.0
			if _bar_config.stacked_normalization == TauBarConfig.StackedNormalization.FRACTION:
				scale = 1.0 / total if total > 0.0 else 0.0
			elif _bar_config.stacked_normalization == TauBarConfig.StackedNormalization.PERCENT:
				scale = 100.0 / total if total > 0.0 else 0.0

			# Compute segments for this category in dataset order
			var segments: Array = []
			var accum := 0.0
			for series_index in range(p_series_count):
				var series_id := _get_bar_series_id(series_index)
				var y_raw := _dataset.get_series_y(series_id, category_index)
				if is_nan(y_raw) or is_inf(y_raw):
					continue
				if y_raw < 0.0:
					continue  # STACKED: skip negative values

				var y := y_raw * scale
				var y0 := accum
				var y1 := accum + y

				segments.append({"series_index": series_index, "y0": y0, "y1": y1})
				accum = y1

			all_segments[category_index] = segments

		# Second pass: paint in z_order (series first, then categories)
		var draw_order := _get_series_draw_order(p_series_count)
		for series_index: int in draw_order:
			for category_index in range(n):
				var group_center_px := _layout.map_x_category_center_to_px(_pane_index, category_index)
				var segments = all_segments[category_index]

				# Find the segment for this series at this category
				var segment = null
				for seg in segments:
					if seg["series_index"] == series_index:
						segment = seg
						break

				if segment == null:
					continue  # This series had no valid data at this category

				var y0_px := _layout.map_y_to_px(_pane_index, segment["y0"], stacked_axis_id)
				var y1_px := _layout.map_y_to_px(_pane_index, segment["y1"], stacked_axis_id)

				var x_value: Variant = categories[category_index]
				var y_value: float = segment["y1"]
				var base_color := _get_bar_color(series_index, category_index, x_value, y_value)
				var alpha_override := _get_bar_alpha(series_index, category_index, x_value, y_value)
				var color := _apply_alpha_override(base_color, alpha_override)

				_draw_bar(p_pane_rect, group_center_px, y0_px, y1_px, bar_width_px, color, series_index, category_index, x_value, y_value)


	func _draw_stacked_bars_continuous_shared_x(p_pane_rect: Rect2, p_series_count: int) -> void:
		var stacked_axis_id := _get_y_axis_id_for_series(_get_bar_series_id(0))
		var n := _dataset.get_shared_sample_count()
		if n <= 0:
			return

		var resolved_bar_width_policy := _geometry_cache.get_resolved_bar_width_policy()

		# First pass: compute all segments for all X positions (in dataset order for stacking)
		var all_segments: Array = []  # Array of arrays, one per X position. FIXME Godot 4.5 does not support nested typed collections.
		all_segments.resize(n)

		for i in range(n):
			var x_value := float(_dataset.get_shared_x(i))
			if is_nan(x_value) or is_inf(x_value):
				all_segments[i] = []
				continue
			if not _is_x_value_valid_for_scale(x_value):
				all_segments[i] = []
				continue

			var total := 0.0
			if _bar_config.stacked_normalization != TauBarConfig.StackedNormalization.NONE:
				for series_index in range(p_series_count):
					var series_id := _get_bar_series_id(series_index)
					var y_value := _dataset.get_series_y(series_id, i)
					if is_nan(y_value) or is_inf(y_value):
						continue
					if y_value < 0.0:
						continue  # STACKED: skip negative values for total calculation
					total += y_value

			var scale := 1.0
			if _bar_config.stacked_normalization == TauBarConfig.StackedNormalization.FRACTION:
				scale = 1.0 / total if total > 0.0 else 0.0
			elif _bar_config.stacked_normalization == TauBarConfig.StackedNormalization.PERCENT:
				scale = 100.0 / total if total > 0.0 else 0.0

			# Compute segments for this X position in dataset order
			var segments: Array = []
			var accum := 0.0
			for series_index in range(p_series_count):
				var series_id := _get_bar_series_id(series_index)
				var y_raw := _dataset.get_series_y(series_id, i)
				if is_nan(y_raw) or is_inf(y_raw):
					continue
				if y_raw < 0.0:
					continue  # STACKED: skip negative values

				var y := y_raw * scale
				var y0 := accum
				var y1 := accum + y

				segments.append({"series_index": series_index, "y0": y0, "y1": y1})
				accum = y1

			all_segments[i] = segments

		# Second pass: paint in z_order (series first, then X positions)
		var draw_order := _get_series_draw_order(p_series_count)
		for series_index: int in draw_order:
			for i in range(n):
				var x_value := float(_dataset.get_shared_x(i))
				if is_nan(x_value) or is_inf(x_value):
					continue
				if not _is_x_value_valid_for_scale(x_value):
					continue

				var segments = all_segments[i]

				# Find the segment for this series at this X position
				var segment = null
				for seg in segments:
					if seg["series_index"] == series_index:
						segment = seg
						break

				if segment == null:
					continue  # This series had no valid data at this X position

				var group_center_px := _layout.map_x_to_px(_pane_index, x_value)

				var bar_width_px := 0.0
				match resolved_bar_width_policy:
					TauBarConfig.BarWidthPolicy.THEME, TauBarConfig.BarWidthPolicy.DATA_UNITS, TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION:
						bar_width_px = _geometry_cache.compute_bar_width_px_for_shared_x_index(i, n)

					_:
						push_error("BarRenderer: bar_width_policy %d is not supported for STACKED + CONTINUOUS" % int(resolved_bar_width_policy))
						return

				var y0_px := _layout.map_y_to_px(_pane_index, segment["y0"], stacked_axis_id)
				var y1_px := _layout.map_y_to_px(_pane_index, segment["y1"], stacked_axis_id)

				var y_value: float = segment["y1"]
				var base_color := _get_bar_color(series_index, i, x_value, y_value)
				var alpha_override := _get_bar_alpha(series_index, i, x_value, y_value)
				var color := _apply_alpha_override(base_color, alpha_override)

				_draw_bar(p_pane_rect, group_center_px, y0_px, y1_px, bar_width_px, color, series_index, i, x_value, y_value)


	func _draw_independent_bars(p_pane_rect: Rect2, p_series_count: int) -> void:
		if p_series_count <= 0:
			return

		var x_config := _get_x_axis_config()

		match x_config.type:
			TauAxisConfig.Type.CATEGORICAL:
				_draw_independent_bars_categorical(p_pane_rect, p_series_count)
			TauAxisConfig.Type.CONTINUOUS:
				_draw_independent_bars_continuous(p_pane_rect, p_series_count)
			_:
				push_error("Unexpected x-axis type %d" % int(x_config.type))


	func _draw_independent_bars_categorical(p_pane_rect: Rect2, p_series_count: int) -> void:
		# Validator ensures: CATEGORICAL requires SHARED_X
		var categories := _layout.domain.x_categories
		var n := categories.size()
		if n <= 0:
			return

		var bar_width_px := _geometry_cache.compute_categorical_bar_width_px(p_pane_rect, n)
		bar_width_px = max(bar_width_px, _MIN_BAR_WIDTH_PX)

		var draw_order := _get_series_draw_order(p_series_count)

		for category_index in range(n):
			var center_px := _layout.map_x_category_center_to_px(_pane_index, category_index)

			for series_index: int in draw_order:
				var series_id := _get_bar_series_id(series_index)

				if category_index >= _dataset.get_series_sample_count(series_id):
					continue

				var y_value := _dataset.get_series_y(series_id, category_index)
				if is_nan(y_value) or is_inf(y_value):
					continue
				if not _is_y_value_valid_for_scale(series_id, y_value):
					continue

				var y_px := _get_y_px_for_series_value(series_id, y_value)
				var zero_px := _get_zero_px_for_series(series_id)

				var x_value: Variant = _get_x_categories_for_series(series_id)[category_index]
				var base_color := _get_bar_color(series_index, category_index, x_value, y_value)
				var alpha_override := _get_bar_alpha(series_index, category_index, x_value, y_value)
				var color := _apply_alpha_override(base_color, alpha_override)

				_draw_bar(p_pane_rect, center_px, zero_px, y_px, bar_width_px, color, series_index, category_index, x_value, y_value)


	func _draw_independent_bars_continuous(p_pane_rect: Rect2, p_series_count: int) -> void:
		if _dataset.get_mode() == Dataset.Mode.SHARED_X:
			_draw_independent_bars_continuous_shared_x(p_pane_rect, p_series_count)
			return
		_draw_independent_bars_continuous_per_series_x(p_pane_rect, p_series_count)


	func _draw_independent_bars_continuous_shared_x(p_pane_rect: Rect2, p_series_count: int) -> void:
		var n := _dataset.get_shared_sample_count()
		if n <= 0:
			return

		var draw_order := _get_series_draw_order(p_series_count)
		var resolved_bar_width_policy := _geometry_cache.get_resolved_bar_width_policy()

		for series_index: int in draw_order:
			var series_id := _get_bar_series_id(series_index)

			for i in range(n):
				var x_value := float(_dataset.get_shared_x(i))
				if is_nan(x_value) or is_inf(x_value):
					continue
				if not _is_x_value_valid_for_scale(x_value):
					continue

				if i >= _dataset.get_series_sample_count(series_id):
					continue

				var y_value := _dataset.get_series_y(series_id, i)
				if is_nan(y_value) or is_inf(y_value):
					continue
				if not _is_y_value_valid_for_scale(series_id, y_value):
					continue

				var center_px := _get_x_px_for_series_value(series_id, x_value)

				var bar_width_px := 0.0
				match resolved_bar_width_policy:
					TauBarConfig.BarWidthPolicy.THEME, TauBarConfig.BarWidthPolicy.DATA_UNITS, TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION:
						bar_width_px = _geometry_cache.compute_bar_width_px_for_shared_x_index(i, n)

					_:
						push_error("BarRenderer: bar_width_policy %d is not supported for INDEPENDENT + CONTINUOUS" % int(resolved_bar_width_policy))
						return

				bar_width_px = max(bar_width_px, _MIN_BAR_WIDTH_PX)

				var y_px := _get_y_px_for_series_value(series_id, y_value)
				var zero_px := _get_zero_px_for_series(series_id)

				var base_color := _get_bar_color(series_index, i, x_value, y_value)
				var alpha_override := _get_bar_alpha(series_index, i, x_value, y_value)
				var color := _apply_alpha_override(base_color, alpha_override)

				_draw_bar(p_pane_rect, center_px, zero_px, y_px, bar_width_px, color, series_index, i, x_value, y_value)


	func _draw_independent_bars_continuous_per_series_x(p_pane_rect: Rect2, p_series_count: int) -> void:
		var draw_order := _get_series_draw_order(p_series_count)
		var resolved_bar_width_policy := _geometry_cache.get_resolved_bar_width_policy()

		for series_index: int in draw_order:
			var series_id := _get_bar_series_id(series_index)

			var count := _dataset.get_series_sample_count(series_id)

			for i in range(count):
				var x_value := float(_dataset.get_series_x(series_id, i))
				if is_nan(x_value) or is_inf(x_value):
					continue
				if not _is_x_value_valid_for_scale(x_value):
					continue

				var y_value := _dataset.get_series_y(series_id, i)
				if is_nan(y_value) or is_inf(y_value):
					continue
				if not _is_y_value_valid_for_scale(series_id, y_value):
					continue

				var bar_width_px := 0.0
				match resolved_bar_width_policy:
					TauBarConfig.BarWidthPolicy.THEME, TauBarConfig.BarWidthPolicy.DATA_UNITS, TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION:
						bar_width_px = _geometry_cache.compute_bar_width_px_for_series_sample(series_id, i, count)

					_:
						push_error("BarRenderer: bar_width_policy %d is not supported for INDEPENDENT + CONTINUOUS" % int(resolved_bar_width_policy))
						return

				bar_width_px = max(bar_width_px, _MIN_BAR_WIDTH_PX)

				var center_px := _get_x_px_for_series_value(series_id, x_value)
				var y_px := _get_y_px_for_series_value(series_id, y_value)
				var zero_px := _get_zero_px_for_series(series_id)

				var base_color := _get_bar_color(series_index, i, x_value, y_value)
				var alpha_override := _get_bar_alpha(series_index, i, x_value, y_value)
				var color := _apply_alpha_override(base_color, alpha_override)

				_draw_bar(p_pane_rect, center_px, zero_px, y_px, bar_width_px, color, series_index, i, x_value, y_value)


	func _get_series_draw_order(p_series_count: int) -> Array[int]:
		var out: Array[int] = []
		out.resize(p_series_count)

		if _bar_config.z_order == TauPaneOverlayConfig.ZOrder.REVERSE_SERIES_ORDER:
			for i in range(p_series_count):
				out[i] = (p_series_count - 1) - i
			return out

		for i in range(p_series_count):
			out[i] = i
		return out
