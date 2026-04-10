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
	_setup_test_8()
	_setup_test_9()
	_setup_test_10()
	_setup_test_11()
	_setup_test_12()

func _on_tick() -> void:
	_t += _timer.wait_time

	_step_test_1()
	_step_test_2()
	_step_test_3()
	_step_test_4()
	_step_test_5()
	_step_test_6()
	_step_test_7()
	_step_test_8()
	_step_test_9()
	_step_test_10()
	_step_test_11()
	_step_test_12()

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

####################################################################################################
# Helpers
####################################################################################################

const APPEND_INTERVAL := 0.5
const NEXT_X_START := 4.0

func _make_plot(p_plot: TauPlot, p_title: String, p_legend_position: TauLegendConfig.Position) -> void:
	#var series_names := PackedStringArray(["Top series", "Middle series", "Bottom series"])
	var series_names := PackedStringArray(["A", "B", "C"])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, X_INIT, [Y_A_INIT, Y_B_INIT, Y_C_INIT], CAPACITY)
	_datasets.append(dataset)

	var legend_config := TauLegendConfig.new()
	legend_config.position = p_legend_position

	p_plot.title = p_title
	p_plot.legend_config = legend_config

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

	p_plot.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"next_x": NEXT_X_START,
		"last_append_t": 0.0,
	})


func _update_plot(p_state_index: int) -> void:
	var st := _state[p_state_index]
	if _t - st["last_append_t"] < APPEND_INTERVAL:
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
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot(%TestPlot1, "OUTSIDE_TOP", TauLegendConfig.Position.OUTSIDE_TOP)


func _step_test_1() -> void:
	_update_plot(0)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot(%TestPlot2, "OUTSIDE_RIGHT", TauLegendConfig.Position.OUTSIDE_RIGHT)


func _step_test_2() -> void:
	_update_plot(1)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_make_plot(%TestPlot3, "OUTSIDE_BOTTOM", TauLegendConfig.Position.OUTSIDE_BOTTOM)


func _step_test_3() -> void:
	_update_plot(2)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_make_plot(%TestPlot4, "OUTSIDE_LEFT", TauLegendConfig.Position.OUTSIDE_LEFT)


func _step_test_4() -> void:
	_update_plot(3)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	_make_plot(%TestPlot5, "INSIDE_TOP", TauLegendConfig.Position.INSIDE_TOP)


func _step_test_5() -> void:
	_update_plot(4)

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	_make_plot(%TestPlot6, "INSIDE_RIGHT", TauLegendConfig.Position.INSIDE_RIGHT)


func _step_test_6() -> void:
	_update_plot(5)

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	_make_plot(%TestPlot7, "INSIDE_BOTTOM", TauLegendConfig.Position.INSIDE_BOTTOM)


func _step_test_7() -> void:
	_update_plot(6)


####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8() -> void:
	_make_plot(%TestPlot8, "INSIDE_LEFT", TauLegendConfig.Position.INSIDE_LEFT)


func _step_test_8() -> void:
	_update_plot(7)


####################################################################################################
# Test 9
####################################################################################################

func _setup_test_9() -> void:
	_make_plot(%TestPlot9, "INSIDE_TOP_RIGHT", TauLegendConfig.Position.INSIDE_TOP_RIGHT)


func _step_test_9() -> void:
	_update_plot(8)

####################################################################################################
# Test 10
####################################################################################################

func _setup_test_10() -> void:
	_make_plot(%TestPlot10, "INSIDE_BOTTOM_RIGHT", TauLegendConfig.Position.INSIDE_BOTTOM_RIGHT)


func _step_test_10() -> void:
	_update_plot(9)


####################################################################################################
# Test 11
####################################################################################################

func _setup_test_11() -> void:
	_make_plot(%TestPlot11, "INSIDE_BOTTOM_LEFT", TauLegendConfig.Position.INSIDE_BOTTOM_LEFT)


func _step_test_11() -> void:
	_update_plot(10)

####################################################################################################
# Test 12
####################################################################################################

func _setup_test_12() -> void:
	_make_plot(%TestPlot12, "INSIDE_TOP_LEFT", TauLegendConfig.Position.INSIDE_TOP_LEFT)


func _step_test_12() -> void:
	_update_plot(11)
