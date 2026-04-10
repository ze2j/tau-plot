@tool
extends Control

class Spectrum extends RefCounted:

	const ATTACK_HZ: float = 18.0
	const RELEASE_HZ: float = 6.0
	const ENERGY_DECAY_HZ: float = 10.0
	const HIT_RATE: float = 1.8
	const HIT_STRENGTH: float = 1.2
	const BREATH: float = 0.08

	var values: Array[float] = []
	var energy: Array[float] = []
	var phase: Array[float] = []

	func _init(p_band_count: int = 16) -> void:
		values.resize(p_band_count)
		energy.resize(p_band_count)
		phase.resize(p_band_count)

		for i in p_band_count:
			values[i] = randf()
			energy[i] = 0.0
			phase[i] = randf() * TAU

	func step(delta: float) -> void:
		for i in values.size():
			_step_band(i, delta)

	func _step_band(i: int, delta: float) -> void:
		# 1) transient impulses (Poisson-ish)
		if randf() < HIT_RATE * delta:
			var impulse := pow(randf(), 3.0) * HIT_STRENGTH
			energy[i] += impulse

		# 2) excitation decay
		energy[i] *= exp(-ENERGY_DECAY_HZ * delta)

		# 3) slow breathing motion
		phase[i] += (2.0 + 3.0 * randf()) * delta
		var slow_noise := sin(phase[i]) * BREATH

		var target := energy[i] + slow_noise

		# 4) fast attack, slow release
		if target > values[i]:
			values[i] += (target - values[i]) * (1.0 - exp(-ATTACK_HZ * delta))
		else:
			values[i] += (target - values[i]) * (1.0 - exp(-RELEASE_HZ * delta))

var _t: float = 0.0

var _datasets: Array[TauPlot.Dataset] = []
var _state: Array[Dictionary] = []

var _spectrum_1: Spectrum = null
var _spectrum_2: Spectrum = null

var _gradient: Gradient = null

func _ready() -> void:
	_t = 0.0
	_datasets.clear()
	_state.clear()
	_spectrum_1 = Spectrum.new(6)
	_spectrum_2 = Spectrum.new(6)

	_gradient = Gradient.new()
	_gradient.offsets = PackedFloat32Array([
		0.0,
		0.25,
		0.5,
		0.75,
		1.0
	])
	_gradient.colors = PackedColorArray([
		Color("e5007d"),
		Color("ca2c88"),
		Color("ab3e8f"),
		Color("874996"),
		Color("5e4e9c"),
	])

	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	#_setup_test_4()
	#_setup_test_5()
	#_setup_test_6()
	#_setup_test_7()
	#_setup_test_8()
	#_setup_test_9()
	#_setup_test_10()

func _process(delta: float) -> void:
	_t += delta

	_spectrum_1.step(delta)
	_spectrum_2.step(delta)

	_step_test_1(delta)
	_step_test_2(delta)
	_step_test_3(delta)
	#_step_test_4()
	#_step_test_5()
	#_step_test_6()
	#_step_test_7()
	#_step_test_8()
	#_step_test_9()
	#_step_test_10()

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["A"])
	var x := PackedStringArray(["B1", "B2", "B3", "B4", "B5", "B6"])
	var y := PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y])
	_datasets.append(dataset)

	%TestPlot1.title = "[GROUPED] Gradient sampled by y value"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.range_override_enabled = true
	left_axis.min_override = -Spectrum.BREATH
	left_axis.max_override = 1.0 # No upper bound in reality

	var visual_callbacks := TauPlot.BarVisualCallbacks.new()
	visual_callbacks.color_callback = Callable(func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> Color:
		return _gradient.sample(clampf(1.0 - y_value, 0.0, 1.0)))

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION
	bar_config.category_width_fraction = 0.5
	bar_config.intra_group_gap_fraction = 0.0
	bar_config.visual_callbacks = visual_callbacks

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
	_state.append({})


func _step_test_1(delta: float) -> void:
	var dataset := _datasets[0]
	dataset.begin_batch()
	for b in range(dataset.get_shared_capacity()):
		dataset.set_series_y(dataset.get_series_id_by_index(0), b, _spectrum_1.values[b])
	dataset.end_batch()

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedStringArray(["B1", "B2", "B3", "B4", "B5", "B6"])
	var y_a := PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
	var y_b := PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot2.title = "[STACKED] Gradient sampled by y value"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.range_override_enabled = true
	left_axis.min_override = -Spectrum.BREATH
	left_axis.max_override = 2.0 # No upper bound in reality

	var visual_callbacks := TauPlot.BarVisualCallbacks.new()
	visual_callbacks.color_callback = Callable(func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> Color:
		return _gradient.sample(clampf(1.0 - y_value, 0.0, 1.0)))

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.STACKED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION
	bar_config.category_width_fraction = 0.5
	bar_config.visual_callbacks = visual_callbacks

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

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot2.plot_xy(dataset, config, bindings)
	_state.append({})


func _step_test_2(delta: float) -> void:
	var dataset := _datasets[1]
	dataset.begin_batch()
	for b in range(dataset.get_shared_capacity()):
		dataset.set_series_y(dataset.get_series_id_by_index(0), b, _spectrum_1.values[b])
		dataset.set_series_y(dataset.get_series_id_by_index(1), b, _spectrum_2.values[b])
	dataset.end_batch()

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["A"])
	var x := PackedStringArray(["B1", "B2", "B3", "B4", "B5", "B6"])
	var y := PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y])
	_datasets.append(dataset)

	%TestPlot3.title = "[INDEPENDENT] Gradient sampled by y value"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.range_override_enabled = true
	left_axis.min_override = -Spectrum.BREATH
	left_axis.max_override = 1.0 # No upper bound in reality

	var visual_callbacks := TauPlot.BarVisualCallbacks.new()
	visual_callbacks.color_callback = Callable(func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> Color:
		return _gradient.sample(clampf(1.0 - y_value, 0.0, 1.0)))

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.visual_callbacks = visual_callbacks

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
	_state.append({})


func _step_test_3(delta: float) -> void:
	var dataset := _datasets[2]
	dataset.begin_batch()
	for b in range(dataset.get_shared_capacity()):
		dataset.set_series_y(dataset.get_series_id_by_index(0), b, _spectrum_1.values[b])
	dataset.end_batch()
