@tool
extends Control

class Spectrum extends RefCounted:

	const ATTACK_HZ: float = 18.0
	const RELEASE_HZ: float = 6.0
	const ENERGY_DECAY_HZ: float = 10.0
	const HIT_RATE: float = 5.5
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

var _spectrum: Spectrum = null
var _spectrum_2: Spectrum = null

var _gradient: Gradient = null

func _ready() -> void:
	_t = 0.0
	_datasets.clear()
	_state.clear()
	_spectrum = Spectrum.new(10)

	_gradient = Gradient.new()
	_gradient.offsets = PackedFloat32Array([
		0.0,
		0.25,
		0.5,
		0.75,
		1.0
	])
	_gradient.colors = PackedColorArray([
		Color("bd0034ff"),
		Color("cc4219ff"),
		Color("c97010ff"),
		Color("b4aa00ff"),
		Color("439800ff"),
	])

	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	_setup_test_5()


func _process(delta: float) -> void:
	_t += delta

	_spectrum.step(delta)

	_step_test_1(delta)
	_step_test_2(delta)
	_step_test_3(delta)
	_step_test_4(delta)
	_step_test_5(delta)

####################################################################################################
# Helpers
####################################################################################################

func make_shared_x_continuous_plot(p_plot: TauPlot, p_title: String, p_interpolation: TauLineConfig.InterpolationMode) -> void:
	var series_names := PackedStringArray(["Series A"])
	var x := PackedFloat64Array([10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0])
	var y_a := PackedFloat64Array([10.0, 20.0, 50.0, 65.0, 70.0, 75.0, 60.0, 45.0, 25.0, 0.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a])
	_datasets.append(dataset)

	p_plot.title = p_title
	p_plot.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 10

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.tick_count_preferred = 10
	y_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE
	y_axis.range_override_enabled = true
	y_axis.min_override = -Spectrum.BREATH
	y_axis.max_override = 1.0

	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT
	line_config.interpolation_modes = [p_interpolation]
	line_config.style.dash_lengths_px = [8]
	var visual_callbacks := TauPlot.LineVisualCallbacks.new()
	visual_callbacks.color_callback = Callable(func(series_index: int, sample_index: int, x_value: Variant, y_value: float) -> Color:
		return _gradient.sample(clampf(1.0 - y_value, 0.0, 1.0))
	)
	line_config.visual_callbacks = visual_callbacks

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

	var bindings: Array[TauXYSeriesBinding] = [sb_a]

	p_plot.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	make_shared_x_continuous_plot(%TestPlot1, "[LINEAR]", TauLineConfig.InterpolationMode.LINEAR)


func _step_test_1(delta: float) -> void:
	var dataset := _datasets[0]
	dataset.begin_batch()
	for b in range(dataset.get_shared_capacity()):
		dataset.set_series_y(dataset.get_series_id_by_index(0), b, _spectrum.values[b])
	dataset.end_batch()

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	make_shared_x_continuous_plot(%TestPlot2, "[STEP_BEFORE]", TauLineConfig.InterpolationMode.STEP_BEFORE)


func _step_test_2(delta: float) -> void:
	var dataset := _datasets[1]
	dataset.begin_batch()
	for b in range(dataset.get_shared_capacity()):
		dataset.set_series_y(dataset.get_series_id_by_index(0), b, _spectrum.values[b])
	dataset.end_batch()

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	make_shared_x_continuous_plot(%TestPlot3, "[STEP_MIDDLE]", TauLineConfig.InterpolationMode.STEP_MIDDLE)


func _step_test_3(delta: float) -> void:
	var dataset := _datasets[2]
	dataset.begin_batch()
	for b in range(dataset.get_shared_capacity()):
		dataset.set_series_y(dataset.get_series_id_by_index(0), b, _spectrum.values[b])
	dataset.end_batch()

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	make_shared_x_continuous_plot(%TestPlot4, "[STEP_AFTER]", TauLineConfig.InterpolationMode.STEP_AFTER)


func _step_test_4(delta: float) -> void:
	var dataset := _datasets[3]
	dataset.begin_batch()
	for b in range(dataset.get_shared_capacity()):
		dataset.set_series_y(dataset.get_series_id_by_index(0), b, _spectrum.values[b])
	dataset.end_batch()

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	make_shared_x_continuous_plot(%TestPlot5, "[SMOOTH_MONOTONE]", TauLineConfig.InterpolationMode.SMOOTH_MONOTONE)


func _step_test_5(delta: float) -> void:
	var dataset := _datasets[4]
	dataset.begin_batch()
	for b in range(dataset.get_shared_capacity()):
		dataset.set_series_y(dataset.get_series_id_by_index(0), b, _spectrum.values[b])
	dataset.end_batch()
