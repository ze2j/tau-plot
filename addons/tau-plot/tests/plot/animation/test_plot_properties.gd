@tool
extends Control

const X: PackedFloat64Array = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
const Y_SHAPE: PackedFloat64Array = [1.0, 4.0, 2.0, 5.0, 2.5, 4.5]
const SERIES_NAMES: PackedStringArray = ["Alpha", "Beta"]
const SERIES_OFFSET := 1.5
const TICK_INTERVAL_S := 3.0
const LEGEND_KEY_HEIGHT_PX := 20

const TITLES: PackedStringArray = [
	"Plain title",
	"",
	"[b]Bold[/b] and [color=orange]colored[/color] title",
	"A deliberately long title that wraps onto a second line and eats more vertical space than the others",
]

# Outside positions consume plot area, inside ones float over it. Alternating
# between the two families exercises both layout paths.
const LEGEND_POSITIONS: PackedInt32Array = [
	TauLegendConfig.Position.OUTSIDE_TOP,
	TauLegendConfig.Position.INSIDE_TOP_RIGHT,
	TauLegendConfig.Position.OUTSIDE_RIGHT,
	TauLegendConfig.Position.INSIDE_BOTTOM_LEFT,
	TauLegendConfig.Position.OUTSIDE_BOTTOM,
	TauLegendConfig.Position.INSIDE_LEFT,
	TauLegendConfig.Position.OUTSIDE_LEFT,
	TauLegendConfig.Position.INSIDE_BOTTOM,
]


var _timer: Timer = null
var _tick_count := 0


func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()

	_create_timer()
	_timer.start()


func _create_timer() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = TICK_INTERVAL_S
	_timer.timeout.connect(_on_tick)
	add_child(_timer)


func _on_tick() -> void:
	_tick_count += 1
	_step_test_1()
	_step_test_2()
	_step_test_3()

####################################################################################################
# Helpers
####################################################################################################

func _make_plot(p_plot: TauPlot, p_title: String, p_legend_config: TauLegendConfig) -> void:
	var dataset := TauPlot.Dataset.make_shared_x_continuous(SERIES_NAMES, X, _make_y_series())

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 6

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.include_zero_in_domain = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.stretch_ratio = 1.0
	pane.overlays = [_make_line_config()]

	var panes: Array[TauPaneConfig] = [pane]

	var bindings: Array[TauXYSeriesBinding] = []
	for i in range(SERIES_NAMES.size()):
		var binding := TauXYSeriesBinding.new()
		binding.series_id = dataset.get_series_id_by_index(i)
		binding.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
		binding.y_axis_id = TauPlot.AxisId.LEFT
		binding.pane_index = 0
		bindings.append(binding)

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = panes

	p_plot.title = p_title
	p_plot.legend_config = p_legend_config
	p_plot.plot_xy(dataset, config, bindings)


func _make_y_series() -> Array[PackedFloat64Array]:
	var offset := PackedFloat64Array()
	for value in Y_SHAPE:
		offset.append(value + SERIES_OFFSET)

	var result: Array[PackedFloat64Array] = [Y_SHAPE, offset]
	return result


func _make_line_config() -> TauLineConfig:
	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT
	line_config.interpolation_modes = [TauLineConfig.InterpolationMode.LINEAR]
	return line_config


func _make_legend_config(p_position: TauLegendConfig.Position) -> TauLegendConfig:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.3, 0.3, 0.3)
	background.set_corner_radius_all(8)
	background.set_content_margin_all(6)

	var legend_config := TauLegendConfig.new()
	legend_config.position = p_position
	legend_config.style.background = background
	legend_config.style.key_size_px = LEGEND_KEY_HEIGHT_PX
	return legend_config

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot(%TestPlot1, TITLES[0], _make_legend_config(TauLegendConfig.Position.OUTSIDE_RIGHT))


func _step_test_1() -> void:
	%TestPlot1.title = TITLES[_tick_count % TITLES.size()]

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot(%TestPlot2, "Legend toggle", _make_legend_config(TauLegendConfig.Position.OUTSIDE_RIGHT))


func _step_test_2() -> void:
	%TestPlot2.legend_enabled = not %TestPlot2.legend_enabled

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_make_plot(%TestPlot3, "Legend position", _make_legend_config(LEGEND_POSITIONS[0]))


func _step_test_3() -> void:
	# FIXME: known limitation workaround
	var position: TauLegendConfig.Position = LEGEND_POSITIONS[_tick_count % LEGEND_POSITIONS.size()]
	%TestPlot3.legend_config = _make_legend_config(position)
