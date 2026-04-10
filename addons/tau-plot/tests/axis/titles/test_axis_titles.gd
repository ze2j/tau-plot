@tool
extends Control

var _datasets: Array[TauPlot.Dataset] = []

func _ready() -> void:
	_setup_all_tests()

func _setup_all_tests() -> void:
	_datasets.clear()

	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	_setup_test_5()
	_setup_test_6()
	_setup_test_7()
	_setup_test_8()
	_setup_test_9()

####################################################################################################
# Shared data
####################################################################################################

const X_6: PackedFloat64Array = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0]

const Y_A: PackedFloat64Array = [1.0, 3.0, 2.0, 4.0, 1.5, 3.5]
const Y_B: PackedFloat64Array = [2.0, 1.5, 3.5, 1.0, 4.0, 2.5]
const Y_C: PackedFloat64Array = [50.0, 25.0, 10.0, 30.0, 20.0, 15.0]
const Y_D: PackedFloat64Array = [0.03, 0.05, 0.20, 0.15, 0.35, 0.01]

func _make_dataset() -> TauPlot.Dataset:
	var series_names := PackedStringArray(["A", "B", "C", "D"])
	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, X_6, [Y_A, Y_B, Y_C, Y_D])
	_datasets.append(dataset)
	return dataset

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	%TestPlot1.title = "X label: BEGIN"

	var dataset := _make_dataset()

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.tick_count_preferred = 6
	x_axis.title = "Shared X"
	x_axis.title_alignment = TauAxisConfig.TitleAlignment.BEGIN

	var left_0 := TauAxisConfig.new()
	left_0.type = TauAxisConfig.Type.CONTINUOUS

	var right_0 := TauAxisConfig.new()
	right_0.type = TauAxisConfig.Type.CONTINUOUS

	var left_1 := TauAxisConfig.new()
	left_1.type = TauAxisConfig.Type.CONTINUOUS

	var right_1 := TauAxisConfig.new()
	right_1.type = TauAxisConfig.Type.CONTINUOUS

	var pane_0 := TauPaneConfig.new()
	pane_0.y_left_axis = left_0
	pane_0.y_right_axis = right_0
	pane_0.overlays = [TauScatterConfig.new()]

	var pane_1 := TauPaneConfig.new()
	pane_1.y_left_axis = left_1
	pane_1.y_right_axis = right_1
	pane_1.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_0, pane_1]

	var sb_p0_left := TauXYSeriesBinding.new()
	sb_p0_left.series_id = dataset.get_series_id_by_index(0)
	sb_p0_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p0_left.pane_index = 0

	var sb_p0_right := TauXYSeriesBinding.new()
	sb_p0_right.series_id = dataset.get_series_id_by_index(1)
	sb_p0_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p0_right.pane_index = 0

	var sb_p1_left := TauXYSeriesBinding.new()
	sb_p1_left.series_id = dataset.get_series_id_by_index(2)
	sb_p1_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p1_left.pane_index = 1

	var sb_p1_right := TauXYSeriesBinding.new()
	sb_p1_right.series_id = dataset.get_series_id_by_index(3)
	sb_p1_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p1_right.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_p0_left, sb_p0_right, sb_p1_left, sb_p1_right]

	%TestPlot1.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	%TestPlot2.title = "X label: CENTER"

	var dataset := _make_dataset()

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.tick_count_preferred = 6
	x_axis.title = "Shared X"
	x_axis.title_alignment = TauAxisConfig.TitleAlignment.CENTER

	var left_0 := TauAxisConfig.new()
	left_0.type = TauAxisConfig.Type.CONTINUOUS

	var right_0 := TauAxisConfig.new()
	right_0.type = TauAxisConfig.Type.CONTINUOUS

	var left_1 := TauAxisConfig.new()
	left_1.type = TauAxisConfig.Type.CONTINUOUS

	var right_1 := TauAxisConfig.new()
	right_1.type = TauAxisConfig.Type.CONTINUOUS

	var pane_0 := TauPaneConfig.new()
	pane_0.y_left_axis = left_0
	pane_0.y_right_axis = right_0
	pane_0.overlays = [TauScatterConfig.new()]

	var pane_1 := TauPaneConfig.new()
	pane_1.y_left_axis = left_1
	pane_1.y_right_axis = right_1
	pane_1.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_0, pane_1]

	var sb_p0_left := TauXYSeriesBinding.new()
	sb_p0_left.series_id = dataset.get_series_id_by_index(0)
	sb_p0_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p0_left.pane_index = 0

	var sb_p0_right := TauXYSeriesBinding.new()
	sb_p0_right.series_id = dataset.get_series_id_by_index(1)
	sb_p0_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p0_right.pane_index = 0

	var sb_p1_left := TauXYSeriesBinding.new()
	sb_p1_left.series_id = dataset.get_series_id_by_index(2)
	sb_p1_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p1_left.pane_index = 1

	var sb_p1_right := TauXYSeriesBinding.new()
	sb_p1_right.series_id = dataset.get_series_id_by_index(3)
	sb_p1_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p1_right.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_p0_left, sb_p0_right, sb_p1_left, sb_p1_right]

	%TestPlot2.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	%TestPlot3.title = "X label: END"

	var dataset := _make_dataset()

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.tick_count_preferred = 6
	x_axis.title = "Shared X"
	x_axis.title_alignment = TauAxisConfig.TitleAlignment.END

	var left_0 := TauAxisConfig.new()
	left_0.type = TauAxisConfig.Type.CONTINUOUS

	var right_0 := TauAxisConfig.new()
	right_0.type = TauAxisConfig.Type.CONTINUOUS

	var left_1 := TauAxisConfig.new()
	left_1.type = TauAxisConfig.Type.CONTINUOUS

	var right_1 := TauAxisConfig.new()
	right_1.type = TauAxisConfig.Type.CONTINUOUS

	var pane_0 := TauPaneConfig.new()
	pane_0.y_left_axis = left_0
	pane_0.y_right_axis = right_0
	pane_0.overlays = [TauScatterConfig.new()]

	var pane_1 := TauPaneConfig.new()
	pane_1.y_left_axis = left_1
	pane_1.y_right_axis = right_1
	pane_1.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_0, pane_1]

	var sb_p0_left := TauXYSeriesBinding.new()
	sb_p0_left.series_id = dataset.get_series_id_by_index(0)
	sb_p0_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p0_left.pane_index = 0

	var sb_p0_right := TauXYSeriesBinding.new()
	sb_p0_right.series_id = dataset.get_series_id_by_index(1)
	sb_p0_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p0_right.pane_index = 0

	var sb_p1_left := TauXYSeriesBinding.new()
	sb_p1_left.series_id = dataset.get_series_id_by_index(2)
	sb_p1_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p1_left.pane_index = 1

	var sb_p1_right := TauXYSeriesBinding.new()
	sb_p1_right.series_id = dataset.get_series_id_by_index(3)
	sb_p1_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p1_right.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_p0_left, sb_p0_right, sb_p1_left, sb_p1_right]

	%TestPlot3.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	%TestPlot4.title = "Left Y labels: VERTICAL + BEGIN"

	var dataset := _make_dataset()

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.tick_count_preferred = 6

	var left_0 := TauAxisConfig.new()
	left_0.type = TauAxisConfig.Type.CONTINUOUS
	left_0.title = "Top Left"
	left_0.title_orientation = TauAxisConfig.TitleOrientation.VERTICAL
	left_0.title_alignment = TauAxisConfig.TitleAlignment.BEGIN

	var right_0 := TauAxisConfig.new()
	right_0.type = TauAxisConfig.Type.CONTINUOUS

	var left_1 := TauAxisConfig.new()
	left_1.type = TauAxisConfig.Type.CONTINUOUS
	left_1.title = "Bottom Left"
	left_1.title_orientation = TauAxisConfig.TitleOrientation.VERTICAL
	left_1.title_alignment = TauAxisConfig.TitleAlignment.BEGIN

	var right_1 := TauAxisConfig.new()
	right_1.type = TauAxisConfig.Type.CONTINUOUS

	var pane_0 := TauPaneConfig.new()
	pane_0.y_left_axis = left_0
	pane_0.y_right_axis = right_0
	pane_0.overlays = [TauScatterConfig.new()]

	var pane_1 := TauPaneConfig.new()
	pane_1.y_left_axis = left_1
	pane_1.y_right_axis = right_1
	pane_1.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_0, pane_1]

	var sb_p0_left := TauXYSeriesBinding.new()
	sb_p0_left.series_id = dataset.get_series_id_by_index(0)
	sb_p0_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p0_left.pane_index = 0

	var sb_p0_right := TauXYSeriesBinding.new()
	sb_p0_right.series_id = dataset.get_series_id_by_index(1)
	sb_p0_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p0_right.pane_index = 0

	var sb_p1_left := TauXYSeriesBinding.new()
	sb_p1_left.series_id = dataset.get_series_id_by_index(2)
	sb_p1_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p1_left.pane_index = 1

	var sb_p1_right := TauXYSeriesBinding.new()
	sb_p1_right.series_id = dataset.get_series_id_by_index(3)
	sb_p1_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p1_right.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_p0_left, sb_p0_right, sb_p1_left, sb_p1_right]

	%TestPlot4.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	%TestPlot5.title = "Left Y labels: VERTICAL + CENTER"

	var dataset := _make_dataset()

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.tick_count_preferred = 6

	var left_0 := TauAxisConfig.new()
	left_0.type = TauAxisConfig.Type.CONTINUOUS
	left_0.title = "Top Left"
	left_0.title_orientation = TauAxisConfig.TitleOrientation.VERTICAL
	left_0.title_alignment = TauAxisConfig.TitleAlignment.CENTER

	var right_0 := TauAxisConfig.new()
	right_0.type = TauAxisConfig.Type.CONTINUOUS

	var left_1 := TauAxisConfig.new()
	left_1.type = TauAxisConfig.Type.CONTINUOUS
	left_1.title = "Bottom Left"
	left_1.title_orientation = TauAxisConfig.TitleOrientation.VERTICAL
	left_1.title_alignment = TauAxisConfig.TitleAlignment.CENTER

	var right_1 := TauAxisConfig.new()
	right_1.type = TauAxisConfig.Type.CONTINUOUS

	var pane_0 := TauPaneConfig.new()
	pane_0.y_left_axis = left_0
	pane_0.y_right_axis = right_0
	pane_0.overlays = [TauScatterConfig.new()]

	var pane_1 := TauPaneConfig.new()
	pane_1.y_left_axis = left_1
	pane_1.y_right_axis = right_1
	pane_1.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_0, pane_1]

	var sb_p0_left := TauXYSeriesBinding.new()
	sb_p0_left.series_id = dataset.get_series_id_by_index(0)
	sb_p0_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p0_left.pane_index = 0

	var sb_p0_right := TauXYSeriesBinding.new()
	sb_p0_right.series_id = dataset.get_series_id_by_index(1)
	sb_p0_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p0_right.pane_index = 0

	var sb_p1_left := TauXYSeriesBinding.new()
	sb_p1_left.series_id = dataset.get_series_id_by_index(2)
	sb_p1_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p1_left.pane_index = 1

	var sb_p1_right := TauXYSeriesBinding.new()
	sb_p1_right.series_id = dataset.get_series_id_by_index(3)
	sb_p1_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p1_right.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_p0_left, sb_p0_right, sb_p1_left, sb_p1_right]

	%TestPlot5.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	%TestPlot6.title = "Left Y labels: VERTICAL + END"

	var dataset := _make_dataset()

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.tick_count_preferred = 6

	var left_0 := TauAxisConfig.new()
	left_0.type = TauAxisConfig.Type.CONTINUOUS
	left_0.title = "Top Left"
	left_0.title_orientation = TauAxisConfig.TitleOrientation.VERTICAL
	left_0.title_alignment = TauAxisConfig.TitleAlignment.END

	var right_0 := TauAxisConfig.new()
	right_0.type = TauAxisConfig.Type.CONTINUOUS

	var left_1 := TauAxisConfig.new()
	left_1.type = TauAxisConfig.Type.CONTINUOUS
	left_1.title = "Bottom Left"
	left_1.title_orientation = TauAxisConfig.TitleOrientation.VERTICAL
	left_1.title_alignment = TauAxisConfig.TitleAlignment.END

	var right_1 := TauAxisConfig.new()
	right_1.type = TauAxisConfig.Type.CONTINUOUS

	var pane_0 := TauPaneConfig.new()
	pane_0.y_left_axis = left_0
	pane_0.y_right_axis = right_0
	pane_0.overlays = [TauScatterConfig.new()]

	var pane_1 := TauPaneConfig.new()
	pane_1.y_left_axis = left_1
	pane_1.y_right_axis = right_1
	pane_1.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_0, pane_1]

	var sb_p0_left := TauXYSeriesBinding.new()
	sb_p0_left.series_id = dataset.get_series_id_by_index(0)
	sb_p0_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p0_left.pane_index = 0

	var sb_p0_right := TauXYSeriesBinding.new()
	sb_p0_right.series_id = dataset.get_series_id_by_index(1)
	sb_p0_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p0_right.pane_index = 0

	var sb_p1_left := TauXYSeriesBinding.new()
	sb_p1_left.series_id = dataset.get_series_id_by_index(2)
	sb_p1_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p1_left.pane_index = 1

	var sb_p1_right := TauXYSeriesBinding.new()
	sb_p1_right.series_id = dataset.get_series_id_by_index(3)
	sb_p1_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p1_right.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_p0_left, sb_p0_right, sb_p1_left, sb_p1_right]

	%TestPlot6.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	%TestPlot7.title = "Right Y labels: VERTICAL + BEGIN"

	var dataset := _make_dataset()

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.tick_count_preferred = 6

	var left_0 := TauAxisConfig.new()
	left_0.type = TauAxisConfig.Type.CONTINUOUS

	var right_0 := TauAxisConfig.new()
	right_0.type = TauAxisConfig.Type.CONTINUOUS
	right_0.title = "Top Right"
	right_0.title_orientation = TauAxisConfig.TitleOrientation.VERTICAL
	right_0.title_alignment = TauAxisConfig.TitleAlignment.BEGIN

	var left_1 := TauAxisConfig.new()
	left_1.type = TauAxisConfig.Type.CONTINUOUS

	var right_1 := TauAxisConfig.new()
	right_1.type = TauAxisConfig.Type.CONTINUOUS
	right_1.title = "Bottom Right"
	right_1.title_orientation = TauAxisConfig.TitleOrientation.VERTICAL
	right_1.title_alignment = TauAxisConfig.TitleAlignment.BEGIN

	var pane_0 := TauPaneConfig.new()
	pane_0.y_left_axis = left_0
	pane_0.y_right_axis = right_0
	pane_0.overlays = [TauScatterConfig.new()]

	var pane_1 := TauPaneConfig.new()
	pane_1.y_left_axis = left_1
	pane_1.y_right_axis = right_1
	pane_1.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_0, pane_1]

	var sb_p0_left := TauXYSeriesBinding.new()
	sb_p0_left.series_id = dataset.get_series_id_by_index(0)
	sb_p0_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p0_left.pane_index = 0

	var sb_p0_right := TauXYSeriesBinding.new()
	sb_p0_right.series_id = dataset.get_series_id_by_index(1)
	sb_p0_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p0_right.pane_index = 0

	var sb_p1_left := TauXYSeriesBinding.new()
	sb_p1_left.series_id = dataset.get_series_id_by_index(2)
	sb_p1_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p1_left.pane_index = 1

	var sb_p1_right := TauXYSeriesBinding.new()
	sb_p1_right.series_id = dataset.get_series_id_by_index(3)
	sb_p1_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p1_right.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_p0_left, sb_p0_right, sb_p1_left, sb_p1_right]

	%TestPlot7.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8() -> void:
	%TestPlot8.title = "Right Y labels: VERTICAL + CENTER"

	var dataset := _make_dataset()

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.tick_count_preferred = 6

	var left_0 := TauAxisConfig.new()
	left_0.type = TauAxisConfig.Type.CONTINUOUS

	var right_0 := TauAxisConfig.new()
	right_0.type = TauAxisConfig.Type.CONTINUOUS
	right_0.title = "Top Right"
	right_0.title_orientation = TauAxisConfig.TitleOrientation.VERTICAL
	right_0.title_alignment = TauAxisConfig.TitleAlignment.CENTER

	var left_1 := TauAxisConfig.new()
	left_1.type = TauAxisConfig.Type.CONTINUOUS

	var right_1 := TauAxisConfig.new()
	right_1.type = TauAxisConfig.Type.CONTINUOUS
	right_1.title = "Bottom Right"
	right_1.title_orientation = TauAxisConfig.TitleOrientation.VERTICAL
	right_1.title_alignment = TauAxisConfig.TitleAlignment.CENTER

	var pane_0 := TauPaneConfig.new()
	pane_0.y_left_axis = left_0
	pane_0.y_right_axis = right_0
	pane_0.overlays = [TauScatterConfig.new()]

	var pane_1 := TauPaneConfig.new()
	pane_1.y_left_axis = left_1
	pane_1.y_right_axis = right_1
	pane_1.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_0, pane_1]

	var sb_p0_left := TauXYSeriesBinding.new()
	sb_p0_left.series_id = dataset.get_series_id_by_index(0)
	sb_p0_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p0_left.pane_index = 0

	var sb_p0_right := TauXYSeriesBinding.new()
	sb_p0_right.series_id = dataset.get_series_id_by_index(1)
	sb_p0_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p0_right.pane_index = 0

	var sb_p1_left := TauXYSeriesBinding.new()
	sb_p1_left.series_id = dataset.get_series_id_by_index(2)
	sb_p1_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p1_left.pane_index = 1

	var sb_p1_right := TauXYSeriesBinding.new()
	sb_p1_right.series_id = dataset.get_series_id_by_index(3)
	sb_p1_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p1_right.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_p0_left, sb_p0_right, sb_p1_left, sb_p1_right]

	%TestPlot8.plot_xy(dataset, config, bindings)

####################################################################################################
# Test 9
####################################################################################################

func _setup_test_9() -> void:
	%TestPlot9.title = "Right Y labels: VERTICAL + END"

	var dataset := _make_dataset()

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.tick_count_preferred = 6

	var left_0 := TauAxisConfig.new()
	left_0.type = TauAxisConfig.Type.CONTINUOUS

	var right_0 := TauAxisConfig.new()
	right_0.type = TauAxisConfig.Type.CONTINUOUS
	right_0.title = "Top Right"
	right_0.title_orientation = TauAxisConfig.TitleOrientation.VERTICAL
	right_0.title_alignment = TauAxisConfig.TitleAlignment.END

	var left_1 := TauAxisConfig.new()
	left_1.type = TauAxisConfig.Type.CONTINUOUS

	var right_1 := TauAxisConfig.new()
	right_1.type = TauAxisConfig.Type.CONTINUOUS
	right_1.title = "Bottom Right"
	right_1.title_orientation = TauAxisConfig.TitleOrientation.VERTICAL
	right_1.title_alignment = TauAxisConfig.TitleAlignment.END

	var pane_0 := TauPaneConfig.new()
	pane_0.y_left_axis = left_0
	pane_0.y_right_axis = right_0
	pane_0.overlays = [TauScatterConfig.new()]

	var pane_1 := TauPaneConfig.new()
	pane_1.y_left_axis = left_1
	pane_1.y_right_axis = right_1
	pane_1.overlays = [TauScatterConfig.new()]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane_0, pane_1]

	var sb_p0_left := TauXYSeriesBinding.new()
	sb_p0_left.series_id = dataset.get_series_id_by_index(0)
	sb_p0_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p0_left.pane_index = 0

	var sb_p0_right := TauXYSeriesBinding.new()
	sb_p0_right.series_id = dataset.get_series_id_by_index(1)
	sb_p0_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p0_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p0_right.pane_index = 0

	var sb_p1_left := TauXYSeriesBinding.new()
	sb_p1_left.series_id = dataset.get_series_id_by_index(2)
	sb_p1_left.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_left.y_axis_id = TauPlot.AxisId.LEFT
	sb_p1_left.pane_index = 1

	var sb_p1_right := TauXYSeriesBinding.new()
	sb_p1_right.series_id = dataset.get_series_id_by_index(3)
	sb_p1_right.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	sb_p1_right.y_axis_id = TauPlot.AxisId.RIGHT
	sb_p1_right.pane_index = 1

	var bindings: Array[TauXYSeriesBinding] = [sb_p0_left, sb_p0_right, sb_p1_left, sb_p1_right]

	%TestPlot9.plot_xy(dataset, config, bindings)
