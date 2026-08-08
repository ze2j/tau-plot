@tool
extends Control

const SAMPLE_COUNT := 16

const X_MIN := -3.0
const X_MAX := 3.0

const CATEGORIES: PackedStringArray = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug"]


func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	_setup_test_5()
	_setup_test_6()
	_setup_test_7()


func _make_series_y(p_series_index: int) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	for i in range(SAMPLE_COUNT):
		out.append(float(p_series_index) + 0.5 + 0.25 * sin(float(i) * 0.7))
	return out


func _make_series_x() -> PackedFloat64Array:
	var out := PackedFloat64Array()
	var step := (X_MAX - X_MIN) / float(SAMPLE_COUNT - 1)
	for i in range(SAMPLE_COUNT):
		out.append(X_MIN + step * float(i))
	return out


func _make_series_names(p_series_count: int) -> PackedStringArray:
	var out := PackedStringArray()
	for s_i in range(p_series_count):
		out.append(char(65 + s_i))
	return out


func _make_continuous_dataset(p_series_count: int) -> TauPlot.Dataset:
	var x_by_series: Array[PackedFloat64Array] = []
	var y_by_series: Array[PackedFloat64Array] = []
	for s_i in range(p_series_count):
		x_by_series.append(_make_series_x())
		y_by_series.append(_make_series_y(s_i))
	return TauPlot.Dataset.make_per_series_x_continuous(_make_series_names(p_series_count), x_by_series, y_by_series)


func _make_categorical_dataset(p_series_count: int) -> TauPlot.Dataset:
	var y_by_series: Array[PackedFloat64Array] = []
	for s_i in range(p_series_count):
		var ys := PackedFloat64Array()
		for i in range(CATEGORIES.size()):
			ys.append(float(s_i) + 0.5 + 0.25 * sin(float(i) * 0.7))
		y_by_series.append(ys)
	return TauPlot.Dataset.make_shared_x_categorical(_make_series_names(p_series_count), CATEGORIES, y_by_series)


func _make_plot(p_plot: TauPlot, p_dataset: TauPlot.Dataset, p_x_axis_type: TauAxisConfig.Type,
				p_scatter_config: TauScatterConfig, p_title: String) -> void:
	p_plot.title = p_title

	var x_axis := TauAxisConfig.new()
	x_axis.type = p_x_axis_type
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [p_scatter_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var bindings: Array[TauXYSeriesBinding] = []
	for s_i in range(p_dataset.get_series_count()):
		var binding := TauXYSeriesBinding.new()
		binding.series_id = p_dataset.get_series_id_by_index(s_i)
		binding.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
		binding.y_axis_id = TauPlot.AxisId.LEFT
		bindings.append(binding)

	p_plot.plot_xy(p_dataset, config, bindings)


func _make_continuous_plot(p_plot: TauPlot, p_series_count: int, p_scatter_config: TauScatterConfig, p_title: String) -> void:
	_make_plot(p_plot, _make_continuous_dataset(p_series_count), TauAxisConfig.Type.CONTINUOUS, p_scatter_config, p_title)


####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var scatter_config := TauScatterConfig.new()
	var sizes: Array[float] = [20.0, 12.0, 5.0]
	scatter_config.style.marker_sizes_px = sizes

	_make_continuous_plot(%TestPlot1, 3, scatter_config, "3 series, 3 sizes: 20 / 12 / 5, no wrap")


####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var scatter_config := TauScatterConfig.new()
	var sizes: Array[float] = [18.0, 6.0]
	scatter_config.style.marker_sizes_px = sizes

	_make_continuous_plot(%TestPlot2, 5, scatter_config, "5 series, 2 sizes: 18 / 6, cycle wraps")


####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var scatter_config := TauScatterConfig.new()
	var sizes: Array[float] = [20.0, 12.0, 5.0]
	scatter_config.style.marker_sizes_px = sizes

	_make_continuous_plot(%TestPlot3, 5, scatter_config, "5 series, 3 sizes: 20 / 12 / 5 / 20 / 12, uneven wrap")


####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	var scatter_config := TauScatterConfig.new()
	var sizes: Array[float] = []
	scatter_config.style.marker_sizes_px = sizes

	_make_continuous_plot(%TestPlot4, 3, scatter_config, "3 series, empty cycle: all at DEFAULT_MARKER_SIZE_PX (12)")


####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	var scatter_config := TauScatterConfig.new()
	var sizes: Array[float] = [0.0, -4.0, 20.0]
	scatter_config.style.marker_sizes_px = sizes

	_make_continuous_plot(%TestPlot5, 3, scatter_config, "3 series, sizes 0 / -4 / 20: first two floored to 1 px")


####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	var scatter_config := TauScatterConfig.new()
	var sizes: Array[float] = [18.0, 6.0, 18.0]
	var hovered_sizes: Array[float] = [26.0, 9.0, 4.0]
	scatter_config.style.marker_sizes_px = sizes
	scatter_config.style.hovered_marker_sizes_px = hovered_sizes

	_make_continuous_plot(%TestPlot6, 3, scatter_config, "Hover me. Base 18 / 6 / 18, hovered 26 / 9 / 4 (C shrinks)")


####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	var scatter_config := TauScatterConfig.new()
	var sizes: Array[float] = [20.0, 12.0, 5.0]
	var hovered_sizes: Array[float] = []
	scatter_config.style.marker_sizes_px = sizes
	scatter_config.style.hovered_marker_sizes_px = hovered_sizes

	_make_continuous_plot(%TestPlot7, 3, scatter_config, "Hover me. Empty hovered cycle: size unchanged, color still highlights")
