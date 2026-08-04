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
	_setup_test_11()
	_setup_test_12()
	_setup_test_13()
	_setup_test_14()
	_setup_test_15()

####################################################################################################
# Helpers
####################################################################################################

func make_shared_x_continuous_plot(p_plot: TauPlot, p_title: String, p_interpolation: TauLineConfig.InterpolationMode, p_num_colors: int) -> void:
	var series_names := PackedStringArray(["Series A"])
	var x := PackedFloat64Array([10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0])
	var y_a := PackedFloat64Array([10.0, 20.0, 50.0, 65.0, 70.0, 75.0, 60.0, 45.0, 25.0, 0.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a])

	p_plot.title = p_title
	p_plot.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 10

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.tick_count_preferred = 10
	y_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE

	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT
	line_config.interpolation_modes = [p_interpolation]
	line_config.style.dash_lengths_px = [8]

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
	var color_buffer_a = TauPlot.VisualAttributes.ColorBuffer.new(x.size())
	var color_values := PackedColorArray([
		Color(0.069, 0.391, 0.338, 1.0),
		Color(0.069, 0.429, 0.508, 1.0),
		Color(0.197, 0.328, 0.575, 1.0),
		Color(0.358, 0.3, 0.475, 1.0),
		Color(0.516, 0.211, 0.37, 1.0),
		Color(0.507, 0.066, 0.284, 1.0),
		Color(0.529, 0.232, 0.197, 1.0),
		Color(0.49, 0.408, 0.116, 1.0),
		Color(0.309, 0.473, 0.129, 1.0),
		Color(0.01, 0.487, 0.249, 1.0),
		])
	color_values.resize(p_num_colors)
	color_buffer_a.append_values(color_values)
	var visual_attributes_a := TauPlot.LineVisualAttributes.new()
	visual_attributes_a.color_buffer = color_buffer_a
	sb_a.visual_attributes = visual_attributes_a

	var bindings: Array[TauXYSeriesBinding] = [sb_a]

	p_plot.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	make_shared_x_continuous_plot(%TestPlot1, "[LINEAR] 10 colors", TauLineConfig.InterpolationMode.LINEAR, 10)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	make_shared_x_continuous_plot(%TestPlot2, "[LINEAR] 5 colors", TauLineConfig.InterpolationMode.LINEAR, 5)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	make_shared_x_continuous_plot(%TestPlot3, "[LINEAR] 1 color", TauLineConfig.InterpolationMode.LINEAR, 1)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	make_shared_x_continuous_plot(%TestPlot4, "[STEP_BEFORE] 10 colors", TauLineConfig.InterpolationMode.STEP_BEFORE, 10)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	make_shared_x_continuous_plot(%TestPlot5, "[STEP_BEFORE] 5 colors", TauLineConfig.InterpolationMode.STEP_BEFORE, 5)


####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	make_shared_x_continuous_plot(%TestPlot6, "[STEP_BEFORE] 1 color", TauLineConfig.InterpolationMode.STEP_BEFORE, 1)

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	make_shared_x_continuous_plot(%TestPlot7, "[STEP_MIDDLE] 10 colors", TauLineConfig.InterpolationMode.STEP_MIDDLE, 10)

####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8() -> void:
	make_shared_x_continuous_plot(%TestPlot8, "[STEP_MIDDLE] 5 colors", TauLineConfig.InterpolationMode.STEP_MIDDLE, 5)

####################################################################################################
# Test 9
####################################################################################################

func _setup_test_9() -> void:
	make_shared_x_continuous_plot(%TestPlot9, "[STEP_MIDDLE] 1 color", TauLineConfig.InterpolationMode.STEP_MIDDLE, 1)

####################################################################################################
# Test 10
####################################################################################################

func _setup_test_10() -> void:
	make_shared_x_continuous_plot(%TestPlot10, "[STEP_AFTER] 10 colors", TauLineConfig.InterpolationMode.STEP_AFTER, 10)

####################################################################################################
# Test 11
####################################################################################################

func _setup_test_11() -> void:
	make_shared_x_continuous_plot(%TestPlot11, "[STEP_AFTER] 5 colors", TauLineConfig.InterpolationMode.STEP_AFTER, 5)

####################################################################################################
# Test 12
####################################################################################################

func _setup_test_12() -> void:
	make_shared_x_continuous_plot(%TestPlot12, "[STEP_AFTER] 1 color", TauLineConfig.InterpolationMode.STEP_AFTER, 1)

####################################################################################################
# Test 13
####################################################################################################

func _setup_test_13() -> void:
	make_shared_x_continuous_plot(%TestPlot13, "[SMOOTH_MONOTONE] 10 colors", TauLineConfig.InterpolationMode.SMOOTH_MONOTONE, 10)

####################################################################################################
# Test 14
####################################################################################################

func _setup_test_14() -> void:
	make_shared_x_continuous_plot(%TestPlot14, "[SMOOTH_MONOTONE] 5 colors", TauLineConfig.InterpolationMode.SMOOTH_MONOTONE, 5)

####################################################################################################
# Test 15
####################################################################################################

func _setup_test_15() -> void:
	make_shared_x_continuous_plot(%TestPlot15, "[SMOOTH_MONOTONE] 1 color", TauLineConfig.InterpolationMode.SMOOTH_MONOTONE, 1)
