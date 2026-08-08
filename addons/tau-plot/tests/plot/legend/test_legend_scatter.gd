@tool
extends Control

const X: PackedFloat64Array = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
const Y_SHAPE: PackedFloat64Array = [1.0, 2.2, 1.4, 2.6, 1.8, 2.8]
const SERIES_OFFSET := 1.0
const SMALL_MARKER_SIZE_PX := 6.0
const DEFAULT_MARKER_SIZE_PX := 12.0
const LARGE_MARKER_SIZE_PX := 24.0
const MARKER_SIZE_DATA_UNITS := 0.4
const THIN_OUTLINE_WIDTH_PX := 1.0
const THICK_OUTLINE_WIDTH_PX := 4.0
const DARK_OUTLINE_COLOR := Color(0.05, 0.05, 0.05)
const LIGHT_OUTLINE_COLOR := Color(0.95, 0.95, 0.95)


func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()

####################################################################################################
# Helpers
####################################################################################################

func _make_single_pane_plot(p_plot: TauPlot, p_title: String, p_series_names: PackedStringArray, p_scatter_config: TauScatterConfig) -> void:
	var series_count := p_series_names.size()
	var dataset := TauPlot.Dataset.make_shared_x_continuous(p_series_names, X, _make_y_series(series_count))

	var pane := TauPaneConfig.new()
	pane.y_left_axis = _make_y_axis()
	pane.overlays = [p_scatter_config]

	var config := TauXYConfig.new()
	config.x_axis = _make_x_axis()
	config.panes = [pane]

	var bindings: Array[TauXYSeriesBinding] = []
	for i in range(series_count):
		bindings.append(_make_binding(dataset, i, 0))

	p_plot.title = p_title
	p_plot.legend_config = _make_legend_config()
	p_plot.plot_xy(dataset, config, bindings)


func _make_pane_per_series_plot(p_plot: TauPlot, p_title: String, p_series_names: PackedStringArray, p_scatter_config_per_pane: Array[TauScatterConfig]) -> void:
	var series_count := p_series_names.size()
	var dataset := TauPlot.Dataset.make_shared_x_continuous(p_series_names, X, _make_y_series(series_count))

	var panes: Array[TauPaneConfig] = []
	var bindings: Array[TauXYSeriesBinding] = []
	for i in range(series_count):
		var pane := TauPaneConfig.new()
		pane.y_left_axis = _make_y_axis()
		pane.stretch_ratio = 1.0
		pane.overlays = [p_scatter_config_per_pane[i]]
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
	binding.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
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
	x_axis.domain_padding_min = 0.05
	x_axis.domain_padding_max = 0.05
	return x_axis


func _make_y_axis() -> TauAxisConfig:
	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.include_zero_in_domain = true
	return y_axis


func _make_scatter_config() -> TauScatterConfig:
	var scatter_config := TauScatterConfig.new()
	scatter_config.marker_size_policy = TauScatterConfig.MarkerSizePolicy.THEME
	scatter_config.style.marker_sizes_px = [DEFAULT_MARKER_SIZE_PX]
	scatter_config.style.outline_width_px = THIN_OUTLINE_WIDTH_PX
	scatter_config.style.outline_color = DARK_OUTLINE_COLOR
	return scatter_config


func _make_outline_config(p_outline_width_px: float, p_outline_color: Color) -> TauScatterConfig:
	var scatter_config := _make_scatter_config()
	scatter_config.style.outline_width_px = p_outline_width_px
	scatter_config.style.outline_color = p_outline_color
	return scatter_config


func _make_size_config(p_marker_size_px: float) -> TauScatterConfig:
	var scatter_config := _make_scatter_config()
	scatter_config.style.marker_sizes_px = [p_marker_size_px]
	return scatter_config


func _make_data_units_config() -> TauScatterConfig:
	var scatter_config := _make_scatter_config()
	scatter_config.marker_size_policy = TauScatterConfig.MarkerSizePolicy.DATA_UNITS
	scatter_config.marker_size_data_units = MARKER_SIZE_DATA_UNITS
	return scatter_config


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
# Test 1: marker shapes
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray([
		"Circle", "Square", "Triangle up", "Triangle down", "Diamond", "Cross", "Plus", "None",
	])

	var scatter_config := _make_scatter_config()
	scatter_config.style.marker_shapes = [
		TauScatterStyle.MarkerShape.CIRCLE,
		TauScatterStyle.MarkerShape.SQUARE,
		TauScatterStyle.MarkerShape.TRIANGLE_UP,
		TauScatterStyle.MarkerShape.TRIANGLE_DOWN,
		TauScatterStyle.MarkerShape.DIAMOND,
		TauScatterStyle.MarkerShape.CROSS,
		TauScatterStyle.MarkerShape.PLUS,
		TauScatterStyle.MarkerShape.NONE,
	]

	_make_single_pane_plot(%TestPlot1, "Marker shapes", series_names, scatter_config)

####################################################################################################
# Test 2: outline
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["No outline", "Thin dark", "Thick light"])

	var scatter_configs: Array[TauScatterConfig] = [
		_make_outline_config(0.0, DARK_OUTLINE_COLOR),
		_make_outline_config(THIN_OUTLINE_WIDTH_PX, DARK_OUTLINE_COLOR),
		_make_outline_config(THICK_OUTLINE_WIDTH_PX, LIGHT_OUTLINE_COLOR),
	]

	_make_pane_per_series_plot(%TestPlot2, "Outline", series_names, scatter_configs)

####################################################################################################
# Test 3: marker size
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["Small", "Default", "Large", "Data units"])

	var scatter_configs: Array[TauScatterConfig] = [
		_make_size_config(SMALL_MARKER_SIZE_PX),
		_make_size_config(DEFAULT_MARKER_SIZE_PX),
		_make_size_config(LARGE_MARKER_SIZE_PX),
		_make_data_units_config(),
	]

	_make_pane_per_series_plot(%TestPlot3, "Marker sizes", series_names, scatter_configs)
