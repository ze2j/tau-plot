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

func make_shared_x_continuous_plot(p_plot: TauPlot, p_title: String, p_interpolation: TauLineConfig.InterpolationMode) -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x := PackedFloat64Array([10.0, 11.0, 12.0, 13.0, 14.0])
	var y_a := PackedFloat64Array([10.0, 20.0, 50.0, 15.0, 10.0])
	var y_b := PackedFloat64Array([50.0, 40.0, 35.0, 5.0, 20.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])

	p_plot.title = p_title
	p_plot.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.tick_count_preferred = 10
	y_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE

	var fill_a := TauLineFill.new()
	fill_a.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill_a.fill_baseline = 10.

	var fill_b := TauLineFill.new()
	fill_b.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill_b.fill_baseline = 20.

	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT
	line_config.interpolation_modes = [p_interpolation]
	line_config.style.fills = [fill_a, fill_b]

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


func make_per_series_x_continuous_plot(p_plot: TauPlot, p_title: String, p_interpolation: TauLineConfig.InterpolationMode) -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([10.0, 11.0, 12.0, 13.0, 14.0])
	var y_a := PackedFloat64Array([10.0, 20.0, 50.0, 15.0, 10.0])
	var x_b := PackedFloat64Array([10.5, 11.5, 12.5, 13.5])
	var y_b := PackedFloat64Array([40.0, 35.0, 5.0, 20.0])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	p_plot.title = p_title
	p_plot.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.tick_count_preferred = 10
	y_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE

	var fill_a := TauLineFill.new()
	fill_a.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill_a.fill_baseline = 10.

	var fill_b := TauLineFill.new()
	fill_b.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill_b.fill_baseline = 20.

	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT
	line_config.interpolation_modes = [p_interpolation]
	line_config.style.fills = [fill_a, fill_b]

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


func make_shared_x_categorical_plot(p_plot: TauPlot, p_title: String, p_interpolation: TauLineConfig.InterpolationMode) -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x := PackedStringArray(["One", "Two", "Three", "Four", "Five"])
	var y_a := PackedFloat64Array([10.0, 20.0, 50.0, 15.0, 10.0])
	var y_b := PackedFloat64Array([50.0, 40.0, 35.0, 5.0, 20.0])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b])

	p_plot.title = p_title
	p_plot.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.tick_count_preferred = 10
	y_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE

	var fill_a := TauLineFill.new()
	fill_a.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill_a.fill_baseline = 10.

	var fill_b := TauLineFill.new()
	fill_b.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill_b.fill_baseline = 20.

	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT
	line_config.interpolation_modes = [p_interpolation]
	line_config.style.fills = [fill_a, fill_b]

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
	make_shared_x_categorical_plot(%TestPlot3, "[LINEAR] SHARED_X + CATEGORICAL", TauLineConfig.InterpolationMode.LINEAR)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	make_shared_x_continuous_plot(%TestPlot4, "[STEP_BEFORE] SHARED_X + CONTINUOUS", TauLineConfig.InterpolationMode.STEP_BEFORE)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	make_per_series_x_continuous_plot(%TestPlot5, "[STEP_BEFORE] PER_SERIES_X + CONTINUOUS", TauLineConfig.InterpolationMode.STEP_BEFORE)

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	make_shared_x_categorical_plot(%TestPlot6, "[STEP_BEFORE] SHARED_X + CATEGORICAL", TauLineConfig.InterpolationMode.STEP_BEFORE)

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	make_shared_x_continuous_plot(%TestPlot7, "[STEP_MIDDLE] SHARED_X + CONTINUOUS", TauLineConfig.InterpolationMode.STEP_MIDDLE)

####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8() -> void:
	make_per_series_x_continuous_plot(%TestPlot8, "[STEP_MIDDLE] PER_SERIES_X + CONTINUOUS", TauLineConfig.InterpolationMode.STEP_MIDDLE)

####################################################################################################
# Test 9
####################################################################################################

func _setup_test_9() -> void:
	make_shared_x_categorical_plot(%TestPlot9, "[STEP_MIDDLE] SHARED_X + CATEGORICAL", TauLineConfig.InterpolationMode.STEP_MIDDLE)

####################################################################################################
# Test 10
####################################################################################################

func _setup_test_10() -> void:
	make_shared_x_continuous_plot(%TestPlot10, "[STEP_AFTER] SHARED_X + CONTINUOUS", TauLineConfig.InterpolationMode.STEP_AFTER)

####################################################################################################
# Test 11
####################################################################################################

func _setup_test_11() -> void:
	make_per_series_x_continuous_plot(%TestPlot11, "[STEP_AFTER] PER_SERIES_X + CONTINUOUS", TauLineConfig.InterpolationMode.STEP_AFTER)

####################################################################################################
# Test 12
####################################################################################################

func _setup_test_12() -> void:
	make_shared_x_categorical_plot(%TestPlot12, "[STEP_AFTER] SHARED_X + CATEGORICAL", TauLineConfig.InterpolationMode.STEP_AFTER)

####################################################################################################
# Test 13
####################################################################################################

func _setup_test_13() -> void:
	make_shared_x_continuous_plot(%TestPlot13, "[SMOOTH_MONOTONE] SHARED_X + CONTINUOUS", TauLineConfig.InterpolationMode.SMOOTH_MONOTONE)

####################################################################################################
# Test 14
####################################################################################################

func _setup_test_14() -> void:
	make_per_series_x_continuous_plot(%TestPlot14, "[SMOOTH_MONOTONE] PER_SERIES_X + CONTINUOUS", TauLineConfig.InterpolationMode.SMOOTH_MONOTONE)

####################################################################################################
# Test 15
####################################################################################################

func _setup_test_15() -> void:
	make_shared_x_categorical_plot(%TestPlot15, "[SMOOTH_MONOTONE] SHARED_X + CATEGORICAL", TauLineConfig.InterpolationMode.SMOOTH_MONOTONE)
