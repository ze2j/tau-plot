@tool
extends Control

var _timer: Timer = null
var _t: float = 0.0

var _datasets: Array[TauPlot.Dataset] = []
var _state: Array[Dictionary] = []
var _slots: Array[_PlotSlot] = []

var _last_fit_report: String = ""


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
	_slots.clear()

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

	_report_fit()

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

# Smallest share of its slot
# Not zero as the title claims a minimum height of its own.
const SPAN_MIN := Vector2(0.20, 0.20)

# In seconds
const SPAN_PERIOD := Vector2(5.0, 7.0)


class _PlotSlot extends Control:

	const _SLOT_COLOR := Color(0.10, 0.10, 0.13)
	const _GIVEN_COLOR := Color(0.30, 0.85, 0.40)
	const _TAKEN_COLOR := Color(0.95, 0.20, 0.20)

	var plot: TauPlot = null

	var _given := Rect2()


	func _init() -> void:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL


	func own(p_plot: TauPlot) -> void:
		plot = p_plot
		add_child(plot)
		plot.set_anchors_preset(Control.PRESET_TOP_LEFT)
		plot.grow_horizontal = Control.GROW_DIRECTION_END
		plot.grow_vertical = Control.GROW_DIRECTION_END


	func set_span(p_span: Vector2) -> void:
		var given_size := (size * p_span).round()
		_given = Rect2(((size - given_size) * 0.5).round(), given_size)
		plot.position = _given.position
		plot.size = _given.size
		queue_redraw()


	func fits() -> bool:
		return plot.size.x <= _given.size.x + 0.5 and plot.size.y <= _given.size.y + 0.5


	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), _SLOT_COLOR)
		draw_rect(_given, _GIVEN_COLOR, false, 1.0)
		if not fits():
			draw_rect(Rect2(plot.position, plot.size), _TAKEN_COLOR, false, 2.0)



func _make_plot(p_title: String, p_legend_position: TauLegendConfig.Position) -> void:
	var series_names := PackedStringArray(["One very long series name", "A shorter one", "SN"])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, X_INIT, [Y_A_INIT, Y_B_INIT, Y_C_INIT], CAPACITY)
	_datasets.append(dataset)

	var plot := TauPlot.new()
	var slot := _PlotSlot.new()
	%Grid.add_child(slot)
	slot.own(plot)
	_slots.append(slot)

	var legend_config := TauLegendConfig.new()
	legend_config.position = p_legend_position

	var legend_background := StyleBoxFlat.new()
	legend_background.bg_color = Color(0.3, 0.3, 0.3)
	legend_background.corner_radius_bottom_left = 12
	legend_background.corner_radius_bottom_right = 12
	legend_background.corner_radius_top_left = 12
	legend_background.corner_radius_top_right = 12
	legend_background.content_margin_bottom = 4
	legend_background.content_margin_left = 4
	legend_background.content_margin_right = 4
	legend_background.content_margin_top = 4
	legend_config.style.background = legend_background

	plot.title = p_title
	plot.legend_config = legend_config

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var y_left_axis_t := TauAxisConfig.new()
	y_left_axis_t.title = "Top"
	y_left_axis_t.type = TauAxisConfig.Type.CONTINUOUS
	y_left_axis_t.include_zero_in_domain = true

	var y_left_axis_m := TauAxisConfig.new()
	y_left_axis_m.title = "Middle"
	y_left_axis_m.type = TauAxisConfig.Type.CONTINUOUS
	y_left_axis_m.include_zero_in_domain = true

	var y_left_axis_b := TauAxisConfig.new()
	y_left_axis_b.title = "Bottom"
	y_left_axis_b.type = TauAxisConfig.Type.CONTINUOUS
	y_left_axis_b.include_zero_in_domain = true

	var scatter_config := TauScatterConfig.new()
	scatter_config.style.marker_shapes = [TauScatterStyle.MarkerShape.SQUARE]

	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT
	line_config.interpolation_modes = [TauLineConfig.InterpolationMode.LINEAR]

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = 0.6

	var pane_t := TauPaneConfig.new()
	pane_t.y_left_axis = y_left_axis_t
	pane_t.stretch_ratio = 1.0
	pane_t.overlays = [scatter_config]

	var pane_m := TauPaneConfig.new()
	pane_m.y_left_axis = y_left_axis_m
	pane_m.stretch_ratio = 1.0
	pane_m.overlays = [line_config]

	var pane_b := TauPaneConfig.new()
	pane_b.y_left_axis = y_left_axis_b
	pane_b.stretch_ratio = 1.0
	pane_b.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_t, pane_m, pane_b]

	var sb_top := TauXYSeriesBinding.new()
	sb_top.series_id = dataset.get_series_id_by_index(0)
	sb_top.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_top.y_axis_id = TauPlot.AxisId.LEFT
	sb_top.pane_index = 0

	var sb_mid := TauXYSeriesBinding.new()
	sb_mid.series_id = dataset.get_series_id_by_index(1)
	sb_mid.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	sb_mid.y_axis_id = TauPlot.AxisId.LEFT
	sb_mid.pane_index = 1

	var sb_bot := TauXYSeriesBinding.new()
	sb_bot.series_id = dataset.get_series_id_by_index(2)
	sb_bot.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_bot.y_axis_id = TauPlot.AxisId.LEFT
	sb_bot.pane_index = 2

	var bindings: Array[TauXYSeriesBinding] = [sb_bot, sb_mid, sb_top]

	plot.plot_xy(dataset, config, bindings)

	_state.append({
		"dataset": dataset,
		"next_x": NEXT_X_START,
		"last_append_t": 0.0,
		"title": p_title,
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


func _resize_slot(p_state_index: int) -> void:
	_slots[p_state_index].set_span(Vector2(
		_span_fraction(SPAN_MIN.x, SPAN_PERIOD.x),
		_span_fraction(SPAN_MIN.y, SPAN_PERIOD.y)))


func _span_fraction(p_min: float, p_period: float) -> float:
	var wave := 0.5 - 0.5 * cos(TAU * _t / p_period)
	return p_min + (1.0 - p_min) * wave


func _report_fit() -> void:
	var over := PackedStringArray()
	for i in _slots.size():
		if not _slots[i].fits():
			over.append(_state[i]["title"])

	var report := "every plot fits the rect it is given"
	if not over.is_empty():
		report = "larger than the rect it is given: %s" % ", ".join(over)
	if report == _last_fit_report:
		return
	_last_fit_report = report
	print(report)

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot("OUTSIDE_TOP", TauLegendConfig.Position.OUTSIDE_TOP)


func _step_test_1() -> void:
	_resize_slot(0)
	_update_plot(0)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot("OUTSIDE_RIGHT", TauLegendConfig.Position.OUTSIDE_RIGHT)


func _step_test_2() -> void:
	_resize_slot(1)
	_update_plot(1)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_make_plot("OUTSIDE_BOTTOM", TauLegendConfig.Position.OUTSIDE_BOTTOM)


func _step_test_3() -> void:
	_resize_slot(2)
	_update_plot(2)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_make_plot("OUTSIDE_LEFT", TauLegendConfig.Position.OUTSIDE_LEFT)


func _step_test_4() -> void:
	_resize_slot(3)
	_update_plot(3)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	_make_plot("INSIDE_TOP", TauLegendConfig.Position.INSIDE_TOP)


func _step_test_5() -> void:
	_resize_slot(4)
	_update_plot(4)

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	_make_plot("INSIDE_RIGHT", TauLegendConfig.Position.INSIDE_RIGHT)


func _step_test_6() -> void:
	_resize_slot(5)
	_update_plot(5)

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	_make_plot("INSIDE_BOTTOM", TauLegendConfig.Position.INSIDE_BOTTOM)


func _step_test_7() -> void:
	_resize_slot(6)
	_update_plot(6)


####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8() -> void:
	_make_plot("INSIDE_LEFT", TauLegendConfig.Position.INSIDE_LEFT)


func _step_test_8() -> void:
	_resize_slot(7)
	_update_plot(7)


####################################################################################################
# Test 9
####################################################################################################

func _setup_test_9() -> void:
	_make_plot("INSIDE_TOP_RIGHT", TauLegendConfig.Position.INSIDE_TOP_RIGHT)


func _step_test_9() -> void:
	_resize_slot(8)
	_update_plot(8)

####################################################################################################
# Test 10
####################################################################################################

func _setup_test_10() -> void:
	_make_plot("INSIDE_BOTTOM_RIGHT", TauLegendConfig.Position.INSIDE_BOTTOM_RIGHT)


func _step_test_10() -> void:
	_resize_slot(9)
	_update_plot(9)


####################################################################################################
# Test 11
####################################################################################################

func _setup_test_11() -> void:
	_make_plot("INSIDE_BOTTOM_LEFT", TauLegendConfig.Position.INSIDE_BOTTOM_LEFT)


func _step_test_11() -> void:
	_resize_slot(10)
	_update_plot(10)

####################################################################################################
# Test 12
####################################################################################################

func _setup_test_12() -> void:
	_make_plot("INSIDE_TOP_LEFT", TauLegendConfig.Position.INSIDE_TOP_LEFT)


func _step_test_12() -> void:
	_resize_slot(11)
	_update_plot(11)
