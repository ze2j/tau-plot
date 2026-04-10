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
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x := PackedStringArray(["C1", "C2", "C3", "C4", "C5", "C6"])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b])

	%TestPlot1.title = "BAR GROUPED + LINEAR"
	%TestPlot1.hover_enabled = true
	var hover_config := TauHoverConfig.new()
	hover_config.crosshair_mode = TauHoverConfig.CrosshairMode.BOTH
	%TestPlot1.hover_config = hover_config

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION
	bar_config.category_width_fraction = 0.5
	bar_config.intra_group_gap_fraction = 0.0

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot1.plot_xy(dataset, config, bindings)


####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x := PackedStringArray(["C1", "C2", "C3", "C4", "C5", "C6"])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b])

	%TestPlot2.title = "BAR STACKED + LINEAR"
	%TestPlot2.hover_enabled = true
	var hover_config := TauHoverConfig.new()
	hover_config.crosshair_mode = TauHoverConfig.CrosshairMode.BOTH
	%TestPlot2.hover_config = hover_config

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.STACKED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION
	bar_config.category_width_fraction = 0.5

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot2.plot_xy(dataset, config, bindings)


####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
	var x_b := PackedFloat64Array([1.6, 3.2, 4.8, 6.4])

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())

	for i in range(x_a.size()):
		y_a[i] = 0.1 * pow(10.0, float(i) * 0.4)
	for i in range(x_b.size()):
		y_b[i] = 3.2 * pow(10.0, float(i) * 0.4)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot3.title = "BAR INDEPENDENT + LINEAR"
	%TestPlot3.hover_enabled = true
	var hover_config := TauHoverConfig.new()
	hover_config.crosshair_mode = TauHoverConfig.CrosshairMode.BOTH
	%TestPlot3.hover_config = hover_config

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 10

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = false

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot3.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4():
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([1.9, -1.4,  3.2,  0.7, -2.1,  2.6])
	var y_a := PackedFloat64Array([2.2,  1.3,  1.7,  1.0,  0.9,  1.5])
	var x_b := PackedFloat64Array([-2.7,  0.9, -1.8,  2.4, -3.1,  1.2])
	var y_b := PackedFloat64Array([1.1,  2.4,  0.8,  1.3,  1.6,  0.5])
	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot4.title = "SCATTER + LINEAR"
	%TestPlot4.hover_enabled = true
	var hover_config := TauHoverConfig.new()
	hover_config.crosshair_mode = TauHoverConfig.CrosshairMode.BOTH
	%TestPlot4.hover_config = hover_config

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 7

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR

	var scatter_config := TauScatterConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot4.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x := PackedStringArray(["C1", "C2", "C3", "C4", "C5", "C6"])
	var y_a := PackedFloat64Array([1.0, 20.0, 1.4, 22.0, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 16.0, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b])

	%TestPlot5.title = "BAR GROUPED + LOGARITHMIC"
	%TestPlot5.hover_enabled = true
	var hover_config := TauHoverConfig.new()
	hover_config.crosshair_mode = TauHoverConfig.CrosshairMode.BOTH
	%TestPlot5.hover_config = hover_config

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION
	bar_config.category_width_fraction = 0.5
	bar_config.intra_group_gap_fraction = 0.0

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.y_major_enabled = true
	grid_line_config.y_minor_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_config]
	pane.grid_line = grid_line_config

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot5.plot_xy(dataset, config, bindings)


####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	pass


####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
	var x_b := PackedFloat64Array([1.6, 3.2, 4.8, 12.3])

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())

	for i in range(x_a.size()):
		y_a[i] = 0.1 * pow(10.0, float(i) * 0.4)
	for i in range(x_b.size()):
		y_b[i] = 0.05 * pow(10.0, float(i) * 0.4)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot7.title = "BAR INDEPENDENT + LOGARITHMIC"
	%TestPlot7.hover_enabled = true
	var hover_config := TauHoverConfig.new()
	hover_config.crosshair_mode = TauHoverConfig.CrosshairMode.BOTH
	%TestPlot7.hover_config = hover_config

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.y_major_enabled = true
	grid_line_config.y_minor_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_config]
	pane.grid_line = grid_line_config

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot7.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8():
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([1.9, 1.4,  3.2,  0.7, 21.0,  260.0])
	var y_a := PackedFloat64Array([2.2,  1.3,  17.0,  1.0,  0.9,  1.5])
	var x_b := PackedFloat64Array([2.7,  0.9, 1.8,  2.4, 31.0,  1.2])
	var y_b := PackedFloat64Array([1.1,  240.0,  80.0,  13.0,  16.0,  0.05])
	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot8.title = "SCATTER + LOGARITHMIC"
	%TestPlot8.hover_enabled = true
	var hover_config := TauHoverConfig.new()
	hover_config.crosshair_mode = TauHoverConfig.CrosshairMode.BOTH
	%TestPlot8.hover_config = hover_config

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

	var scatter_config := TauScatterConfig.new()

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_minor_enabled = true
	grid_line_config.y_major_enabled = true
	grid_line_config.y_minor_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_config]
	pane.grid_line = grid_line_config

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot8.plot_xy(dataset, config, bindings)
