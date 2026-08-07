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

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.0, 0.5, NAN, INF, 2.0, 2.5, 3.0])
	var y_a := PackedFloat64Array([1.0, 2.0, 4.0, 4.5, 4.0, 2.0, 1.0])
	var y_b := PackedFloat64Array([2.0, 3.0, 5.0, 5.5, 5.0, 3.0, 2.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])

	%TestPlot1.title = "[SHARED_X] 3rd and 4th x values are invalid"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true

	var fill := TauLineFill.new()
	fill.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill.fill_baseline = 0.

	var line_config := TauLineConfig.new()
	line_config.gap_policy = TauLineConfig.GapPolicy.BRIDGE
	line_config.style.fills = [fill]

	var pane_config := TauPaneConfig.new()
	pane_config.y_left_axis = y_axis
	pane_config.overlays = [line_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_config]
	config.style.series_alphas = [0.8]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot1.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x_a := PackedFloat64Array([0.0, 0.5, NAN, INF, 2.0, 2.5, 3.0])
	var x_b := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0])
	var y_a := PackedFloat64Array([1.0, 2.0, 4.0, 4.5, 4.0, 2.0, 1.0])
	var y_b := PackedFloat64Array([2.0, 3.0, 5.0, 5.5, 5.0, 3.0, 2.0])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot2.title = "[PER_SERIES_X] 3rd and 4th x values are invalid for series A"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true

	var fill := TauLineFill.new()
	fill.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill.fill_baseline = 0.

	var line_config := TauLineConfig.new()
	line_config.gap_policy = TauLineConfig.GapPolicy.BRIDGE
	line_config.style.fills = [fill]

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [line_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]
	config.style.series_alphas = [0.8]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot2.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0])
	var y_a := PackedFloat64Array([1.0, 2.0, INF, NAN, 4.0, 2.0, 1.0])
	var y_b := PackedFloat64Array([2.0, 3.0, 5.0, 5.5, 5.0, 3.0, 2.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])

	%TestPlot3.title = "[SHARED_X] 3rd and 4th y values are invalid for series A"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true

	var fill := TauLineFill.new()
	fill.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill.fill_baseline = 0.

	var line_config := TauLineConfig.new()
	line_config.gap_policy = TauLineConfig.GapPolicy.BRIDGE
	line_config.style.fills = [fill]

	var pane_config := TauPaneConfig.new()
	pane_config.y_left_axis = y_axis
	pane_config.overlays = [line_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_config]
	config.style.series_alphas = [0.8]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot3.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x_a := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0])
	var x_b := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0])
	var y_a := PackedFloat64Array([1.0, 2.0, INF, NAN, 4.0, 2.0, 1.0])
	var y_b := PackedFloat64Array([2.0, 3.0, 5.0, 5.5, 5.0, 3.0, 2.0])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot4.title = "[PER_SERIES_X] 3rd and 4th y values are invalid for series A"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true

	var fill := TauLineFill.new()
	fill.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill.fill_baseline = 0.

	var line_config := TauLineConfig.new()
	line_config.gap_policy = TauLineConfig.GapPolicy.BRIDGE
	line_config.style.fills = [fill]

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [line_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]
	config.style.series_alphas = [0.8]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot4.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([pow(10, -3), pow(10, -2), -pow(10, -1), NAN, pow(10, 1), pow(10, 2), pow(10, 3)])
	var y_a := PackedFloat64Array([1.0, 2.0, 4.0, 4.5, 4.0, 2.0, 1.0])
	var y_b := PackedFloat64Array([2.0, 3.0, 5.0, 5.5, 5.0, 3.0, 2.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])

	%TestPlot5.title = "[LOG][SHARED_X] 3rd and 4th x values are invalid"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true

	var fill := TauLineFill.new()
	fill.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill.fill_baseline = 0.

	var line_config := TauLineConfig.new()
	line_config.gap_policy = TauLineConfig.GapPolicy.BRIDGE
	line_config.style.fills = [fill]

	var pane_config := TauPaneConfig.new()
	pane_config.y_left_axis = y_axis
	pane_config.overlays = [line_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_config]
	config.style.series_alphas = [0.8]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot5.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x_a := PackedFloat64Array([pow(10, -3), pow(10, -2), -pow(10, -1), INF, pow(10, 1), pow(10, 2), pow(10, 3)])
	var x_b := PackedFloat64Array([pow(10, -3), pow(10, -2), pow(10, -1), pow(10, 0), pow(10, 1), pow(10, 2), pow(10, 3)])
	var y_a := PackedFloat64Array([1.0, 2.0, 4.0, 4.5, 4.0, 2.0, 1.0])
	var y_b := PackedFloat64Array([2.0, 3.0, 5.0, 5.5, 5.0, 3.0, 2.0])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot6.title = "[LOG][PER_SERIES_X] 3rd and 4th x values are invalid for series A"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true

	var fill := TauLineFill.new()
	fill.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill.fill_baseline = 0.

	var line_config := TauLineConfig.new()
	line_config.gap_policy = TauLineConfig.GapPolicy.BRIDGE
	line_config.style.fills = [fill]

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [line_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]
	config.style.series_alphas = [0.8]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot6.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0])
	var y_a := PackedFloat64Array([pow(10, 1), pow(10, 2), -pow(10, 4), INF,        pow(10, 4), pow(10, 2), pow(10, 1)])
	var y_b := PackedFloat64Array([pow(10, 2), pow(10, 3),  pow(10, 5), pow(10, 6), pow(10, 5), pow(10, 3), pow(10, 2)])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])

	%TestPlot7.title = "[LOG][SHARED_X] 3rd and 4th y values are invalid for series A"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

	var fill := TauLineFill.new()
	fill.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill.fill_baseline = 1.

	var line_config := TauLineConfig.new()
	line_config.gap_policy = TauLineConfig.GapPolicy.BRIDGE
	line_config.style.fills = [fill]

	var pane_config := TauPaneConfig.new()
	pane_config.y_left_axis = y_axis
	pane_config.overlays = [line_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_config]
	config.style.series_alphas = [0.8]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot7.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x_a := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0])
	var x_b := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0])
	var y_a := PackedFloat64Array([pow(10, 1), pow(10, 2), -pow(10, 4), INF,        pow(10, 4), pow(10, 2), pow(10, 1)])
	var y_b := PackedFloat64Array([pow(10, 2), pow(10, 3),  pow(10, 5), pow(10, 6), pow(10, 5), pow(10, 3), pow(10, 2)])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot8.title = "[LOG][PER_SERIES_X] 3rd and 4th y values are invalid for series A"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

	var fill := TauLineFill.new()
	fill.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill.fill_baseline = 1.

	var line_config := TauLineConfig.new()
	line_config.gap_policy = TauLineConfig.GapPolicy.BRIDGE
	line_config.style.fills = [fill]

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [line_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]
	config.style.series_alphas = [0.8]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot8.plot_xy(dataset, config, bindings)
