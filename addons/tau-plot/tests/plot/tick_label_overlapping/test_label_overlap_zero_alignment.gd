@tool
extends Control

const SAMPLE_COUNT := 20
const TICK_COUNT_PREFERRED := 60
const MAJOR_GRID_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.35)
const MINOR_GRID_LINE_COLOR := Color(0.35, 0.75, 1.0, 0.55)
const MINOR_GRID_LINE_DASH_PX := 4

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

func _make_dataset(p_y_left_max: float, p_y_right_max: float) -> TauPlot.Dataset:
	var x := PackedFloat64Array()
	var y_left := PackedFloat64Array()
	var y_right := PackedFloat64Array()
	x.resize(SAMPLE_COUNT)
	y_left.resize(SAMPLE_COUNT)
	y_right.resize(SAMPLE_COUNT)
	for i in range(SAMPLE_COUNT):
		x[i] = float(i)
		y_left[i] = p_y_left_max * (0.25 + 0.5 * sin(float(i) * 0.5))
		y_right[i] = p_y_right_max * (0.5 + 0.5 * cos(float(i) * 0.7))
	var series_names := PackedStringArray(["Left", "Right"])
	return TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_left, y_right])


func _apply_rank_style(p_pane: TauPaneConfig) -> void:
	p_pane.style.y_major_grid_line_color = MAJOR_GRID_LINE_COLOR
	p_pane.style.y_minor_grid_line_color = MINOR_GRID_LINE_COLOR
	p_pane.style.y_minor_grid_line_dash_px = MINOR_GRID_LINE_DASH_PX


func _make_plot(
		p_plot: TauPlot,
		p_title: String,
		p_left_strategy: TauAxisConfig.OverlapStrategy,
		p_right_strategy: TauAxisConfig.OverlapStrategy,
		p_align_y_axes_at_zero: bool) -> void:
	var dataset := _make_dataset(1_000_000, 500)

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS

	var y_left_axis := TauAxisConfig.new()
	y_left_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_left_axis.include_zero_in_domain = p_align_y_axes_at_zero
	y_left_axis.tick_count_preferred = TICK_COUNT_PREFERRED
	y_left_axis.overlap_strategy = p_left_strategy

	var y_right_axis := TauAxisConfig.new()
	y_right_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_right_axis.include_zero_in_domain = p_align_y_axes_at_zero
	y_right_axis.tick_count_preferred = TICK_COUNT_PREFERRED
	y_right_axis.overlap_strategy = p_right_strategy

	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.y_major_enabled = true
	grid_line_config.y_source_axis_id = TauPlot.AxisId.LEFT

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_left_axis
	pane.y_right_axis = y_right_axis
	pane.align_y_axes_at_zero = p_align_y_axes_at_zero
	pane.grid_line = grid_line_config
	pane.overlays = [TauScatterConfig.new()]
	_apply_rank_style(pane)

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_left := TauXYSeriesBinding.new()
	sb_left.series_id = dataset.get_series_id_by_index(0)
	sb_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_left.y_axis_id = TauPlot.AxisId.LEFT

	var sb_right := TauXYSeriesBinding.new()
	sb_right.series_id = dataset.get_series_id_by_index(1)
	sb_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_right.y_axis_id = TauPlot.AxisId.RIGHT

	var bindings: Array[TauXYSeriesBinding] = [sb_left, sb_right]

	p_plot.title = p_title
	p_plot.legend_enabled = true
	p_plot.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot(%TestPlot1, "[no zero alignment] 60 ticks, NONE on left, NONE on right => both sides overlap", TauAxisConfig.OverlapStrategy.NONE, TauAxisConfig.OverlapStrategy.NONE, false)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot(%TestPlot2, "[no zero alignment] 60 ticks, SKIP_LABELS on left, NONE on right => left readable, right overlaps", TauAxisConfig.OverlapStrategy.SKIP_LABELS, TauAxisConfig.OverlapStrategy.NONE, false)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_make_plot(%TestPlot3, "[no zero alignment] 60 ticks, NONE on left, REDUCE_COUNT on right => left overlaps, right has fewer ticks", TauAxisConfig.OverlapStrategy.NONE, TauAxisConfig.OverlapStrategy.REDUCE_COUNT, false)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_make_plot(%TestPlot4, "[with zero alignment] 60 ticks, SKIP_LABELS on both => zeros face each other, grid lines follow the left axis", TauAxisConfig.OverlapStrategy.SKIP_LABELS, TauAxisConfig.OverlapStrategy.SKIP_LABELS, true)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	_make_plot(%TestPlot5, "[with zero alignment] 60 ticks, REDUCE_COUNT on left, SKIP_LABELS on right => zeros stay aligned", TauAxisConfig.OverlapStrategy.REDUCE_COUNT, TauAxisConfig.OverlapStrategy.SKIP_LABELS, true)

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	_make_plot(%TestPlot6, "[with zero alignment] 60 ticks, SKIP_LABELS on left, REDUCE_COUNT on right => zeros stay aligned", TauAxisConfig.OverlapStrategy.SKIP_LABELS, TauAxisConfig.OverlapStrategy.REDUCE_COUNT, true)
