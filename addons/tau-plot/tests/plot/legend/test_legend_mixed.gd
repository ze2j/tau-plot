@tool
extends Control

const X: PackedFloat64Array = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]
const Y_SHAPE: PackedFloat64Array = [1.0, 2.2, 1.4, 2.6, 1.8, 2.8]
const SERIES_OFFSET := 1.0
const BAR_WIDTH_X_UNITS := 0.6


func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()

####################################################################################################
# Helpers
####################################################################################################

func _make_plot(p_plot: TauPlot, p_title: String, p_series_names: PackedStringArray, p_overlays: Array[TauPaneOverlayConfig], p_bindings_by_series: Array[Array], p_transposed: bool) -> void:
	var series_count := p_series_names.size()
	var dataset := TauPlot.Dataset.make_shared_x_continuous(p_series_names, X, _make_y_series(series_count))

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 9
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.FRACTION
	x_axis.domain_padding_min = 0.1
	x_axis.domain_padding_max = 0.1

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.include_zero_in_domain = true

	var y_axis_id := TauPlot.AxisId.BOTTOM if p_transposed else TauPlot.AxisId.LEFT

	var pane := TauPaneConfig.new()
	if p_transposed:
		pane.y_bottom_axis = y_axis
	else:
		pane.y_left_axis = y_axis
	pane.overlays = p_overlays

	var config := TauXYConfig.new()
	config.x_axis_id = TauPlot.AxisId.LEFT if p_transposed else TauPlot.AxisId.BOTTOM
	config.x_axis = x_axis
	config.panes = [pane]

	var bindings: Array[TauXYSeriesBinding] = []
	for series_index in range(series_count):
		for entry in p_bindings_by_series[series_index]:
			var binding := TauXYSeriesBinding.new()
			binding.series_id = dataset.get_series_id_by_index(series_index)
			binding.overlay_type = entry["overlay_type"]
			binding.y_axis_id = y_axis_id
			binding.show_in_legend = entry.get("show_in_legend", true)
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


func _make_scatter_config() -> TauScatterConfig:
	var scatter_config := TauScatterConfig.new()
	scatter_config.style.marker_shapes = [TauScatterStyle.MarkerShape.CIRCLE]
	return scatter_config


func _make_bar_config() -> TauBarConfig:
	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.DATA_UNITS
	bar_config.bar_width_x_units = BAR_WIDTH_X_UNITS
	bar_config.style.style_box = StyleBoxFlat.new()
	return bar_config


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
# Test 1: two keys in one row
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["Line and scatter", "Line", "Scatter"])

	var overlays: Array[TauPaneOverlayConfig] = [_make_line_config(), _make_scatter_config()]

	var bindings_by_series: Array[Array] = [
		[
			{"overlay_type": TauXYSeriesBinding.PaneOverlayType.LINE},
			{"overlay_type": TauXYSeriesBinding.PaneOverlayType.SCATTER},
		],
		[{"overlay_type": TauXYSeriesBinding.PaneOverlayType.LINE}],
		[{"overlay_type": TauXYSeriesBinding.PaneOverlayType.SCATTER}],
	]

	_make_plot(%TestPlot1, "Two keys", series_names, overlays, bindings_by_series, false)

####################################################################################################
# Test 2: three keys in one row
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["Bar, line and scatter", "Bar"])

	var overlays: Array[TauPaneOverlayConfig] = [_make_bar_config(), _make_line_config(), _make_scatter_config()]

	var bindings_by_series: Array[Array] = [
		[
			{"overlay_type": TauXYSeriesBinding.PaneOverlayType.BAR},
			{"overlay_type": TauXYSeriesBinding.PaneOverlayType.LINE},
			{"overlay_type": TauXYSeriesBinding.PaneOverlayType.SCATTER},
		],
		[{"overlay_type": TauXYSeriesBinding.PaneOverlayType.BAR}],
	]

	_make_plot(%TestPlot2, "Three keys", series_names, overlays, bindings_by_series, false)

####################################################################################################
# Test 3: show_in_legend
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["Scatter key hidden", "No row", "Line"])

	var overlays: Array[TauPaneOverlayConfig] = [_make_line_config(), _make_scatter_config()]

	var bindings_by_series: Array[Array] = [
		[
			{"overlay_type": TauXYSeriesBinding.PaneOverlayType.LINE},
			{"overlay_type": TauXYSeriesBinding.PaneOverlayType.SCATTER, "show_in_legend": false},
		],
		[
			{"overlay_type": TauXYSeriesBinding.PaneOverlayType.LINE, "show_in_legend": false},
			{"overlay_type": TauXYSeriesBinding.PaneOverlayType.SCATTER, "show_in_legend": false},
		],
		[{"overlay_type": TauXYSeriesBinding.PaneOverlayType.LINE}],
	]

	_make_plot(%TestPlot3, "First series has no scatter key, second series has no key at all", series_names, overlays, bindings_by_series, false)

####################################################################################################
# Test 4: transposed plot
####################################################################################################

func _setup_test_4() -> void:
	var series_names := PackedStringArray(["Bar", "Line and scatter"])

	var overlays: Array[TauPaneOverlayConfig] = [_make_bar_config(), _make_line_config(), _make_scatter_config()]

	var bindings_by_series: Array[Array] = [
		[{"overlay_type": TauXYSeriesBinding.PaneOverlayType.BAR}],
		[
			{"overlay_type": TauXYSeriesBinding.PaneOverlayType.LINE},
			{"overlay_type": TauXYSeriesBinding.PaneOverlayType.SCATTER},
		],
	]

	_make_plot(%TestPlot4, "Transposed", series_names, overlays, bindings_by_series, true)
