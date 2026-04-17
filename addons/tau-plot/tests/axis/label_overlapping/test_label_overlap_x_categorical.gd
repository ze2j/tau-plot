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

const PERIOD := 4.0

func _triangle(p_t: float, p_period: float) -> float:
	var phase := fmod(p_t, p_period) / p_period
	return 1.0 - abs(2.0 * phase - 1.0)

func _make_category(p_char_count: int) -> String:
	var s := ""
	for i in range(p_char_count):
		s += char(65 + (i % 26))
	return s

func _make_categories(p_count: int, p_char_count: int) -> PackedStringArray:
	var cats := PackedStringArray()
	for i in range(p_count):
		cats.append(_make_category(p_char_count) + str(i))
	return cats

func _make_y(p_count: int) -> PackedFloat64Array:
	var y := PackedFloat64Array()
	for i in range(p_count):
		y.append(1.0 + sin(float(i) * 0.5))
	return y

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var nb_categories := 10
	var categories := _make_categories(nb_categories, 12)
	var y := _make_y(nb_categories)

	var series_names := PackedStringArray(["A"])
	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, categories, [y])
	_datasets.append(dataset)

	%TestPlot1.title = "[NONE] 12 chars categories => labels overlap freely"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE

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
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot1.legend_enabled = false
	%TestPlot1.plot_xy(dataset, config, bindings)

	_state.append({})

func _step_test_1() -> void:
	pass

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var nb_categories := 10
	var categories := _make_categories(nb_categories, 12)
	var y := _make_y(nb_categories)

	var series_names := PackedStringArray(["A"])
	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, categories, [y])
	_datasets.append(dataset)

	%TestPlot2.title = "[SKIP_LABELS] 12 chars categories => some labels hidden"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

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
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot2.legend_enabled = false
	%TestPlot2.plot_xy(dataset, config, bindings)

	_state.append({})

func _step_test_2() -> void:
	pass

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var nb_categories := 10
	var categories := _make_categories(nb_categories, 1)
	var y := _make_y(nb_categories)

	var series_names := PackedStringArray(["A"])
	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, categories, [y])
	_datasets.append(dataset)

	%TestPlot3.title = "[SKIP_LABELS] Animate category char count [1, 12] => labels grow and get skipped"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

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
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot3.legend_enabled = false
	%TestPlot3.plot_xy(dataset, config, bindings)

	_state.append(
		{
			"dataset": dataset,
			"nb_categories": nb_categories,
			"prev_char_count": 1
		}
	)

func _step_test_3() -> void:
	var st := _state[2]
	var dataset: TauPlot.Dataset = st["dataset"]
	var nb_categories: int = st["nb_categories"]

	var char_count := 1 + int(_triangle(_t, PERIOD) * 11.0)
	if char_count == st["prev_char_count"]:
		return
	st["prev_char_count"] = char_count

	dataset.begin_batch()
	for i in range(nb_categories):
		dataset.set_shared_x(i, _make_category(char_count) + str(i))
	dataset.end_batch()

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	var nb_categories := 10
	var categories := _make_categories(nb_categories, 6)
	var y := _make_y(nb_categories)

	var series_names := PackedStringArray(["A"])
	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, categories, [y])
	_datasets.append(dataset)

	%TestPlot4.title = "[SKIP_LABELS] Animate min_x_label_spacing_px [0, 100] => labels disappear progressively"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS
	x_axis.min_label_spacing_px = 0

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
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot4.legend_enabled = false
	%TestPlot4.plot_xy(dataset, config, bindings)

	_state.append(
		{
			"plot": %TestPlot4,
			"x_axis": x_axis
		}
	)

func _step_test_4() -> void:
	var st := _state[3]
	var plot: Control = st["plot"]
	var x_axis: TauAxisConfig = st["x_axis"]

	x_axis.min_label_spacing_px = int(_triangle(_t, PERIOD) * 100.0)
	plot.refresh_now()

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	var categories := PackedStringArray(["A"])
	var y := PackedFloat64Array([3.0])

	var series_names := PackedStringArray(["A"])
	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, categories, [y])
	_datasets.append(dataset)

	%TestPlot5.title = "[SKIP_LABELS] 1 category, animate char count [1, 100] => label always shown"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

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
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot5.legend_enabled = false
	%TestPlot5.plot_xy(dataset, config, bindings)

	_state.append(
		{
			"dataset": dataset,
			"prev_char_count": 1
		}
	)

func _step_test_5() -> void:
	var st := _state[4]
	var dataset: TauPlot.Dataset = st["dataset"]

	var char_count := 1 + int(_triangle(_t, PERIOD) * 99.0)
	if char_count == st["prev_char_count"]:
		return
	st["prev_char_count"] = char_count

	dataset.set_shared_x(0, _make_category(char_count))

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	var categories := PackedStringArray(["A"])
	var y := PackedFloat64Array([3.0])

	var series_names := PackedStringArray(["A"])
	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, categories, [y])
	_datasets.append(dataset)

	%TestPlot6.title = "[SKIP_LABELS] 1 category, animate min_x_label_spacing_px [500, 1500] => label always shown"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS
	x_axis.min_label_spacing_px = 500

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
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	%TestPlot6.legend_enabled = false
	%TestPlot6.plot_xy(dataset, config, bindings)

	_state.append(
		{
			"plot": %TestPlot6,
			"x_axis": x_axis
		}
	)

func _step_test_6() -> void:
	var st := _state[5]
	var plot: Control = st["plot"]
	var x_axis: TauAxisConfig = st["x_axis"]

	x_axis.min_label_spacing_px = 500 + int(_triangle(_t, PERIOD) * 1000.0)
	plot.refresh_now()
