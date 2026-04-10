@tool
extends Control

var x_a := PackedFloat64Array([
	 1.9, -1.4,  3.2,  0.7, -2.1,  2.6,
	-0.8,  1.3,  3.5, -0.2,  2.1, -1.9,
	 0.4,  2.9, -2.4,  1.6,  0.0,  3.6,
	-0.5,  2.3, -1.1,  1.1,  2.8, -1.7,
	 3.0, -2.0,  1.4, -0.3,  2.4,  0.9,
	-1.5,  3.3,  1.8, -2.2,  2.7,  0.2,
	 1.0, -0.7,  3.4, -1.2,  2.0,  0.5,
	-2.3,  1.7,  2.5, -0.1,  3.1, -1.6
])
var y_a := PackedFloat64Array([
	 2.2,  1.3,  1.7,  1.0,  0.9,  1.5,
	 1.8,  2.1,  1.4,  1.6,  1.9,  1.2,
	 1.4,  1.8,  1.1,  2.3,  1.7,  1.5,
	 1.3,  1.6,  1.0,  2.0,  1.4,  1.2,
	 1.9,  1.1,  2.2,  1.5,  1.7,  1.3,
	 1.0,  1.8,  2.0,  0.9,  1.6,  1.4,
	 2.1,  1.2,  1.5,  1.7,  2.3,  1.6,
	 1.0,  1.9,  1.4,  1.8,  2.0,  1.3
])

var x_b := PackedFloat64Array([
	-2.7,  0.9, -1.8,  2.4, -3.1,  1.2,
	-0.4,  1.9, -2.2,  0.1,  2.7, -1.0,
	 0.6, -3.3,  1.5, -0.9,
	 2.1, -2.5,  0.4,  1.7, -1.3,  2.6,
	-0.2,  1.0, -2.9,  0.8,  2.3, -1.6,
	 1.3, -3.0,  0.0,  1.8
])
var y_b := PackedFloat64Array([
	 1.1,  2.4,  0.8,  1.3,  1.6,  0.5,
	 1.7,  1.9,  1.0,  1.5,  1.2,  1.4,
	 2.0,  1.8,  1.1,  1.6,
	 1.9,  0.9,  1.4,  2.1,  1.0,  1.3,
	 1.6,  2.2,  1.7,  1.2,  1.5,  0.8,
	 1.1,  1.4,  1.8,  2.0
])

func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	_setup_test_5()
	_setup_test_6()
	_setup_test_7()
	_setup_test_8()


func _make_plot(p_plot: TauPlot, p_marker_shape: TauScatterStyle.MarkerShape, p_title: String):
	var series_names := PackedStringArray(["A", "B"])

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])

	p_plot.title = p_title

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR

	var scatter_config := TauScatterConfig.new()
	scatter_config.style.marker_shapes[0] = p_marker_shape

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [scatter_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	p_plot.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	_make_plot(%TestPlot1, TauScatterStyle.MarkerShape.CIRCLE, "CIRCLE for series A, default shape for series B (SQUARE)")

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	_make_plot(%TestPlot2, TauScatterStyle.MarkerShape.SQUARE, "SQUARE for series A, default shape for series B (SQUARE)")

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	_make_plot(%TestPlot3, TauScatterStyle.MarkerShape.TRIANGLE_UP, "TRIANGLE_UP for series A, default shape for series B (SQUARE)")

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	_make_plot(%TestPlot4, TauScatterStyle.MarkerShape.TRIANGLE_DOWN, "TRIANGLE_DOWN for series A, default shape for series B (SQUARE)")

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	_make_plot(%TestPlot5, TauScatterStyle.MarkerShape.DIAMOND, "DIAMOND for series A, default shape for series B (SQUARE)")

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	_make_plot(%TestPlot6, TauScatterStyle.MarkerShape.CROSS, "CROSS for series A, default shape for series B (SQUARE)")

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	_make_plot(%TestPlot7, TauScatterStyle.MarkerShape.PLUS, "PLUS for series A, default shape for series B (SQUARE)")

####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8() -> void:
	_make_plot(%TestPlot8, TauScatterStyle.MarkerShape.NONE, "NONE for series A, default shape for series B (SQUARE)")
