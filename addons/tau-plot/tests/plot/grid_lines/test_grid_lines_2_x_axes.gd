@tool
extends Control

const MAJOR_GRID_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.35)
const MINOR_GRID_LINE_COLOR := Color(0.35, 0.75, 1.0, 0.55)
const MINOR_GRID_LINE_DASH_PX := 4

var x_a := PackedFloat64Array([
	 1.9, -1.4,  3.2,  0.7, -2.1,  2.6,
	-0.8,  1.3,  3.5, -0.2,  2.1, -1.9,
	 0.4,  2.9, -2.4,  1.6,  0.0,  3.6,
	-0.5,  2.3, -1.1,  1.1,  2.8, -1.7,
	 3.0, -2.0,  1.4, -0.3,  2.4,  0.9,
	-1.5,  3.3,  1.8, -2.2,  2.7,  0.2,
	 1.0, -0.7,  3.4, -1.2,  2.0,  0.5,
	-2.3,  1.7,  2.5, -0.1,  3.1, -1.6
])
var y_a := PackedFloat64Array([
	 2.2,  1.3,  1.7,  1.0,  0.9,  1.5,
	 1.8,  2.1,  1.4,  1.6,  1.9,  1.2,
	 1.4,  1.8,  1.1,  2.3,  1.7,  1.5,
	 1.3,  1.6,  1.0,  2.0,  1.4,  1.2,
	 1.9,  1.1,  2.2,  1.5,  1.7,  1.3,
	 1.0,  1.8,  2.0,  0.9,  1.6,  1.4,
	 2.1,  1.2,  1.5,  1.7,  2.3,  1.6,
	 1.0,  1.9,  1.4,  1.8,  2.0,  1.3
])

var x_b := PackedFloat64Array([
	-2.7,  0.9, -1.8,  2.4, -3.1,  1.2,
	-0.4,  1.9, -2.2,  0.1,  2.7, -1.0,
	 0.6, -3.3,  1.5, -0.9,
	 2.1, -2.5,  0.4,  1.7, -1.3,  2.6,
	-0.2,  1.0, -2.9,  0.8,  2.3, -1.6,
	 1.3, -3.0,  0.0,  1.8
])
var y_b := PackedFloat64Array([
	 11.0,  24,  8,  1.3,  16,  0.5,
	 17.0,  19,  10,  150,  12,  10,
	 200.0,  18,  11,  100,
	 19,  9,  1.4,  21,  10,  13,
	 16,  22,  1.7,  12,  15,  0.8,
	 11,  14,  1.8,  20
])

func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()

####################################################################################################
# Helpers
####################################################################################################

func _apply_rank_style(p_pane: TauPaneConfig) -> void:
	p_pane.style.x_major_grid_line_color = MAJOR_GRID_LINE_COLOR
	p_pane.style.y_major_grid_line_color = MAJOR_GRID_LINE_COLOR
	p_pane.style.x_minor_grid_line_color = MINOR_GRID_LINE_COLOR
	p_pane.style.y_minor_grid_line_color = MINOR_GRID_LINE_COLOR
	p_pane.style.x_minor_grid_line_dash_px = MINOR_GRID_LINE_DASH_PX
	p_pane.style.y_minor_grid_line_dash_px = MINOR_GRID_LINE_DASH_PX


func _assign_y_axis(p_pane: TauPaneConfig, p_axis_id: TauPlot.AxisId, p_axis: TauAxisConfig) -> void:
	match p_axis_id:
		TauPlot.AxisId.LEFT:
			p_pane.y_left_axis = p_axis
		TauPlot.AxisId.BOTTOM:
			p_pane.y_bottom_axis = p_axis


func _make_plot(
		p_plot: TauPlot,
		p_title: String,
		p_x_axis_id: TauPlot.AxisId,
		p_y_axis_id: TauPlot.AxisId,
		p_grid_x_source_axis_id: TauPlot.AxisId) -> void:
	var series_names := PackedStringArray(["A", "B"])
	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	var x_axis := TauAxisConfig.new()
	x_axis.title = "CELSIUS (°C)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var x2_axis := TauAxisConfig.new()
	x2_axis.title = "FAHRENHEIT (°F)"
	x2_axis.type = TauAxisConfig.Type.CONTINUOUS
	x2_axis.scale = TauAxisConfig.Scale.LINEAR
	x2_axis.tick_count_preferred = 32

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.tick_count_preferred = 20

	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_minor_enabled = false
	grid_line_config.x_source_axis_id = p_grid_x_source_axis_id

	var pane_config := TauPaneConfig.new()
	pane_config.overlays = [TauScatterConfig.new()]
	pane_config.grid_line = grid_line_config
	_assign_y_axis(pane_config, p_y_axis_id, y_axis)
	_apply_rank_style(pane_config)

	var xy_config := TauXYConfig.new()
	xy_config.x_axis = x_axis
	xy_config.x_axis_id = p_x_axis_id
	xy_config.secondary_x_axis = x2_axis
	xy_config.secondary_x_axis_transform = func(c: float) -> float: return c * 1.8 + 32.0
	xy_config.panes = [pane_config]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = p_y_axis_id

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = p_y_axis_id

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	p_plot.title = p_title
	p_plot.plot_xy(dataset, xy_config, bindings)

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot(
		%TestPlot1,
		"Grid from the BOTTOM x-axis => lines on the Celsius ticks, solid white on major, dashed blue on minor (when implemented)",
		TauPlot.AxisId.BOTTOM,
		TauPlot.AxisId.LEFT,
		TauPlot.AxisId.BOTTOM)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot(
		%TestPlot2,
		"Grid from the TOP x-axis => lines on the Fahrenheit ticks",
		TauPlot.AxisId.BOTTOM,
		TauPlot.AxisId.LEFT,
		TauPlot.AxisId.TOP)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_make_plot(
		%TestPlot3,
		"Grid from the LEFT x-axis => horizontal lines on the Celsius ticks",
		TauPlot.AxisId.LEFT,
		TauPlot.AxisId.BOTTOM,
		TauPlot.AxisId.LEFT)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_make_plot(
		%TestPlot4,
		"Grid from the RIGHT x-axis => horizontal lines on the Fahrenheit ticks",
		TauPlot.AxisId.LEFT,
		TauPlot.AxisId.BOTTOM,
		TauPlot.AxisId.RIGHT)
