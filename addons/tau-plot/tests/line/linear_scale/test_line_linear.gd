@tool
extends Control

func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()


####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["Series A", "Series B", "Series C"])
	var x := PackedFloat64Array([10.0, 11.0, 12.0, 13.0])
	var y_a := PackedFloat64Array([5.0, 10.0, 8.0, 12.0])
	var y_b := PackedFloat64Array([25.0, 28.0, 23.0, 7.0])
	var y_c := PackedFloat64Array([30.0, 28.0, 39.0, 67.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b, y_c])

	%TestPlot1.title = "SHARED_X + CONTINUOUS"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR

	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT

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

	var sb_c := TauXYSeriesBinding.new()
	sb_c.series_id = dataset.get_series_id_by_index(2)
	sb_c.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_c.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b, sb_c]

	%TestPlot1.plot_xy(dataset, config, bindings)


####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["Series A", "Series B", "Series C"])
	var x_a := PackedFloat64Array([10.0, 11.0, 12.0, 13.0])
	var x_b := PackedFloat64Array([9.0, 10.3, 12.7, 14.1])
	var x_c := PackedFloat64Array([9.2, 10.1, 10.5, 10.9])

	var y_a := PackedFloat64Array([5.0, 10.0, 8.0, 12.0])
	var y_b := PackedFloat64Array([25.0, 28.0, 23.0, 7.0])
	var y_c := PackedFloat64Array([30.0, 28.0, 39.0, 67.0])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b, x_c], [y_a, y_b, y_c])

	%TestPlot2.title = "PER_SERIES_X + CONTINUOUS"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR

	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT

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

	var sb_c := TauXYSeriesBinding.new()
	sb_c.series_id = dataset.get_series_id_by_index(2)
	sb_c.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_c.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b, sb_c]

	%TestPlot2.plot_xy(dataset, config, bindings)


####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["Series A", "Series B", "Series C"])
	var x := PackedStringArray(["One", "Two", "Three", "Four"])
	var y_a := PackedFloat64Array([5.0, 10.0, 8.0, 12.0])
	var y_b := PackedFloat64Array([25.0, 28.0, 23.0, 7.0])
	var y_c := PackedFloat64Array([30.0, 28.0, 39.0, 67.0])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b, y_c])

	%TestPlot3.title = "SHARED_X + CATEGORICAL"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR

	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT

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

	var sb_c := TauXYSeriesBinding.new()
	sb_c.series_id = dataset.get_series_id_by_index(2)
	sb_c.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_c.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b, sb_c]

	%TestPlot3.plot_xy(dataset, config, bindings)
