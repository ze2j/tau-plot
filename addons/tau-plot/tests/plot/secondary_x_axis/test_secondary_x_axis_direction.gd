@tool
extends Control

# Every point sits on a round secondary x value, and the x grid lines come from
# the secondary x axis. A point off its grid line means the secondary labels no
# longer match the data.

func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	# Fahrenheit 40, 60, ... 200.
	var x := PackedFloat64Array()
	for fahrenheit in range(40, 201, 20):
		x.append((float(fahrenheit) - 32.0) / 1.8)
	var y := PackedFloat64Array([3.0, 5.0, 4.0, 6.0, 5.0, 7.0, 6.0, 8.0, 7.0])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(["A"], x, [y])

	%TestPlot1.title = "Inverted primary x axis: markers on the °F grid lines"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "CELSIUS (°C), inverted"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.inverted = true

	var x2_axis := TauAxisConfig.new()
	x2_axis.title = "FAHRENHEIT (°F)"
	x2_axis.type = TauAxisConfig.Type.CONTINUOUS
	x2_axis.tick_count_preferred = 10

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_source_axis_id = TauPlot.AxisId.TOP

	var scatter_config := TauScatterConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_config]
	pane.grid_line = grid_line_config

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.BOTTOM
	config.secondary_x_axis = x2_axis
	config.secondary_x_axis_transform = func(c: float) -> float: return c * 1.8 + 32.0
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot1.legend_enabled = false
	%TestPlot1.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	# Fahrenheit 40, 60, ... 200.
	var x := PackedFloat64Array()
	for fahrenheit in range(40, 201, 20):
		x.append((float(fahrenheit) - 32.0) / 1.8)
	var y := PackedFloat64Array([3.0, 5.0, 4.0, 6.0, 5.0, 7.0, 6.0, 8.0, 7.0])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(["A"], x, [y])

	%TestPlot2.title = "Vertical x axis: markers on the °F grid lines"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "CELSIUS (°C)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS

	var x2_axis := TauAxisConfig.new()
	x2_axis.title = "FAHRENHEIT (°F)"
	x2_axis.type = TauAxisConfig.Type.CONTINUOUS
	x2_axis.tick_count_preferred = 10

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_source_axis_id = TauPlot.AxisId.RIGHT

	var scatter_config := TauScatterConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_bottom_axis = y_axis
	pane.overlays = [scatter_config]
	pane.grid_line = grid_line_config

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.LEFT
	config.secondary_x_axis = x2_axis
	config.secondary_x_axis_transform = func(c: float) -> float: return c * 1.8 + 32.0
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.BOTTOM

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot2.legend_enabled = false
	%TestPlot2.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	# Fuel left 5, 10, ... 55.
	var x := PackedFloat64Array()
	for fuel in range(5, 56, 5):
		x.append((60.0 - float(fuel)) / 0.8)
	var y := PackedFloat64Array([3.0, 5.0, 4.0, 6.0, 5.0, 7.0, 6.0, 8.0, 7.0, 9.0, 8.0])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(["A"], x, [y])

	%TestPlot3.title = "Decreasing transform, inverted primary: secondary runs left to right"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "DISTANCE (km), inverted"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.inverted = true

	var x2_axis := TauAxisConfig.new()
	x2_axis.title = "FUEL LEFT (L)"
	x2_axis.type = TauAxisConfig.Type.CONTINUOUS
	x2_axis.tick_count_preferred = 12

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_source_axis_id = TauPlot.AxisId.TOP

	var scatter_config := TauScatterConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_config]
	pane.grid_line = grid_line_config

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.BOTTOM
	config.secondary_x_axis = x2_axis
	config.secondary_x_axis_transform = func(km: float) -> float: return 60.0 - 0.8 * km
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot3.legend_enabled = false
	%TestPlot3.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_4() -> void:
	# Fuel left 5, 10, ... 55.
	var x := PackedFloat64Array()
	for fuel in range(5, 56, 5):
		x.append((60.0 - float(fuel)) / 0.8)
	var y := PackedFloat64Array([3.0, 5.0, 4.0, 6.0, 5.0, 7.0, 6.0, 8.0, 7.0, 9.0, 8.0])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(["A"], x, [y])

	%TestPlot4.title = "Decreasing transform: secondary runs right to left"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "DISTANCE (km)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS

	var x2_axis := TauAxisConfig.new()
	x2_axis.title = "FUEL LEFT (L)"
	x2_axis.type = TauAxisConfig.Type.CONTINUOUS
	x2_axis.tick_count_preferred = 12

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_source_axis_id = TauPlot.AxisId.TOP

	var scatter_config := TauScatterConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_config]
	pane.grid_line = grid_line_config

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.BOTTOM
	config.secondary_x_axis = x2_axis
	config.secondary_x_axis_transform = func(km: float) -> float: return 60.0 - 0.8 * km
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot4.legend_enabled = false
	%TestPlot4.plot_xy(dataset, config, bindings)
