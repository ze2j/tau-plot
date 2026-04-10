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
# Dataset helpers
####################################################################################################

const SAMPLE_COUNT := 20

func _triangle(p_t: float, p_period: float) -> float:
	var phase := fmod(p_t, p_period) / p_period
	return 1.0 - abs(2.0 * phase - 1.0)


# Creates a two-series dataset with positive-only y values.
# Series 0 -> LEFT axis, Series 1 -> RIGHT axis.
func _make_dataset(p_y_left_max: float, p_y_right_max: float) -> TauPlot.Dataset:
	var x := PackedFloat64Array()
	var y_left := PackedFloat64Array()
	var y_right := PackedFloat64Array()
	x.resize(SAMPLE_COUNT)
	y_left.resize(SAMPLE_COUNT)
	y_right.resize(SAMPLE_COUNT)
	for i in range(SAMPLE_COUNT):
		x[i] = float(i)
		y_left[i] = p_y_left_max * (0.5 + 0.4 * sin(float(i) * 0.5))
		y_right[i] = p_y_right_max * (0.5 + 0.4 * cos(float(i) * 0.7))
	var series_names := PackedStringArray(["Left", "Right"])
	return TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_left, y_right])


# Creates a two-series dataset where y values span negative to positive.
# "Bipolar" means the data crosses zero on both sides, which is needed for
# TauPaneConfig.align_y_axes_at_zero to engage (that feature only activates when
# zero falls inside both domains).
func _make_dataset_bipolar(p_y_left_max: float, p_y_right_max: float) -> TauPlot.Dataset:
	var x := PackedFloat64Array()
	var y_left := PackedFloat64Array()
	var y_right := PackedFloat64Array()
	x.resize(SAMPLE_COUNT)
	y_left.resize(SAMPLE_COUNT)
	y_right.resize(SAMPLE_COUNT)
	for i in range(SAMPLE_COUNT):
		x[i] = float(i)
		y_left[i] = p_y_left_max * sin(float(i) * 0.5)
		y_right[i] = p_y_right_max * cos(float(i) * 0.7)
	var series_names := PackedStringArray(["Left", "Right"])
	return TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_left, y_right])


# Creates a two-series dataset with linear left and log-spaced right y values.
func _make_log_dataset(p_y_left_max: float, p_log_min_exp: float, p_log_max_exp: float) -> TauPlot.Dataset:
	var x := PackedFloat64Array()
	var y_left := PackedFloat64Array()
	var y_right := PackedFloat64Array()
	x.resize(SAMPLE_COUNT)
	y_left.resize(SAMPLE_COUNT)
	y_right.resize(SAMPLE_COUNT)
	for i in range(SAMPLE_COUNT):
		var t := float(i) / float(SAMPLE_COUNT - 1)
		x[i] = float(i)
		y_left[i] = p_y_left_max * (0.5 + 0.4 * sin(float(i) * 0.5))
		y_right[i] = pow(10.0, p_log_min_exp + t * (p_log_max_exp - p_log_min_exp))
	var series_names := PackedStringArray(["Left", "Right"])
	return TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_left, y_right])


func _update_series_y(p_dataset: TauPlot.Dataset, p_series_id: int, p_y_max: float, p_phase_offset: float) -> void:
	var new_y := PackedFloat64Array()
	new_y.resize(SAMPLE_COUNT)
	for i in range(SAMPLE_COUNT):
		new_y[i] = p_y_max * (0.5 + 0.4 * sin(float(i) * 0.5 + p_phase_offset))
	p_dataset.set_series_y_slice(p_series_id, 0, new_y)


func _update_series_y_bipolar(p_dataset: TauPlot.Dataset, p_series_id: int, p_y_max: float, p_phase_offset: float) -> void:
	var new_y := PackedFloat64Array()
	new_y.resize(SAMPLE_COUNT)
	for i in range(SAMPLE_COUNT):
		new_y[i] = p_y_max * sin(float(i) * 0.5 + p_phase_offset)
	p_dataset.set_series_y_slice(p_series_id, 0, new_y)

####################################################################################################
# Test 1
####################################################################################################

const T1_PERIOD := 15.0
const T1_LEFT_Y_MIN := 10.0
const T1_LEFT_Y_MAX := 1_000_000.0
const T1_RIGHT_Y_STABLE := 500.0

func _setup_test_1() -> void:
	%TestPlot1.title = "[NONE] Animate LEFT y range [10, 1M], right stable => both sides overlap freely"

	var dataset := _make_dataset(T1_LEFT_Y_MIN, T1_RIGHT_Y_STABLE)
	_datasets.append(dataset)

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS

	var left_axis := TauAxisConfig.new()
	left_axis.title = "LEFT"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.include_zero_in_domain = false
	left_axis.tick_count_preferred = 12
	left_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE

	var right_axis := TauAxisConfig.new()
	right_axis.title = "RIGHT"
	right_axis.type = TauAxisConfig.Type.CONTINUOUS
	right_axis.include_zero_in_domain = false
	right_axis.tick_count_preferred = 12
	right_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.y_right_axis = right_axis
	pane.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_l := TauXYSeriesBinding.new()
	sb_l.series_id = dataset.get_series_id_by_index(0)
	sb_l.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_l.y_axis_id = TauPlot.AxisId.LEFT

	var sb_r := TauXYSeriesBinding.new()
	sb_r.series_id = dataset.get_series_id_by_index(1)
	sb_r.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_r.y_axis_id = TauPlot.AxisId.RIGHT

	var bindings: Array[TauXYSeriesBinding] = [sb_l, sb_r]

	%TestPlot1.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"series_id_left": dataset.get_series_id_by_index(0),
		"series_id_right": dataset.get_series_id_by_index(1),
	})


func _step_test_1() -> void:
	var st := _state[0]
	var y_max := T1_LEFT_Y_MIN + _triangle(_t, T1_PERIOD) * (T1_LEFT_Y_MAX - T1_LEFT_Y_MIN)
	_update_series_y(st["dataset"], st["series_id_left"], y_max, 0.0)

####################################################################################################
# Test 2
####################################################################################################

const T2_PERIOD := 15.0
const T2_LEFT_Y_MIN := 10.0
const T2_LEFT_Y_MAX := 1_000_000.0
const T2_RIGHT_Y_STABLE := 500.0

func _setup_test_2() -> void:
	%TestPlot2.title = "[REDUCE_COUNT] Animate LEFT y range [10, 1M], right stable => left drops ticks, right unchanged"

	var dataset := _make_dataset(T2_LEFT_Y_MIN, T2_RIGHT_Y_STABLE)
	_datasets.append(dataset)

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS

	var left_axis := TauAxisConfig.new()
	left_axis.title = "LEFT"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.include_zero_in_domain = false
	left_axis.tick_count_preferred = 12
	left_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.REDUCE_COUNT

	var right_axis := TauAxisConfig.new()
	right_axis.title = "RIGHT"
	right_axis.type = TauAxisConfig.Type.CONTINUOUS
	right_axis.include_zero_in_domain = false
	right_axis.tick_count_preferred = 12
	right_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.REDUCE_COUNT

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.y_right_axis = right_axis
	pane.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_l := TauXYSeriesBinding.new()
	sb_l.series_id = dataset.get_series_id_by_index(0)
	sb_l.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_l.y_axis_id = TauPlot.AxisId.LEFT

	var sb_r := TauXYSeriesBinding.new()
	sb_r.series_id = dataset.get_series_id_by_index(1)
	sb_r.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_r.y_axis_id = TauPlot.AxisId.RIGHT

	var bindings: Array[TauXYSeriesBinding] = [sb_l, sb_r]

	%TestPlot2.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"series_id_left": dataset.get_series_id_by_index(0),
	})


func _step_test_2() -> void:
	var st := _state[1]
	var y_max := T2_LEFT_Y_MIN + _triangle(_t, T2_PERIOD) * (T2_LEFT_Y_MAX - T2_LEFT_Y_MIN)
	_update_series_y(st["dataset"], st["series_id_left"], y_max, 0.0)

####################################################################################################
# Test 3
####################################################################################################

const T3_PERIOD := 15.0
const T3_LEFT_Y_STABLE := 500.0
const T3_RIGHT_Y_MIN := 10.0
const T3_RIGHT_Y_MAX := 1_000_000.0

func _setup_test_3() -> void:
	%TestPlot3.title = "[SKIP_LABELS] Animate RIGHT y range [10, 1M], left stable => right skips labels, left unchanged"

	var dataset := _make_dataset(T3_LEFT_Y_STABLE, T3_RIGHT_Y_MIN)
	_datasets.append(dataset)

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS

	var left_axis := TauAxisConfig.new()
	left_axis.title = "LEFT"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.include_zero_in_domain = false
	left_axis.tick_count_preferred = 12
	left_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var right_axis := TauAxisConfig.new()
	right_axis.title = "RIGHT"
	right_axis.type = TauAxisConfig.Type.CONTINUOUS
	right_axis.include_zero_in_domain = false
	right_axis.tick_count_preferred = 12
	right_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.y_right_axis = right_axis
	pane.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_l := TauXYSeriesBinding.new()
	sb_l.series_id = dataset.get_series_id_by_index(0)
	sb_l.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_l.y_axis_id = TauPlot.AxisId.LEFT

	var sb_r := TauXYSeriesBinding.new()
	sb_r.series_id = dataset.get_series_id_by_index(1)
	sb_r.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_r.y_axis_id = TauPlot.AxisId.RIGHT

	var bindings: Array[TauXYSeriesBinding] = [sb_l, sb_r]

	%TestPlot3.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"series_id_right": dataset.get_series_id_by_index(1),
	})


func _step_test_3() -> void:
	var st := _state[2]
	var y_max := T3_RIGHT_Y_MIN + _triangle(_t, T3_PERIOD) * (T3_RIGHT_Y_MAX - T3_RIGHT_Y_MIN)
	_update_series_y(st["dataset"], st["series_id_right"], y_max, 0.0)

####################################################################################################
# Test 4
####################################################################################################

const T4_PERIOD := 15.0
const T4_Y_MIN := 10.0
const T4_Y_MAX := 1_000_000.0

func _setup_test_4() -> void:
	%TestPlot4.title = "[SKIP_LABELS] Animate BOTH y ranges [10, 1M] => both sides skip labels in lock-step"

	var dataset := _make_dataset(T4_Y_MIN, T4_Y_MIN)
	_datasets.append(dataset)

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS

	var left_axis := TauAxisConfig.new()
	left_axis.title = "LEFT"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.include_zero_in_domain = false
	left_axis.tick_count_preferred = 12
	left_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var right_axis := TauAxisConfig.new()
	right_axis.title = "RIGHT"
	right_axis.type = TauAxisConfig.Type.CONTINUOUS
	right_axis.include_zero_in_domain = false
	right_axis.tick_count_preferred = 12
	right_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.y_right_axis = right_axis
	pane.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_l := TauXYSeriesBinding.new()
	sb_l.series_id = dataset.get_series_id_by_index(0)
	sb_l.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_l.y_axis_id = TauPlot.AxisId.LEFT

	var sb_r := TauXYSeriesBinding.new()
	sb_r.series_id = dataset.get_series_id_by_index(1)
	sb_r.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_r.y_axis_id = TauPlot.AxisId.RIGHT

	var bindings: Array[TauXYSeriesBinding] = [sb_l, sb_r]

	%TestPlot4.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"series_id_left": dataset.get_series_id_by_index(0),
		"series_id_right": dataset.get_series_id_by_index(1),
	})


func _step_test_4() -> void:
	var st := _state[3]
	var y_max := T4_Y_MIN + _triangle(_t, T4_PERIOD) * (T4_Y_MAX - T4_Y_MIN)
	_update_series_y(st["dataset"], st["series_id_left"], y_max, 0.0)
	_update_series_y(st["dataset"], st["series_id_right"], y_max, 0.5)

####################################################################################################
# Test 5
####################################################################################################

const T5_PERIOD := 10.0
const T5_LEFT_Y_MAX := 1_000_000.0
const T5_RIGHT_LOG_MIN_EXP := -3.0
const T5_RIGHT_LOG_MAX_EXP := 6.0
const T5_SPACING_MIN := 0
const T5_SPACING_MAX := 150

func _setup_test_5() -> void:
	%TestPlot5.title = "[REDUCE_COUNT] LEFT=LINEAR RIGHT=LOG, animate y min_label_spacing_px [0, 150] => both respond, different arithmetic"

	# LEFT: linear, RIGHT: logarithmic -- right side uses log-spaced positive values.
	var dataset := _make_log_dataset(T5_LEFT_Y_MAX, T5_RIGHT_LOG_MIN_EXP, T5_RIGHT_LOG_MAX_EXP)
	_datasets.append(dataset)

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS

	var left_axis := TauAxisConfig.new()
	left_axis.title = "LEFT (linear)"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.include_zero_in_domain = false
	left_axis.tick_count_preferred = 12
	left_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.REDUCE_COUNT
	left_axis.min_label_spacing_px = T5_SPACING_MIN

	var right_axis := TauAxisConfig.new()
	right_axis.title = "RIGHT (log)"
	right_axis.type = TauAxisConfig.Type.CONTINUOUS
	right_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	right_axis.include_zero_in_domain = false
	right_axis.tick_count_preferred = 12
	right_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.REDUCE_COUNT
	right_axis.min_label_spacing_px = T5_SPACING_MIN

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.y_right_axis = right_axis
	pane.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_l := TauXYSeriesBinding.new()
	sb_l.series_id = dataset.get_series_id_by_index(0)
	sb_l.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_l.y_axis_id = TauPlot.AxisId.LEFT

	var sb_r := TauXYSeriesBinding.new()
	sb_r.series_id = dataset.get_series_id_by_index(1)
	sb_r.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_r.y_axis_id = TauPlot.AxisId.RIGHT

	var bindings: Array[TauXYSeriesBinding] = [sb_l, sb_r]

	%TestPlot5.plot_xy(dataset, config, bindings)

	_state.append({"plot": %TestPlot5, "left_axis": left_axis})


func _step_test_5() -> void:
	var st := _state[4]
	st["left_axis"].min_label_spacing_px = T5_SPACING_MIN + int(_triangle(_t, T5_PERIOD) * float(T5_SPACING_MAX - T5_SPACING_MIN))
	st["plot"].refresh_now()

####################################################################################################
# Test 6
####################################################################################################

const T6_PERIOD := 15.0
const T6_LEFT_Y_MIN := 10.0
const T6_LEFT_Y_MAX := 1_000_000.0
const T6_RIGHT_Y_STABLE := 500.0

func _setup_test_6() -> void:
	%TestPlot6.title = "[SKIP_LABELS] align_at_zero=true, animate LEFT y range [10, 1M] => labels skip correctly while zero-alignment holds"

	# Bipolar data (spans zero on both sides) to allow zero-alignment to engage.
	var dataset := _make_dataset_bipolar(T6_LEFT_Y_MIN, T6_RIGHT_Y_STABLE)
	_datasets.append(dataset)

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS

	var left_axis := TauAxisConfig.new()
	left_axis.title = "LEFT"
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.include_zero_in_domain = true
	left_axis.tick_count_preferred = 12
	left_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var right_axis := TauAxisConfig.new()
	right_axis.title = "RIGHT"
	right_axis.type = TauAxisConfig.Type.CONTINUOUS
	right_axis.include_zero_in_domain = true
	right_axis.tick_count_preferred = 12
	right_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.y_right_axis = right_axis
	pane.align_y_axes_at_zero = true
	pane.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_l := TauXYSeriesBinding.new()
	sb_l.series_id = dataset.get_series_id_by_index(0)
	sb_l.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_l.y_axis_id = TauPlot.AxisId.LEFT

	var sb_r := TauXYSeriesBinding.new()
	sb_r.series_id = dataset.get_series_id_by_index(1)
	sb_r.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_r.y_axis_id = TauPlot.AxisId.RIGHT

	var bindings: Array[TauXYSeriesBinding] = [sb_l, sb_r]

	%TestPlot6.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"series_id_left": dataset.get_series_id_by_index(0),
	})


func _step_test_6() -> void:
	var st := _state[5]
	var y_max := T6_LEFT_Y_MIN + _triangle(_t, T6_PERIOD) * (T6_LEFT_Y_MAX - T6_LEFT_Y_MIN)
	_update_series_y_bipolar(st["dataset"], st["series_id_left"], y_max, 0.0)
