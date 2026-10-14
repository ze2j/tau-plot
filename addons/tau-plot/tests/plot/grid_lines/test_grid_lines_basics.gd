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
	 1.1,  2.4,  0.8,  1.3,  1.6,  0.5,
	 1.7,  1.9,  1.0,  1.5,  1.2,  1.4,
	 2.0,  1.8,  1.1,  1.6,
	 1.9,  0.9,  1.4,  2.1,  1.0,  1.3,
	 1.6,  2.2,  1.7,  1.2,  1.5,  0.8,
	 1.1,  1.4,  1.8,  2.0
])

func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	_setup_test_5()
	_setup_test_6()

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


func _make_grid_line_config(p_x_major: bool, p_x_minor: bool, p_y_major: bool, p_y_minor: bool) -> TauGridLineConfig:
	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = p_x_major
	grid_line_config.x_minor_enabled = p_x_minor
	grid_line_config.y_major_enabled = p_y_major
	grid_line_config.y_minor_enabled = p_y_minor
	return grid_line_config


func _make_plot(p_plot: TauPlot, p_title: String, p_grid_line_config: TauGridLineConfig) -> void:
	var series_names := PackedStringArray(["A", "B"])
	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis_left := TauAxisConfig.new()
	y_axis_left.type = TauAxisConfig.Type.CONTINUOUS
	y_axis_left.scale = TauAxisConfig.Scale.LINEAR
	y_axis_left.tick_count_preferred = 20

	var pane_config := TauPaneConfig.new()
	pane_config.y_left_axis = y_axis_left
	pane_config.overlays = [TauScatterConfig.new()]
	pane_config.grid_line = p_grid_line_config
	_apply_rank_style(pane_config)

	var xy_config := TauXYConfig.new()
	xy_config.x_axis = x_axis
	xy_config.panes = [pane_config]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	p_plot.title = p_title
	p_plot.plot_xy(dataset, xy_config, bindings)

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot(%TestPlot1, "No grid line => empty pane background", null)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot(%TestPlot2, "X major only => vertical solid white lines on the X ticks", _make_grid_line_config(true, false, false, false))

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_make_plot(%TestPlot3, "Y major only => horizontal solid white lines on the Y ticks", _make_grid_line_config(false, false, true, false))

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_make_plot(%TestPlot4, "X major and Y major => full solid white grid", _make_grid_line_config(true, false, true, false))

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	_make_plot(%TestPlot5, "X minor only => nothing drawn, a linear axis has no minor tick", _make_grid_line_config(false, true, false, false))

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	_make_plot(%TestPlot6, "X and Y, major and minor => full solid white grid, no dashed blue line", _make_grid_line_config(true, true, true, true))
