# Dependencies
const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout
const ScatterGeometry := preload("res://addons/tau-plot/plot/xy/scatter/scatter_geometry.gd").ScatterGeometry
const SeriesAxisAssignment := preload("res://addons/tau-plot/plot/xy/series_axis_assignment.gd").SeriesAxisAssignment
const AxisId := preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const Axis := preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis
const VisualAttributes := preload("res://addons/tau-plot/plot/xy/visual_attributes.gd").VisualAttributes
const ScatterVisualAttributes := preload("res://addons/tau-plot/plot/xy/scatter/scatter_visual_attributes.gd").ScatterVisualAttributes
const MarkerShape := preload("res://addons/tau-plot/plot/xy/scatter/scatter_style.gd").MarkerShape
const HoverHighlight := preload("res://addons/tau-plot/plot/xy/hover/hover_highlight.gd").HoverHighlight

const SCATTER_SHADER: Shader = preload("res://addons/tau-plot/plot/xy/scatter/scatter.gdshader")

# Draws scatter plots using one persistent MultiMesh per series.
#
# Each series owns a single MultiMeshInstance2D whose instance_count equals
# the series ring-buffer capacity (from the dataset). The visible_instance_count
# is set to the number of markers actually written each frame, avoiding GPU
# buffer reallocation on every update.
#
# Marker shape is packed into per-instance custom data so a single shared
# ShaderMaterial handles all shapes (including CROSS and PLUS via SDF).
#
# Update flow:
#   plot.gd calls update_scatter() when data/layout changes.
#   update_scatter() iterates series in draw order, writing transform, color,
#   and custom data directly into each series MultiMesh.
class ScatterRenderer extends Control:
	var _layout: XYLayout = null
	var _dataset: Dataset = null
	var _scatter_config: TauScatterConfig = null
	var _series_assignment: SeriesAxisAssignment = null

	# Parallel to _scatter_series_ids: one entry per pane-local series, in the same order.
	# Series without user-supplied attributes get an empty instance. This is the only
	# per-series array indexed by the pane-local index rather than the dataset-global one.
	var _visual_attributes: Array[ScatterVisualAttributes] = []

	# Pane index this renderer belongs to. Used for per-pane domain/layout queries.
	var _pane_index: int = 0

	var _scatter_series_ids: PackedInt64Array = PackedInt64Array()

	# Cached GPU resources (created once, reused across updates).
	var _unit_quad_mesh: ArrayMesh = null
	var _shared_material: ShaderMaterial = null

	# Persistent per-series render entry cache
	var _series_cache: Dictionary[int, _SeriesRenderEntry] = {}

	# Cache
	var _geometry_cache: ScatterGeometry = null

	# Resolved style instances pushed by xy_plot. Treat as read-only.
	var _scatter_style: TauScatterStyle = null
	var _xy_style: TauXYStyle = null

	# Hover hit-testing caches. Rebuilt every update_scatter() call.
	# Parallel arrays: index i describes the i-th visible marker.
	var _hover_screen_positions: PackedVector2Array = PackedVector2Array()
	var _hover_series_ids: PackedInt64Array = PackedInt64Array()
	var _hover_sample_indices: PackedInt32Array = PackedInt32Array()
	var _hover_x_values: Array = []  # Variant per marker (float or String)
	var _hover_y_values: PackedFloat64Array = PackedFloat64Array()

	# Hover highlight state. When _highlight_active is true, every marker's color
	# is run through the hover color callback to dim non-hovered and brighten
	# hovered markers.
	var _highlight_active: bool = false
	var _hovered_series_id: int = -1
	var _hovered_sample_index: int = -1
	var _hover_highlight_callback: Callable = Callable()


	func _init(p_layout: XYLayout,
				p_dataset: Dataset,
				p_scatter_config: TauScatterConfig,
				p_series_assignment: SeriesAxisAssignment,
				p_pane_index: int = 0,
				p_visual_attributes: Array[ScatterVisualAttributes] = [],
				p_scatter_series_ids: PackedInt64Array = PackedInt64Array()) -> void:
		theme_type_variation = &"TauScatter"
		_layout = p_layout
		_dataset = p_dataset
		_scatter_config = p_scatter_config
		_series_assignment = p_series_assignment
		_pane_index = p_pane_index
		_visual_attributes = p_visual_attributes
		_scatter_series_ids = p_scatter_series_ids


	func _ready() -> void:
		# Ignore mouse events (this is a rendering-only control).
		mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Pre-build shared GPU resources.
		_build_unit_quad_mesh()
		_build_shared_material()


	func get_config() -> TauScatterConfig:
		return _scatter_config


	## Receives the resolved TauScatterStyle from xy_plot after cascade resolution.
	func set_resolved_scatter_style(p_style: TauScatterStyle) -> void:
		_scatter_style = p_style


	## Receives the resolved TauXYStyle from xy_plot after cascade resolution.
	func set_resolved_xy_style(p_style: TauXYStyle) -> void:
		_xy_style = p_style


	## Updates the hover highlight state. Called by HoverController when the
	## hovered sample changes or when highlight is activated/deactivated.
	func set_hover_state(p_active: bool, p_series_id: int, p_sample_index: int, p_color_callback: Callable) -> void:
		var changed := p_active != _highlight_active or p_series_id != _hovered_series_id or p_sample_index != _hovered_sample_index
		_highlight_active = p_active
		_hovered_series_id = p_series_id
		_hovered_sample_index = p_sample_index
		_hover_highlight_callback = p_color_callback
		if changed:
			_update_hover_instances()

	####################################################################################################
	# Public API
	####################################################################################################

	# Called by plot.gd instead of queue_redraw().
	# Iterates series in draw order, writing marker data directly into each
	# series MultiMesh. No intermediate marker objects or batch grouping.
	func update_scatter() -> void:
		var pane_rect := _layout.get_pane_rect(_pane_index)
		if pane_rect.size.x <= 0.0 or pane_rect.size.y <= 0.0:
			_hide_all_entries()
			_clear_hover_caches()
			return

		_geometry_cache = ScatterGeometry.new(_layout, _scatter_config, _scatter_style, _pane_index)

		var series_count := _get_scatter_series_count()
		if series_count <= 0:
			_hide_all_entries()
			_clear_hover_caches()
			return

		_prune_cache()

		# Reset hover caches before rebuilding.
		_clear_hover_caches()

		var draw_order := _get_series_draw_order(series_count)
		var x_config := _get_x_axis_config()

		for draw_rank in range(draw_order.size()):
			var series_index: int = draw_order[draw_rank]
			var series_id := _get_scatter_series_id(series_index)

			var entry := _get_or_create_entry(series_id)
			entry.mmi.visible = true
			_apply_data_area_clip(entry.mmi, pane_rect)

			# Set child draw order so later draw_rank renders on top.
			if entry.mmi.get_index() != draw_rank:
				move_child(entry.mmi, draw_rank)

			var marker_count := 0
			match x_config.type:
				TauAxisConfig.Type.CATEGORICAL:
					marker_count = _write_series_categorical(pane_rect, series_index, series_id, entry)
				TauAxisConfig.Type.CONTINUOUS:
					if _dataset.get_mode() == Dataset.Mode.SHARED_X:
						marker_count = _write_series_shared_x(pane_rect, series_index, series_id, entry)
					else:
						marker_count = _write_series_per_series_x(pane_rect, series_index, series_id, entry)

			entry.mm.visible_instance_count = marker_count


	## Creates a legend key Control for a scatter overlay using the same SDF shader
	## as the main scatter rendering path. The returned Control hosts a single-instance
	## MultiMeshInstance2D that renders the marker shape with fill color, alpha,
	## outline color, and outline width, producing a pixel-perfect match.
	##
	## Reads all visual properties from resolved styles on this renderer instance:
	## fill color, alpha, marker shape, outline color, outline width, marker size.
	## For DATA_UNITS marker size policy, computes size at the domain midpoint.
	func create_legend_key_control(p_global_series_index: int) -> Control:
		var key := _ScatterLegendKey.new(_unit_quad_mesh, _shared_material)
		_write_legend_key(p_global_series_index, key)
		return key


	## Re-resolves the appearance of a legend key created by
	## create_legend_key_control(), so a style change costs no rebuild of the
	## legend row. Under the DATA_UNITS marker size policy the requested box
	## follows the current layout, so call it after the layout update.
	func refresh_legend_key_control(p_global_series_index: int, p_control: Control) -> void:
		_write_legend_key(p_global_series_index, p_control as _ScatterLegendKey)


	####################################################################################################
	# Legend key
	####################################################################################################

	## Control hosting the single-instance MultiMesh that draws one marker.
	## Rendered through the same shared SDF material as the scatter path, so the
	## key is pixel-identical to a real marker.
	class _ScatterLegendKey extends Control:
		var _multi_mesh: MultiMesh = null

		func _init(p_mesh: Mesh, p_material: Material) -> void:
			_multi_mesh = MultiMesh.new()
			_multi_mesh.transform_format = MultiMesh.TRANSFORM_2D
			_multi_mesh.use_colors = true
			_multi_mesh.use_custom_data = true
			_multi_mesh.mesh = p_mesh
			_multi_mesh.instance_count = 1
			_multi_mesh.visible_instance_count = 1

			var mmi := MultiMeshInstance2D.new()
			mmi.multimesh = _multi_mesh
			mmi.material = p_material
			add_child(mmi)

		## Sizes the box to the marker and writes the single instance, centered.
		func write_marker(p_size_px: float, p_fill_color: Color, p_custom_data: Color) -> void:
			custom_minimum_size = Vector2(p_size_px, p_size_px)
			var marker_transform := Transform2D().scaled(Vector2(p_size_px, p_size_px))
			marker_transform.origin = Vector2(p_size_px * 0.5, p_size_px * 0.5)
			_multi_mesh.set_instance_transform_2d(0, marker_transform)
			_multi_mesh.set_instance_color(0, p_fill_color)
			_multi_mesh.set_instance_custom_data(0, p_custom_data)


	## Resolves the marker size in pixels for the legend key.
	## THEME policy: uses the resolved scatter style size cycle.
	## DATA_UNITS policy: computes pixel size at the domain x midpoint
	## via ScatterGeometry.compute_marker_size_px_at_x. Keys are also built
	## before the first layout update, where no pixel span exists yet, so the
	## theme size stands in until refresh_legend_key_control() runs.
	func _resolve_legend_marker_size_px(p_global_series_index: int) -> float:
		var policy := _scatter_config.get_resolved_marker_size_policy()
		if policy == TauScatterConfig.MarkerSizePolicy.DATA_UNITS and _layout.has_pane_layouts():
			var x_domain := _layout.domain.x_axis_domain
			if x_domain.min_val < x_domain.max_val:
				var x_mid: float = (x_domain.min_val + x_domain.max_val) * 0.5
				var geom := ScatterGeometry.new(_layout, _scatter_config, _scatter_style, _pane_index)
				return geom.compute_marker_size_px_at_x(x_mid)
		return _scatter_style.get_series_size_px(p_global_series_index)


	# Resolves the marker appearance and writes it into the key. Per-sample
	# styling and hover emphasis are left out, so the key shows the per-series
	# marker only.
	func _write_legend_key(p_global_series_index: int, p_key: _ScatterLegendKey) -> void:
		var alpha := _xy_style.get_series_alpha(p_global_series_index)
		var fill_color := _apply_alpha(_xy_style.get_series_color(p_global_series_index), alpha)
		var outline_color := _apply_alpha(_scatter_style.outline_color, alpha)
		var shape: MarkerShape = _scatter_style.get_series_shape(p_global_series_index)

		var size_px := _resolve_legend_marker_size_px(p_global_series_index)
		var outline_width_norm: float = 0.0
		if size_px > 0.0:
			outline_width_norm = clampf(_scatter_style.outline_width_px / size_px, 0.0, 0.5)

		p_key.write_marker(size_px, fill_color, _pack_custom_data(outline_color, shape, outline_width_norm))


	####################################################################################################
	# Per-series render entry cache
	####################################################################################################

	class _SeriesRenderEntry extends RefCounted:
		var mmi: MultiMeshInstance2D = null
		var mm: MultiMesh = null
		var cached_capacity: int = 0


	func _get_or_create_entry(p_series_id: int) -> _SeriesRenderEntry:
		if _series_cache.has(p_series_id):
			var entry: _SeriesRenderEntry = _series_cache[p_series_id]
			var capacity := _dataset.get_series_capacity(p_series_id)
			if capacity != entry.cached_capacity:
				_resize_entry(entry, capacity)
			return entry

		var capacity := _dataset.get_series_capacity(p_series_id)
		var entry := _SeriesRenderEntry.new()

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_2D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = _unit_quad_mesh
		mm.instance_count = capacity
		mm.visible_instance_count = 0

		var mmi := MultiMeshInstance2D.new()
		mmi.multimesh = mm
		mmi.material = _shared_material

		entry.mmi = mmi
		entry.mm = mm
		entry.cached_capacity = capacity

		add_child(mmi)
		_series_cache[p_series_id] = entry
		return entry


	# Confines the markers to the data area.
	func _apply_data_area_clip(p_mmi: MultiMeshInstance2D, p_pane_rect: Rect2) -> void:
		var canvas_item := p_mmi.get_canvas_item()
		RenderingServer.canvas_item_set_custom_rect(canvas_item, true, p_pane_rect)
		RenderingServer.canvas_item_set_clip(canvas_item, true)


	func _resize_entry(p_entry: _SeriesRenderEntry, p_new_capacity: int) -> void:
		p_entry.mm.instance_count = p_new_capacity
		p_entry.mm.visible_instance_count = 0
		p_entry.cached_capacity = p_new_capacity


	func _prune_cache() -> void:
		# Build a set of active series ids for fast lookup.
		var active_ids := {}
		for sid in _scatter_series_ids:
			active_ids[sid] = true

		var stale_ids: Array[int] = []
		for sid in _series_cache:
			if not active_ids.has(sid):
				stale_ids.append(sid)

		for sid in stale_ids:
			var entry: _SeriesRenderEntry = _series_cache[sid]
			remove_child(entry.mmi)
			entry.mmi.queue_free()
			_series_cache.erase(sid)


	func _hide_all_entries() -> void:
		for sid in _series_cache:
			var entry: _SeriesRenderEntry = _series_cache[sid]
			entry.mm.visible_instance_count = 0
			entry.mmi.visible = false


	####################################################################################################
	# GPU resource construction (cached, built once)
	####################################################################################################

	func _build_unit_quad_mesh() -> void:
		# A unit quad from (-0.5, -0.5) to (0.5, 0.5) with UVs from (0, 0) to (1, 1).
		# Two triangles. Used by all marker shapes (the shader determines the shape via SDF).
		_unit_quad_mesh = ArrayMesh.new()

		var verts := PackedVector2Array([
			Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5),
			Vector2(-0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)
		])
		var uvs := PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0),
			Vector2(0.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)
		])

		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		_unit_quad_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


	func _build_shared_material() -> void:
		# One ShaderMaterial shared by all series. Shape type is per-instance data,
		# not a uniform, so no per-shape materials are needed.
		_shared_material = ShaderMaterial.new()
		_shared_material.shader = SCATTER_SHADER


	####################################################################################################
	# Private series helpers
	####################################################################################################

	func _get_scatter_series_count() -> int:
		return _scatter_series_ids.size()


	func _get_scatter_series_id(p_scatter_index: int) -> int:
		return _scatter_series_ids[p_scatter_index]


	func _get_series_draw_order(p_series_count: int) -> Array[int]:
		var out: Array[int] = []
		out.resize(p_series_count)

		if _scatter_config.z_order == TauPaneOverlayConfig.ZOrder.REVERSE_SERIES_ORDER:
			for i in range(p_series_count):
				out[i] = (p_series_count - 1) - i
			return out

		for i in range(p_series_count):
			out[i] = i
		return out


	# Returns the dataset-global series index for a given pane-local series index.
	func _get_global_series_index(p_local_index: int) -> int:
		return _dataset.get_series_index_by_id(_scatter_series_ids[p_local_index])


	####################################################################################################
	# Private property resolution fallback chains
	####################################################################################################

	func _get_marker_color(p_series_index: int, p_sample_index: int, p_x_value: Variant, p_y_value: float) -> Color:
		# Try per sample color (with VisualAttributes)
		var buf = _visual_attributes[p_series_index].color_buffer
		if buf != null and p_sample_index >= 0 and p_sample_index < buf.size():
			var c = buf.get_value(p_sample_index)
			if c != VisualAttributes.ColorBuffer.NO_COLOR:
				return c

		var global_series_index := _get_global_series_index(p_series_index)

		# Try per sample color (with VisualCallbacks)
		var vc = _scatter_config.scatter_visual_callbacks
		if vc != null and vc.color_callback.is_valid():
			var c = vc.color_callback.call(global_series_index, p_sample_index, p_x_value, p_y_value)
			if c != VisualAttributes.ColorBuffer.NO_COLOR:
				return c

		# Use per series color from TauXYStyle (theme if set, otherwise default palette).
		return _xy_style.get_series_color(global_series_index)


	func _get_marker_alpha(p_series_index: int, p_sample_index: int, p_x_value: Variant, p_y_value: float) -> float:
		# Try per sample alpha (with VisualAttributes)
		var buf = _visual_attributes[p_series_index].alpha_buffer
		if buf != null and p_sample_index >= 0 and p_sample_index < buf.size():
			var alpha = buf.get_value(p_sample_index)
			if alpha >= 0.0:
				return alpha

		var global_series_index := _get_global_series_index(p_series_index)

		# Try per sample alpha (with VisualCallbacks)
		var vc = _scatter_config.scatter_visual_callbacks
		if vc != null and vc.alpha_callback.is_valid():
			var alpha = vc.alpha_callback.call(global_series_index, p_sample_index, p_x_value, p_y_value)
			if alpha >= 0.0:
				return alpha

		# Use per series alpha from TauXYStyle (theme if set, otherwise default value).
		return _xy_style.get_series_alpha(global_series_index)


	func _get_marker_size_px(p_series_index: int, p_sample_index: int, p_x_value: Variant, p_y_value: float) -> float:
		var global_series_index := _get_global_series_index(p_series_index)

		# Try per sample marker size (with VisualAttributes)
		var buf = _visual_attributes[p_series_index].size_buffer
		if buf != null and p_sample_index >= 0 and p_sample_index < buf.size():
			var sz = buf.get_value(p_sample_index)
			if sz >= 0.0:
				var policy := _geometry_cache.get_resolved_marker_size_policy()
				if policy == TauScatterConfig.MarkerSizePolicy.DATA_UNITS:
					return _compute_size_px_from_data_units(sz, p_x_value, global_series_index)
				return max(sz, 1.0)

		# Try per sample marker size (with VisualCallbacks)
		var vc = _scatter_config.scatter_visual_callbacks
		if vc != null and vc.size_callback.is_valid():
			var sz = vc.size_callback.call(global_series_index, p_sample_index, p_x_value, p_y_value)
			if sz >= 0.0:
				var policy := _geometry_cache.get_resolved_marker_size_policy()
				if policy == TauScatterConfig.MarkerSizePolicy.DATA_UNITS:
					return _compute_size_px_from_data_units(sz, p_x_value, global_series_index)
				return max(sz, 1.0)

		var policy := _geometry_cache.get_resolved_marker_size_policy()
		match policy:
			TauScatterConfig.MarkerSizePolicy.DATA_UNITS:
				if p_x_value is float:
					# If marker size is provided in data units on a CONTINUOUS axis, its size needs
					# to be computed.
					return _geometry_cache.compute_marker_size_px_at_x(p_x_value)
				else:
					# If marker size is provided in data units on a CATEGORICAL axis, use marker size
					# from theme if set, otherwise from style default value.
					return _geometry_cache.get_marker_size_px_from_theme(global_series_index)
			_:
				# Use marker size from theme if set, otherwise from style default value.
				return _geometry_cache.get_marker_size_px_from_theme(global_series_index)


	# A negative value is the "no override" sentinel, so it falls through to the
	# next step. Any other value out of range draws a circle, as it does on the
	# style, but without a message: this runs once per sample.
	func _get_marker_shape(p_series_index: int, p_sample_index: int, p_x_value: Variant, p_y_value: float) -> MarkerShape:
		# Try per sample marker shape (with VisualAttributes)
		var buf = _visual_attributes[p_series_index].shape_buffer
		if buf != null and p_sample_index >= 0 and p_sample_index < buf.size():
			var shape_val: int = buf.get_value(p_sample_index)
			if shape_val >= 0:
				return TauScatterStyle.resolve_marker_shape(shape_val)

		# Try per sample marker shape (with VisualCallbacks)
		var vc = _scatter_config.scatter_visual_callbacks
		if vc != null and vc.shape_callback.is_valid():
			var shape_val := int(vc.shape_callback.call(_get_global_series_index(p_series_index), p_sample_index, p_x_value, p_y_value))
			if shape_val >= 0:
				return TauScatterStyle.resolve_marker_shape(shape_val)

		# Use per series shape (from theme if set, otherwise from style default value)
		return _scatter_style.get_series_shape(_get_global_series_index(p_series_index))


	func _get_marker_outline_color(p_series_index: int, p_sample_index: int, p_x_value: Variant, p_y_value: float) -> Color:
		# Try per sample outline color (with VisualAttributes)
		var buf = _visual_attributes[p_series_index].outline_color_buffer
		if buf != null and p_sample_index >= 0 and p_sample_index < buf.size():
			var c = buf.get_value(p_sample_index)
			if c != VisualAttributes.ColorBuffer.NO_COLOR:
				return c

		var global_series_index := _get_global_series_index(p_series_index)

		# Try per sample outline color (with VisualCallbacks)
		var vc = _scatter_config.scatter_visual_callbacks
		if vc != null and vc.outline_color_callback.is_valid():
			var c = vc.outline_color_callback.call(global_series_index, p_sample_index, p_x_value, p_y_value)
			if c != VisualAttributes.ColorBuffer.NO_COLOR:
				return c

		# Use outline color from theme if set, otherwise from style default value.
		return _scatter_style.outline_color


	func _get_marker_outline_width(p_series_index: int, p_sample_index: int, p_x_value: Variant, p_y_value: float) -> float:
		# Try per sample outline width (with VisualAttributes)
		var buf = _visual_attributes[p_series_index].outline_width_buffer
		if buf != null and p_sample_index >= 0 and p_sample_index < buf.size():
			var w = buf.get_value(p_sample_index)
			if w >= 0.0:
				return w

		# Try per sample outline width (with VisualCallbacks)
		var vc = _scatter_config.scatter_visual_callbacks
		if vc != null and vc.outline_width_callback.is_valid():
			var w = vc.outline_width_callback.call(_get_global_series_index(p_series_index), p_sample_index, p_x_value, p_y_value)
			if w >= 0.0:
				return w

		# Use outline width from theme if set, otherwise from style default value.
		return _scatter_style.outline_width_px


	func _apply_alpha(p_color: Color, p_alpha: float) -> Color:
		var c := p_color
		c.a = clampf(p_alpha, 0.0, 1.0)
		return c


	## Applies the hover color callback (or the built-in default) to a marker's resolved color.
	func _apply_hover_color(p_color: Color, p_series_id: int, p_sample_index: int) -> Color:
		if not _highlight_active:
			return p_color
		var is_hovered := p_series_id == _hovered_series_id and p_sample_index == _hovered_sample_index
		return HoverHighlight.resolve(p_color, is_hovered, _hover_highlight_callback)


	####################################################################################################
	# Hover instance patching
	####################################################################################################

	## Rewrites per-instance color on all visible markers without rebuilding
	## transforms. Called from set_hover_state() when the hover highlight changes.
	func _update_hover_instances() -> void:
		var marker_count: int = _hover_screen_positions.size()
		if marker_count <= 0:
			return

		for idx: int in range(marker_count):
			var series_id: int = _hover_series_ids[idx]
			var sample_index: int = _hover_sample_indices[idx]
			var x_value: Variant = _hover_x_values[idx]
			var y_value: float = _hover_y_values[idx]

			# Resolve the local series index from the dataset series ID.
			var series_index: int = -1
			for si: int in range(_scatter_series_ids.size()):
				if _scatter_series_ids[si] == series_id:
					series_index = si
					break
			if series_index == -1:
				continue

			var entry: _SeriesRenderEntry = _series_cache.get(series_id)
			if entry == null:
				continue

			# Determine this marker's slot in the MultiMesh. We need to count
			# how many markers for this series_id precede this one in the hover
			# caches. The hover caches are built in draw order, and within each
			# series, markers are written sequentially starting from slot 0.
			var slot: int = 0
			for prev: int in range(idx):
				if _hover_series_ids[prev] == series_id:
					slot += 1

			if slot >= entry.mm.visible_instance_count:
				continue

			# Re-resolve color through the normal pipeline, then apply hover.
			var base_color := _get_marker_color(series_index, sample_index, x_value, y_value)
			var alpha := _get_marker_alpha(series_index, sample_index, x_value, y_value)
			var fill_color := _apply_alpha(base_color, alpha)
			fill_color = _apply_hover_color(fill_color, series_id, sample_index)
			entry.mm.set_instance_color(slot, fill_color)

			# Rewrite transform and custom_data for the hovered marker so that
			# size and outline reflect hovered-state style properties.
			var is_hovered := _highlight_active and series_id == _hovered_series_id and sample_index == _hovered_sample_index
			var size_px := _get_marker_size_px(series_index, sample_index, x_value, y_value)
			var outline_color: Color
			var outline_width: float
			if is_hovered:
				# An empty hovered size cycle returns the sentinel and leaves the base size in place.
				var hovered_size_px := _scatter_style.get_series_hovered_size_px(_get_global_series_index(series_index))
				if hovered_size_px > 0.0:
					size_px = hovered_size_px
				outline_width = _scatter_style.hovered_outline_width_px
				outline_color = _apply_alpha(_scatter_style.hovered_outline_color, alpha)
			else:
				outline_width = _get_marker_outline_width(series_index, sample_index, x_value, y_value)
				outline_color = _apply_alpha(_get_marker_outline_color(series_index, sample_index, x_value, y_value), alpha)

			var screen_pos: Vector2 = _hover_screen_positions[idx]
			var t := Transform2D()
			t = t.scaled(Vector2(size_px, size_px))
			t.origin = screen_pos
			entry.mm.set_instance_transform_2d(slot, t)

			var ow_norm: float = 0.0
			if size_px > 0.0:
				ow_norm = clampf(outline_width / size_px, 0.0, 0.5)
			var shape := _get_marker_shape(series_index, sample_index, x_value, y_value)
			entry.mm.set_instance_custom_data(slot, _pack_custom_data(outline_color, shape, ow_norm))


	####################################################################################################
	# Private size conversion
	####################################################################################################

	func _compute_size_px_from_data_units(p_size_data_units: float, p_x_value: Variant, p_global_series_index: int) -> float:
		if p_size_data_units <= 0.0:
			return 1.0
		if p_x_value is float or p_x_value is int:
			var half := p_size_data_units * 0.5
			var x_f := float(p_x_value)
			# Use shared x axis mapping for size computation (DATA_UNITS is X-space).
			var px0 := _layout.map_x_to_px(_pane_index, x_f - half)
			var px1 := _layout.map_x_to_px(_pane_index, x_f + half)
			return max(absf(px1 - px0), 1.0)
		return _geometry_cache.get_marker_size_px_from_theme(p_global_series_index)


	####################################################################################################
	# Private axis helpers
	####################################################################################################

	func _get_y_axis_id_for_series(p_series_id: int) -> AxisId:
		var axis_id: int = _series_assignment.get_y_axis_id_for_series(p_series_id, _pane_index)
		if axis_id != -1:
			return axis_id as AxisId
		# Fallback: should not happen if validation passed.
		push_error("ScatterRenderer: series %d not assigned to any y-axis in pane %d" % [p_series_id, _pane_index])
		return Axis.get_orthogonal_axes(_layout.domain.config.x_axis_id)[0]


	func _get_y_px_for_series_value(p_series_id: int, p_y_value: float) -> float:
		var axis_id := _get_y_axis_id_for_series(p_series_id)
		return _layout.map_y_to_px(_pane_index, p_y_value, axis_id)


	func _is_y_value_valid_for_scale(p_series_id: int, p_y_value: float) -> bool:
		var axis_id := _get_y_axis_id_for_series(p_series_id)
		var pane_domain := _layout.domain.get_pane_domain(_pane_index)
		var y_axis_domain := pane_domain.get_y_axis_domain(axis_id)
		if y_axis_domain != null and y_axis_domain.scale == TauAxisConfig.Scale.LOGARITHMIC:
			return p_y_value > 0.0
		return true


	func _is_x_value_valid_for_scale_for_series(p_series_id: int, p_x_value: float) -> bool:
		var x_config := _get_x_axis_config()
		if x_config.type == TauAxisConfig.Type.CONTINUOUS:
			if x_config.scale == TauAxisConfig.Scale.LOGARITHMIC:
				return p_x_value > 0.0
		return true


	# Returns the shared x axis config.
	func _get_x_axis_config() -> TauAxisConfig:
		return _layout.domain.config.x_axis


	func _get_x_px_for_series_value(p_series_id: int, p_x_value: float) -> float:
		return _layout.map_x_to_px(_pane_index, p_x_value)


	func _get_x_category_center_px(p_series_id: int, p_category_index: int) -> float:
		return _layout.map_x_category_center_to_px(_pane_index, p_category_index)


	func _get_x_categories_for_series(p_series_id: int) -> PackedStringArray:
		return _layout.domain.x_categories


	func _is_center_in_pane_rect(p_pane_rect: Rect2, p_x: float, p_y: float) -> bool:
		# Half-pixel tolerance prevents flickering when a marker center lands
		# exactly on the pane boundary due to floating-point rounding in layout
		# mapping. This is purely cosmetic and does not affect layout or ticks.
		const TOLERANCE_PX := 0.5
		var screen := _layout.map_point_to_screen(p_x, p_y)
		return (screen.x >= p_pane_rect.position.x - TOLERANCE_PX and
				screen.x <= p_pane_rect.position.x + p_pane_rect.size.x + TOLERANCE_PX and
				screen.y >= p_pane_rect.position.y - TOLERANCE_PX and
				screen.y <= p_pane_rect.position.y + p_pane_rect.size.y + TOLERANCE_PX)

	####################################################################################################
	# Per-instance custom data packing
	####################################################################################################

	# Packs outline_color, shape_type, and outline_width into a single Color for INSTANCE_CUSTOM.
	#
	# Layout:
	#   .r = outline_color.r  (passed through directly)
	#   .g = outline_color.g  (passed through directly)
	#   .b = floor(outline_color.b * 255.0) + (shape_type + 0.5) / 16.0
	#         The integer part encodes blue as a quantized 0-255 value scaled to 0.0-255.0.
	#         The fractional part encodes shape_type so the shader can recover it.
	#         It holds 16 slots, which every MarkerShape member fits in.
	#   .a = outline_width_normalized
	static func _pack_custom_data(p_outline_color: Color, p_shape: MarkerShape, p_outline_width_norm: float) -> Color:
		var blue_quantized := floorf(p_outline_color.b * 255.0)
		var shape_fract := (float(p_shape) + 0.5) / 16.0
		var packed_b := blue_quantized + shape_fract
		return Color(p_outline_color.r, p_outline_color.g, packed_b, p_outline_width_norm)


	####################################################################################################
	# Direct per-series marker writing
	####################################################################################################

	func _write_marker_to_entry(p_entry: _SeriesRenderEntry, p_slot: int,
								 p_series_index: int, p_sample_index: int,
								 p_x_value: Variant, p_y_value: float,
								 p_cx: float, p_cy: float) -> int:
		var shape := _get_marker_shape(p_series_index, p_sample_index, p_x_value, p_y_value)
		if shape == MarkerShape.NONE:
			return 0

		var size_px := _get_marker_size_px(p_series_index, p_sample_index, p_x_value, p_y_value)
		var base_color := _get_marker_color(p_series_index, p_sample_index, p_x_value, p_y_value)
		var alpha := _get_marker_alpha(p_series_index, p_sample_index, p_x_value, p_y_value)
		var fill_color := _apply_alpha(base_color, alpha)
		var series_id := _get_scatter_series_id(p_series_index)
		fill_color = _apply_hover_color(fill_color, series_id, p_sample_index)
		var outline_color := _get_marker_outline_color(p_series_index, p_sample_index, p_x_value, p_y_value)
		outline_color = _apply_alpha(outline_color, alpha)
		var outline_width := _get_marker_outline_width(p_series_index, p_sample_index, p_x_value, p_y_value)

		# Hovered-state style property overrides for the specifically hovered marker.
		if _highlight_active and series_id == _hovered_series_id and p_sample_index == _hovered_sample_index:
			# An empty hovered size cycle returns the sentinel and leaves the base size in place.
			var hovered_size_px := _scatter_style.get_series_hovered_size_px(_get_global_series_index(p_series_index))
			if hovered_size_px > 0.0:
				size_px = hovered_size_px
			outline_width = _scatter_style.hovered_outline_width_px
			outline_color = _apply_alpha(_scatter_style.hovered_outline_color, alpha)

		# Transform: translate to center, scale by size_px.
		# The callers pass the x-axis pixel as p_cx and the y-axis pixel as p_cy
		var screen := _layout.map_point_to_screen(p_cx, p_cy)
		var t := Transform2D()
		t = t.scaled(Vector2(size_px, size_px))
		t.origin = screen
		p_entry.mm.set_instance_transform_2d(p_slot, t)

		# Color: fill color with alpha
		p_entry.mm.set_instance_color(p_slot, fill_color)

		# Custom data: outline info + shape type packed together
		var ow_norm: float = 0.0
		if size_px > 0.0:
			ow_norm = clampf(outline_width / size_px, 0.0, 0.5)
		p_entry.mm.set_instance_custom_data(p_slot, _pack_custom_data(outline_color, shape, ow_norm))

		# Record hover data for hit testing.
		_hover_screen_positions.append(screen)
		_hover_series_ids.append(series_id)
		_hover_sample_indices.append(p_sample_index)
		_hover_x_values.append(p_x_value)
		_hover_y_values.append(p_y_value)

		return 1


	func _write_series_categorical(p_pane_rect: Rect2, p_series_index: int, p_series_id: int, p_entry: _SeriesRenderEntry) -> int:
		var categories := _get_x_categories_for_series(p_series_id)
		var n := categories.size()
		var slot := 0
		for cat_idx in range(n):
			if cat_idx >= _dataset.get_series_sample_count(p_series_id):
				continue
			var y_value := _dataset.get_series_y(p_series_id, cat_idx)
			if is_nan(y_value) or is_inf(y_value):
				continue
			if not _is_y_value_valid_for_scale(p_series_id, y_value):
				continue
			var cx := _get_x_category_center_px(p_series_id, cat_idx)
			var cy := _get_y_px_for_series_value(p_series_id, y_value)
			if not _is_center_in_pane_rect(p_pane_rect, cx, cy):
				continue
			var x_val: Variant = categories[cat_idx]
			slot += _write_marker_to_entry(p_entry, slot, p_series_index, cat_idx, x_val, y_value, cx, cy)
		return slot


	func _write_series_shared_x(p_pane_rect: Rect2, p_series_index: int, p_series_id: int, p_entry: _SeriesRenderEntry) -> int:
		var n := _dataset.get_shared_sample_count()
		var slot := 0
		for i in range(n):
			var x_value := float(_dataset.get_shared_x(i))
			if is_nan(x_value) or is_inf(x_value):
				continue
			if not _is_x_value_valid_for_scale_for_series(p_series_id, x_value):
				continue
			if i >= _dataset.get_series_sample_count(p_series_id):
				continue
			var y_value := _dataset.get_series_y(p_series_id, i)
			if is_nan(y_value) or is_inf(y_value):
				continue
			if not _is_y_value_valid_for_scale(p_series_id, y_value):
				continue
			var cx := _get_x_px_for_series_value(p_series_id, x_value)
			var cy := _get_y_px_for_series_value(p_series_id, y_value)
			if not _is_center_in_pane_rect(p_pane_rect, cx, cy):
				continue
			slot += _write_marker_to_entry(p_entry, slot, p_series_index, i, x_value, y_value, cx, cy)
		return slot


	func _write_series_per_series_x(p_pane_rect: Rect2, p_series_index: int, p_series_id: int, p_entry: _SeriesRenderEntry) -> int:
		var count := _dataset.get_series_sample_count(p_series_id)
		var slot := 0
		for i in range(count):
			var x_value := float(_dataset.get_series_x(p_series_id, i))
			if is_nan(x_value) or is_inf(x_value):
				continue
			if not _is_x_value_valid_for_scale_for_series(p_series_id, x_value):
				continue
			var y_value := _dataset.get_series_y(p_series_id, i)
			if is_nan(y_value) or is_inf(y_value):
				continue
			if not _is_y_value_valid_for_scale(p_series_id, y_value):
				continue
			var cx := _get_x_px_for_series_value(p_series_id, x_value)
			var cy := _get_y_px_for_series_value(p_series_id, y_value)
			if not _is_center_in_pane_rect(p_pane_rect, cx, cy):
				continue
			slot += _write_marker_to_entry(p_entry, slot, p_series_index, i, x_value, y_value, cx, cy)
		return slot


	####################################################################################################
	# Hover hit testing
	####################################################################################################

	func _clear_hover_caches() -> void:
		_hover_screen_positions.clear()
		_hover_series_ids.clear()
		_hover_sample_indices.clear()
		_hover_x_values.clear()
		_hover_y_values.clear()


	## Returns the hover cache size (number of visible markers with cached positions).
	func get_hover_cache_size() -> int:
		return _hover_screen_positions.size()


	## Returns the cached screen position for the i-th visible marker.
	func get_hover_screen_position(p_index: int) -> Vector2:
		return _hover_screen_positions[p_index]


	## Returns the series_id for the i-th visible marker.
	func get_hover_series_id(p_index: int) -> int:
		return _hover_series_ids[p_index]


	## Returns the sample index for the i-th visible marker.
	func get_hover_sample_index(p_index: int) -> int:
		return _hover_sample_indices[p_index]


	## Returns the x value for the i-th visible marker.
	func get_hover_x_value(p_index: int) -> Variant:
		return _hover_x_values[p_index]


	## Returns the y value for the i-th visible marker.
	func get_hover_y_value(p_index: int) -> float:
		return _hover_y_values[p_index]
