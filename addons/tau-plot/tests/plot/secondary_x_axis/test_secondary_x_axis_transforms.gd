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
	# Period 0.2, 0.4, ... 2.0 seconds.
	var x := PackedFloat64Array()
	for i in range(1, 11):
		x.append(1.0 / (0.2 * float(i)))
	var y := PackedFloat64Array([3.0, 5.0, 4.0, 6.0, 5.0, 7.0, 6.0, 8.0, 7.0, 9.0])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(["A"], x, [y])

	%TestPlot1.title = "Curved transform 1/x: uneven gaps, markers on the period grid lines"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "FREQUENCY (Hz)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.range_override_enabled = true
	x_axis.min_override = 0.4
	x_axis.max_override = 5.2

	var x2_axis := TauAxisConfig.new()
	x2_axis.title = "PERIOD (s)"
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
	config.secondary_x_axis_transform = func(f: float) -> float: return 1.0 / f
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
	# Milligrams 20, 50, 100, 300, 1000, 2000, 5000.
	var x := PackedFloat64Array()
	for milligrams in [20.0, 50.0, 100.0, 300.0, 1000.0, 2000.0, 5000.0]:
		x.append(milligrams / 1000.0)
	var y := PackedFloat64Array([3.0, 5.0, 4.0, 6.0, 5.0, 7.0, 6.0])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(["A"], x, [y])

	%TestPlot2.title = "Logarithmic primary, LOGARITHMIC secondary 1000·x: markers on the mg grid lines"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "MASS (g)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var x2_axis := TauAxisConfig.new()
	x2_axis.title = "MASS (mg)"
	x2_axis.type = TauAxisConfig.Type.CONTINUOUS
	x2_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_minor_enabled = true
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
	config.secondary_x_axis_transform = func(grams: float) -> float: return 1000.0 * grams
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot2.legend_enabled = false
	%TestPlot2.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	# Gain -50, -40, ... 50 dB.
	var x := PackedFloat64Array()
	for decibels in range(-50, 51, 10):
		x.append(pow(10.0, float(decibels) / 20.0))
	var y := PackedFloat64Array([3.0, 5.0, 4.0, 6.0, 5.0, 7.0, 6.0, 8.0, 7.0, 9.0, 8.0])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(["A"], x, [y])

	%TestPlot3.title = "Logarithmic primary, LINEAR secondary 20·log10(x): markers on the dB grid lines"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "AMPLITUDE RATIO"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var x2_axis := TauAxisConfig.new()
	x2_axis.title = "GAIN (dB)"
	x2_axis.type = TauAxisConfig.Type.CONTINUOUS
	x2_axis.scale = TauAxisConfig.Scale.LINEAR
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
	config.secondary_x_axis_transform = func(ratio: float) -> float: return 20.0 * log(ratio) / log(10.0)
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot3.legend_enabled = false
	%TestPlot3.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	# Counts 2, 5, 20, 50, 200, 500, 2000, 5000.
	var x := PackedFloat64Array()
	for count in [2.0, 5.0, 20.0, 50.0, 200.0, 500.0, 2000.0, 5000.0]:
		x.append(log(count) / log(10.0))
	var y := PackedFloat64Array([3.0, 5.0, 4.0, 6.0, 5.0, 7.0, 6.0, 8.0])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(["A"], x, [y])

	%TestPlot4.title = "Linear primary, LOGARITHMIC secondary 10^x: markers on the count grid lines"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "EXPONENT"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var x2_axis := TauAxisConfig.new()
	x2_axis.title = "COUNT"
	x2_axis.type = TauAxisConfig.Type.CONTINUOUS
	x2_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_minor_enabled = true
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
	config.secondary_x_axis_transform = func(exponent: float) -> float: return pow(10.0, exponent)
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot4.legend_enabled = false
	%TestPlot4.plot_xy(dataset, config, bindings)
