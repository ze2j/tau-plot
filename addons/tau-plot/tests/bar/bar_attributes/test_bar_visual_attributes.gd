@tool
extends Control

var _timer: Timer = null
var _t: float = 0.0

var _datasets: Array[TauPlot.Dataset] = []
var _state: Array[Dictionary] = []

var _gradient: Gradient = null


func _ready() -> void:
	_gradient = Gradient.new()
	_gradient.offsets = PackedFloat32Array([
		0.0,
		0.25,
		0.5,
		0.75,
		1.0
	])
	_gradient.colors = PackedColorArray([
		Color("e5007d"),
		Color("ca2c88"),
		Color("ab3e8f"),
		Color("874996"),
		Color("5e4e9c"),
	])
	_create_timer()
	_setup_all_tests()
	_timer.start()


func _create_timer() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = 0.016
	_timer.timeout.connect(_on_tick)
	add_child(_timer)


func _setup_all_tests() -> void:
	_datasets.clear()
	_state.clear()

	_setup_test_1()
	_setup_test_2()
	_setup_test_3()
	_setup_test_4()
	_setup_test_5()
	_setup_test_6()
	_setup_test_7()



func _on_tick() -> void:
	_t += _timer.wait_time

	#_step_test_1()
	#_step_test_2()
	#_step_test_3()
	#_step_test_4()
	#_step_test_5()
	#_step_test_6()
	_step_test_7()


####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedStringArray(["C1", "C2", "C3", "C4", "C5", "C6"])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot1.title = "[GROUPED] A: first two of six samples pure blue, B: last two of four pure red, others use default colors."

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION
	bar_config.category_width_fraction = 0.5
	bar_config.intra_group_gap_fraction = 0.0

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT
	var color_buffer_a = TauPlot.VisualAttributes.ColorBuffer.new(x.size())
	color_buffer_a.append_values([Color(0.0, 0.0, 1.0), Color(0.0, 0.0, 1.0)])
	var visual_attributes_a := TauPlot.BarVisualAttributes.new()
	visual_attributes_a.color_buffer = color_buffer_a
	sb_a.visual_attributes = visual_attributes_a

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT
	var color_buffer_b = TauPlot.VisualAttributes.ColorBuffer.new(x.size())
	color_buffer_b.append_values([TauPlot.VisualAttributes.ColorBuffer.NO_COLOR,
								TauPlot.VisualAttributes.ColorBuffer.NO_COLOR,
								TauPlot.VisualAttributes.ColorBuffer.NO_COLOR,
								TauPlot.VisualAttributes.ColorBuffer.NO_COLOR,
								Color(1.0, 0.0, 0.0), Color(1.0, 0.0, 0.0)])
	var visual_attributes_b := TauPlot.BarVisualAttributes.new()
	visual_attributes_b.color_buffer = color_buffer_b
	sb_b.visual_attributes = visual_attributes_b

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot1.plot_xy(dataset, config, bindings)
	_state.append({})


####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedStringArray(["C1", "C2", "C3", "C4", "C5", "C6"])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot2.title = "[STACKED] A: first two of six samples pure blue, B: last two of four pure red, others use default colors."

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.STACKED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION
	bar_config.category_width_fraction = 0.5

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT
	var color_buffer_a = TauPlot.VisualAttributes.ColorBuffer.new(x.size())
	color_buffer_a.append_values([Color(0.0, 0.0, 1.0), Color(0.0, 0.0, 1.0)])
	var visual_attributes_a := TauPlot.BarVisualAttributes.new()
	visual_attributes_a.color_buffer = color_buffer_a
	sb_a.visual_attributes = visual_attributes_a

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT
	var color_buffer_b = TauPlot.VisualAttributes.ColorBuffer.new(x.size())
	color_buffer_b.append_values([TauPlot.VisualAttributes.ColorBuffer.NO_COLOR,
								TauPlot.VisualAttributes.ColorBuffer.NO_COLOR,
								TauPlot.VisualAttributes.ColorBuffer.NO_COLOR,
								TauPlot.VisualAttributes.ColorBuffer.NO_COLOR,
								Color(1.0, 0.0, 0.0), Color(1.0, 0.0, 0.0)])
	var visual_attributes_b := TauPlot.BarVisualAttributes.new()
	visual_attributes_b.color_buffer = color_buffer_b
	sb_b.visual_attributes = visual_attributes_b

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot2.plot_xy(dataset, config, bindings)
	_state.append({})

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
	var x_b := PackedFloat64Array([1.6, 3.2, 4.8, 6.4])

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())

	for i in range(x_a.size()):
		y_a[i] = 0.1 * pow(10.0, float(i) * 0.4)
	for i in range(x_b.size()):
		y_b[i] = 0.05 * pow(10.0, float(i) * 0.4)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot3.title = "[INDEPENDENT] A: first two of six samples pure blue, B: last two of four pure red, others use default colors."

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	left_axis.include_zero_in_domain = false

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT
	var color_buffer_a = TauPlot.VisualAttributes.ColorBuffer.new(x_a.size())
	color_buffer_a.append_values([Color(0.0, 0.0, 1.0), Color(0.0, 0.0, 1.0)])
	var visual_attributes_a := TauPlot.BarVisualAttributes.new()
	visual_attributes_a.color_buffer = color_buffer_a
	sb_a.visual_attributes = visual_attributes_a

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT
	var color_buffer_b = TauPlot.VisualAttributes.ColorBuffer.new(x_b.size())
	color_buffer_b.append_values([TauPlot.VisualAttributes.ColorBuffer.NO_COLOR,
								TauPlot.VisualAttributes.ColorBuffer.NO_COLOR,
								TauPlot.VisualAttributes.ColorBuffer.NO_COLOR,
								TauPlot.VisualAttributes.ColorBuffer.NO_COLOR,
								Color(1.0, 0.0, 0.0), Color(1.0, 0.0, 0.0)])
	var visual_attributes_b := TauPlot.BarVisualAttributes.new()
	visual_attributes_b.color_buffer = color_buffer_b
	sb_b.visual_attributes = visual_attributes_b

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot3.plot_xy(dataset, config, bindings)
	_state.append({})


####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedStringArray(["C1", "C2", "C3", "C4", "C5", "C6"])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot4.title = "[GROUPED] A: first two samples nearly transparent, B: last two half-transparent, others use default colors."

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION
	bar_config.category_width_fraction = 0.5
	bar_config.intra_group_gap_fraction = 0.0

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT
	var alpha_buffer_a = TauPlot.VisualAttributes.AlphaBuffer.new(x.size())
	alpha_buffer_a.append_values([0.2, 0.2])
	var visual_attributes_a := TauPlot.BarVisualAttributes.new()
	visual_attributes_a.alpha_buffer = alpha_buffer_a
	sb_a.visual_attributes = visual_attributes_a

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT
	var alpha_buffer_b = TauPlot.VisualAttributes.AlphaBuffer.new(x.size())
	alpha_buffer_b.append_values([-1.0, -1.0, -1.0, -1.0, 0.5, 0.5])
	var visual_attributes_b := TauPlot.BarVisualAttributes.new()
	visual_attributes_b.alpha_buffer = alpha_buffer_b
	sb_b.visual_attributes = visual_attributes_b

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot4.plot_xy(dataset, config, bindings)
	_state.append({})


####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedStringArray(["C1", "C2", "C3", "C4", "C5", "C6"])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot5.title = "[STACKED] A: first two samples nearly transparent, B: last two half-transparent, others use default colors."

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.SKIP_LABELS

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.STACKED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION
	bar_config.category_width_fraction = 0.5

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT
	var alpha_buffer_a = TauPlot.VisualAttributes.AlphaBuffer.new(x.size())
	alpha_buffer_a.append_values([0.2, 0.2])
	var visual_attributes_a := TauPlot.BarVisualAttributes.new()
	visual_attributes_a.alpha_buffer = alpha_buffer_a
	sb_a.visual_attributes = visual_attributes_a

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT
	var alpha_buffer_b = TauPlot.VisualAttributes.AlphaBuffer.new(x.size())
	alpha_buffer_b.append_values([-1.0, -1.0, -1.0, -1.0, 0.5, 0.5])
	var visual_attributes_b := TauPlot.BarVisualAttributes.new()
	visual_attributes_b.alpha_buffer = alpha_buffer_b
	sb_b.visual_attributes = visual_attributes_b

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot5.plot_xy(dataset, config, bindings)
	_state.append({})

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	var series_names := PackedStringArray(["Series A", "Series B"])
	var x_a := PackedFloat64Array([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
	var x_b := PackedFloat64Array([1.6, 3.2, 4.8, 6.4])

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x_a.size())
	y_b.resize(x_b.size())

	for i in range(x_a.size()):
		y_a[i] = 0.1 * pow(10.0, float(i) * 0.4)
	for i in range(x_b.size()):
		y_b[i] = 0.05 * pow(10.0, float(i) * 0.4)

	var dataset := TauPlot.Dataset.make_per_series_x_continuous(series_names, [x_a, x_b], [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot6.title = "[INDEPENDENT] A: first two samples nearly transparent, B: last two half-transparent, others use default colors."

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	left_axis.include_zero_in_domain = false

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.INDEPENDENT
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT
	var alpha_buffer_a = TauPlot.VisualAttributes.AlphaBuffer.new(x_a.size())
	alpha_buffer_a.append_values([0.2, 0.2])
	var visual_attributes_a := TauPlot.BarVisualAttributes.new()
	visual_attributes_a.alpha_buffer = alpha_buffer_a
	sb_a.visual_attributes = visual_attributes_a

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT
	var alpha_buffer_b = TauPlot.VisualAttributes.AlphaBuffer.new(x_b.size())
	alpha_buffer_b.append_values([-1.0, -1.0, 0.5, 0.5])
	var visual_attributes_b := TauPlot.BarVisualAttributes.new()
	visual_attributes_b.alpha_buffer = alpha_buffer_b
	sb_b.visual_attributes = visual_attributes_b

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot6.plot_xy(dataset, config, bindings)
	_state.append({})

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	var series_names := PackedStringArray(["Stream"])
	var x := PackedFloat64Array()
	var y := PackedFloat64Array()

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y], 32)
	_datasets.append(dataset)

	%TestPlot7.title = "Streaming - New sample and new color every 16 ms"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true
	left_axis.range_override_enabled = true
	left_axis.min_override = 0.0
	left_axis.max_override = 6.0

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED

	var pane := TauPaneConfig.new()
	pane.y_left_axis = left_axis
	pane.overlays = [bar_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var sb_a := TauXYSeriesBinding.new()
	sb_a.series_id = dataset.get_series_id_by_index(0)
	sb_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_a.y_axis_id = TauPlot.AxisId.LEFT
	var visual_attributes_a := TauPlot.BarVisualAttributes.new()
	visual_attributes_a.color_buffer = TauPlot.VisualAttributes.ColorBuffer.new(dataset.get_shared_capacity())
	sb_a.visual_attributes = visual_attributes_a

	var bindings: Array[TauXYSeriesBinding] = [sb_a]

	%TestPlot7.plot_xy(dataset, config, bindings)

	_state.append({
		"plot": %TestPlot7,
		"next_x": 0.0,
		"time_since_append_s": 0.0,
		"append_period_s": 0.016,
		"attributes": visual_attributes_a
	})


func _step_test_7() -> void:
	var dataset := _datasets[6]
	var st := _state[6]
	var plot: TauPlot = st["plot"]

	st["time_since_append_s"] = float(st["time_since_append_s"]) + _timer.wait_time
	if float(st["time_since_append_s"]) < float(st["append_period_s"]):
		return
	st["time_since_append_s"] = 0.0

	var x := float(st["next_x"])
	st["next_x"] = x + 0.2

	var ys := PackedFloat64Array([
		4.0 + 2.0 * sin(3.2 * _t),
	])

	dataset.append_shared_sample(x, ys)
	var attributes: TauPlot.BarVisualAttributes = st["attributes"]
	attributes.color_buffer.append_value(_gradient.sample(fmod(3.2 * _t, 1.0)))
