@tool
extends Control

const PERIOD := 8.0

var _timer: Timer = null
var _t: float = 0.0

var _datasets: Array[TauPlot.Dataset] = []

var _test_3_dataset: TauPlot.Dataset = null
var _test_3_char_count: int = 1
var _test_4_x_axis: TauAxisConfig = null
var _test_5_dataset: TauPlot.Dataset = null
var _test_5_char_count: int = 1
var _test_6_x_axis: TauAxisConfig = null

func _ready() -> void:
	_create_timer()
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	_setup_test_5()
	_setup_test_6()
	_timer.start()

func _create_timer() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = 0.016
	_timer.timeout.connect(_on_tick)
	add_child(_timer)

func _on_tick() -> void:
	_t += _timer.wait_time

	_step_test_3()
	_step_test_4()
	_step_test_5()
	_step_test_6()

####################################################################################################
# Helpers
####################################################################################################

func _compute_triangle(p_t: float, p_period: float) -> float:
	var phase := fmod(p_t, p_period) / p_period
	return 1.0 - abs(2.0 * phase - 1.0)


func _make_category(p_char_count: int) -> String:
	var s := ""
	for i in range(p_char_count):
		s += char(65 + (i % 26))
	return s


func _make_dataset(p_category_count: int, p_char_count: int) -> TauPlot.Dataset:
	var categories := PackedStringArray()
	var y := PackedFloat64Array()
	for i in range(p_category_count):
		categories.append(_make_category(p_char_count) + str(i))
		y.append(1.0 + sin(float(i) * 0.5))

	var series_names := PackedStringArray(["A"])
	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, categories, [y])
	_datasets.append(dataset)
	return dataset


func _make_plot(
		p_plot: TauPlot,
		p_title: String,
		p_dataset: TauPlot.Dataset,
		p_strategy: TauAxisConfig.OverlapStrategy,
		p_min_label_spacing: int) -> TauAxisConfig:
	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = p_strategy
	x_axis.min_label_spacing_px = p_min_label_spacing

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [TauBarConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = p_dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	p_plot.title = p_title
	p_plot.legend_enabled = false
	p_plot.plot_xy(p_dataset, config, bindings)

	return x_axis

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot(
		%TestPlot1,
		"[NONE] 10 categories of 12 chars => every label drawn, labels overlap freely",
		_make_dataset(10, 12),
		TauAxisConfig.OverlapStrategy.NONE,
		TauAxisConfig.new().min_label_spacing_px)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot(
		%TestPlot2,
		"[SKIP_LABELS] 10 categories of 12 chars => bars unchanged, some labels dropped, last one kept",
		_make_dataset(10, 12),
		TauAxisConfig.OverlapStrategy.SKIP_LABELS,
		TauAxisConfig.new().min_label_spacing_px)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_test_3_dataset = _make_dataset(10, 1)
	_make_plot(
		%TestPlot3,
		"[SKIP_LABELS] 10 categories, char count animated in [1, 64] over 8 s => labels grow and get dropped",
		_test_3_dataset,
		TauAxisConfig.OverlapStrategy.SKIP_LABELS,
		TauAxisConfig.new().min_label_spacing_px)

func _step_test_3() -> void:
	var char_count := 1 + int(_compute_triangle(_t, PERIOD) * 63.0)
	if char_count == _test_3_char_count:
		return
	_test_3_char_count = char_count

	_test_3_dataset.begin_batch()
	for i in range(10):
		_test_3_dataset.set_shared_x(i, _make_category(char_count) + str(i))
	_test_3_dataset.end_batch()

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_test_4_x_axis = _make_plot(
		%TestPlot4,
		"[SKIP_LABELS] 10 categories of 6 chars, spacing animated in [0, 500] over 8 s => labels disappear progressively",
		_make_dataset(10, 6),
		TauAxisConfig.OverlapStrategy.SKIP_LABELS,
		0)

func _step_test_4() -> void:
	_test_4_x_axis.min_label_spacing_px = int(_compute_triangle(_t, PERIOD) * 500.0)
	%TestPlot4.refresh_now()

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	_test_5_dataset = _make_dataset(1, 1)
	_make_plot(
		%TestPlot5,
		"[SKIP_LABELS] 1 category, char count animated in [1, 100] over 8 s => the label is always drawn",
		_test_5_dataset,
		TauAxisConfig.OverlapStrategy.SKIP_LABELS,
		TauAxisConfig.new().min_label_spacing_px)

func _step_test_5() -> void:
	var char_count := 1 + int(_compute_triangle(_t, PERIOD) * 99.0)
	if char_count == _test_5_char_count:
		return
	_test_5_char_count = char_count

	_test_5_dataset.set_shared_x(0, _make_category(char_count) + "0")

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	_test_6_x_axis = _make_plot(
		%TestPlot6,
		"[SKIP_LABELS] 1 category, spacing animated in [500, 1500] over 8 s => the label is always drawn",
		_make_dataset(1, 1),
		TauAxisConfig.OverlapStrategy.SKIP_LABELS,
		500)

func _step_test_6() -> void:
	_test_6_x_axis.min_label_spacing_px = 500 + int(_compute_triangle(_t, PERIOD) * 1000.0)
	%TestPlot6.refresh_now()
