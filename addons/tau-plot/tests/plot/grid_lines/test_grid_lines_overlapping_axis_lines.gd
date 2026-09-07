@tool
extends Control


func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	_setup_test_5()
	_setup_test_6()
	_setup_test_7()
	_setup_test_8()


func _make_plot_linear(p_plot: TauPlot, p_grid_line_config: TauGridLineConfig, p_title: String):
	var series_names := PackedStringArray(["Test"])

	var x := PackedFloat64Array([0, 1, 2, 3, 4])
	var y := PackedFloat64Array([0.1, 0.3, 0.47, 0.63, 0.75])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y])

	p_plot.title = p_title
	p_plot.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.DATA_UNITS
	x_axis.domain_padding_min = 0.
	x_axis.domain_padding_max = 0.

	var y_axis := TauAxisConfig.new()

	var line_config := TauLineConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [line_config]
	pane.grid_line = p_grid_line_config
	pane.style.x_major_grid_line_dash_px = 6
	pane.style.x_minor_grid_line_dash_px = 6
	pane.style.y_major_grid_line_dash_px = 6
	pane.style.y_minor_grid_line_dash_px = 6

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var b0 := TauXYSeriesBinding.new()
	b0.series_id = dataset.get_series_id_by_index(0)
	b0.pane_index = 0
	b0.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	b0.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [b0]

	p_plot.plot_xy(dataset, config, bindings)


func _make_plot_log(p_plot: TauPlot, p_grid_line_config: TauGridLineConfig, p_title: String):
	var series_names := PackedStringArray(["Test"])

	var x := PackedFloat64Array([1, 20, 300, 400, 5000])
	var y := PackedFloat64Array([2.0, 2.9, 3.7, 4.4, 5.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y])

	p_plot.title = p_title
	p_plot.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.DATA_UNITS
	x_axis.domain_padding_min = 0.
	x_axis.domain_padding_max = 0.
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	x_axis.include_zero_in_domain = false

	var y_axis := TauAxisConfig.new()
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false
	y_axis.range_override_enabled = true
	y_axis.min_override = 2.0
	y_axis.max_override = 5.0

	var line_config := TauLineConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [line_config]
	pane.grid_line = p_grid_line_config
	pane.style.x_major_grid_line_dash_px = 6
	pane.style.x_minor_grid_line_dash_px = 6
	pane.style.y_major_grid_line_dash_px = 6
	pane.style.y_minor_grid_line_dash_px = 6

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var b0 := TauXYSeriesBinding.new()
	b0.series_id = dataset.get_series_id_by_index(0)
	b0.pane_index = 0
	b0.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	b0.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [b0]

	p_plot.plot_xy(dataset, config, bindings)


####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot_linear(%TestPlot1, null, "Linear scales: no grid line")

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	_make_plot_linear(%TestPlot2, grid_line_config, "Linear scales: X major only")

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.y_major_enabled = true
	_make_plot_linear(%TestPlot3, grid_line_config, "Linear scales: Y major only")

#####################################################################################################
## Test 4
#####################################################################################################

func _setup_test_4() -> void:
	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.y_major_enabled = true
	_make_plot_linear(%TestPlot4, grid_line_config, "Linear scales: X major and Y major")

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	_make_plot_log(%TestPlot5, null, "Log scales: no grid line")

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	_make_plot_log(%TestPlot6, grid_line_config, "Log scales: X major only")

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.y_major_enabled = true
	_make_plot_log(%TestPlot7, grid_line_config, "Log scales: Y major only")

#####################################################################################################
## Test 8
#####################################################################################################

func _setup_test_8() -> void:
	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.y_major_enabled = true
	_make_plot_log(%TestPlot8, grid_line_config, "Log scales: X major and Y major")
