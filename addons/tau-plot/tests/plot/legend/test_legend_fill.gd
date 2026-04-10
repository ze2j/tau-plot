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
	#_setup_test_4()
	#_setup_test_5()
	#_setup_test_6()

func _on_tick() -> void:
	_t += _timer.wait_time

	#_step_test_1()
	_step_test_2()
	_step_test_3()
	#_step_test_4()
	#_step_test_5()
	#_step_test_6()

####################################################################################################
# Shared initial data
####################################################################################################

const X_INIT: PackedFloat64Array = [0.0, 1.0, 2.0, 3.0]
const Y_A_INIT: PackedFloat64Array = [1.0, 3.0, 2.0, 4.0]
const Y_B_INIT: PackedFloat64Array = [2.0, 1.5, 3.5, 1.0]
const Y_C_INIT: PackedFloat64Array = [0.5, 2.5, 1.0, 3.0]
const Y_D_INIT: PackedFloat64Array = [3.0, 0.5, 2.0, 1.5]

const CATS_INIT: PackedStringArray = ["Jan", "Feb", "Mar", "Apr"]

const CAPACITY := 64

const X_A: PackedFloat64Array= [
	 1.9, -1.4,  3.2,  0.7, -2.1,  2.6,
	-0.8,  1.3,  3.5, -0.2,  2.1, -1.9,
	 0.4,  2.9, -2.4,  1.6,  0.0,  3.6,
	-0.5,  2.3, -1.1,  1.1,  2.8, -1.7,
	 3.0, -2.0,  1.4, -0.3,  2.4,  0.9,
	-1.5,  3.3,  1.8, -2.2,  2.7,  0.2,
	 1.0, -0.7,  3.4, -1.2,  2.0,  0.5,
	-2.3,  1.7,  2.5, -0.1,  3.1, -1.6
]
const Y_A: PackedFloat64Array= [
	 2.2,  1.3,  1.7,  1.0,  0.9,  1.5,
	 1.8,  2.1,  1.4,  1.6,  1.9,  1.2,
	 1.4,  1.8,  1.1,  2.3,  1.7,  1.5,
	 1.3,  1.6,  1.0,  2.0,  1.4,  1.2,
	 1.9,  1.1,  2.2,  1.5,  1.7,  1.3,
	 1.0,  1.8,  2.0,  0.9,  1.6,  1.4,
	 2.1,  1.2,  1.5,  1.7,  2.3,  1.6,
	 1.0,  1.9,  1.4,  1.8,  2.0,  1.3
]

const X_B: PackedFloat64Array= [
	-2.7,  0.9, -1.8,  2.4, -3.1,  1.2,
	-0.4,  1.9, -2.2,  0.1,  2.7, -1.0,
	 0.6, -3.3,  1.5, -0.9,
	 2.1, -2.5,  0.4,  1.7, -1.3,  2.6,
	-0.2,  1.0, -2.9,  0.8,  2.3, -1.6,
	 1.3, -3.0,  0.0,  1.8
]
const Y_B: PackedFloat64Array= [
	 1.1,  2.4,  0.8,  1.3,  1.6,  0.5,
	 1.7,  1.9,  1.0,  1.5,  1.2,  1.4,
	 2.0,  1.8,  1.1,  1.6,
	 1.9,  0.9,  1.4,  2.1,  1.0,  1.3,
	 1.6,  2.2,  1.7,  1.2,  1.5,  0.8,
	 1.1,  1.4,  1.8,  2.0
]

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["Series A"])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [X_A], [Y_A])

	%TestPlot1.title = "One series"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR

	var scatter_config := TauScatterConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [scatter_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a]

	%TestPlot1.plot_xy(dataset, config, bindings)
	_state.append({})

####################################################################################################
# Test 2
####################################################################################################

const T2_APPEND_INTERVAL := 1.0
const T2_NEXT_X_START := 4.0

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["Price", "Volume"])
	var y_price := PackedFloat64Array([100.0, 105.0, 98.0, 112.0])
	var y_volume := PackedFloat64Array([5.0, 8.0, 3.0, 12.0])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, X_INIT, [y_price, y_volume], CAPACITY)
	_datasets.append(dataset)

	%TestPlot2.title = "Two series"

	var time_axis := TauAxisConfig.new()
	time_axis.title = "Time"
	time_axis.type = TauAxisConfig.Type.CONTINUOUS
	time_axis.scale = TauAxisConfig.Scale.LINEAR

	var price_axis := TauAxisConfig.new()
	price_axis.title = "Price"
	price_axis.type = TauAxisConfig.Type.CONTINUOUS
	price_axis.include_zero_in_domain = false

	var volume_axis := TauAxisConfig.new()
	volume_axis.title = "Volume"
	volume_axis.type = TauAxisConfig.Type.CONTINUOUS
	volume_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.6

	var pane_price := TauPaneConfig.new()
	pane_price.y_left_axis = price_axis
	pane_price.stretch_ratio = 3.0
	pane_price.overlays = [bar_config]

	var pane_vol := TauPaneConfig.new()
	pane_vol.y_left_axis = volume_axis
	pane_vol.stretch_ratio = 1.0
	pane_vol.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = time_axis
	config.panes = [pane_price, pane_vol]

	var sb_price := TauXYSeriesBinding.new()
	sb_price.series_id = dataset.get_series_id_by_index(0)
	sb_price.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_price.y_axis_id = TauPlot.AxisId.LEFT
	sb_price.pane_index = 0

	var sb_vol := TauXYSeriesBinding.new()
	sb_vol.series_id = dataset.get_series_id_by_index(1)
	sb_vol.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_vol.y_axis_id = TauPlot.AxisId.LEFT
	sb_vol.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_price, sb_vol]

	%TestPlot2.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"next_x": T2_NEXT_X_START,
		"last_append_t": 0.0,
	})


func _step_test_2() -> void:
	var st := _state[1]
	if _t - st["last_append_t"] < T2_APPEND_INTERVAL:
		return

	var dataset: TauPlot.Dataset = st["dataset"]
	var next_x: float = st["next_x"]

	var y_price_new := randf_range(90.0, 120.0)
	var y_volume_new := randf_range(1.0, 15.0)
	dataset.append_shared_sample(next_x, PackedFloat64Array([y_price_new, y_volume_new]))

	st["next_x"] = next_x + T2_APPEND_INTERVAL
	st["last_append_t"] = _t

####################################################################################################
# Test 3
####################################################################################################

const T3_APPEND_INTERVAL := 0.5
const T3_NEXT_X_START := 4.0

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["Top", "Mid", "Bot"])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, X_INIT, [Y_A_INIT, Y_B_INIT, Y_C_INIT], CAPACITY)
	_datasets.append(dataset)

	%TestPlot3.title = "Three series"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var left_t := TauAxisConfig.new()
	left_t.title = "Top"
	left_t.type = TauAxisConfig.Type.CONTINUOUS
	left_t.include_zero_in_domain = true

	var left_m := TauAxisConfig.new()
	left_m.title = "Middle"
	left_m.type = TauAxisConfig.Type.CONTINUOUS
	left_m.include_zero_in_domain = true

	var left_b := TauAxisConfig.new()
	left_b.title = "Bottom"
	left_b.type = TauAxisConfig.Type.CONTINUOUS
	left_b.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.6

	var pane_t := TauPaneConfig.new()
	pane_t.y_left_axis = left_t
	pane_t.stretch_ratio = 2.0
	pane_t.overlays = [bar_config]

	var pane_m := TauPaneConfig.new()
	pane_m.y_left_axis = left_m
	pane_m.stretch_ratio = 1.0
	pane_m.overlays = [bar_config]

	var pane_b := TauPaneConfig.new()
	pane_b.y_left_axis = left_b
	pane_b.stretch_ratio = 1.0
	pane_b.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_t, pane_m, pane_b]

	var sb_top := TauXYSeriesBinding.new()
	sb_top.series_id = dataset.get_series_id_by_index(0)
	sb_top.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_top.y_axis_id = TauPlot.AxisId.LEFT
	sb_top.pane_index = 0

	var sb_mid := TauXYSeriesBinding.new()
	sb_mid.series_id = dataset.get_series_id_by_index(1)
	sb_mid.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_mid.y_axis_id = TauPlot.AxisId.LEFT
	sb_mid.pane_index = 1

	var sb_bot := TauXYSeriesBinding.new()
	sb_bot.series_id = dataset.get_series_id_by_index(2)
	sb_bot.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_bot.y_axis_id = TauPlot.AxisId.LEFT
	sb_bot.pane_index = 2

	var bindings: Array[TauXYSeriesBinding] = [sb_bot, sb_mid, sb_top]

	%TestPlot3.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"next_x": T3_NEXT_X_START,
		"last_append_t": 0.0,
	})


func _step_test_3() -> void:
	var st := _state[2]
	if _t - st["last_append_t"] < T3_APPEND_INTERVAL:
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
