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


func _on_tick() -> void:
	_t += _timer.wait_time

	_step_test_1()
	_step_test_2()
	_step_test_3()
	_step_test_4()
	_step_test_5()
	_step_test_6()
	_step_test_7()

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["Series A", "Series B", "Series C"])
	var x_a := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])
	var x_b := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0].map(func (x) -> float: return 1.1*x))
	var x_c := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0].map(func (x) -> float: return 1.2*x))

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	var y_c := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())
	y_c.resize(x_c.size())

	for i in range(x_a.size()):
		y_a[i] = 5.0 +  2.5 * sin(float(i) * 0.3)
	for i in range(x_b.size()):
		y_b[i] = 4.0 +  2.0 * cos(float(i) * 0.5)
	for i in range(x_c.size()):
		y_c[i] = 3.0 +  2.5 * sin(float(i) * 0.7)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b, x_c], [y_a, y_b, y_c])
	_datasets.append(dataset)
	_state.append({})

	%TestPlot1.title = "[LOG X, LINEAR Y] Independent - Animated Y values in [2.5, 7.5]"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X (log scale)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.title = "Y (linear)"
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.range_override_enabled = true
	y_axis.min_override = 0.01
	y_axis.max_override = 8.00

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


func _step_test_1() -> void:
	var dataset := _datasets[0]

	dataset.begin_batch()
	var ids := dataset.get_series_ids()
	for s_i in range(ids.size()):
		var series_id := ids[s_i]
		var n := dataset.get_series_sample_count(series_id)

		var values := PackedFloat64Array()
		values.resize(n)
		var phase := float(s_i) * 0.7
		for i in range(values.size()):
			values[i] = 5.0 + 2.5 * sin(_t + phase + float(i) * 0.5)

		dataset.set_series_y_slice(series_id, 0, values)
	dataset.end_batch()

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
	var x_b := PackedFloat64Array([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0].map(func (x) -> float: return 1.1*x))

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())

	for i in range(x_a.size()):
		y_a[i] = 0.1 * pow(10.0, float(i) * 0.4)
	for i in range(x_b.size()):
		y_b[i] = 0.05 * pow(10.0, float(i) * 0.4)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])
	_datasets.append(dataset)
	_state.append({})

	%TestPlot2.title = "[LINEAR X, LOG Y] Independent - Animated Y values (exponential growth)"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X (linear)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var y_axis := TauAxisConfig.new()
	y_axis.title = "Y (log scale)"
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

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

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot2.plot_xy(dataset, config, bindings)


func _step_test_2() -> void:
	var dataset := _datasets[1]

	dataset.begin_batch()
	var ids := dataset.get_series_ids()
	for s_i in range(ids.size()):
		var series_id := ids[s_i]
		var n := dataset.get_series_sample_count(series_id)

		var values := PackedFloat64Array()
		values.resize(n)
		var base_multiplier := 0.1 if s_i == 0 else 0.05
		var phase := float(s_i) * 1.2

		for i in range(n):
			var osc := 1.0 + 0.5 * sin(_t + phase)
			values[i] = base_multiplier * pow(10.0, float(i) * 0.4) * osc

		dataset.set_series_y_slice(series_id, 0, values)
	dataset.end_batch()

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([0.05, 0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])
	var x_b := PackedFloat64Array([0.05, 0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0].map(func (x) -> float: return 1.1*x))

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())

	for i in range(x_a.size()):
		y_a[i] = pow(x_a[i], 0.5)
	for i in range(x_b.size()):
		y_b[i] = pow(x_b[i], 0.25)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])
	_datasets.append(dataset)
	_state.append({})

	%TestPlot3.title = "[LOG X, LOG Y] Independent - Animated Y values (power laws => linear in log-log)"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X (log scale)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.title = "Y (log scale)"
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

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

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot3.plot_xy(dataset, config, bindings)


func _step_test_3() -> void:
	var dataset := _datasets[2]

	# Animate by varying the power law exponent slightly
	dataset.begin_batch()
	var ids := dataset.get_series_ids()
	for s_i in range(ids.size()):
		var series_id := ids[s_i]

		var n := dataset.get_series_sample_count(series_id)
		var values := PackedFloat64Array()
		values.resize(n)
		var base_exponent := 2.0 if s_i == 0 else 1.5
		var exponent := base_exponent + 0.3 * sin(_t + float(s_i))

		for i in range(n):
			var x_val := float(dataset.get_series_x(series_id, i))
			values[i] = pow(x_val, exponent)

		dataset.set_series_y_slice(series_id, 0, values)
	dataset.end_batch()

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_datasets.append(null)
	_state.append({})


func _step_test_4() -> void:
	pass

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
	var series_names := PackedStringArray(["Stream A", "Stream B"])
	# Start with a few initial points
	var x := PackedFloat64Array([1.0, 2.0, 5.0])

	var y_a := PackedFloat64Array([3.0, 5.0, 4.0])
	var y_b := PackedFloat64Array([2.0, 4.0, 3.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b], 64)
	_datasets.append(dataset)
	_state.append({
		"next_x": 10.0,
		"time_since_append_s": 0.0,
		"append_period_s": 0.5,
	})

	%TestPlot7.title = "[LOG X] Streaming - New samples every 0.5s"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X (log scale, growing)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.title = "Y (linear)"
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

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot7.plot_xy(dataset, config, bindings)


func _step_test_7() -> void:
	var dataset := _datasets[6]
	var st := _state[6]

	st["time_since_append_s"] = float(st["time_since_append_s"]) + _timer.wait_time
	if float(st["time_since_append_s"]) < float(st["append_period_s"]):
		return
	st["time_since_append_s"] = 0.0

	var next_x := float(st["next_x"])

	# Append new sample at increasing X (logarithmic progression)
	var ys := PackedFloat64Array([
		4.0 + 2.0 * sin(_t),
		3.0 + 2.0 * cos(_t * 1.5)
	])

	dataset.append_shared_sample(next_x, ys)

	# Next X grows exponentially (log-uniform spacing)
	st["next_x"] = next_x * 1.5
