@tool
extends Control

const TICK_COUNT_PREFERRED := 100
const Y_MAX := 1_000_000.0

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

func _make_dataset(p_y_max: float) -> TauPlot.Dataset:
	var x := PackedFloat64Array()
	var y := PackedFloat64Array()
	const SAMPLE_COUNT := 20
	x.resize(SAMPLE_COUNT)
	y.resize(SAMPLE_COUNT)
	for i in range(SAMPLE_COUNT):
		x[i] = float(i)
		y[i] = p_y_max * (0.5 + 0.5 * sin(float(i) * 0.5))
	var series_names := PackedStringArray(["A"])
	return TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y])


func _make_plot(p_plot: TauPlot, p_title: String, p_strategy: TauAxisConfig.OverlapStrategy, p_min_label_spacing: int) -> void:
	var dataset := _make_dataset(Y_MAX)

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.include_zero_in_domain = true
	y_axis.tick_count_preferred = TICK_COUNT_PREFERRED
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
	_make_plot(%TestPlot1, "[NONE] spacing 0 => every tick labeled, labels overlap", TauAxisConfig.OverlapStrategy.NONE, 0)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot(%TestPlot2, "[REDUCE_COUNT] spacing 0 => fewer ticks, every tick labeled", TauAxisConfig.OverlapStrategy.REDUCE_COUNT, 0)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_make_plot(%TestPlot3, "[SKIP_LABELS] spacing 0 => all ticks kept, some labels dropped", TauAxisConfig.OverlapStrategy.SKIP_LABELS, 0)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_make_plot(%TestPlot4, "[NONE] spacing 100 => every tick labeled, labels overlap", TauAxisConfig.OverlapStrategy.NONE, 100)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	_make_plot(%TestPlot5, "[REDUCE_COUNT] spacing 100 => fewer ticks, every tick labeled", TauAxisConfig.OverlapStrategy.REDUCE_COUNT, 100)

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	_make_plot(%TestPlot6, "[SKIP_LABELS] spacing 100 => all ticks kept, some labels dropped", TauAxisConfig.OverlapStrategy.SKIP_LABELS, 100)
