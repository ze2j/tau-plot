@tool
extends Control

const MAJOR_GRID_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.35)
const MAJOR_GRID_LINE_DASH_PX := 6
const MINOR_GRID_LINE_COLOR := Color(0.35, 0.75, 1.0, 0.55)
const MINOR_GRID_LINE_DASH_PX := 2

func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	_setup_test_5()
	_setup_test_6()
	_setup_test_7()
	_setup_test_8()

####################################################################################################
# Helpers
####################################################################################################

func _apply_rank_style(p_pane: TauPaneConfig) -> void:
	p_pane.style.x_major_grid_line_color = MAJOR_GRID_LINE_COLOR
	p_pane.style.y_major_grid_line_color = MAJOR_GRID_LINE_COLOR
	p_pane.style.x_major_grid_line_dash_px = MAJOR_GRID_LINE_DASH_PX
	p_pane.style.y_major_grid_line_dash_px = MAJOR_GRID_LINE_DASH_PX
	p_pane.style.x_minor_grid_line_color = MINOR_GRID_LINE_COLOR
	p_pane.style.y_minor_grid_line_color = MINOR_GRID_LINE_COLOR
	p_pane.style.x_minor_grid_line_dash_px = MINOR_GRID_LINE_DASH_PX
	p_pane.style.y_minor_grid_line_dash_px = MINOR_GRID_LINE_DASH_PX


func _make_plot(
		p_plot: TauPlot,
		p_title: String,
		p_grid_line_config: TauGridLineConfig,
		p_x_axis: TauAxisConfig,
		p_y_axis: TauAxisConfig,
		p_x: PackedFloat64Array,
		p_y: PackedFloat64Array) -> void:
	var series_names := PackedStringArray(["Test"])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, p_x, [p_y])

	var pane := TauPaneConfig.new()
	pane.y_left_axis = p_y_axis
	pane.overlays = [TauLineConfig.new()]
	pane.grid_line = p_grid_line_config
	_apply_rank_style(pane)

	var config := TauXYConfig.new()
	config.x_axis = p_x_axis
	config.panes = [pane]

	var b0 := TauXYSeriesBinding.new()
	b0.series_id = dataset.get_series_id_by_index(0)
	b0.pane_index = 0
	b0.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	b0.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [b0]

	p_plot.title = p_title
	p_plot.legend_enabled = false
	p_plot.plot_xy(dataset, config, bindings)


func _make_plot_linear(p_plot: TauPlot, p_grid_line_config: TauGridLineConfig, p_title: String) -> void:
	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.DATA_UNITS
	x_axis.domain_padding_min = 0.0
	x_axis.domain_padding_max = 0.0

	var y_axis := TauAxisConfig.new()

	_make_plot(
		p_plot,
		p_title,
		p_grid_line_config,
		x_axis,
		y_axis,
		PackedFloat64Array([0, 1, 2, 3, 4]),
		PackedFloat64Array([0.1, 0.3, 0.47, 0.63, 0.75]))


func _make_plot_log(p_plot: TauPlot, p_grid_line_config: TauGridLineConfig, p_title: String) -> void:
	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.DATA_UNITS
	x_axis.domain_padding_min = 0.0
	x_axis.domain_padding_max = 0.0
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	x_axis.include_zero_in_domain = false

	var y_axis := TauAxisConfig.new()
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false
	y_axis.range_override_enabled = true
	y_axis.min_override = 2.0
	y_axis.max_override = 5.0

	_make_plot(
		p_plot,
		p_title,
		p_grid_line_config,
		x_axis,
		y_axis,
		PackedFloat64Array([1, 20, 300, 400, 5000]),
		PackedFloat64Array([2.0, 2.9, 3.7, 4.4, 5.0]))


func _make_grid_line_config(p_x_major: bool, p_y_major: bool) -> TauGridLineConfig:
	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = p_x_major
	grid_line_config.y_major_enabled = p_y_major
	return grid_line_config

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot_linear(%TestPlot1, null, "Linear scales, no grid line => the pane border is the only line on the edges")

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot_linear(%TestPlot2, _make_grid_line_config(true, false), "Linear scales, X major => no line on the first and last tick, they sit on the pane border")

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_make_plot_linear(%TestPlot3, _make_grid_line_config(false, true), "Linear scales, Y major => no line on a tick that sits on the pane border")

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_make_plot_linear(%TestPlot4, _make_grid_line_config(true, true), "Linear scales, X and Y major => no line on the four edges, the pane border stays clean")

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	_make_plot_log(%TestPlot5, null, "Log scales, Y domain [2, 5], no grid line => the pane border is the only line on the edges")

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	_make_plot_log(%TestPlot6, _make_grid_line_config(true, false), "Log scales, Y domain [2, 5], X major => no line on a tick that sits on the pane border")

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	_make_plot_log(%TestPlot7, _make_grid_line_config(false, true), "Log scales, Y domain [2, 5], Y major => no major tick in the domain, so no line is drawn")

####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8() -> void:
	_make_plot_log(%TestPlot8, _make_grid_line_config(true, true), "Log scales, Y domain [2, 5], X and Y major => vertical lines only, the Y axis has no major tick, and no line on the edges")
