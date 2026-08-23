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

####################################################################################################
# Helpers
####################################################################################################

func make_shared_x_continuous_plot(p_plot: TauPlot, p_title: String, p_interpolation: TauLineConfig.InterpolationMode, p_series_a_dash_px: int) -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x := PackedFloat64Array([10.0, 11.0, 12.0, 13.0, 14.0])
	var y_a := PackedFloat64Array([10.0, 20.0, 50.0, 65.0, 70.0])
	var y_b := PackedFloat64Array([20.0, 12.0, 23.0, 7.0, 29.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])

	p_plot.title = p_title

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.tick_count_preferred = 10
	y_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE

	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT
	line_config.interpolation_modes = [p_interpolation]
	line_config.style.dash_lengths_px = [p_series_a_dash_px, 0]

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

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	p_plot.plot_xy(dataset, config, bindings)


####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	make_shared_x_continuous_plot(%TestPlot1, "LINEAR + dash = 2 for series A", TauLineConfig.InterpolationMode.LINEAR, 2)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	make_shared_x_continuous_plot(%TestPlot2, "LINEAR + dash = 4 for series A", TauLineConfig.InterpolationMode.LINEAR, 4)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	make_shared_x_continuous_plot(%TestPlot3, "LINEAR + dash = 8 for series A", TauLineConfig.InterpolationMode.LINEAR, 8)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	make_shared_x_continuous_plot(%TestPlot4, "STEP_MIDDLE + dash = 2 for series A", TauLineConfig.InterpolationMode.STEP_MIDDLE, 2)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	make_shared_x_continuous_plot(%TestPlot5, "STEP_MIDDLE + dash = 4 for series A", TauLineConfig.InterpolationMode.STEP_MIDDLE, 4)

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	make_shared_x_continuous_plot(%TestPlot6, "STEP_MIDDLE + dash = 8 for series A", TauLineConfig.InterpolationMode.STEP_MIDDLE, 8)

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	make_shared_x_continuous_plot(%TestPlot7, "SMOOTH_MONOTONE + dash = 2 for series A", TauLineConfig.InterpolationMode.SMOOTH_MONOTONE, 2)

####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8() -> void:
	make_shared_x_continuous_plot(%TestPlot8, "SMOOTH_MONOTONE + dash = 4 for series A", TauLineConfig.InterpolationMode.SMOOTH_MONOTONE, 4)

####################################################################################################
# Test 9
####################################################################################################

func _setup_test_9() -> void:
	make_shared_x_continuous_plot(%TestPlot9, "SMOOTH_MONOTONE + dash = 8 for series A", TauLineConfig.InterpolationMode.SMOOTH_MONOTONE, 8)
