const AxisId := preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const Axis := preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis
const SeriesAxisAssignment := preload("res://addons/tau-plot/plot/xy/series_axis_assignment.gd").SeriesAxisAssignment
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout

const _OrientedTitle := preload("res://addons/tau-plot/ui/oriented_title.tscn")


# Manages the creation, positioning, and teardown of axis title controls around
# an XY pane stack.
#
# Two of the four edge containers run along the stacking direction and hold one
# control per pane, either an OrientedTitle with label text or a blank spacer
# that preserves stretch ratios. The other two run across the stack and hold a
# single control spanning the whole edge. This class owns those controls and
# gives each of them the data area rectangle it aligns with.
class XYAxisTitleLayout extends RefCounted:

	# The four edge containers (owned by the XYPlot scene tree, not by this class).
	var _left_container: BoxContainer = null
	var _right_container: BoxContainer = null
	var _top_container: BoxContainer = null
	var _bottom_container: BoxContainer = null

	# Controls per edge. The two edges along the stacking direction hold one
	# entry per pane, the two across it hold a single entry.
	var _titles_left: Array = []
	var _titles_right: Array = []
	var _titles_top: Array = []
	var _titles_bottom: Array = []

	# True when panes stack vertically, false otherwise.
	var _panes_stack_vertically: bool = true


	func _init(p_left: BoxContainer, p_right: BoxContainer,
			p_top: BoxContainer, p_bottom: BoxContainer) -> void:
		_left_container = p_left
		_right_container = p_right
		_top_container = p_top
		_bottom_container = p_bottom


	## Creates the axis title controls on all four edges.
	## Call [method clear] before calling this if a previous layout exists.
	func build(p_xy_config: TauXYConfig, p_series_assignment: SeriesAxisAssignment) -> void:
		clear()

		_panes_stack_vertically = Axis.is_horizontal(p_xy_config.x_axis_id)

		var pane_count := p_xy_config.panes.size()

		var has_any_left := false
		var has_any_right := false
		var has_any_top := false
		var has_any_bottom := false

		if _panes_stack_vertically:
			_titles_left.resize(pane_count)
			_titles_right.resize(pane_count)
			for pane_index in range(pane_count):
				var pane_config: TauPaneConfig = p_xy_config.panes[pane_index]
				has_any_left = _build_pane_edge(
					AxisId.LEFT, p_xy_config, pane_config, pane_index,
					p_series_assignment, _left_container, _titles_left,
					true, has_any_left)
				has_any_right = _build_pane_edge(
					AxisId.RIGHT, p_xy_config, pane_config, pane_index,
					p_series_assignment, _right_container, _titles_right,
					true, has_any_right)

			has_any_top = _build_cross_edge(
				AxisId.TOP, p_xy_config, pane_count, p_series_assignment,
				_top_container, _titles_top, false)
			has_any_bottom = _build_cross_edge(
				AxisId.BOTTOM, p_xy_config, pane_count, p_series_assignment,
				_bottom_container, _titles_bottom, false)
		else:
			_titles_top.resize(pane_count)
			_titles_bottom.resize(pane_count)
			for pane_index in range(pane_count):
				var pane_config: TauPaneConfig = p_xy_config.panes[pane_index]
				has_any_top = _build_pane_edge(
					AxisId.TOP, p_xy_config, pane_config, pane_index,
					p_series_assignment, _top_container, _titles_top,
					false, has_any_top)
				has_any_bottom = _build_pane_edge(
					AxisId.BOTTOM, p_xy_config, pane_config, pane_index,
					p_series_assignment, _bottom_container, _titles_bottom,
					false, has_any_bottom)

			has_any_left = _build_cross_edge(
				AxisId.LEFT, p_xy_config, pane_count, p_series_assignment,
				_left_container, _titles_left, true)
			has_any_right = _build_cross_edge(
				AxisId.RIGHT, p_xy_config, pane_count, p_series_assignment,
				_right_container, _titles_right, true)

		_left_container.visible = has_any_left
		_right_container.visible = has_any_right
		_top_container.visible = has_any_top
		_bottom_container.visible = has_any_bottom


	## Gives every title control the data area rectangle it aligns with.
	func update_insets(p_xy_layout: XYLayout, p_panes: Array) -> void:
		if p_xy_layout == null:
			return
		var pane_count := p_xy_layout.pane_layouts.size()
		for i in range(pane_count):
			if i >= p_panes.size() or p_panes[i] == null:
				continue
			var pane_rect: Rect2 = p_xy_layout.pane_layouts[i].pane_rect
			var pane: Control = p_panes[i]

			# Global coordinates, so the alignment is correct whatever the
			# nesting depth of each title container.
			var data_left_global := pane.global_position.x + pane_rect.position.x
			var data_right_global := data_left_global + pane_rect.size.x
			var data_top_global := pane.global_position.y + pane_rect.position.y
			var data_bottom_global := data_top_global + pane_rect.size.y

			if _panes_stack_vertically:
				_apply_data_area(_titles_left, i, data_top_global, data_bottom_global, false)
				_apply_data_area(_titles_right, i, data_top_global, data_bottom_global, false)
				# One control for the whole edge, aligned with the pane that
				# draws the axis.
				if _is_pane_nearest_to_edge(i, pane_count, AxisId.TOP):
					_apply_data_area(_titles_top, 0, data_left_global, data_right_global, true)
				if _is_pane_nearest_to_edge(i, pane_count, AxisId.BOTTOM):
					_apply_data_area(_titles_bottom, 0, data_left_global, data_right_global, true)
			else:
				_apply_data_area(_titles_top, i, data_left_global, data_right_global, true)
				_apply_data_area(_titles_bottom, i, data_left_global, data_right_global, true)
				if _is_pane_nearest_to_edge(i, pane_count, AxisId.LEFT):
					_apply_data_area(_titles_left, 0, data_top_global, data_bottom_global, false)
				if _is_pane_nearest_to_edge(i, pane_count, AxisId.RIGHT):
					_apply_data_area(_titles_right, 0, data_top_global, data_bottom_global, false)


	## Sets the stretch ratio of the title controls of one pane.
	## Each edge container along the stacking direction splits its length
	## between its controls by stretch ratio, so a title only sits next to its
	## pane while the two ratios match. The edges across the stack hold a
	## single control and take no ratio.
	## [param p_pane_index] Zero-based pane index.
	## [param p_stretch_ratio] The stretch ratio of the pane.
	func set_stretch_ratio_for_pane(p_pane_index: int, p_stretch_ratio: float) -> void:
		if _panes_stack_vertically:
			_titles_left[p_pane_index].size_flags_stretch_ratio = p_stretch_ratio
			_titles_right[p_pane_index].size_flags_stretch_ratio = p_stretch_ratio
		else:
			_titles_top[p_pane_index].size_flags_stretch_ratio = p_stretch_ratio
			_titles_bottom[p_pane_index].size_flags_stretch_ratio = p_stretch_ratio


	## Updates the separation theme override on all four title containers.
	func update_separation(p_gap: int) -> void:
		_left_container.add_theme_constant_override(&"separation", p_gap)
		_right_container.add_theme_constant_override(&"separation", p_gap)
		_top_container.add_theme_constant_override(&"separation", p_gap)
		_bottom_container.add_theme_constant_override(&"separation", p_gap)


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

	## Builds the control of one pane on an edge running along the stacking
	## direction, which always carries a y axis. Returns an updated has_any flag.
	func _build_pane_edge(
			p_axis_id: AxisId, p_xy_config: TauXYConfig, p_pane_config: TauPaneConfig,
			p_pane_index: int,
			p_series_assignment: SeriesAxisAssignment,
			p_container: BoxContainer, p_titles_array: Array,
			p_is_vertical_container: bool, p_has_any: bool) -> bool:

		var cfg: TauAxisConfig = _get_axis_config(p_axis_id, p_xy_config, p_pane_config)
		var text := cfg.title if cfg != null else ""
		var has_series := _axis_has_series(p_axis_id, p_xy_config, p_pane_index, p_series_assignment)

		if not text.is_empty() and has_series:
			var label := _OrientedTitle.instantiate()
			_fill_along_container(label, p_is_vertical_container)
			label.size_flags_stretch_ratio = p_pane_config.stretch_ratio
			label.text = text
			label.title_orientation = _resolve_title_orientation(cfg.title_orientation, p_axis_id)
			label.title_alignment = cfg.title_alignment
			label.text_alignment = cfg.title_text_alignment
			p_container.add_child(label)
			p_titles_array[p_pane_index] = label
			return true

		var spacer := Control.new()
		_fill_along_container(spacer, p_is_vertical_container)
		spacer.size_flags_stretch_ratio = p_pane_config.stretch_ratio
		p_container.add_child(spacer)
		p_titles_array[p_pane_index] = spacer
		return p_has_any


	## Builds the single control of an edge running across the stack, which
	## always carries the primary or the secondary x axis. Returns whether a
	## title was built.
	func _build_cross_edge(
			p_axis_id: AxisId, p_xy_config: TauXYConfig, p_pane_count: int,
			p_series_assignment: SeriesAxisAssignment,
			p_container: BoxContainer, p_titles_array: Array,
			p_is_vertical_container: bool) -> bool:

		p_titles_array.resize(1)
		p_titles_array[0] = null

		# The axis is drawn on the pane nearest the edge, so that is the pane
		# whose data area the title aligns with.
		var pane_index := _nearest_pane_to_edge(p_pane_count, p_axis_id)
		if pane_index < 0:
			return false

		var pane_config: TauPaneConfig = p_xy_config.panes[pane_index]
		var cfg: TauAxisConfig = _get_axis_config(p_axis_id, p_xy_config, pane_config)
		var text := cfg.title if cfg != null else ""
		var has_series := _axis_has_series(p_axis_id, p_xy_config, pane_index, p_series_assignment)
		if text.is_empty() or not has_series:
			return false

		var label := _OrientedTitle.instantiate()
		_fill_along_container(label, p_is_vertical_container)
		label.text = text
		label.title_orientation = _resolve_title_orientation(cfg.title_orientation, p_axis_id)
		label.title_alignment = cfg.title_alignment
		label.text_alignment = cfg.title_text_alignment
		p_container.add_child(label)
		p_titles_array[0] = label
		return true


	static func _fill_along_container(p_control: Control, p_is_vertical_container: bool) -> void:
		if p_is_vertical_container:
			p_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
		else:
			p_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL


	static func _apply_data_area(p_titles: Array, p_index: int,
			p_begin_global: float, p_end_global: float, p_aligns_horizontally: bool) -> void:
		if p_index >= p_titles.size() or p_titles[p_index] == null:
			return
		# Spacers carry no alignment.
		if not &"data_begin_global" in p_titles[p_index]:
			return
		var ctrl: Control = p_titles[p_index]
		ctrl.aligns_horizontally = p_aligns_horizontally
		ctrl.data_begin_global = p_begin_global
		ctrl.data_end_global = p_end_global


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
		return p_pane_index == _nearest_pane_to_edge(p_pane_count, p_edge)


	## Returns the index of the pane closest to [param p_edge], or -1 when
	## there is no pane.
	static func _nearest_pane_to_edge(p_pane_count: int, p_edge: AxisId) -> int:
		if p_pane_count == 0:
			return -1
		match p_edge:
			AxisId.BOTTOM, AxisId.RIGHT:
				return p_pane_count - 1
		return 0


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
