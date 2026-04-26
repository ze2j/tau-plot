@tool
extends Control

func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	_setup_test_5()
	_setup_test_6()


####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["Series A", "Series B", "Series C"])
	var x := PackedFloat64Array([0.1, 0.5, 1.0, -5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	var y_c := PackedFloat64Array()
	y_a.resize(x.size())
	y_b.resize(x.size())
	y_c.resize(x.size())

	for i in range(x.size()):
		y_a[i] = 5.0 +  2.5 * sin(float(i) * 0.3)
		y_b[i] = 4.0 +  2.0 * cos(float(i) * 0.5)
		y_c[i] = 3.0 +  2.5 * sin(float(i) * 0.7)

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b, y_c])

	%TestPlot1.title = "[LOG X, LINEAR Y] Grouped - 4th x value is negative"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X (log scale)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.title = "Y (linear)"
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.range_override_enabled = true
	y_axis.min_override = 0.01
	y_axis.max_override = 8.00

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION
	bar_config.bar_gap_x_units = 1.01

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

	var sb_c := TauXYSeriesBinding.new()
	sb_c.series_id = dataset.get_series_id_by_index(2)
	sb_c.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_c.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b, sb_c]

	%TestPlot1.plot_xy(dataset, config, bindings)


####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x := PackedFloat64Array([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x.size())
	y_b.resize(x.size())

	for i in range(x.size()):
		y_a[i] = 0.1 * pow(10.0, float(i) * 0.4) if i != 3 else -666.0
		y_b[i] = 0.05 * pow(10.0, float(i) * 0.4)

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])

	%TestPlot2.title = "[LINEAR X, LOG Y] Grouped - 4th y value is negative for series A"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X (linear)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var y_axis := TauAxisConfig.new()
	y_axis.title = "Y (log scale)"
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED

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
	var series_names := PackedStringArray(["Series A", "Series B", "Series C"])
	var x := PackedFloat64Array([0.1, 0.5, 1.0, -5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	var y_c := PackedFloat64Array()
	y_a.resize(x.size())
	y_b.resize(x.size())
	y_c.resize(x.size())

	for i in range(x.size()):
		y_a[i] = 5.0 +  2.5 * sin(float(i) * 0.3)
		y_b[i] = 4.0 +  2.0 * cos(float(i) * 0.5)
		y_c[i] = 3.0 +  2.5 * sin(float(i) * 0.7)

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b, y_c])

	%TestPlot3.title = "[LOG X, LINEAR Y] Stacked - 4th x value is negative"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X (log scale)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.title = "Y (linear)"
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.STACKED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION
	bar_config.bar_gap_x_units = 1.01

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

	var sb_c := TauXYSeriesBinding.new()
	sb_c.series_id = dataset.get_series_id_by_index(2)
	sb_c.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_c.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b, sb_c]

	%TestPlot3.plot_xy(dataset, config, bindings)


####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	pass

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	var series_names := PackedStringArray(["Series A", "Series B", "Series C"])
	var x_a := PackedFloat64Array([0.1, 0.5, 1.0, -5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])
	var x_b := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0].map(func (x) -> float: return 1.1*x))
	var x_c := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0].map(func (x) -> float: return 1.2*x))

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	var y_c := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())
	y_c.resize(x_c.size())

	for i in range(x_a.size()):
		y_a[i] = 5.0 +  2.5 * sin(float(i) * 0.3)
	for i in range(x_b.size()):
		y_b[i] = 4.0 +  2.0 * cos(float(i) * 0.5)
	for i in range(x_c.size()):
		y_c[i] = 3.0 +  2.5 * sin(float(i) * 0.7)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b, x_c], [y_a, y_b, y_c])

	%TestPlot5.title = "[LOG X, LINEAR Y] Independent - 4th x value is negative for series A"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X (log scale)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.title = "Y (linear)"
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.range_override_enabled = true
	y_axis.min_override = 0.01
	y_axis.max_override = 8.00

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.THEME
	bar_config.style.bar_width_px = 25

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

	var sb_c := TauXYSeriesBinding.new()
	sb_c.series_id = dataset.get_series_id_by_index(2)
	sb_c.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_c.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b, sb_c]

	%TestPlot5.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
	var x_b := PackedFloat64Array([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0].map(func (x) -> float: return 1.1*x))

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())

	for i in range(x_a.size()):
		y_a[i] = 0.1 * pow(10.0, float(i) * 0.4) if i != 3 else -666.0
	for i in range(x_b.size()):
		y_b[i] = 0.05 * pow(10.0, float(i) * 0.4)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot6.title = "[LINEAR X, LOG Y] Independent - 4th y value is negative for series A"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X (linear)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var y_axis := TauAxisConfig.new()
	y_axis.title = "Y (log scale)"
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT

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

	%TestPlot6.plot_xy(dataset, config, bindings)
