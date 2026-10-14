@tool
extends Control

var x := PackedStringArray(["One", "Two", "Three"])
var y_a := PackedFloat64Array([2.2,  1.3,  1.7])
var y_b := PackedFloat64Array([11.0,  24,  8])

func _ready() -> void:
	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["A", "B"])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b])

	%TestPlot1.title = "Use BOTTOM x-axis"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.tick_count_preferred = 20

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED

	var pane_config := TauPaneConfig.new()
	pane_config.y_left_axis = y_axis
	pane_config.overlays = [bar_config]
	pane_config.grid_line = grid_line_config

	var xy_config := TauXYConfig.new()
	xy_config.x_axis = x_axis
	xy_config.x_axis_id = TauPlot.AxisId.BOTTOM
	xy_config.panes = [pane_config]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot1.plot_xy(dataset, xy_config, bindings)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["A", "B"])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b])

	%TestPlot2.title = "Use TOP x-axis"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.tick_count_preferred = 20
	y_axis.inverted = true

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED

	var pane_config := TauPaneConfig.new()
	pane_config.y_left_axis = y_axis
	pane_config.overlays = [bar_config]
	pane_config.grid_line = grid_line_config

	var xy_config := TauXYConfig.new()
	xy_config.x_axis = x_axis
	xy_config.x_axis_id = TauPlot.AxisId.TOP
	xy_config.panes = [pane_config]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot2.plot_xy(dataset, xy_config, bindings)

####################################################################################################
# Test 3
####################################################################################################
func _setup_test_3() -> void:
	var series_names := PackedStringArray(["A", "B"])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b])

	%TestPlot3.title = "Use LEFT x-axis"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.tick_count_preferred = 20

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED

	var pane_config := TauPaneConfig.new()
	pane_config.y_bottom_axis = y_axis
	pane_config.overlays = [bar_config]
	pane_config.grid_line = grid_line_config

	var xy_config := TauXYConfig.new()
	xy_config.x_axis = x_axis
	xy_config.x_axis_id = TauPlot.AxisId.LEFT
	xy_config.panes = [pane_config]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.BOTTOM

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.BOTTOM

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot3.plot_xy(dataset, xy_config, bindings)

#####################################################################################################
## Test 4
#####################################################################################################

func _setup_test_4() -> void:
	var series_names := PackedStringArray(["A", "B"])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b])

	%TestPlot4.title = "Use RIGHT x-axis"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LINEAR
	y_axis.tick_count_preferred = 20
	y_axis.inverted = true

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.x_major_enabled = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED

	var pane_config := TauPaneConfig.new()
	pane_config.y_bottom_axis = y_axis
	pane_config.overlays = [bar_config]
	pane_config.grid_line = grid_line_config

	var xy_config := TauXYConfig.new()
	xy_config.x_axis = x_axis
	xy_config.x_axis_id = TauPlot.AxisId.RIGHT
	xy_config.panes = [pane_config]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.BOTTOM

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.BOTTOM

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot4.plot_xy(dataset, xy_config, bindings)
