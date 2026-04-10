const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const Axis = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis
const SeriesAxisAssignment := preload("res://addons/tau-plot/plot/xy/series_axis_assignment.gd").SeriesAxisAssignment
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout

const _OrientedTitle := preload("res://addons/tau-plot/ui/oriented_title.tscn")


# Manages the creation, positioning, and teardown of per-pane axis title controls
# around an XY pane stack.
#
# Each of the four edges (left, right, top, bottom) has a container that holds
# one control per pane: either an OrientedTitle with label text or a blank spacer
# that preserves stretch ratios. This class owns those controls and aligns their
# insets to the data area rectangles computed by XYLayout.
class XYAxisTitleLayout extends RefCounted:

	# The four edge containers (owned by the XYPlot scene tree, not by this class).
	var _left_container: BoxContainer = null
	var _right_container: BoxContainer = null
	var _top_container: BoxContainer = null
	var _bottom_container: BoxContainer = null

	# Per-pane controls (OrientedTitle instances or spacers), one per edge.
	var _titles_left: Array = []
	var _titles_right: Array = []
	var _titles_top: Array = []
	var _titles_bottom: Array = []


	func _init(p_left: BoxContainer, p_right: BoxContainer,
			p_top: BoxContainer, p_bottom: BoxContainer) -> void:
		_left_container = p_left
		_right_container = p_right
		_top_container = p_top
		_bottom_container = p_bottom


	## Creates axis title controls (or spacers) for every pane on all four edges.
	## Call [method clear] before calling this if a previous layout exists.
	func build(p_xy_config: TauXYConfig, p_series_assignment: SeriesAxisAssignment) -> void:
		clear()

		var pane_count := p_xy_config.panes.size()
		_titles_left.resize(pane_count)
		_titles_right.resize(pane_count)
		_titles_top.resize(pane_count)
		_titles_bottom.resize(pane_count)

		var has_any_left := false
		var has_any_right := false
		var has_any_top := false
		var has_any_bottom := false

		for pane_index in range(pane_count):
			var pane_config: TauPaneConfig = p_xy_config.panes[pane_index]

			# Left edge
			has_any_left = _build_edge(
				AxisId.LEFT, p_xy_config, pane_config, pane_index, pane_count,
				p_series_assignment, _left_container, _titles_left,
				true, has_any_left)

			# Right edge
			has_any_right = _build_edge(
				AxisId.RIGHT, p_xy_config, pane_config, pane_index, pane_count,
				p_series_assignment, _right_container, _titles_right,
				true, has_any_right)

			# Top edge
			has_any_top = _build_edge(
				AxisId.TOP, p_xy_config, pane_config, pane_index, pane_count,
				p_series_assignment, _top_container, _titles_top,
				false, has_any_top)

			# Bottom edge
			has_any_bottom = _build_edge(
				AxisId.BOTTOM, p_xy_config, pane_config, pane_index, pane_count,
				p_series_assignment, _bottom_container, _titles_bottom,
				false, has_any_bottom)

		_left_container.visible = has_any_left
		_right_container.visible = has_any_right
		_top_container.visible = has_any_top
		_bottom_container.visible = has_any_bottom


	## Updates title control insets so labels align with the data area rectangles.
	func update_insets(p_xy_layout: XYLayout, p_pane_containers: Array) -> void:
		if p_xy_layout == null:
			return
		var pane_count := p_xy_layout.pane_layouts.size()
		for i in range(pane_count):
			if i >= p_pane_containers.size() or p_pane_containers[i] == null:
				continue
			var pane_rect: Rect2 = p_xy_layout.pane_layouts[i].pane_rect
			var pane_container: Control = p_pane_containers[i]

			# Convert data area edges to global coordinates so insets are correct
			# regardless of nesting depth relative to each title container.
			var data_left_global := pane_container.global_position.x + pane_rect.position.x
			var data_right_global := data_left_global + pane_rect.size.x
			var data_top_global := pane_container.global_position.y + pane_rect.position.y
			var data_bottom_global := data_top_global + pane_rect.size.y

			# Left/Right containers stack vertically, so insets are top and bottom.
			_apply_vertical_insets(_titles_left, i, data_top_global, data_bottom_global)
			_apply_vertical_insets(_titles_right, i, data_top_global, data_bottom_global)

			# Top/Bottom containers stack horizontally, so insets are left and right.
			_apply_horizontal_insets(_titles_top, i, data_left_global, data_right_global)
			_apply_horizontal_insets(_titles_bottom, i, data_left_global, data_right_global)


	## Updates the separation theme override on all four title containers.
	func update_separation(p_gap: int) -> void:
		_left_container.add_theme_constant_override(&"separation", p_gap)
		_right_container.add_theme_constant_override(&"separation", p_gap)
		_top_container.add_theme_constant_override(&"separation", p_gap)
		_bottom_container.add_theme_constant_override(&"separation", p_gap)


	## Frees all title controls and spacers from the edge containers, then hides them.
	func clear() -> void:
		_clear_edge(_left_container, _titles_left)
		_clear_edge(_right_container, _titles_right)
		_clear_edge(_top_container, _titles_top)
		_clear_edge(_bottom_container, _titles_bottom)
		_left_container.visible = false
		_right_container.visible = false
		_top_container.visible = false
		_bottom_container.visible = false


	############################################################################################
	# Private
	############################################################################################

	## Builds a single edge control for one pane. Returns an updated has_any flag.
	func _build_edge(
			p_axis_id: AxisId, p_xy_config: TauXYConfig, p_pane_config: TauPaneConfig,
			p_pane_index: int, p_pane_count: int,
			p_series_assignment: SeriesAxisAssignment,
			p_container: BoxContainer, p_titles_array: Array,
			p_is_vertical_container: bool, p_has_any: bool) -> bool:

		var cfg: TauAxisConfig = _get_axis_config(p_axis_id, p_xy_config, p_pane_config)
		var text := cfg.title if cfg != null else ""
		var has_series := _axis_has_series(p_axis_id, p_xy_config, p_pane_index, p_series_assignment)
		var is_shared_x := (p_axis_id == p_xy_config.x_axis_id or p_axis_id == Axis.get_opposite(p_xy_config.x_axis_id))
		# Shared x axis titles appear only on the pane nearest to the edge.
		var show := not text.is_empty() and has_series and (not is_shared_x or _is_pane_nearest_to_edge(p_pane_index, p_pane_count, p_axis_id))

		if show:
			var label := _OrientedTitle.instantiate()
			if p_is_vertical_container:
				label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			else:
				label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.size_flags_stretch_ratio = p_pane_config.stretch_ratio
			label.text = text
			label.title_orientation = _resolve_title_orientation(cfg.title_orientation, p_axis_id)
			label.title_alignment = cfg.title_alignment
			label.text_alignment = cfg.title_text_alignment
			p_container.add_child(label)
			p_titles_array[p_pane_index] = label
			return true
		else:
			var spacer := Control.new()
			if p_is_vertical_container:
				spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
			else:
				spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spacer.size_flags_stretch_ratio = p_pane_config.stretch_ratio
			p_container.add_child(spacer)
			p_titles_array[p_pane_index] = spacer
			return p_has_any


	static func _apply_vertical_insets(p_titles: Array, p_index: int,
			p_data_top_global: float, p_data_bottom_global: float) -> void:
		if p_index >= p_titles.size() or p_titles[p_index] == null:
			return
		if not &"inset_top" in p_titles[p_index]:
			return
		var ctrl: Control = p_titles[p_index]
		ctrl.inset_top = p_data_top_global - ctrl.global_position.y
		ctrl.inset_bottom = (ctrl.global_position.y + ctrl.size.y) - p_data_bottom_global


	static func _apply_horizontal_insets(p_titles: Array, p_index: int,
			p_data_left_global: float, p_data_right_global: float) -> void:
		if p_index >= p_titles.size() or p_titles[p_index] == null:
			return
		if not &"inset_left" in p_titles[p_index]:
			return
		var ctrl: Control = p_titles[p_index]
		ctrl.inset_left = p_data_left_global - ctrl.global_position.x
		ctrl.inset_right = (ctrl.global_position.x + ctrl.size.x) - p_data_right_global


	static func _clear_edge(p_container: BoxContainer, p_titles: Array) -> void:
		for node in p_titles:
			if node != null and is_instance_valid(node):
				p_container.remove_child(node)
				node.queue_free()
		p_titles.clear()


	## Returns true if [param p_pane_index] is the pane closest to [param p_edge].
	## In a vertical stack (x horizontal), TOP is nearest pane 0, BOTTOM is nearest pane N-1.
	## In a horizontal stack (x vertical), LEFT is nearest pane 0, RIGHT is nearest pane N-1.
	static func _is_pane_nearest_to_edge(p_pane_index: int, p_pane_count: int, p_edge: AxisId) -> bool:
		match p_edge:
			AxisId.BOTTOM, AxisId.RIGHT:
				return p_pane_index == p_pane_count - 1
			AxisId.TOP, AxisId.LEFT:
				return p_pane_index == 0
		return false


	# Returns the TauAxisConfig that occupies a given edge, considering that the
	# x-axis and secondary x-axis are global while y-axes come from TauPaneConfig.
	static func _get_axis_config(p_axis_id: AxisId, p_xy_config: TauXYConfig, p_pane_cfg: TauPaneConfig) -> TauAxisConfig:
		if p_axis_id == p_xy_config.x_axis_id:
			return p_xy_config.x_axis
		if p_axis_id == Axis.get_opposite(p_xy_config.x_axis_id):
			return p_xy_config.secondary_x_axis
		return p_pane_cfg.get_y_axis_config(p_axis_id)


	# Returns true if the given axis has at least one series assigned to it.
	# For x-axis ids the check is whether any series exists at all.
	static func _axis_has_series(p_axis_id: AxisId, p_xy_config: TauXYConfig,
			p_pane_index: int, p_assignment: SeriesAxisAssignment) -> bool:
		if p_axis_id == p_xy_config.x_axis_id or p_axis_id == Axis.get_opposite(p_xy_config.x_axis_id):
			return p_assignment.get_x_axis_series_count(p_pane_index) > 0
		return p_assignment.get_y_axis_series_count(p_pane_index, p_axis_id) > 0


	static func _resolve_title_orientation(p_orientation: TauAxisConfig.TitleOrientation, p_axis_id: AxisId) -> TauAxisConfig.TitleOrientation:
		if p_orientation != TauAxisConfig.TitleOrientation.AUTO:
			return p_orientation
		if p_axis_id == AxisId.BOTTOM or p_axis_id == AxisId.TOP:
			return TauAxisConfig.TitleOrientation.HORIZONTAL
		return TauAxisConfig.TitleOrientation.VERTICAL
