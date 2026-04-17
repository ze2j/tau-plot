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
# Shared initial data
####################################################################################################

const X_4: PackedFloat64Array = [0.0, 1.0, 2.0, 3.0]
const X_6: PackedFloat64Array = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
const Y_A_INIT: PackedFloat64Array = [1.0, 3.0, 2.0, 4.0, 1.5, 3.5]
const Y_B_INIT: PackedFloat64Array = [2.0, 1.5, 3.5, 1.0, 4.0, 2.5]
const Y_C_INIT: PackedFloat64Array = [0.5, 2.5, 1.0, 3.0, 2.0, 1.0]
const Y_D_INIT: PackedFloat64Array = [3.0, 0.5, 2.0, 1.5, 1.0, 1.5]

const SAMPLE_COUNT := 6

const CATS_INIT: PackedStringArray = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]

const CAPACITY := 64

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [X_6, X_6], [Y_A_INIT, Y_B_INIT])
	_datasets.append(dataset)

	%TestPlot1.title = "[PER_SERIES_X] Update both series Y values, invert y axes"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X axis"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = SAMPLE_COUNT

	var bottom_a := TauAxisConfig.new()
	bottom_a.title = "A Y values"
	bottom_a.type = TauAxisConfig.Type.CONTINUOUS
	bottom_a.include_zero_in_domain = true
	bottom_a.inverted = true

	var bottom_b := TauAxisConfig.new()
	bottom_b.title = "B Y values"
	bottom_b.type = TauAxisConfig.Type.CONTINUOUS
	bottom_b.include_zero_in_domain = true
	bottom_b.inverted = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.6

	var pane_a := TauPaneConfig.new()
	pane_a.y_bottom_axis = bottom_a
	pane_a.overlays = [bar_config]

	var pane_b := TauPaneConfig.new()
	pane_b.y_bottom_axis = bottom_b
	pane_b.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.RIGHT
	config.panes = [pane_a, pane_b]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.BOTTOM
	sb_a.pane_index = 0

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.BOTTOM
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
	var series_id_b = dataset.get_series_id_by_index(1)

	dataset.begin_batch()
	for i in range(SAMPLE_COUNT):
		var base: float = Y_A_INIT[i]
		var y_new_a := base + 2.0 * sin(_t * 1.5 + float(i) * 0.85)
		var y_new_b := base + 2.0 * sin(_t * 1.3 + float(i) * 0.75)
		dataset.set_series_y(series_id_a, i, y_new_a)
		dataset.set_series_y(series_id_b, i, y_new_b)
	dataset.end_batch()

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["A"])
	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [X_6], [Y_A_INIT])
	_datasets.append(dataset)

	%TestPlot2.title = "[PER_SERIES_X] Single series, two panes, invert y axes"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X axis"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = SAMPLE_COUNT

	var bar_axis := TauAxisConfig.new()
	bar_axis.title = "BAR"
	bar_axis.type = TauAxisConfig.Type.CONTINUOUS
	bar_axis.include_zero_in_domain = true
	bar_axis.inverted = true

	var scatter_axis := TauAxisConfig.new()
	scatter_axis.title = "SCATTER"
	scatter_axis.type = TauAxisConfig.Type.CONTINUOUS
	scatter_axis.include_zero_in_domain = true
	scatter_axis.inverted = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.6

	var scatter_config := TauScatterConfig.new()
	scatter_config.marker_size_policy = TauScatterConfig.MarkerSizePolicy.DATA_UNITS
	scatter_config.marker_size_data_units = 0.6

	var pane_l := TauPaneConfig.new()
	pane_l.y_bottom_axis = bar_axis
	pane_l.overlays = [bar_config]

	var pane_r := TauPaneConfig.new()
	pane_r.y_bottom_axis = scatter_axis
	pane_r.overlays = [scatter_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.RIGHT
	config.panes = [pane_l, pane_r]

	var sb_l := TauXYSeriesBinding.new()
	sb_l.series_id = dataset.get_series_id_by_index(0)
	sb_l.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_l.y_axis_id = TauPlot.AxisId.BOTTOM
	sb_l.pane_index = 0

	var sb_r := TauXYSeriesBinding.new()
	sb_r.series_id = dataset.get_series_id_by_index(0)
	sb_r.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_r.y_axis_id = TauPlot.AxisId.BOTTOM
	sb_r.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_l, sb_r]

	%TestPlot2.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset
	})


func _step_test_2() -> void:
	var st := _state[1]
	var dataset: TauPlot.Dataset = st["dataset"]
	var series_id_a = dataset.get_series_id_by_index(0)

	dataset.begin_batch()
	for i in range(SAMPLE_COUNT):
		var base: float = Y_A_INIT[i]
		var y_new_a := base + 2.0 * sin(_t * 1.5 + float(i) * 0.85)
		dataset.set_series_y(series_id_a, i, y_new_a)
	dataset.end_batch()


####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [X_6, X_6], [Y_A_INIT, Y_B_INIT])
	_datasets.append(dataset)

	%TestPlot3.title = "[PER_SERIES_X] Update both series Y values, invert y axes"

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X axis"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = SAMPLE_COUNT

	var bottom_a := TauAxisConfig.new()
	bottom_a.title = "A Y values"
	bottom_a.type = TauAxisConfig.Type.CONTINUOUS
	bottom_a.include_zero_in_domain = true
	bottom_a.inverted = true

	var bottom_b := TauAxisConfig.new()
	bottom_b.title = "B Y values"
	bottom_b.type = TauAxisConfig.Type.CONTINUOUS
	bottom_b.include_zero_in_domain = true
	bottom_b.inverted = true

	var scatter_config := TauScatterConfig.new()
	scatter_config.marker_size_policy = TauScatterConfig.MarkerSizePolicy.DATA_UNITS
	scatter_config.marker_size_data_units = 0.6

	var pane_a := TauPaneConfig.new()
	pane_a.y_bottom_axis = bottom_a
	pane_a.overlays = [scatter_config]

	var pane_b := TauPaneConfig.new()
	pane_b.y_bottom_axis = bottom_b
	pane_b.overlays = [scatter_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.RIGHT
	config.panes = [pane_a, pane_b]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.BOTTOM
	sb_a.pane_index = 0

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.BOTTOM
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
		var base: float = Y_A_INIT[i]
		var y_new_a := base + 2.0 * sin(_t * 1.5 + float(i) * 0.85)
		var y_new_b := base + 2.0 * sin(_t * 1.3 + float(i) * 0.75)
		dataset.set_series_y(series_id_a, i, y_new_a)
		dataset.set_series_y(series_id_b, i, y_new_b)
	dataset.end_batch()


####################################################################################################
# Test 4
####################################################################################################

const T4_APPEND_INTERVAL := 1.0
const T4_NEXT_X_START := 4.0

func _setup_test_4() -> void:
	var series_names := PackedStringArray(["Volume", "Price"])
	var y_volume := PackedFloat64Array([5.0, 8.0, 3.0, 12.0, 9.0, 10.0])
	var y_price := PackedFloat64Array([100.0, 105.0, 98.0, 112.0, 101.0, 103.0])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, X_6, [y_volume, y_price], CAPACITY)
	_datasets.append(dataset)

	%TestPlot4.title = "[SHARED_X] Append Price + Volume (3:1 stretch ratio), invert y axes"

	var time_axis := TauAxisConfig.new()
	time_axis.title = "Time"
	time_axis.type = TauAxisConfig.Type.CONTINUOUS
	time_axis.scale = TauAxisConfig.Scale.LINEAR

	var price_axis := TauAxisConfig.new()
	price_axis.title = "Price"
	price_axis.type = TauAxisConfig.Type.CONTINUOUS
	price_axis.include_zero_in_domain = false
	price_axis.inverted = true

	var volume_axis := TauAxisConfig.new()
	volume_axis.title = "Volume"
	volume_axis.type = TauAxisConfig.Type.CONTINUOUS
	volume_axis.include_zero_in_domain = true
	volume_axis.inverted = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.6

	var pane_price := TauPaneConfig.new()
	pane_price.y_bottom_axis = price_axis
	pane_price.stretch_ratio = 3.0
	pane_price.overlays = [bar_config]

	var pane_vol := TauPaneConfig.new()
	pane_vol.y_bottom_axis = volume_axis
	pane_vol.stretch_ratio = 1.0
	pane_vol.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = time_axis
	config.x_axis_id = TauPlot.AxisId.RIGHT
	config.panes = [pane_vol, pane_price]

	var sb_price := TauXYSeriesBinding.new()
	sb_price.series_id = dataset.get_series_id_by_index(0)
	sb_price.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_price.y_axis_id = TauPlot.AxisId.BOTTOM
	sb_price.pane_index = 0

	var sb_vol := TauXYSeriesBinding.new()
	sb_vol.series_id = dataset.get_series_id_by_index(1)
	sb_vol.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_vol.y_axis_id = TauPlot.AxisId.BOTTOM
	sb_vol.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_price, sb_vol]

	%TestPlot4.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"next_x": T4_NEXT_X_START,
		"last_append_t": 0.0,
	})


func _step_test_4() -> void:
	var st := _state[3]
	if _t - st["last_append_t"] < T4_APPEND_INTERVAL:
		return

	var dataset: TauPlot.Dataset = st["dataset"]
	var next_x: float = st["next_x"]

	var y_volume_new := randf_range(1.0, 15.0)
	var y_price_new := randf_range(90.0, 120.0)
	dataset.append_shared_sample(next_x, PackedFloat64Array([y_volume_new, y_price_new]))

	st["next_x"] = next_x + T4_APPEND_INTERVAL
	st["last_append_t"] = _t

####################################################################################################
# Test 5
####################################################################################################

const T5_APPEND_INTERVAL := 0.5
const T5_NEXT_X_START := 4.0

func _setup_test_5() -> void:
	var series_names := PackedStringArray(["Left", "Middle", "Right"])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, X_6, [Y_A_INIT, Y_B_INIT, Y_C_INIT], CAPACITY)
	_datasets.append(dataset)

	%TestPlot5.title = "[SHARED_X] Append to 3 panes (2:1:1 stretch ratio), invert y axes"

	var time_axis := TauAxisConfig.new()
	time_axis.type = TauAxisConfig.Type.CONTINUOUS
	time_axis.scale = TauAxisConfig.Scale.LINEAR
	time_axis.title = "Time"

	var y_l := TauAxisConfig.new()
	y_l.title = "Left"
	y_l.type = TauAxisConfig.Type.CONTINUOUS
	y_l.include_zero_in_domain = true
	y_l.inverted = true

	var y_m := TauAxisConfig.new()
	y_m.title = "Middle"
	y_m.type = TauAxisConfig.Type.CONTINUOUS
	y_m.include_zero_in_domain = true
	y_m.inverted = true

	var y_r := TauAxisConfig.new()
	y_r.title = "Right"
	y_r.type = TauAxisConfig.Type.CONTINUOUS
	y_r.include_zero_in_domain = true
	y_r.inverted = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.6

	var pane_l := TauPaneConfig.new()
	pane_l.y_bottom_axis = y_l
	pane_l.stretch_ratio = 2.0
	pane_l.overlays = [bar_config]

	var pane_m := TauPaneConfig.new()
	pane_m.y_bottom_axis = y_m
	pane_m.stretch_ratio = 1.0
	pane_m.overlays = [bar_config]

	var pane_r := TauPaneConfig.new()
	pane_r.y_bottom_axis = y_r
	pane_r.stretch_ratio = 1.0
	pane_r.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = time_axis
	config.x_axis_id = TauPlot.AxisId.RIGHT
	config.panes = [pane_l, pane_m, pane_r]

	var sb_left := TauXYSeriesBinding.new()
	sb_left.series_id = dataset.get_series_id_by_index(0)
	sb_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_left.y_axis_id = TauPlot.AxisId.BOTTOM
	sb_left.pane_index = 0

	var sb_mid := TauXYSeriesBinding.new()
	sb_mid.series_id = dataset.get_series_id_by_index(1)
	sb_mid.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_mid.y_axis_id = TauPlot.AxisId.BOTTOM
	sb_mid.pane_index = 1

	var sb_right := TauXYSeriesBinding.new()
	sb_right.series_id = dataset.get_series_id_by_index(2)
	sb_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_right.y_axis_id = TauPlot.AxisId.BOTTOM
	sb_right.pane_index = 2

	var bindings: Array[TauXYSeriesBinding] = [sb_left, sb_mid, sb_right]

	%TestPlot5.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"next_x": T5_NEXT_X_START,
		"last_append_t": 0.0,
	})


func _step_test_5() -> void:
	var st := _state[4]
	if _t - st["last_append_t"] < T5_APPEND_INTERVAL:
		return

	var dataset: TauPlot.Dataset = st["dataset"]
	var next_x: float = st["next_x"]

	var y_t_new := randf_range(1.0, 5.0)
	var y_m_new := randf_range(1.0, 5.0)
	var y_b_new := randf_range(1.0, 5.0)
	dataset.append_shared_sample(next_x, PackedFloat64Array([y_t_new, y_m_new, y_b_new]))

	st["next_x"] = next_x + 1.0
	st["last_append_t"] = _t

####################################################################################################
# Test 6
####################################################################################################

const T6_APPEND_INTERVAL := 0.8
const T6_CAT_NAMES: PackedStringArray = ["Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

func _setup_test_6() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, CATS_INIT, [Y_A_INIT, Y_B_INIT], 12)
	_datasets.append(dataset)

	%TestPlot6.title = "[SHARED_X] Append new categories, invert y axes"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var y_l := TauAxisConfig.new()
	y_l.title = "Left"
	y_l.type = TauAxisConfig.Type.CONTINUOUS
	y_l.include_zero_in_domain = true
	y_l.inverted = true

	var y_r := TauAxisConfig.new()
	y_r.title = "Right"
	y_r.type = TauAxisConfig.Type.CONTINUOUS
	y_r.include_zero_in_domain = true
	y_r.inverted = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT

	var pane_t := TauPaneConfig.new()
	pane_t.y_bottom_axis = y_l
	pane_t.overlays = [bar_config]

	var pane_b := TauPaneConfig.new()
	pane_b.y_bottom_axis = y_r
	pane_b.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = TauPlot.AxisId.RIGHT
	config.panes = [pane_t, pane_b]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.BOTTOM
	sb_a.pane_index = 0

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.BOTTOM
	sb_b.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot6.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"cat_index": 0,
		"last_append_t": 0.0,
	})


func _step_test_6() -> void:
	var st := _state[5]
	if _t - st["last_append_t"] < T6_APPEND_INTERVAL:
		return

	var cat_index: int = st["cat_index"]
	var dataset: TauPlot.Dataset = st["dataset"]

	# When all extra categories have been appended, clear and restart from initial data
	if cat_index >= T6_CAT_NAMES.size():
		dataset.begin_batch()
		dataset.clear_samples()
		for i in range(CATS_INIT.size()):
			dataset.append_shared_sample(CATS_INIT[i], PackedFloat64Array([Y_A_INIT[i], Y_B_INIT[i]]))
		dataset.end_batch()
		st["cat_index"] = 0
		st["last_append_t"] = _t
		return

	var cat_name: String = T6_CAT_NAMES[cat_index]

	var y_a_new := randf_range(1.0, 5.0)
	var y_b_new := randf_range(1.0, 5.0)
	dataset.append_shared_sample(cat_name, PackedFloat64Array([y_a_new, y_b_new]))

	st["cat_index"] = cat_index + 1
	st["last_append_t"] = _t
