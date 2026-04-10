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

const PERIOD := 6.0
const SAMPLE_COUNT := 20

func _triangle(p_t: float, p_period: float) -> float:
	var phase := fmod(p_t, p_period) / p_period
	return 1.0 - abs(2.0 * phase - 1.0)

func _make_log_dataset(p_log_min_exp: float, p_log_max_exp: float) -> TauPlot.Dataset:
	var x := PackedFloat64Array()
	var y := PackedFloat64Array()
	x.resize(SAMPLE_COUNT)
	y.resize(SAMPLE_COUNT)
	for i in range(SAMPLE_COUNT):
		var t := float(i) / float(SAMPLE_COUNT - 1)
		x[i] = pow(10.0, p_log_min_exp + t * (p_log_max_exp - p_log_min_exp))
		y[i] = -1.0 + 4.0 * (0.5 + 0.4 * sin(float(i) * 0.5))
	var series_names := PackedStringArray(["A"])
	return TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y])

func _update_log_x_range(p_dataset: TauPlot.Dataset, p_log_min_exp: float, p_log_max_exp: float) -> void:
	p_dataset.begin_batch()
	for i in range(SAMPLE_COUNT):
		var t := float(i) / float(SAMPLE_COUNT - 1)
		p_dataset.set_shared_x(i, pow(10.0, p_log_min_exp + t * (p_log_max_exp - p_log_min_exp)))
	p_dataset.end_batch()

####################################################################################################
# Test 1
####################################################################################################

const T1_LOG_MIN_EXP := -9.0
const T1_LOG_MAX_EXP_START := 0.0
const T1_LOG_MAX_EXP_END := 9.0

func _setup_test_1() -> void:
	var dataset := _make_log_dataset(T1_LOG_MIN_EXP, T1_LOG_MAX_EXP_START)
	_datasets.append(dataset)

	%TestPlot1.title = "[NONE] Animate x_max from 1 to 1e9 => no prevention applied"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
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
	var log_max_exp := T1_LOG_MAX_EXP_START + _triangle(_t, PERIOD) * (T1_LOG_MAX_EXP_END - T1_LOG_MAX_EXP_START)
	_update_log_x_range(_state[0]["dataset"], T1_LOG_MIN_EXP, log_max_exp)

####################################################################################################
# Test 2
####################################################################################################

const T2_LOG_MIN_EXP := -9.0
const T2_LOG_MAX_EXP_START := 0.0
const T2_LOG_MAX_EXP_END := 9.0

func _setup_test_2() -> void:
	var dataset := _make_log_dataset(T2_LOG_MIN_EXP, T2_LOG_MAX_EXP_START)
	_datasets.append(dataset)

	%TestPlot2.title = "[REDUCE_COUNT] Animate x_max from 1 to 1e9 => ticks reduce to fit"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
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
	var log_max_exp := T2_LOG_MAX_EXP_START + _triangle(_t, PERIOD) * (T2_LOG_MAX_EXP_END - T2_LOG_MAX_EXP_START)
	_update_log_x_range(_state[1]["dataset"], T2_LOG_MIN_EXP, log_max_exp)

####################################################################################################
# Test 3
####################################################################################################

const T3_LOG_MIN_EXP := -9.0
const T3_LOG_MAX_EXP_START := 0.0
const T3_LOG_MAX_EXP_END := 9.0

func _setup_test_3() -> void:
	var dataset := _make_log_dataset(T3_LOG_MIN_EXP, T3_LOG_MAX_EXP_START)
	_datasets.append(dataset)

	%TestPlot3.title = "[SKIP_LABELS] Animate x_max from 1 to 1e9 => labels hidden progressively"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
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
	var log_max_exp := T3_LOG_MAX_EXP_START + _triangle(_t, PERIOD) * (T3_LOG_MAX_EXP_END - T3_LOG_MAX_EXP_START)
	_update_log_x_range(_state[2]["dataset"], T3_LOG_MIN_EXP, log_max_exp)

####################################################################################################
# Test 4
####################################################################################################

const T4_LOG_MIN_EXP := -9.0
const T4_LOG_MAX_EXP := 9.0
const T4_SPACING_MIN := 0
const T4_SPACING_MAX := 300

func _setup_test_4() -> void:
	var dataset := _make_log_dataset(T4_LOG_MIN_EXP, T4_LOG_MAX_EXP)
	_datasets.append(dataset)

	%TestPlot4.title = "[NONE] Animate x min_label_spacing_px [0, 300] => no prevention applied"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
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
	st["x_axis"].min_label_spacing_px = T4_SPACING_MIN + int(_triangle(_t, PERIOD) * float(T4_SPACING_MAX - T4_SPACING_MIN))
	st["plot"].refresh_now()

####################################################################################################
# Test 5
####################################################################################################

const T5_LOG_MIN_EXP := -9.0
const T5_LOG_MAX_EXP := 9.0
const T5_SPACING_MIN := 0
const T5_SPACING_MAX := 300

func _setup_test_5() -> void:
	var dataset := _make_log_dataset(T5_LOG_MIN_EXP, T5_LOG_MAX_EXP)
	_datasets.append(dataset)

	%TestPlot5.title = "[REDUCE_COUNT] Animate x min_label_spacing_px [0, 300]"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
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
	st["x_axis"].min_label_spacing_px = T5_SPACING_MIN + int(_triangle(_t, PERIOD) * float(T5_SPACING_MAX - T5_SPACING_MIN))
	st["plot"].refresh_now()

####################################################################################################
# Test 6
####################################################################################################

const T6_LOG_MIN_EXP := -9.0
const T6_LOG_MAX_EXP := 9.0
const T6_SPACING_MIN := 0
const T6_SPACING_MAX := 300

func _setup_test_6() -> void:
	var dataset := _make_log_dataset(T6_LOG_MIN_EXP, T6_LOG_MAX_EXP)
	_datasets.append(dataset)

	%TestPlot6.title = "[SKIP_LABELS] Animate x min_label_spacing_px [0, 300]"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
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
	st["x_axis"].min_label_spacing_px = T6_SPACING_MIN + int(_triangle(_t, PERIOD) * float(T6_SPACING_MAX - T6_SPACING_MIN))
	st["plot"].refresh_now()
