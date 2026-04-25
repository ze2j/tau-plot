@tool
extends Control

func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.0, NAN, 1.0, INF, 2.0, 2.5])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])

	%TestPlot1.title = "[SHARED_X] 2nd and 4th x values are invalid"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true

	var scatter_config := TauScatterConfig.new()
	scatter_config.marker_size_policy = TauScatterConfig.MarkerSizePolicy.DATA_UNITS
	scatter_config.marker_size_data_units = 0.1

	var pane_config := TauPaneConfig.new()
	pane_config.y_left_axis = y_axis
	pane_config.overlays = [scatter_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_config]
	config.style.series_alpha = 0.8

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot1.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x_a := PackedFloat64Array([0.0, NAN, 1.0, INF, 2.0, 2.5])
	var x_b := PackedFloat64Array([0.25, 0.75, 1.25, 1.75, 2.25])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot2.title = "[PER_SERIES_X] 2nd and 4th x values are invalid for series A"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true

	var scatter_config := TauScatterConfig.new()
	scatter_config.marker_size_policy = TauScatterConfig.MarkerSizePolicy.DATA_UNITS
	scatter_config.marker_size_data_units = 0.1

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]
	config.style.series_alpha = 0.8

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot2.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5])
	var y_a := PackedFloat64Array([1.0, NAN, 1.4, INF, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])

	%TestPlot3.title = "[SHARED_X] 2nd and 4th y values are invalid for series A"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true

	var scatter_config := TauScatterConfig.new()
	scatter_config.marker_size_policy = TauScatterConfig.MarkerSizePolicy.DATA_UNITS
	scatter_config.marker_size_data_units = 0.1

	var pane_config := TauPaneConfig.new()
	pane_config.y_left_axis = y_axis
	pane_config.overlays = [scatter_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_config]
	config.style.series_alpha = 0.8

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot3.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x_a := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5])
	var x_b := PackedFloat64Array([0.25, 0.75, 1.25, 1.75, 2.25])
	var y_a := PackedFloat64Array([1.0, NAN, 1.4, INF, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	%TestPlot4.title = "[PER_SERIES_X] 2nd and 4th y values are invalid for series A"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true

	var scatter_config := TauScatterConfig.new()
	scatter_config.marker_size_policy = TauScatterConfig.MarkerSizePolicy.DATA_UNITS
	scatter_config.marker_size_data_units = 0.1

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]
	config.style.series_alpha = 0.8

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
