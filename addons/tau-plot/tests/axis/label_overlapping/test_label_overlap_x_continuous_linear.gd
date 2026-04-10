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
# Helpers
####################################################################################################

const SAMPLE_COUNT := 20

func _triangle(p_t: float, p_period: float) -> float:
	var phase := fmod(p_t, p_period) / p_period
	return 1.0 - abs(2.0 * phase - 1.0)

func _make_linear_dataset(p_x_max: float) -> TauPlot.Dataset:
	var x := PackedFloat64Array()
	var y := PackedFloat64Array()
	x.resize(SAMPLE_COUNT)
	y.resize(SAMPLE_COUNT)
	for i in range(SAMPLE_COUNT):
		var t := float(i) / float(SAMPLE_COUNT - 1)
		x[i] = t * p_x_max
		y[i] = -1.0 + 4.0 * (0.5 + 0.4 * sin(float(i) * 0.5))
	var series_names := PackedStringArray(["A"])
	return TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y])

func _update_linear_x_range(p_dataset: TauPlot.Dataset, p_x_max: float) -> void:
	p_dataset.begin_batch()
	for i in range(SAMPLE_COUNT):
		var t := float(i) / float(SAMPLE_COUNT - 1)
		p_dataset.set_shared_x(i, t * p_x_max)
	p_dataset.end_batch()

####################################################################################################
# Test 1
####################################################################################################

const T1_PERIOD := 15.0
const T1_TICK_PREFERRED := 12
const T1_X_RANGE_MIN := 1000.0
const T1_X_RANGE_MAX := 1000000.0

func _setup_test_1() -> void:
	var dataset := _make_linear_dataset(T1_X_RANGE_MIN)
	_datasets.append(dataset)

	%TestPlot1.title = "[NONE] Animate x_max from 1000 to 1M => no prevention applied"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = T1_TICK_PREFERRED
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot1.plot_xy(dataset, config, bindings)

	_state.append({"dataset": dataset})


func _step_test_1() -> void:
	var x_max := T1_X_RANGE_MIN + _triangle(_t, T1_PERIOD) * (T1_X_RANGE_MAX - T1_X_RANGE_MIN)
	_update_linear_x_range(_state[0]["dataset"], x_max)

####################################################################################################
# Test 2
####################################################################################################

const T2_PERIOD := 15.0
const T2_TICK_PREFERRED := 12
const T2_X_RANGE_MIN := 1000.0
const T2_X_RANGE_MAX := 1000000.0

func _setup_test_2() -> void:
	var dataset := _make_linear_dataset(T2_X_RANGE_MIN)
	_datasets.append(dataset)

	%TestPlot2.title = "[REDUCE_COUNT] Animate x_max from 1000 to 1M => ticks reduce to fit"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = T2_TICK_PREFERRED
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.REDUCE_COUNT

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot2.plot_xy(dataset, config, bindings)

	_state.append({"dataset": dataset})


func _step_test_2() -> void:
	var x_max := T2_X_RANGE_MIN + _triangle(_t, T2_PERIOD) * (T2_X_RANGE_MAX - T2_X_RANGE_MIN)
	_update_linear_x_range(_state[1]["dataset"], x_max)

####################################################################################################
# Test 3
####################################################################################################

const T3_PERIOD := 15.0
const T3_TICK_PREFERRED := 12
const T3_X_RANGE_MIN := 1000.0
const T3_X_RANGE_MAX := 1000000.0

func _setup_test_3() -> void:
	var dataset := _make_linear_dataset(T3_X_RANGE_MIN)
	_datasets.append(dataset)

	%TestPlot3.title = "[SKIP_LABELS] Animate x_max from 1000 to 1M => labels hidden progressively"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = T3_TICK_PREFERRED
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot3.plot_xy(dataset, config, bindings)

	_state.append({"dataset": dataset})


func _step_test_3() -> void:
	var x_max := T3_X_RANGE_MIN + _triangle(_t, T3_PERIOD) * (T3_X_RANGE_MAX - T3_X_RANGE_MIN)
	_update_linear_x_range(_state[2]["dataset"], x_max)

####################################################################################################
# Test 4
####################################################################################################

const T4_PERIOD := 10.0
const T4_TICK_PREFERRED := 12
const T4_X_MAX := 1_000_000.0
const T4_SPACING_MIN := 0
const T4_SPACING_MAX := 100

func _setup_test_4() -> void:
	var dataset := _make_linear_dataset(T4_X_MAX)
	_datasets.append(dataset)

	%TestPlot4.title = "[NONE] Animate x min_label_spacing_px [0, 100] => no prevention applied"


	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = T4_TICK_PREFERRED
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE
	x_axis.min_label_spacing_px = T4_SPACING_MIN

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot4.plot_xy(dataset, config, bindings)

	_state.append({"plot": %TestPlot4, "x_axis": x_axis})


func _step_test_4() -> void:
	var st := _state[3]
	st["x_axis"].min_label_spacing_px = T4_SPACING_MIN + int(_triangle(_t, T4_PERIOD) * float(T4_SPACING_MAX - T4_SPACING_MIN))
	st["plot"].refresh_now()

####################################################################################################
# Test 5
####################################################################################################

const T5_PERIOD := 10.0
const T5_TICK_PREFERRED := 12
const T5_X_MAX := 1000000.0
const T5_SPACING_MIN := 0
const T5_SPACING_MAX := 100

func _setup_test_5() -> void:
	var dataset := _make_linear_dataset(T5_X_MAX)
	_datasets.append(dataset)

	%TestPlot5.title = "[REDUCE_COUNT] Animate x min_label_spacing_px [0, 100]"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = T5_TICK_PREFERRED
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.REDUCE_COUNT
	x_axis.min_label_spacing_px = T5_SPACING_MIN

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot5.plot_xy(dataset, config, bindings)

	_state.append({"plot": %TestPlot5, "x_axis": x_axis})


func _step_test_5() -> void:
	var st := _state[4]
	st["x_axis"].min_label_spacing_px = T5_SPACING_MIN + int(_triangle(_t, T5_PERIOD) * float(T5_SPACING_MAX - T5_SPACING_MIN))
	st["plot"].refresh_now()

####################################################################################################
# Test 6
####################################################################################################

const T6_PERIOD := 10.0
const T6_TICK_PREFERRED := 12
const T6_X_MAX := 1000000.0
const T6_SPACING_MIN := 0
const T6_SPACING_MAX := 100

func _setup_test_6() -> void:
	var dataset := _make_linear_dataset(T6_X_MAX)
	_datasets.append(dataset)

	%TestPlot6.title = "[SKIP_LABELS] Animate x min_label_spacing_px [0, 100]"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = T6_TICK_PREFERRED
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS
	x_axis.min_label_spacing_px = T6_SPACING_MIN

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot6.plot_xy(dataset, config, bindings)

	_state.append({"plot": %TestPlot6, "x_axis": x_axis})


func _step_test_6() -> void:
	var st := _state[5]
	st["x_axis"].min_label_spacing_px = T6_SPACING_MIN + int(_triangle(_t, T6_PERIOD) * float(T6_SPACING_MAX - T6_SPACING_MIN))
	st["plot"].refresh_now()
