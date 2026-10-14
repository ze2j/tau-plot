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
	var dataset := TauPlot.Dataset.make_shared_x_categorical(["A"], ["alpha", "beta"], [PackedFloat64Array([1.23, 4.56])])

	%TestPlot1.title = "BOTTOM x-axis not inverted"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.inverted = false

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.BOTTOM
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.LEFT
	sb.pane_index = 0

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot1.legend_enabled = false
	%TestPlot1.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var dataset := TauPlot.Dataset.make_shared_x_categorical(["A"], ["alpha", "beta"], [PackedFloat64Array([1.23, 4.56])])

	%TestPlot2.title = "BOTTOM x-axis inverted"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.inverted = true

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.BOTTOM
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.LEFT
	sb.pane_index = 0

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot2.legend_enabled = false
	%TestPlot2.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var dataset := TauPlot.Dataset.make_shared_x_categorical(["A"], ["alpha", "beta"], [PackedFloat64Array([1.23, 4.56])])

	%TestPlot3.title = "TOP x-axis not inverted"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.inverted = false

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.TOP
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.LEFT
	sb.pane_index = 0

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot3.legend_enabled = false
	%TestPlot3.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	var dataset := TauPlot.Dataset.make_shared_x_categorical(["A"], ["alpha", "beta"], [PackedFloat64Array([1.23, 4.56])])

	%TestPlot4.title = "TOP x-axis inverted"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.inverted = true

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.TOP
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.LEFT
	sb.pane_index = 0

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot4.legend_enabled = false
	%TestPlot4.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	var dataset := TauPlot.Dataset.make_shared_x_categorical(["A"], ["alpha", "beta"], [PackedFloat64Array([1.23, 4.56])])

	%TestPlot5.title = "LEFT x-axis not inverted"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.inverted = false

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT

	var pane := TauPaneConfig.new()
	pane.y_bottom_axis = y_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.LEFT
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.BOTTOM
	sb.pane_index = 0

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot5.legend_enabled = false
	%TestPlot5.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	var dataset := TauPlot.Dataset.make_shared_x_categorical(["A"], ["alpha", "beta"], [PackedFloat64Array([1.23, 4.56])])

	%TestPlot6.title = "LEFT x-axis inverted"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.inverted = true

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT

	var pane := TauPaneConfig.new()
	pane.y_bottom_axis = y_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.LEFT
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.BOTTOM
	sb.pane_index = 0

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot6.legend_enabled = false
	%TestPlot6.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	var dataset := TauPlot.Dataset.make_shared_x_categorical(["A"], ["alpha", "beta"], [PackedFloat64Array([1.23, 4.56])])

	%TestPlot7.title = "RIGHT x-axis not inverted"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.inverted = false

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT

	var pane := TauPaneConfig.new()
	pane.y_bottom_axis = y_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.RIGHT
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.BOTTOM
	sb.pane_index = 0

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot7.legend_enabled = false
	%TestPlot7.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8() -> void:
	var dataset := TauPlot.Dataset.make_shared_x_categorical(["A"], ["alpha", "beta"], [PackedFloat64Array([1.23, 4.56])])

	%TestPlot8.title = "RIGHT x-axis inverted"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.inverted = true

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT

	var pane := TauPaneConfig.new()
	pane.y_bottom_axis = y_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.RIGHT
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.BOTTOM
	sb.pane_index = 0

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot8.legend_enabled = false
	%TestPlot8.plot_xy(dataset, config, bindings)
