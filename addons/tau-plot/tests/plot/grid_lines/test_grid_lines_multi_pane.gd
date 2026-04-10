@tool
extends Control

func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	#_setup_test_5()
	#_setup_test_6()



####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])
	var x_b := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0].map(func (x) -> float: return 1.1*x))

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())

	for i in range(x_a.size()):
		y_a[i] = 10.0 * exp(float(i) * 0.3)
	for i in range(x_b.size()):
		y_b[i] = 9.0 * exp(float(i) * 0.31)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot1.title = "Major and minor grid lines on both axes in all panes"
	%TestPlot1.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X-axis"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_minor_enabled = true
	grid_line_config.y_major_enabled = true
	grid_line_config.y_minor_enabled = true

	var scatter_config := TauScatterConfig.new()

	var pane_0 := TauPaneConfig.new()
	pane_0.y_left_axis = y_axis
	pane_0.overlays = [scatter_config]
	pane_0.grid_line = grid_line_config

	var pane_1 := TauPaneConfig.new()
	pane_1.y_left_axis = y_axis
	pane_1.overlays = [scatter_config]
	pane_1.grid_line = grid_line_config

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_0, pane_1]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.pane_index = 0
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.pane_index = 1
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot1.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])
	var x_b := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0].map(func (x) -> float: return 1.1*x))

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())

	for i in range(x_a.size()):
		y_a[i] = 10.0 * exp(float(i) * 0.3)
	for i in range(x_b.size()):
		y_b[i] = 9.0 * exp(float(i) * 0.31)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot2.title = "Major and minor grid lines on all axes in all panes, except for bottom pane (only major)"
	%TestPlot2.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X-axis"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_minor_enabled = true
	grid_line_config.y_major_enabled = true
	grid_line_config.y_minor_enabled = true

	var grid_line_override: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_override.x_major_enabled = true
	grid_line_override.x_minor_enabled = false
	grid_line_override.y_major_enabled = true
	grid_line_override.y_minor_enabled = false

	var scatter_config := TauScatterConfig.new()

	var pane_0 := TauPaneConfig.new()
	pane_0.y_left_axis = y_axis
	pane_0.overlays = [scatter_config]
	pane_0.grid_line = grid_line_config

	var pane_1 := TauPaneConfig.new()
	pane_1.y_left_axis = y_axis
	pane_1.overlays = [scatter_config]
	pane_1.grid_line = grid_line_override

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_0, pane_1]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.pane_index = 0
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.pane_index = 1
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot2.plot_xy(dataset, config, bindings)


####################################################################################################
# Test 3
####################################################################################################
func _setup_test_3() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0])
	var x_b := PackedFloat64Array([10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0].map(func (x) -> float: return 1.5*x))

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())

	for i in range(x_a.size()):
		y_a[i] = 10.0 * exp(float(i) * 0.3)
	for i in range(x_b.size()):
		y_b[i] = 9.0 * exp(float(i) * 0.31)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot3.title = "Major and minor grid lines on both axes in all panes"
	%TestPlot3.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X-axis"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_minor_enabled = true
	grid_line_config.y_major_enabled = true
	grid_line_config.y_minor_enabled = true

	var scatter_config := TauScatterConfig.new()

	var pane_0 := TauPaneConfig.new()
	pane_0.y_bottom_axis = y_axis
	pane_0.overlays = [scatter_config]
	pane_0.grid_line = grid_line_config

	var pane_1 := TauPaneConfig.new()
	pane_1.y_bottom_axis = y_axis
	pane_1.overlays = [scatter_config]
	pane_1.grid_line = grid_line_config

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.LEFT
	config.panes = [pane_0, pane_1]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.pane_index = 0
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.BOTTOM

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.pane_index = 1
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.BOTTOM

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot3.plot_xy(dataset, config, bindings)


#####################################################################################################
## Test 4
#####################################################################################################

func _setup_test_4() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0])
	var x_b := PackedFloat64Array([10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0].map(func (x) -> float: return 1.5*x))

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())

	for i in range(x_a.size()):
		y_a[i] = 10.0 * exp(float(i) * 0.3)
	for i in range(x_b.size()):
		y_b[i] = 9.0 * exp(float(i) * 0.31)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot4.title = "Major and minor grid lines on all axes in all panes, except for right pane (only major)"
	%TestPlot4.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X-axis"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_minor_enabled = true
	grid_line_config.y_major_enabled = true
	grid_line_config.y_minor_enabled = true

	var grid_line_override: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_override.x_major_enabled = true
	grid_line_override.x_minor_enabled = false
	grid_line_override.y_major_enabled = true
	grid_line_override.y_minor_enabled = false

	var scatter_config := TauScatterConfig.new()

	var pane_0 := TauPaneConfig.new()
	pane_0.y_bottom_axis = y_axis
	pane_0.overlays = [scatter_config]
	pane_0.grid_line = grid_line_config

	var pane_1 := TauPaneConfig.new()
	pane_1.y_bottom_axis = y_axis
	pane_1.overlays = [scatter_config]
	pane_1.grid_line = grid_line_override

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.LEFT
	config.panes = [pane_0, pane_1]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.pane_index = 0
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.BOTTOM

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.pane_index = 1
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.BOTTOM

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot4.plot_xy(dataset, config, bindings)


#####################################################################################################
## Test 5
#####################################################################################################

func _setup_test_5() -> void:
	pass


#####################################################################################################
## Test 6
#####################################################################################################

func _setup_test_6() -> void:
	pass
