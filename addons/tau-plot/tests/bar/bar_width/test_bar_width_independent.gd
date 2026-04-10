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
	_setup_test_7()
	_setup_test_8()
	_setup_test_9()
	_setup_test_10()

func _on_tick() -> void:
	_t += _timer.wait_time

	_step_test_1()
	_step_test_2()
	_step_test_3()
	_step_test_4()
	_step_test_5()
	_step_test_6()
	_step_test_7()
	_step_test_8()
	_step_test_9()
	_step_test_10()

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["A"])
	var x := PackedStringArray(["C1", "C2", "C3", "C4", "C5", "C6"])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a])
	_datasets.append(dataset)

	%TestPlot1.title = "[Policy = CATEGORY_WIDTH_FRACTION] Animate category_width_fraction [0, 1]"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION
	bar_config.category_width_fraction = 0.5

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a]

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

	bar_config.category_width_fraction = clampf(0.5 + 0.5 * sin(_t * 0.7), 0.0, 1.0)
	plot.refresh_now()

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_datasets.append(null)
	_state.append({})

func _step_test_2() -> void:
	pass

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["A"])
	var x := PackedFloat64Array([0.0, 1.0, 1.5, 3.0, 4.5, 6.0])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a])
	_datasets.append(dataset)

	%TestPlot3.title = "[Policy = DATA_UNITS][LINEAR] Animate bar_width_x_units [0, 0.5]"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 15

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.25

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a]

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
	var series_names := PackedStringArray(["A"])
	var x := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])

	var y_a := PackedFloat64Array()
	y_a.resize(x.size())
	for i in range(x.size()):
		y_a[i] = 5.0 + 3.0 * sin(float(i) * 0.5)

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a])
	_datasets.append(dataset)

	%TestPlot4.title = "[Policy = DATA_UNITS][LOGARITHMIC] Animate bar_width_log_factor [1, 2]"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_log_factor = 1.5

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a]

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

	bar_config.bar_width_log_factor = clampf(1.5 + 0.5 * sin(_t * 0.6), 1.0, 2.0)
	plot.refresh_now()

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	_datasets.append(null)
	_state.append({})

func _step_test_5() -> void:
	pass

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	_datasets.append(null)
	_state.append({})

func _step_test_6() -> void:
	pass

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	var series_names := PackedStringArray(["A"])
	var x := PackedFloat64Array([0.0, 1.0, 1.5, 3.0, 4.5, 6.0])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a])
	_datasets.append(dataset)

	%TestPlot7.title = "[Policy = NEIGHBOR_SPACING_FRACTION][LINEAR] Animate neighbor_spacing_fraction [0, 1]"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 15

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION
	bar_config.neighbor_spacing_fraction = 0.5

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a]

	%TestPlot7.plot_xy(dataset, config, bindings)

	_state.append(
		{
			"plot": %TestPlot7,
			"bar_config": bar_config
		}
	)

func _step_test_7() -> void:
	var st := _state[6]
	var plot: Control = st["plot"]
	var bar_config: TauBarConfig = st["bar_config"]

	bar_config.neighbor_spacing_fraction = clampf(0.5 + 0.5 * sin(_t * 0.6), 0.0, 1.0)
	plot.refresh_now()

####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8() -> void:
	var series_names := PackedStringArray(["A"])
	var x := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])

	var y_a := PackedFloat64Array()
	y_a.resize(x.size())
	for i in range(x.size()):
		y_a[i] = 5.0 + 3.0 * sin(float(i) * 0.5)

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a])
	_datasets.append(dataset)

	%TestPlot8.title = "[Policy = NEIGHBOR_SPACING_FRACTION][LOGARITHMIC] Animate neighbor_spacing_fraction ]0, 1]"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION
	bar_config.neighbor_spacing_fraction = 0.8

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a]

	%TestPlot8.plot_xy(dataset, config, bindings)

	_state.append(
		{
			"plot": %TestPlot8,
			"bar_config": bar_config
		}
	)

func _step_test_8() -> void:
	var st := _state[7]
	var plot: Control = st["plot"]
	var bar_config: TauBarConfig = st["bar_config"]

	bar_config.neighbor_spacing_fraction = clampf(0.5 + 0.5 * sin(_t * 0.6), 0.0001, 1.0)
	plot.refresh_now()

####################################################################################################
# Test 9
####################################################################################################

func _setup_test_9() -> void:
	_datasets.append(null)
	_state.append({})

func _step_test_9() -> void:
	pass

####################################################################################################
# Test 10
####################################################################################################

func _setup_test_10() -> void:
	_datasets.append(null)
	_state.append({})

func _step_test_10() -> void:
	pass
