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
	_setup_test_9()
	_setup_test_10()

####################################################################################################
# Helpers
####################################################################################################

func make_shared_x_continuous_plot(p_plot: TauPlot, p_title: String, p_interpolation: TauLineConfig.InterpolationMode) -> void:
	var series_names := PackedStringArray(["Series A"])
	var x := PackedFloat64Array([pow(10, -2), pow(10, -1), pow(10, 0), pow(10, 1), pow(10, 2)])
	var y_a := PackedFloat64Array([10.0, 20.0, 50.0, 65.0, 70.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a])

	p_plot.title = p_title
	p_plot.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	x_axis.include_zero_in_domain = false

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.tick_count_preferred = 10
	y_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE

	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT
	line_config.interpolation_modes = [p_interpolation]

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [line_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a]

	p_plot.plot_xy(dataset, config, bindings)


func make_per_series_x_continuous_plot(p_plot: TauPlot, p_title: String, p_interpolation: TauLineConfig.InterpolationMode) -> void:
	var series_names := PackedStringArray(["Series A"])
	var x_a := PackedFloat64Array([pow(10, -2), pow(10, -1), pow(10, 0), pow(10, 1), pow(10, 2)])
	var y_a := PackedFloat64Array([10.0, 20.0, 50.0, 65.0, 70.0])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a], [y_a])

	p_plot.title = p_title
	p_plot.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	x_axis.include_zero_in_domain = false

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.tick_count_preferred = 10
	y_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE

	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT
	line_config.interpolation_modes = [p_interpolation]

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [line_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a]

	p_plot.plot_xy(dataset, config, bindings)


####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	make_shared_x_continuous_plot(%TestPlot1, "[LINEAR] SHARED_X + CONTINUOUS", TauLineConfig.InterpolationMode.LINEAR)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	make_per_series_x_continuous_plot(%TestPlot2, "[LINEAR] PER_SERIES_X + CONTINUOUS", TauLineConfig.InterpolationMode.LINEAR)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	make_shared_x_continuous_plot(%TestPlot3, "[STEP_BEFORE] SHARED_X + CONTINUOUS", TauLineConfig.InterpolationMode.STEP_BEFORE)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	make_per_series_x_continuous_plot(%TestPlot4, "[STEP_BEFORE] PER_SERIES_X + CONTINUOUS", TauLineConfig.InterpolationMode.STEP_BEFORE)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	make_shared_x_continuous_plot(%TestPlot5, "[STEP_MIDDLE] SHARED_X + CONTINUOUS", TauLineConfig.InterpolationMode.STEP_MIDDLE)

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	make_per_series_x_continuous_plot(%TestPlot6, "[STEP_MIDDLE] PER_SERIES_X + CONTINUOUS", TauLineConfig.InterpolationMode.STEP_MIDDLE)

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	make_shared_x_continuous_plot(%TestPlot7, "[STEP_AFTER] SHARED_X + CONTINUOUS", TauLineConfig.InterpolationMode.STEP_AFTER)

####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8() -> void:
	make_per_series_x_continuous_plot(%TestPlot8, "[STEP_AFTER] PER_SERIES_X + CONTINUOUS", TauLineConfig.InterpolationMode.STEP_AFTER)

####################################################################################################
# Test 9
####################################################################################################

func _setup_test_9() -> void:
	make_shared_x_continuous_plot(%TestPlot9, "[SMOOTH_MONOTONE] SHARED_X + CONTINUOUS", TauLineConfig.InterpolationMode.SMOOTH_MONOTONE)

####################################################################################################
# Test 10
####################################################################################################

func _setup_test_10() -> void:
	make_per_series_x_continuous_plot(%TestPlot10, "[SMOOTH_MONOTONE] PER_SERIES_X + CONTINUOUS", TauLineConfig.InterpolationMode.SMOOTH_MONOTONE)
