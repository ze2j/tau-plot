@tool
extends Control

const LOG_MIN_EXP := -9.0
const LOG_MAX_EXP := 9.0

func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	_setup_test_5()
	_setup_test_6()

####################################################################################################
# Helpers
####################################################################################################

func _make_log_dataset(p_log_min_exp: float, p_log_max_exp: float) -> TauPlot.Dataset:
	var x := PackedFloat64Array()
	var y := PackedFloat64Array()
	const SAMPLE_COUNT := 20
	x.resize(SAMPLE_COUNT)
	y.resize(SAMPLE_COUNT)
	for i in range(SAMPLE_COUNT):
		var t := float(i) / float(SAMPLE_COUNT - 1)
		x[i] = float(i)
		y[i] = pow(10.0, p_log_min_exp + t * (p_log_max_exp - p_log_min_exp))
	var series_names := PackedStringArray(["A"])
	return TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y])


func _make_plot(p_plot: TauPlot, p_title: String, p_strategy: TauAxisConfig.OverlapStrategy, p_min_label_spacing: int) -> void:
	var dataset := _make_log_dataset(LOG_MIN_EXP, LOG_MAX_EXP)

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false
	y_axis.overlap_strategy = p_strategy
	y_axis.min_label_spacing_px = p_min_label_spacing

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb := TauXYSeriesBinding.new()
	sb.series_id = dataset.get_series_id_by_index(0)
	sb.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb]

	p_plot.title = p_title
	p_plot.legend_enabled = false
	p_plot.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot(%TestPlot1, "[NONE] domain [1e-9, 1e9], default spacing => one label per decade, labels may overlap", TauAxisConfig.OverlapStrategy.NONE, TauAxisConfig.new().min_label_spacing_px)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot(%TestPlot2, "[REDUCE_COUNT] domain [1e-9, 1e9], default spacing => warns and falls back to SKIP_LABELS", TauAxisConfig.OverlapStrategy.REDUCE_COUNT, TauAxisConfig.new().min_label_spacing_px)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_make_plot(%TestPlot3, "[SKIP_LABELS] domain [1e-9, 1e9], default spacing => all ticks kept, decades skipped until labels fit", TauAxisConfig.OverlapStrategy.SKIP_LABELS, TauAxisConfig.new().min_label_spacing_px)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_make_plot(%TestPlot4, "[NONE] domain [1e-9, 1e9], spacing 100 => one label per decade, labels may overlap", TauAxisConfig.OverlapStrategy.NONE, 100)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	_make_plot(%TestPlot5, "[REDUCE_COUNT] domain [1e-9, 1e9], spacing 100 => warns and falls back to SKIP_LABELS", TauAxisConfig.OverlapStrategy.REDUCE_COUNT, 100)

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	_make_plot(%TestPlot6, "[SKIP_LABELS] domain [1e-9, 1e9], spacing 100 => all ticks kept, decades skipped until labels fit", TauAxisConfig.OverlapStrategy.SKIP_LABELS, 100)
