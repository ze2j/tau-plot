@tool
extends Control

const X: PackedFloat64Array = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
const Y_SHAPE: PackedFloat64Array = [1.0, 2.2, 1.4, 2.6, 1.8, 2.8]
const SERIES_OFFSET := 3.0


func _ready() -> void:
	_setup_test_1()
	_setup_test_2()

####################################################################################################
# Helpers
####################################################################################################

func _make_plot(p_plot: TauPlot, p_title: String, p_series_names: PackedStringArray, p_line_config: TauLineConfig) -> void:
	var series_count := p_series_names.size()
	var dataset := TauPlot.Dataset.make_shared_x_continuous(p_series_names, X, _make_y_series(series_count))

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 9
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.FRACTION
	x_axis.domain_padding_min = 0.0
	x_axis.domain_padding_max = 0.0

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.include_zero_in_domain = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [p_line_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var bindings: Array[TauXYSeriesBinding] = []
	for i in range(series_count):
		var binding := TauXYSeriesBinding.new()
		binding.series_id = dataset.get_series_id_by_index(i)
		binding.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
		binding.y_axis_id = TauPlot.AxisId.LEFT
		bindings.append(binding)

	p_plot.title = p_title
	p_plot.legend_config = _make_legend_config()
	p_plot.plot_xy(dataset, config, bindings)


func _make_y_series(p_count: int) -> Array[PackedFloat64Array]:
	var result: Array[PackedFloat64Array] = []
	for i in range(p_count):
		var y := PackedFloat64Array()
		for value in Y_SHAPE:
			y.append(value + float(i) * SERIES_OFFSET)
		result.append(y)
	return result


func _make_line_config() -> TauLineConfig:
	var line_config := TauLineConfig.new()
	line_config.mode = TauLineConfig.LineMode.INDEPENDENT
	line_config.interpolation_modes = [TauLineConfig.InterpolationMode.LINEAR]
	return line_config


func _make_flat_fill(p_color: Color) -> TauLineFill:
	var fill := TauLineFill.new()
	fill.fill_mode = TauLineFill.FillMode.TO_BASELINE
	fill.color = p_color
	fill.alpha = 0.5
	return fill


func _make_no_fill() -> TauLineFill:
	var fill := TauLineFill.new()
	fill.fill_mode = TauLineFill.FillMode.NONE
	return fill


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
# Test 1: stroke variants
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["Solid", "Thick", "Dashed", "Dashed, clamped", "Thick, clamped"])

	var line_config := _make_line_config()
	line_config.style.line_widths_px = [2.0, 6.0, 2.0, 2.0, 24.0]
	line_config.style.dash_lengths_px = [0, 0, 4, 20, 0]

	_make_plot(%TestPlot1, "Stroke", series_names, line_config)

####################################################################################################
# Test 2: stroke and fill combinations
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["Line and fill", "Fill only", "Line only", "Neither"])

	var line_config := _make_line_config()
	line_config.style.line_widths_px = [2.0, 0.0, 2.0, 0.0]

	var fills: Array[TauLineFill] = [
		_make_flat_fill(Color(0.2, 0.7, 1.0)),
		_make_flat_fill(TauLineFill.NO_COLOR),
		_make_no_fill(),
		_make_no_fill(),
	]
	line_config.style.fills = fills

	_make_plot(%TestPlot2, "Stroke and fill", series_names, line_config)
