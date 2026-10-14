@tool
extends VBoxContainer

const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const SeriesAxisAssignment := preload("res://addons/tau-plot/plot/xy/series_axis_assignment.gd").SeriesAxisAssignment
const XYDomain := preload("res://addons/tau-plot/plot/xy/xy_domain.gd").XYDomain
const XYDomainOverrides := preload("res://addons/tau-plot/plot/xy/xy_domain_overrides.gd").XYDomainOverrides
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout
const AxisId := preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId


func _ready() -> void:
	var results: Array[String] = []
	_append_results(results, AxisId.BOTTOM, false, false, "Horizontal, default")
	_append_results(results, AxisId.BOTTOM, true, true, "Horizontal, inverted")
	_append_results(results, AxisId.LEFT, false, false, "Vertical, default")
	_append_results(results, AxisId.LEFT, true, true, "Vertical, inverted")
	%Results.text = "\n".join(results)


func _append_results(p_results: Array[String], p_x_axis_id: AxisId, p_x_inverted: bool,
		p_y_inverted: bool, p_label: String) -> void:
	var layout := _make_degenerate_layout(p_x_axis_id, p_x_inverted, p_y_inverted)
	var x_expected := 10.0 if AxisId.BOTTOM == p_x_axis_id else 20.0
	var y_expected := 20.0 if AxisId.BOTTOM == p_x_axis_id else 10.0
	var x_actual: float = layout.map_x_to_px(0, 5.0)
	var y_axis_id: AxisId = AxisId.LEFT if AxisId.BOTTOM == p_x_axis_id else AxisId.TOP
	var y_actual: float = layout.map_y_to_px(0, 7.0, y_axis_id)
	p_results.append("%s — X: %s, Y: %s" % [
		p_label,
		_format_result(x_actual, x_expected),
		_format_result(y_actual, y_expected),
	])


func _make_degenerate_layout(p_x_axis_id: AxisId, p_x_inverted: bool,
		p_y_inverted: bool) -> XYLayout:
	var dataset := Dataset.make_shared_x_continuous(
		PackedStringArray(["series"]),
		PackedFloat64Array([5.0]),
		[PackedFloat64Array([7.0])]
	)

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.inverted = p_x_inverted

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.inverted = p_y_inverted

	var y_axis_id: AxisId = AxisId.LEFT if AxisId.BOTTOM == p_x_axis_id else AxisId.TOP
	var pane := TauPaneConfig.new()
	if AxisId.LEFT == y_axis_id:
		pane.y_left_axis = y_axis
	else:
		pane.y_top_axis = y_axis

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = p_x_axis_id
	config.panes = [pane]

	var assignment := SeriesAxisAssignment.new(1)
	assignment.assign(dataset.get_series_id_by_index(0), 0, y_axis_id)
	var overrides := XYDomainOverrides.new()
	overrides.init_panes(1)
	var empty_series: Array[PackedInt64Array] = [PackedInt64Array()]
	var domain := XYDomain.new(dataset, config, assignment, empty_series, empty_series, overrides)

	domain.x_axis_domain.min_val = 5.0
	domain.x_axis_domain.max_val = 5.0
	var y_domain = domain.get_pane_domain(0).get_y_axis_domain(y_axis_id)
	y_domain.min_val = 7.0
	y_domain.max_val = 7.0

	var layout := XYLayout.new(domain)
	layout._x_is_horizontal = AxisId.BOTTOM == p_x_axis_id
	var pane_layout := XYLayout.PaneLayout.new()
	pane_layout.pane_rect = Rect2(10.0, 20.0, 100.0, 200.0)
	layout.pane_layouts = [pane_layout]
	layout._compute_axis_mappings([y_axis_id])
	return layout


func _format_result(p_actual: float, p_expected: float) -> String:
	return "%s (%.1f, expected %.1f)" % [
		"PASS" if is_equal_approx(p_actual, p_expected) else "FAIL",
		p_actual,
		p_expected,
	]
