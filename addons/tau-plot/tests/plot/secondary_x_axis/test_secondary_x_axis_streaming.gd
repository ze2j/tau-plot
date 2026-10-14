@tool
extends Control

# The primary x range sweeps back and forth across 0. While it holds 0 the
# secondary x range is invalid: the secondary labels and grid lines vanish,
# then come back once 0 leaves the range. The plot must not move, and the
# output shows one warning per plot.

var _timer: Timer = null
var _t: float = 0.0

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
	_state.clear()

	_setup_test_1()
	_setup_test_2()

func _on_tick() -> void:
	_t += _timer.wait_time

	_step_test_1()
	_step_test_2()

####################################################################################################
# Shared constants
####################################################################################################

const CAPACITY := 30
const APPEND_INTERVAL := 0.05
const PHASE_STEP := 0.05

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var x := PackedFloat64Array()
	var y := PackedFloat64Array()
	for i in range(CAPACITY):
		var phase := float(i) * PHASE_STEP
		x.append(3.0 + 4.0 * sin(phase))
		y.append(5.0 + 2.0 * cos(phase * 3.0))
	var dataset := TauPlot.Dataset.make_shared_x_continuous(["A"], x, [y], CAPACITY)

	%TestPlot1.title = "BOTTOM x axis: 1/x labels vanish and come back"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "FREQUENCY (Hz)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.include_zero_in_domain = false

	var x2_axis := TauAxisConfig.new()
	x2_axis.title = "PERIOD (s)"
	x2_axis.type = TauAxisConfig.Type.CONTINUOUS

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.range_override_enabled = true
	y_axis.min_override = 0
	y_axis.max_override = 10

	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_source_axis_id = TauPlot.AxisId.TOP

	var scatter_config := TauScatterConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_config]
	pane.grid_line = grid_line_config

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.BOTTOM
	config.secondary_x_axis = x2_axis
	config.secondary_x_axis_transform = func(f: float) -> float: return 1.0 / f
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot1.legend_enabled = false
	%TestPlot1.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"next_sample": CAPACITY,
		"last_append_t": 0.0,
	})


func _step_test_1() -> void:
	var st := _state[0]
	if _t - st["last_append_t"] < APPEND_INTERVAL:
		return

	var dataset: TauPlot.Dataset = st["dataset"]
	var phase := float(st["next_sample"]) * PHASE_STEP
	dataset.append_shared_sample(3.0 + 4.0 * sin(phase), PackedFloat64Array([5.0 + 2.0 * cos(phase * 3.0)]))

	st["next_sample"] += 1
	st["last_append_t"] = _t

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var x := PackedFloat64Array()
	var y := PackedFloat64Array()
	for i in range(CAPACITY):
		var phase := float(i) * PHASE_STEP
		x.append(3.0 + 4.0 * sin(phase))
		y.append(5.0 + 2.0 * cos(phase * 3.0))
	var dataset := TauPlot.Dataset.make_shared_x_continuous(["A"], x, [y], CAPACITY)

	%TestPlot2.title = "LEFT x axis: 1/x labels vanish and come back"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "FREQUENCY (Hz)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.include_zero_in_domain = false

	var x2_axis := TauAxisConfig.new()
	x2_axis.title = "PERIOD (s)"
	x2_axis.type = TauAxisConfig.Type.CONTINUOUS

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.range_override_enabled = true
	y_axis.min_override = 0
	y_axis.max_override = 10

	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_source_axis_id = TauPlot.AxisId.RIGHT

	var scatter_config := TauScatterConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_bottom_axis = y_axis
	pane.overlays = [scatter_config]
	pane.grid_line = grid_line_config

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.LEFT
	config.secondary_x_axis = x2_axis
	config.secondary_x_axis_transform = func(f: float) -> float: return 1.0 / f
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.BOTTOM

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot2.legend_enabled = false
	%TestPlot2.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"next_sample": CAPACITY,
		"last_append_t": 0.0,
	})


func _step_test_2() -> void:
	var st := _state[1]
	if _t - st["last_append_t"] < APPEND_INTERVAL:
		return

	var dataset: TauPlot.Dataset = st["dataset"]
	var phase := float(st["next_sample"]) * PHASE_STEP
	dataset.append_shared_sample(3.0 + 4.0 * sin(phase), PackedFloat64Array([5.0 + 2.0 * cos(phase * 3.0)]))

	st["next_sample"] += 1
	st["last_append_t"] = _t
