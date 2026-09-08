@tool
extends Control

const SAMPLE_COUNT := 20
const MAJOR_GRID_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.35)
const MINOR_GRID_LINE_COLOR := Color(0.35, 0.75, 1.0, 0.55)
const MINOR_GRID_LINE_DASH_PX := 4

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

func _make_dataset(p_x_min: float, p_x_max: float) -> TauPlot.Dataset:
	var x := PackedFloat64Array()
	var y := PackedFloat64Array()
	x.resize(SAMPLE_COUNT)
	y.resize(SAMPLE_COUNT)

	var log_min := log(p_x_min) / log(10.0)
	var log_max := log(p_x_max) / log(10.0)
	for i in range(SAMPLE_COUNT):
		var t := float(i) / float(SAMPLE_COUNT - 1)
		x[i] = pow(10.0, log_min + t * (log_max - log_min))
		y[i] = 0.5 + 0.4 * sin(float(i) * 0.5)

	var series_names := PackedStringArray(["A"])
	return TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y])


func _apply_rank_style(p_pane: TauPaneConfig) -> void:
	p_pane.style.x_major_grid_line_color = MAJOR_GRID_LINE_COLOR
	p_pane.style.x_minor_grid_line_color = MINOR_GRID_LINE_COLOR
	p_pane.style.x_minor_grid_line_dash_px = MINOR_GRID_LINE_DASH_PX


func _make_plot(p_plot: TauPlot, p_title: String, p_x_min: float, p_x_max: float) -> void:
	var dataset := _make_dataset(p_x_min, p_x_max)

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	x_axis.include_zero_in_domain = false
	x_axis.range_override_enabled = true
	x_axis.min_override = p_x_min
	x_axis.max_override = p_x_max

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR

	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_minor_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [TauScatterConfig.new()]
	pane.grid_line = grid_line_config
	_apply_rank_style(pane)

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	p_plot.title = p_title
	p_plot.legend_enabled = false
	p_plot.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot(%TestPlot1, "[2, 5] => no major tick, ticks 2 3 4 5 all minor and all labeled, dashed blue lines on 3 and 4 only", 2.0, 5.0)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot(%TestPlot2, "[1.2, 8] => no major tick, ticks 2 to 8 all minor and all labeled, dashed blue lines on 2 to 7", 1.2, 8.0)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_make_plot(%TestPlot3, "[8, 30] => major tick at 10 with a solid white line, dashed blue lines on 9 and 20, none on 8 and 30", 8.0, 30.0)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_make_plot(%TestPlot4, "[8, 12] => major tick at 10 with a solid white line, dashed blue line on 9, none on 8", 8.0, 12.0)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	_make_plot(%TestPlot5, "[4.5, 5.5] => round value fallback, ticks 4.5 5 5.5 all major and all labeled, one solid white line on 5", 4.5, 5.5)

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	_make_plot(%TestPlot6, "[1.01, 1.05] => round value fallback, ticks 1.01 to 1.05 all major and all labeled, solid white lines on 1.02 1.03 1.04", 1.01, 1.05)
