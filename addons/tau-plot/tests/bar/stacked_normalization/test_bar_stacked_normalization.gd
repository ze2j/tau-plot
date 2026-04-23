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
	var x := PackedFloat64Array([10.0, 11.0, 12.0, 13.0])
	var y_a := PackedFloat64Array([5.0, 10.0, 15.0, 20.0])
	var y_b := PackedFloat64Array([25.0, 30.0, 35.0, 40.0])
	var y_c := PackedFloat64Array([30.0, 40.0, 50.0, 60.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b, y_c])

	%TestPlot1.title = "[CONTINUOUS] with stacked_normalization = NONE"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.DATA_UNITS
	x_axis.domain_padding_min = 0.5
	x_axis.domain_padding_max = 0.5

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.STACKED
	bar_config.stacked_normalization = TauBarConfig.StackedNormalization.NONE

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
	var series_names := PackedStringArray(["Series A", "Series B", "Series C"])
	var x := PackedFloat64Array([10.0, 11.0, 12.0, 13.0])
	var y_a := PackedFloat64Array([5.0, 10.0, 15.0, 20.0])
	var y_b := PackedFloat64Array([25.0, 30.0, 35.0, 40.0])
	var y_c := PackedFloat64Array([30.0, 40.0, 50.0, 60.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b, y_c])

	%TestPlot2.title = "[CONTINUOUS] with stacked_normalization = FRACTION"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.DATA_UNITS
	x_axis.domain_padding_min = 0.5
	x_axis.domain_padding_max = 0.5

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.STACKED
	bar_config.stacked_normalization = TauBarConfig.StackedNormalization.FRACTION

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

	%TestPlot2.plot_xy(dataset, config, bindings)


####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["Series A", "Series B", "Series C"])
	var x := PackedFloat64Array([10.0, 11.0, 12.0, 13.0])
	var y_a := PackedFloat64Array([5.0, 10.0, 15.0, 20.0])
	var y_b := PackedFloat64Array([25.0, 30.0, 35.0, 40.0])
	var y_c := PackedFloat64Array([30.0, 40.0, 50.0, 60.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b, y_c])

	%TestPlot3.title = "[CONTINUOUS] with stacked_normalization = PERCENT"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.DATA_UNITS
	x_axis.domain_padding_min = 0.5
	x_axis.domain_padding_max = 0.5

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.format_tick_label = func(label: String) -> String:
		return label + "%"

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.STACKED
	bar_config.stacked_normalization = TauBarConfig.StackedNormalization.PERCENT

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
	var series_names := PackedStringArray(["Series A", "Series B", "Series C"])
	var x := PackedStringArray(["One", "Two", "Three", "Four"])
	var y_a := PackedFloat64Array([5.0, 10.0, 15.0, 20.0])
	var y_b := PackedFloat64Array([25.0, 30.0, 35.0, 40.0])
	var y_c := PackedFloat64Array([30.0, 40.0, 50.0, 60.0])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b, y_c])

	%TestPlot4.title = "[CATEGORICAL] with stacked_normalization = NONE"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.STACKED
	bar_config.stacked_normalization = TauBarConfig.StackedNormalization.NONE

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

	%TestPlot4.plot_xy(dataset, config, bindings)


####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	var series_names := PackedStringArray(["Series A", "Series B", "Series C"])
	var x := PackedStringArray(["One", "Two", "Three", "Four"])
	var y_a := PackedFloat64Array([5.0, 10.0, 15.0, 20.0])
	var y_b := PackedFloat64Array([25.0, 30.0, 35.0, 40.0])
	var y_c := PackedFloat64Array([30.0, 40.0, 50.0, 60.0])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b, y_c])

	%TestPlot5.title = "[CATEGORICAL] with stacked_normalization = FRACTION"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.STACKED
	bar_config.stacked_normalization = TauBarConfig.StackedNormalization.FRACTION

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
	var series_names := PackedStringArray(["Series A", "Series B", "Series C"])
	var x := PackedStringArray(["One", "Two", "Three", "Four"])
	var y_a := PackedFloat64Array([5.0, 10.0, 15.0, 20.0])
	var y_b := PackedFloat64Array([25.0, 30.0, 35.0, 40.0])
	var y_c := PackedFloat64Array([30.0, 40.0, 50.0, 60.0])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b, y_c])

	%TestPlot6.title = "[CATEGORICAL] with stacked_normalization = PERCENT"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.format_tick_label = func(label: String) -> String:
		return label + "%"

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.STACKED
	bar_config.stacked_normalization = TauBarConfig.StackedNormalization.PERCENT

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

	%TestPlot6.plot_xy(dataset, config, bindings)
