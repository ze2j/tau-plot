@tool
extends Control

const GRADIENT_TEXTURE_V := preload("res://addons/tau-plot/tests/assets/green_to_red_v.png")
const GRADIENT_TEXTURE_H := preload("res://addons/tau-plot/tests/assets/green_to_red_h.png")
const TILE_TEXTURE := preload("res://addons/tau-plot/tests/assets/dots.png")

const X: PackedFloat64Array = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
const Y_SHAPE: PackedFloat64Array = [1.0, 4.0, 2.0, 5.0, 2.5, 4.5]
const MAGNITUDE_BASELINE := 3.0
const SPAN_NAMES: PackedStringArray = ["LINE", "VALUE_Y", "VALUE_X", "MAGNITUDE"]
const LEGEND_KEY_HEIGHT_PX := 20
const TILE_ROTATION_DEG := 30.0
const TILE_SCROLL_SPEED_PX := 20.0


var _timer: Timer = null
var _t: float = 0.0
var _scrolling_fill: TauLineFill = null


func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()

	_create_timer()
	_timer.start()


func _create_timer() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = 0.016
	_timer.timeout.connect(_on_tick)
	add_child(_timer)


func _on_tick() -> void:
	_t += _timer.wait_time
	_step_test_4()

####################################################################################################
# Helpers
####################################################################################################

func _make_plot(p_plot: TauPlot, p_title: String, p_series_names: PackedStringArray, p_line_config: TauLineConfig, p_invert_x: bool, p_invert_y: bool) -> void:
	var series_count := p_series_names.size()
	var dataset := TauPlot.Dataset.make_shared_x_continuous(p_series_names, X, _make_y_series(series_count))

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.inverted = p_invert_x
	x_axis.tick_count_preferred = 9
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.FRACTION
	x_axis.domain_padding_min = 0.0
	x_axis.domain_padding_max = 0.0

	var panes: Array[TauPaneConfig] = []
	var bindings: Array[TauXYSeriesBinding] = []
	for i in range(series_count):
		var y_axis := TauAxisConfig.new()
		y_axis.type = TauAxisConfig.Type.CONTINUOUS
		y_axis.include_zero_in_domain = true
		y_axis.inverted = p_invert_y

		var pane := TauPaneConfig.new()
		pane.y_left_axis = y_axis
		pane.stretch_ratio = 1.0
		pane.overlays = [p_line_config]
		panes.append(pane)

		var binding := TauXYSeriesBinding.new()
		binding.series_id = dataset.get_series_id_by_index(i)
		binding.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
		binding.y_axis_id = TauPlot.AxisId.LEFT
		binding.pane_index = i
		bindings.append(binding)

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = panes

	p_plot.title = p_title
	p_plot.legend_config = _make_legend_config()
	p_plot.plot_xy(dataset, config, bindings)


func _make_y_series(p_count: int) -> Array[PackedFloat64Array]:
	var result: Array[PackedFloat64Array] = []
	for i in range(p_count):
		result.append(Y_SHAPE)
	return result


func _make_line_config() -> TauLineConfig:
	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT
	line_config.interpolation_modes = [TauLineConfig.InterpolationMode.LINEAR]
	return line_config


func _make_span_line_config() -> TauLineConfig:
	var magnitude_fill := _make_gradient_fill(TauLineFill.FillStretchSpan.MAGNITUDE, GRADIENT_TEXTURE_V)
	magnitude_fill.fill_baseline = MAGNITUDE_BASELINE

	var fills: Array[TauLineFill] = [
		_make_gradient_fill(TauLineFill.FillStretchSpan.LINE, GRADIENT_TEXTURE_V),
		_make_gradient_fill(TauLineFill.FillStretchSpan.VALUE_Y, GRADIENT_TEXTURE_V),
		_make_gradient_fill(TauLineFill.FillStretchSpan.VALUE_X, GRADIENT_TEXTURE_H),
		magnitude_fill,
	]

	var line_config := _make_line_config()
	line_config.style.fills = fills
	return line_config


func _make_gradient_fill(p_span: TauLineFill.FillStretchSpan, p_gradient_texture: Texture2D) -> TauLineFill:
	var fill := TauLineFill.new()
	fill.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill.texture = p_gradient_texture
	fill.texture_mode = TauLineFill.FillTextureMode.STRETCH
	fill.stretch_span = p_span
	fill.stretch_range_policy = TauLineFill.StretchRangePolicy.DOMAIN
	fill.alpha = 1.0
	return fill


func _make_tile_fill(p_rotation_deg: float) -> TauLineFill:
	var fill := TauLineFill.new()
	fill.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill.texture = TILE_TEXTURE
	fill.texture_mode = TauLineFill.FillTextureMode.TILE
	fill.tile_scale = 0.2
	fill.tile_rotation_deg = p_rotation_deg
	fill.tile_offset_px = Vector2.ZERO
	fill.alpha = 1.0
	return fill


func _make_legend_config() -> TauLegendConfig:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.3, 0.3, 0.3)
	background.set_corner_radius_all(8)
	background.set_content_margin_all(6)

	var legend_config := TauLegendConfig.new()
	legend_config.position = TauLegendConfig.Position.OUTSIDE_RIGHT
	legend_config.style.background = background
	legend_config.style.key_size_px = LEGEND_KEY_HEIGHT_PX
	return legend_config

####################################################################################################
# Test 1: every span on normal axes
####################################################################################################

func _setup_test_1() -> void:
	_make_plot(%TestPlot1, "Normal axes", SPAN_NAMES, _make_span_line_config(), false, false)

####################################################################################################
# Test 2: inverted y axis
####################################################################################################

func _setup_test_2() -> void:
	_make_plot(%TestPlot2, "Inverted y", SPAN_NAMES, _make_span_line_config(), false, true)

####################################################################################################
# Test 3: inverted x axis
####################################################################################################

func _setup_test_3() -> void:
	_make_plot(%TestPlot3, "Inverted x", SPAN_NAMES, _make_span_line_config(), true, false)

####################################################################################################
# Test 4: tiled pattern
####################################################################################################

func _setup_test_4() -> void:
	var series_names := PackedStringArray(["Scrolling", "Rotated"])

	_scrolling_fill = _make_tile_fill(0.0)

	var line_config := _make_line_config()
	var fills: Array[TauLineFill] = [_scrolling_fill, _make_tile_fill(TILE_ROTATION_DEG)]
	line_config.style.fills = fills

	_make_plot(%TestPlot4, "Tiled with animated offset", series_names, line_config, false, false)


func _step_test_4() -> void:
	_scrolling_fill.tile_offset_px = Vector2(-_t * TILE_SCROLL_SPEED_PX, 0.0)
