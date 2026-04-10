@tool
extends Control

var _timer: Timer = null
var _t: float = 0.0

var _datasets: Array[TauPlot.Dataset] = []
var _state: Array[Dictionary] = []

func _ready() -> void:
	_create_timer()
	_setup_all_tests()
	_timer.start()

func _create_timer() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = 0.016
	_timer.timeout.connect(_on_tick)
	add_child(_timer)

func _setup_all_tests() -> void:
	_datasets.clear()
	_state.clear()

	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	_setup_test_5()
	_setup_test_6()

func _on_tick() -> void:
	_t += _timer.wait_time

	_step_test_1()
	_step_test_2()
	_step_test_3()
	_step_test_4()
	_step_test_5()
	_step_test_6()

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot1.title = "[GROUPED] z-order = SERIES_ORDER"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var left_axis := TauAxisConfig.new()
	left_axis.title = "Y"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.z_order = TauPaneOverlayConfig.ZOrder.SERIES_ORDER
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.25
	bar_config.bar_gap_x_units = 0.0

	var pane_config := TauPaneConfig.new()
	pane_config.y_left_axis = left_axis
	pane_config.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_config]
	config.style.series_alpha = 0.8

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

	_state.append(
		{
			"plot": %TestPlot1,
			"bar_config": bar_config
		}
	)

func _step_test_1() -> void:
	var st := _state[0]
	var plot: Control = st["plot"]
	var bar_config: TauBarConfig = st["bar_config"]

	bar_config.bar_width_x_units = clampf(0.25 + 0.25 * sin(_t * 0.5), 0.0, 0.5)
	plot.refresh_now()

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot2.title = "[STACKED]  z-order = SERIES_ORDER"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var left_axis := TauAxisConfig.new()
	left_axis.title = "Y"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.STACKED
	bar_config.z_order = TauPaneOverlayConfig.ZOrder.SERIES_ORDER
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.4

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]
	config.style.series_alpha = 0.8

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

	_state.append(
		{
			"plot": %TestPlot2,
			"bar_config": bar_config
		}
	)

func _step_test_2() -> void:
	var st := _state[1]
	var plot: Control = st["plot"]
	var bar_config: TauBarConfig = st["bar_config"]

	bar_config.bar_width_x_units = clampf(0.4 + 0.4 * sin(_t * 0.6), 0.0, 0.8)
	plot.refresh_now()

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x_a := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5])
	var x_b := PackedFloat64Array([0.25, 0.75, 1.25, 1.75, 2.25])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot3.title = "[INDEPENDENT]  z-order = SERIES_ORDER"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var left_axis := TauAxisConfig.new()
	left_axis.title = "Y"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.z_order = TauPaneOverlayConfig.ZOrder.SERIES_ORDER
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.25

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]
	config.style.series_alpha = 0.8

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

	_state.append(
		{
			"plot": %TestPlot3,
			"bar_config": bar_config
		}
	)

func _step_test_3() -> void:
	var st := _state[2]
	var plot: Control = st["plot"]
	var bar_config: TauBarConfig = st["bar_config"]

	bar_config.bar_width_x_units = clampf(0.25 + 0.25 * sin(_t * 0.6), 0.0, 0.5)
	plot.refresh_now()

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot4.title = "[GROUPED] z-order = REVERSE_SERIES_ORDER"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var left_axis := TauAxisConfig.new()
	left_axis.title = "Y"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.z_order = TauPaneOverlayConfig.ZOrder.REVERSE_SERIES_ORDER
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.25
	bar_config.bar_gap_x_units = 0.0

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]
	config.style.series_alpha = 0.8

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot4.plot_xy(dataset, config, bindings)

	_state.append(
		{
			"plot": %TestPlot4,
			"bar_config": bar_config
		}
	)

func _step_test_4() -> void:
	var st := _state[3]
	var plot: Control = st["plot"]
	var bar_config: TauBarConfig = st["bar_config"]

	bar_config.bar_width_x_units = clampf(0.25 + 0.25 * sin(_t * 0.5), 0.0, 0.5)
	plot.refresh_now()

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot5.title = "[STACKED]  z-order = REVERSE_SERIES_ORDER"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var left_axis := TauAxisConfig.new()
	left_axis.title = "Y"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.STACKED
	bar_config.z_order = TauPaneOverlayConfig.ZOrder.REVERSE_SERIES_ORDER
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.4

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]
	config.style.series_alpha = 0.8

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

	_state.append(
		{
			"plot": %TestPlot5,
			"bar_config": bar_config
		}
	)

func _step_test_5() -> void:
	var st := _state[4]
	var plot: Control = st["plot"]
	var bar_config: TauBarConfig = st["bar_config"]

	bar_config.bar_width_x_units = clampf(0.4 + 0.4 * sin(_t * 0.6), 0.0, 0.8)
	plot.refresh_now()

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x_a := PackedFloat64Array([0.0, 0.5, 1.0, 1.5, 2.0, 2.5])
	var x_b := PackedFloat64Array([0.25, 0.75, 1.25, 1.75, 2.25])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot6.title = "[INDEPENDENT]  z-order = REVERSE_SERIES_ORDER"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var left_axis := TauAxisConfig.new()
	left_axis.title = "Y"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.z_order = TauPaneOverlayConfig.ZOrder.REVERSE_SERIES_ORDER
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.25

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]
	config.style.series_alpha = 0.8

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

	_state.append(
		{
			"plot": %TestPlot6,
			"bar_config": bar_config
		}
	)

func _step_test_6() -> void:
	var st := _state[5]
	var plot: Control = st["plot"]
	var bar_config: TauBarConfig = st["bar_config"]

	bar_config.bar_width_x_units = clampf(0.25 + 0.25 * sin(_t * 0.6), 0.0, 0.5)
	plot.refresh_now()
