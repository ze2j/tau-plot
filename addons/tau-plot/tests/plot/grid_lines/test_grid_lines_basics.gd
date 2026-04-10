@tool
extends Control

var x_a := PackedFloat64Array([
	 1.9, -1.4,  3.2,  0.7, -2.1,  2.6,
	-0.8,  1.3,  3.5, -0.2,  2.1, -1.9,
	 0.4,  2.9, -2.4,  1.6,  0.0,  3.6,
	-0.5,  2.3, -1.1,  1.1,  2.8, -1.7,
	 3.0, -2.0,  1.4, -0.3,  2.4,  0.9,
	-1.5,  3.3,  1.8, -2.2,  2.7,  0.2,
	 1.0, -0.7,  3.4, -1.2,  2.0,  0.5,
	-2.3,  1.7,  2.5, -0.1,  3.1, -1.6
])
var y_a := PackedFloat64Array([
	 2.2,  1.3,  1.7,  1.0,  0.9,  1.5,
	 1.8,  2.1,  1.4,  1.6,  1.9,  1.2,
	 1.4,  1.8,  1.1,  2.3,  1.7,  1.5,
	 1.3,  1.6,  1.0,  2.0,  1.4,  1.2,
	 1.9,  1.1,  2.2,  1.5,  1.7,  1.3,
	 1.0,  1.8,  2.0,  0.9,  1.6,  1.4,
	 2.1,  1.2,  1.5,  1.7,  2.3,  1.6,
	 1.0,  1.9,  1.4,  1.8,  2.0,  1.3
])

var x_b := PackedFloat64Array([
	-2.7,  0.9, -1.8,  2.4, -3.1,  1.2,
	-0.4,  1.9, -2.2,  0.1,  2.7, -1.0,
	 0.6, -3.3,  1.5, -0.9,
	 2.1, -2.5,  0.4,  1.7, -1.3,  2.6,
	-0.2,  1.0, -2.9,  0.8,  2.3, -1.6,
	 1.3, -3.0,  0.0,  1.8
])
var y_b := PackedFloat64Array([
	 1.1,  2.4,  0.8,  1.3,  1.6,  0.5,
	 1.7,  1.9,  1.0,  1.5,  1.2,  1.4,
	 2.0,  1.8,  1.1,  1.6,
	 1.9,  0.9,  1.4,  2.1,  1.0,  1.3,
	 1.6,  2.2,  1.7,  1.2,  1.5,  0.8,
	 1.1,  1.4,  1.8,  2.0
])

func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	_setup_test_5()
	_setup_test_6()


func _make_plot_linear(p_plot: TauPlot, p_grid_line_config: TauGridLineConfig, p_title: String):
	var series_names := PackedStringArray(["A", "B"])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	p_plot.title = p_title

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis_left := TauAxisConfig.new()
	y_axis_left.type = TauAxisConfig.Type.CONTINUOUS
	y_axis_left.scale = TauAxisConfig.Scale.LINEAR
	y_axis_left.tick_count_preferred = 20

	var scatter_config := TauScatterConfig.new()

	var pane_config := TauPaneConfig.new()
	pane_config.y_left_axis = y_axis_left
	pane_config.overlays = [scatter_config]
	pane_config.grid_line = p_grid_line_config

	var xy_config := TauXYConfig.new()
	xy_config.x_axis = x_axis
	xy_config.panes = [pane_config]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	p_plot.plot_xy(dataset, xy_config, bindings)

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	_make_plot_linear(%TestPlot1, grid_line_config, "X major only")

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.y_major_enabled = true
	_make_plot_linear(%TestPlot2, grid_line_config, "Y major only")

####################################################################################################
# Test 3
####################################################################################################
func _setup_test_3() -> void:
	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.y_major_enabled = true
	_make_plot_linear(%TestPlot3, grid_line_config, "X major and Y major")

#####################################################################################################
## Test 4
#####################################################################################################

func _setup_test_4() -> void:
	var series_names := PackedStringArray(["Series A", "Series B", "Series C"])
	var x_a := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])
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

	%TestPlot4.title = "X major and minor"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X (log scale)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var left_axis := TauAxisConfig.new()
	left_axis.title = "Y (linear)"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.range_override_enabled = true
	left_axis.min_override = 0.01
	left_axis.max_override = 8.00

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_minor_enabled = true

	var scatter_config := TauScatterConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
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

	var sb_c := TauXYSeriesBinding.new()
	sb_c.series_id = dataset.get_series_id_by_index(2)
	sb_c.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_c.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b, sb_c]

	%TestPlot4.plot_xy(dataset, config, bindings)


#####################################################################################################
## Test 5
#####################################################################################################

func _setup_test_5() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
	var x_b := PackedFloat64Array([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0].map(func (x) -> float: return 1.1*x))

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())

	for i in range(x_a.size()):
		y_a[i] = 0.5 * pow(10.0, float(i) * 0.1)
	for i in range(x_b.size()):
		y_b[i] = 0.25 * pow(10.0, float(i) * 0.1)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot5.title = "Y major and minor"
	%TestPlot5.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X (linear)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var left_axis := TauAxisConfig.new()
	left_axis.title = "Y (log scale)"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	left_axis.include_zero_in_domain = false

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.y_major_enabled = true
	grid_line_config.y_minor_enabled = true

	var scatter_config := TauScatterConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
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

	%TestPlot5.plot_xy(dataset, config, bindings)


#####################################################################################################
## Test 6
#####################################################################################################

func _setup_test_6() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([0.05, 0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])
	var x_b := PackedFloat64Array([0.05, 0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0].map(func (x) -> float: return 1.1*x))

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())

	for i in range(x_a.size()):
		y_a[i] = pow(x_a[i], 0.1)
	for i in range(x_b.size()):
		y_b[i] = pow(x_b[i], 0.05)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot6.title = "X and Y major and minor"
	%TestPlot6.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X (log scale)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var left_axis := TauAxisConfig.new()
	left_axis.title = "Y (log scale)"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	left_axis.include_zero_in_domain = false

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_minor_enabled = true
	grid_line_config.y_major_enabled = true
	grid_line_config.y_minor_enabled = true

	var scatter_config := TauScatterConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
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

	%TestPlot6.plot_xy(dataset, config, bindings)
