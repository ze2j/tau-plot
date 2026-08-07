@tool
extends Control

const BAR_TEXTURE := preload("res://addons/tau-plot/tests/assets/red_fade_v.png")

const X: PackedFloat64Array = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
const Y_SHAPE: PackedFloat64Array = [1.0, 2.2, 1.4, 2.6, 1.8, 2.8]
const SERIES_OFFSET := 0.5
const CORNER_RADIUS_PX := 6
const BORDER_WIDTH_PX := 3
const BORDER_COLOR := Color(0.1, 0.1, 0.1)
const FADED_SERIES_ALPHAS: Array[float] = [0.3, 0.7]


func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()

####################################################################################################
# Helpers
####################################################################################################

func _make_single_pane_plot(p_plot: TauPlot, p_title: String, p_series_names: PackedStringArray, p_bar_config: TauBarConfig, p_series_alphas: Array[float] = [1.0]) -> void:
	var series_count := p_series_names.size()
	var dataset := TauPlot.Dataset.make_shared_x_continuous(p_series_names, X, _make_y_series(series_count))

	var pane := TauPaneConfig.new()
	pane.y_left_axis = _make_y_axis()
	pane.overlays = [p_bar_config]

	var config := TauXYConfig.new()
	config.x_axis = _make_x_axis()
	config.panes = [pane]
	config.style.series_alphas = p_series_alphas

	var bindings: Array[TauXYSeriesBinding] = []
	for i in range(series_count):
		bindings.append(_make_binding(dataset, i, 0))

	p_plot.title = p_title
	p_plot.legend_config = _make_legend_config()
	p_plot.plot_xy(dataset, config, bindings)


func _make_pane_per_series_plot(p_plot: TauPlot, p_title: String, p_series_names: PackedStringArray, p_bar_config_per_pane: Array[TauBarConfig]) -> void:
	var series_count := p_series_names.size()
	var dataset := TauPlot.Dataset.make_shared_x_continuous(p_series_names, X, _make_y_series(series_count))

	var panes: Array[TauPaneConfig] = []
	var bindings: Array[TauXYSeriesBinding] = []
	for i in range(series_count):
		var pane := TauPaneConfig.new()
		pane.y_left_axis = _make_y_axis()
		pane.stretch_ratio = 1.0
		pane.overlays = [p_bar_config_per_pane[i]]
		panes.append(pane)

		bindings.append(_make_binding(dataset, i, i))

	var config := TauXYConfig.new()
	config.x_axis = _make_x_axis()
	config.panes = panes

	p_plot.title = p_title
	p_plot.legend_config = _make_legend_config()
	p_plot.plot_xy(dataset, config, bindings)


func _make_binding(p_dataset: TauPlot.Dataset, p_series_index: int, p_pane_index: int) -> TauXYSeriesBinding:
	var binding := TauXYSeriesBinding.new()
	binding.series_id = p_dataset.get_series_id_by_index(p_series_index)
	binding.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	binding.y_axis_id = TauPlot.AxisId.LEFT
	binding.pane_index = p_pane_index
	return binding


func _make_y_series(p_count: int) -> Array[PackedFloat64Array]:
	var result: Array[PackedFloat64Array] = []
	for i in range(p_count):
		var y := PackedFloat64Array()
		for value in Y_SHAPE:
			y.append(value + float(i) * SERIES_OFFSET)
		result.append(y)
	return result


func _make_x_axis() -> TauAxisConfig:
	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 9
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.FRACTION
	x_axis.domain_padding_min = 0.1
	x_axis.domain_padding_max = 0.1
	return x_axis


func _make_y_axis() -> TauAxisConfig:
	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.include_zero_in_domain = true
	return y_axis


func _make_bar_config(p_mode: TauBarConfig.BarMode, p_style_box: StyleBox, p_series_count: int) -> TauBarConfig:
	var bar_config := TauBarConfig.new()
	bar_config.mode = p_mode
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = maxf(1. / float(p_series_count) - 0.02, 0.1)
	bar_config.style.style_box = p_style_box
	return bar_config


func _make_flat_box(p_corner_radius_px: int, p_border_width_px: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(p_corner_radius_px)
	box.set_border_width_all(p_border_width_px)
	box.border_color = BORDER_COLOR
	return box


func _make_texture_box() -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = BAR_TEXTURE
	return box


func _make_legend_config() -> TauLegendConfig:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.3, 0.3, 0.3)
	background.set_corner_radius_all(8)
	background.set_content_margin_all(6)

	var legend_config := TauLegendConfig.new()
	legend_config.position = TauLegendConfig.Position.OUTSIDE_RIGHT
	legend_config.style.background = background
	return legend_config

####################################################################################################
# Test 1: style box shapes
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["Flat", "Rounded", "Bordered"])
	var series_count = series_names.size()

	var bar_configs: Array[TauBarConfig] = [
		_make_bar_config(TauBarConfig.BarMode.INDEPENDENT, _make_flat_box(0, 0), series_count),
		_make_bar_config(TauBarConfig.BarMode.INDEPENDENT, _make_flat_box(CORNER_RADIUS_PX, 0), series_count),
		_make_bar_config(TauBarConfig.BarMode.INDEPENDENT, _make_flat_box(0, BORDER_WIDTH_PX), series_count),
	]

	_make_pane_per_series_plot(%TestPlot1, "Style box", series_names, bar_configs)

####################################################################################################
# Test 2: texture style box
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["Texture A", "Texture B"])

	var bar_config := _make_bar_config(TauBarConfig.BarMode.GROUPED, _make_texture_box(), series_names.size())

	_make_single_pane_plot(%TestPlot2, "Texture style box", series_names, bar_config)

####################################################################################################
# Test 3: alpha cycle
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["Color 1", "Color 2", "Color 3", "Color 4", "Color 5"])

	var bar_config := _make_bar_config(TauBarConfig.BarMode.GROUPED, _make_flat_box(CORNER_RADIUS_PX, 0), series_names.size())

	_make_single_pane_plot(%TestPlot3, "Alpha cycle", series_names, bar_config, FADED_SERIES_ALPHAS)
