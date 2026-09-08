@tool
extends Control

const MAJOR_GRID_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.35)
const MINOR_GRID_LINE_COLOR := Color(0.35, 0.75, 1.0, 0.55)
const MINOR_GRID_LINE_DASH_PX := 4

func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()

####################################################################################################
# Helpers
####################################################################################################

func _make_dataset(p_x_values: PackedFloat64Array) -> TauPlot.Dataset:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := p_x_values
	var x_b := PackedFloat64Array()
	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	x_b.resize(x_a.size())
	y_a.resize(x_a.size())
	y_b.resize(x_a.size())

	for i in range(x_a.size()):
		x_b[i] = 1.1 * x_a[i]
		y_a[i] = 10.0 * exp(float(i) * 0.3)
		y_b[i] = 9.0 * exp(float(i) * 0.31)

	return TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])


func _apply_rank_style(p_pane: TauPaneConfig) -> void:
	p_pane.style.x_major_grid_line_color = MAJOR_GRID_LINE_COLOR
	p_pane.style.y_major_grid_line_color = MAJOR_GRID_LINE_COLOR
	p_pane.style.x_minor_grid_line_color = MINOR_GRID_LINE_COLOR
	p_pane.style.y_minor_grid_line_color = MINOR_GRID_LINE_COLOR
	p_pane.style.x_minor_grid_line_dash_px = MINOR_GRID_LINE_DASH_PX
	p_pane.style.y_minor_grid_line_dash_px = MINOR_GRID_LINE_DASH_PX


func _make_grid_line_config(p_minor_enabled: bool) -> TauGridLineConfig:
	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true
	grid_line_config.x_minor_enabled = p_minor_enabled
	grid_line_config.y_major_enabled = true
	grid_line_config.y_minor_enabled = p_minor_enabled
	return grid_line_config


func _make_pane(p_y_axis_id: TauPlot.AxisId, p_y_axis: TauAxisConfig, p_grid_line_config: TauGridLineConfig) -> TauPaneConfig:
	var pane := TauPaneConfig.new()
	pane.overlays = [TauScatterConfig.new()]
	pane.grid_line = p_grid_line_config
	match p_y_axis_id:
		TauPlot.AxisId.LEFT:
			pane.y_left_axis = p_y_axis
		TauPlot.AxisId.BOTTOM:
			pane.y_bottom_axis = p_y_axis
	_apply_rank_style(pane)
	return pane


func _make_plot(
		p_plot: TauPlot,
		p_title: String,
		p_x_values: PackedFloat64Array,
		p_x_axis_id: TauPlot.AxisId,
		p_y_axis_id: TauPlot.AxisId,
		p_pane_1_minor_enabled: bool) -> void:
	var dataset := _make_dataset(p_x_values)

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X-axis"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.include_zero_in_domain = false

	var pane_0 := _make_pane(p_y_axis_id, y_axis, _make_grid_line_config(true))
	var pane_1 := _make_pane(p_y_axis_id, y_axis, _make_grid_line_config(p_pane_1_minor_enabled))

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.x_axis_id = p_x_axis_id
	config.panes = [pane_0, pane_1]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.pane_index = 0
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = p_y_axis_id

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.pane_index = 1
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = p_y_axis_id

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	p_plot.title = p_title
	p_plot.legend_enabled = false
	p_plot.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot(
		%TestPlot1,
		"Stacked panes, major and minor everywhere => both panes show solid white and dashed blue lines",
		PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0]),
		TauPlot.AxisId.BOTTOM,
		TauPlot.AxisId.LEFT,
		true)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot(
		%TestPlot2,
		"Stacked panes, minor off in the bottom pane => no dashed blue line there, solid white lines unchanged",
		PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0]),
		TauPlot.AxisId.BOTTOM,
		TauPlot.AxisId.LEFT,
		false)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_make_plot(
		%TestPlot3,
		"Side by side panes, major and minor everywhere => both panes show solid white and dashed blue lines",
		PackedFloat64Array([10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0]),
		TauPlot.AxisId.LEFT,
		TauPlot.AxisId.BOTTOM,
		true)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_make_plot(
		%TestPlot4,
		"Side by side panes, minor off in the right pane => no dashed blue line there, solid white lines unchanged",
		PackedFloat64Array([10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0]),
		TauPlot.AxisId.LEFT,
		TauPlot.AxisId.BOTTOM,
		false)
