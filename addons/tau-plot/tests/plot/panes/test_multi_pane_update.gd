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
	#_setup_test_7()


func _on_tick() -> void:
	_t += _timer.wait_time

	_step_test_1()
	_step_test_2()
	_step_test_3()
	_step_test_4()
	_step_test_5()
	_step_test_6()
	#_step_test_7()

####################################################################################################
# Shared initial data
####################################################################################################

const X_6: PackedFloat64Array = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
const Y_A_INIT: PackedFloat64Array = [1.0, 3.0, 2.0, 4.0, 1.5, 3.5]
const Y_B_INIT: PackedFloat64Array = [2.0, 1.5, 3.5, 1.0, 4.0, 2.5]
const Y_C_INIT: PackedFloat64Array = [0.5, 2.5, 1.0, 3.0, 2.0, 1.0]

const SAMPLE_COUNT := 6

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [X_6, X_6], [Y_A_INIT, Y_B_INIT])
	_datasets.append(dataset)

	%TestPlot1.title = "[PER_SERIES_X] Update series A Y values only"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = SAMPLE_COUNT

	var left_a := TauAxisConfig.new()
	left_a.title = "Series A"
	left_a.type = TauAxisConfig.Type.CONTINUOUS
	left_a.include_zero_in_domain = true

	var left_b := TauAxisConfig.new()
	left_b.title = "Series B"
	left_b.type = TauAxisConfig.Type.CONTINUOUS
	left_b.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.6

	var pane_a := TauPaneConfig.new()
	pane_a.y_left_axis = left_a
	pane_a.overlays = [bar_config]

	var pane_b := TauPaneConfig.new()
	pane_b.y_left_axis = left_b
	pane_b.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_a, pane_b]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT
	sb_a.pane_index = 0

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT
	sb_b.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot1.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset
	})


func _step_test_1() -> void:
	var st := _state[0]
	var dataset: TauPlot.Dataset = st["dataset"]
	var series_id_a = dataset.get_series_id_by_index(0)

	dataset.begin_batch()
	for i in range(SAMPLE_COUNT):
		var base: float = Y_A_INIT[i]
		var y_new := base + 2.0 * sin(_t * 1.5 + float(i) * 0.8)
		dataset.set_series_y(series_id_a, i, maxf(y_new, 0.1))
	dataset.end_batch()

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [X_6, X_6], [Y_A_INIT, Y_B_INIT])
	_datasets.append(dataset)

	%TestPlot2.title = "[PER_SERIES_X] Update series B Y values only"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = SAMPLE_COUNT

	var left_a := TauAxisConfig.new()
	left_a.title = "Series A"
	left_a.type = TauAxisConfig.Type.CONTINUOUS
	left_a.include_zero_in_domain = true

	var left_b := TauAxisConfig.new()
	left_b.title = "Series B"
	left_b.type = TauAxisConfig.Type.CONTINUOUS
	left_b.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.6

	var pane_a := TauPaneConfig.new()
	pane_a.y_left_axis = left_a
	pane_a.overlays = [bar_config]

	var pane_b := TauPaneConfig.new()
	pane_b.y_left_axis = left_b
	pane_b.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_a, pane_b]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT
	sb_a.pane_index = 0

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT
	sb_b.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot2.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset
	})


func _step_test_2() -> void:
	var st := _state[1]
	var dataset: TauPlot.Dataset = st["dataset"]
	var series_id_b = dataset.get_series_id_by_index(1)

	dataset.begin_batch()
	for i in range(SAMPLE_COUNT):
		var base: float = Y_B_INIT[i]
		var y_new := base + 2.0 * sin(_t * 1.5 + float(i) * 0.8)
		dataset.set_series_y(series_id_b, i, maxf(y_new, 0.1))
	dataset.end_batch()

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [X_6, X_6], [Y_A_INIT, Y_B_INIT])
	_datasets.append(dataset)

	%TestPlot3.title = "[PER_SERIES_X] Update both series Y values"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = SAMPLE_COUNT

	var left_a := TauAxisConfig.new()
	left_a.title = "Series A"
	left_a.type = TauAxisConfig.Type.CONTINUOUS
	left_a.include_zero_in_domain = true

	var left_b := TauAxisConfig.new()
	left_b.title = "Series B"
	left_b.type = TauAxisConfig.Type.CONTINUOUS
	left_b.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.6

	var pane_a := TauPaneConfig.new()
	pane_a.y_left_axis = left_a
	pane_a.overlays = [bar_config]

	var pane_b := TauPaneConfig.new()
	pane_b.y_left_axis = left_b
	pane_b.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_a, pane_b]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT
	sb_a.pane_index = 0

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT
	sb_b.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot3.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset
	})


func _step_test_3() -> void:
	var st := _state[2]
	var dataset: TauPlot.Dataset = st["dataset"]
	var series_id_a = dataset.get_series_id_by_index(0)
	var series_id_b = dataset.get_series_id_by_index(1)

	dataset.begin_batch()
	for i in range(SAMPLE_COUNT):
		var base_a: float = Y_A_INIT[i]
		var base_b: float = Y_B_INIT[i]
		var y_a := base_a + 2.0 * sin(_t * 1.5 + float(i) * 0.8)
		var y_b := base_b + 2.0 * sin(_t * 1.5 + float(i) * 0.8)
		dataset.set_series_y(series_id_a, i, maxf(y_a, 0.1))
		dataset.set_series_y(series_id_b, i, maxf(y_b, 0.1))
	dataset.end_batch()

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [X_6, X_6], [Y_A_INIT, Y_B_INIT])
	_datasets.append(dataset)

	%TestPlot4.title = "[PER_SERIES_X] Update series A X values only"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = SAMPLE_COUNT

	var left_a := TauAxisConfig.new()
	left_a.title = "Series A"
	left_a.type = TauAxisConfig.Type.CONTINUOUS
	left_a.include_zero_in_domain = true

	var left_b := TauAxisConfig.new()
	left_b.title = "Series B"
	left_b.type = TauAxisConfig.Type.CONTINUOUS
	left_b.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.6

	var pane_a := TauPaneConfig.new()
	pane_a.y_left_axis = left_a
	pane_a.overlays = [bar_config]

	var pane_b := TauPaneConfig.new()
	pane_b.y_left_axis = left_b
	pane_b.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_a, pane_b]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT
	sb_a.pane_index = 0

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT
	sb_b.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot4.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset
	})


func _step_test_4() -> void:
	var st := _state[3]
	var dataset: TauPlot.Dataset = st["dataset"]
	var series_id_a = dataset.get_series_id_by_index(0)

	dataset.begin_batch()
	for i in range(SAMPLE_COUNT):
		var base: float = X_6[i]
		var x_new := base + 0.5 * sin(_t * 1.5 + float(i) * 0.8)
		dataset.set_series_x(series_id_a, i, x_new)
	dataset.end_batch()

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [X_6, X_6], [Y_A_INIT, Y_B_INIT])
	_datasets.append(dataset)

	%TestPlot5.title = "[PER_SERIES_X] Update series B X values only"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = SAMPLE_COUNT

	var left_a := TauAxisConfig.new()
	left_a.title = "Series A"
	left_a.type = TauAxisConfig.Type.CONTINUOUS
	left_a.include_zero_in_domain = true

	var left_b := TauAxisConfig.new()
	left_b.title = "Series B"
	left_b.type = TauAxisConfig.Type.CONTINUOUS
	left_b.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.6

	var pane_a := TauPaneConfig.new()
	pane_a.y_left_axis = left_a
	pane_a.overlays = [bar_config]

	var pane_b := TauPaneConfig.new()
	pane_b.y_left_axis = left_b
	pane_b.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_a, pane_b]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT
	sb_a.pane_index = 0

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT
	sb_b.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot5.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset
	})


func _step_test_5() -> void:
	var st := _state[4]
	var dataset: TauPlot.Dataset = st["dataset"]
	var series_id_b = dataset.get_series_id_by_index(1)

	dataset.begin_batch()
	for i in range(SAMPLE_COUNT):
		var base: float = X_6[i]
		var x_new := base + 0.5 * sin(_t * 1.5 + float(i) * 0.8)
		dataset.set_series_x(series_id_b, i, x_new)
	dataset.end_batch()

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, X_6, [Y_A_INIT, Y_B_INIT])
	_datasets.append(dataset)

	%TestPlot6.title = "[SHARED_X] Update shared X values => both panes shift horizontally"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = SAMPLE_COUNT

	var left_a := TauAxisConfig.new()
	left_a.title = "Series A"
	left_a.type = TauAxisConfig.Type.CONTINUOUS
	left_a.include_zero_in_domain = true

	var left_b := TauAxisConfig.new()
	left_b.title = "Series B"
	left_b.type = TauAxisConfig.Type.CONTINUOUS
	left_b.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.6

	var pane_a := TauPaneConfig.new()
	pane_a.y_left_axis = left_a
	pane_a.overlays = [bar_config]

	var pane_b := TauPaneConfig.new()
	pane_b.y_left_axis = left_b
	pane_b.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_a, pane_b]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT
	sb_a.pane_index = 0

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT
	sb_b.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot6.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
	})


func _step_test_6() -> void:
	var st := _state[5]
	var dataset: TauPlot.Dataset = st["dataset"]

	var offset := 3.0 * sin(_t * 0.8)
	dataset.begin_batch()
	for i in range(SAMPLE_COUNT):
		dataset.set_shared_x(i, X_6[i] + offset)
	dataset.end_batch()
