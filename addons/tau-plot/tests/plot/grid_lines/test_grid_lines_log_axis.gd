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
	_setup_test_5()
	_setup_test_6()

####################################################################################################
# Helpers
####################################################################################################

func _make_dataset() -> TauPlot.Dataset:
	var series_names := PackedStringArray(["A", "B"])
	var x_a := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])
	var x_b := PackedFloat64Array()
	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	x_b.resize(x_a.size())
	y_a.resize(x_a.size())
	y_b.resize(x_a.size())

	for i in range(x_a.size()):
		x_b[i] = 1.2 * x_a[i]
		y_a[i] = 2.0 * pow(10.0, float(i) * 0.25)
		y_b[i] = 1.0 * pow(10.0, float(i) * 0.25)

	return TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])


func _apply_rank_style(p_pane: TauPaneConfig) -> void:
	p_pane.style.x_major_grid_line_color = MAJOR_GRID_LINE_COLOR
	p_pane.style.y_major_grid_line_color = MAJOR_GRID_LINE_COLOR
	p_pane.style.x_minor_grid_line_color = MINOR_GRID_LINE_COLOR
	p_pane.style.y_minor_grid_line_color = MINOR_GRID_LINE_COLOR
	p_pane.style.x_minor_grid_line_dash_px = MINOR_GRID_LINE_DASH_PX
	p_pane.style.y_minor_grid_line_dash_px = MINOR_GRID_LINE_DASH_PX


func _make_grid_line_config(p_x_major: bool, p_x_minor: bool, p_y_major: bool, p_y_minor: bool) -> TauGridLineConfig:
	var grid_line_config := TauGridLineConfig.new()
	grid_line_config.x_major_enabled = p_x_major
	grid_line_config.x_minor_enabled = p_x_minor
	grid_line_config.y_major_enabled = p_y_major
	grid_line_config.y_minor_enabled = p_y_minor
	return grid_line_config


func _make_plot(p_plot: TauPlot, p_title: String, p_grid_line_config: TauGridLineConfig) -> void:
	var dataset := _make_dataset()

	var x_axis := TauAxisConfig.new()
	x_axis.title = "X (log scale)"
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	x_axis.include_zero_in_domain = false

	var y_axis_left := TauAxisConfig.new()
	y_axis_left.title = "Y (log scale)"
	y_axis_left.type = TauAxisConfig.Type.CONTINUOUS
	y_axis_left.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis_left.include_zero_in_domain = false

	var pane_config := TauPaneConfig.new()
	pane_config.y_left_axis = y_axis_left
	pane_config.overlays = [TauScatterConfig.new()]
	pane_config.grid_line = p_grid_line_config
	_apply_rank_style(pane_config)

	var xy_config := TauXYConfig.new()
	xy_config.x_axis = x_axis
	xy_config.panes = [pane_config]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	p_plot.title = p_title
	p_plot.legend_enabled = false
	p_plot.plot_xy(dataset, xy_config, bindings)

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot(%TestPlot1, "No grid line => empty pane background", null)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot(%TestPlot2, "X major only => one solid white line per power of ten", _make_grid_line_config(true, false, false, false))

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_make_plot(%TestPlot3, "X minor only => dashed blue lines on the 2 to 9 positions, none on the powers of ten", _make_grid_line_config(false, true, false, false))

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_make_plot(%TestPlot4, "X major and minor => solid white on the powers of ten, dashed blue between them", _make_grid_line_config(true, true, false, false))

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	_make_plot(%TestPlot5, "Y major and minor => solid white on the powers of ten, dashed blue between them", _make_grid_line_config(false, false, true, true))

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	_make_plot(%TestPlot6, "X and Y, major and minor => full grid, every rank readable", _make_grid_line_config(true, true, true, true))
