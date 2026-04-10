@tool
extends Control

const THEME_10_0 = preload("res://addons/tau-plot/tests/bar/bar_width/theme_width_10_gap_0.tres")
const THEME_30_0 = preload("res://addons/tau-plot/tests/bar/bar_width/theme_width_30_gap_0.tres")
const THEME_30_10 = preload("res://addons/tau-plot/tests/bar/bar_width/theme_width_30_gap_10.tres")

const THEME_10_0_INDEX = 0
const THEME_30_0_INDEX = 1
const THEME_30_10_INDEX = 2

var themes := [THEME_10_0, THEME_30_0, THEME_30_10]

var _timer: Timer = null
var _t: float = 0.0

var _datasets: Array[TauPlot.Dataset] = []
var _state: Array[Dictionary] = []

func _ready() -> void:
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
	_setup_test_8()

func _on_tick() -> void:
	_t += _timer.wait_time

	_step_test_1()
	_step_test_2()
	_step_test_3()
	_step_test_4()
	_step_test_5()
	_step_test_6()
	_step_test_7()
	_step_test_8()

####################################################################################################
# Test 1
####################################################################################################

func _setup_test_1() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.0, 1.0, 1.5, 3.0, 4.5, 6.0])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot1.title = "[Policy = THEME][LINEAR] Toggle themes every 1s with bar_width_px = 10 and 30"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 13

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.THEME

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

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot1.plot_xy(dataset, config, bindings)

	_state.append(
		{
			"plot": %TestPlot1,
			"time_since_step_s": 0.0,
			"step_period_s": 1.0,
			"theme_index": THEME_10_0_INDEX
		}
	)

func _step_test_1() -> void:
	var st := _state[0]
	var plot: Control = st["plot"]

	st["time_since_step_s"] = float(st["time_since_step_s"]) + _timer.wait_time
	if float(st["time_since_step_s"]) >= float(st["step_period_s"]):
		st["time_since_step_s"] = 0.0
		var theme_index: int = st["theme_index"]
		theme_index = 1 - theme_index
		plot.theme = themes[theme_index]
		st["theme_index"] = theme_index

####################################################################################################
# Test 2
####################################################################################################

func _setup_test_2() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x.size())
	y_b.resize(x.size())
	for i in range(x.size()):
		y_a[i] = 5.0 + 3.0 * sin(float(i) * 0.5)
		y_b[i] = 5.0 + 2.0 * sin(float(i) * 0.4)

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot2.title = "[Policy = THEME][LOGARITHMIC] Toggle themes every 1s with bar_width_px = 10 and 30"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.THEME

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

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot2.plot_xy(dataset, config, bindings)

	_state.append(
		{
			"plot": %TestPlot2,
			"time_since_step_s": 0.0,
			"step_period_s": 1.0,
			"theme_index": THEME_10_0_INDEX
		}
	)

func _step_test_2() -> void:
	var st := _state[1]
	var plot: Control = st["plot"]

	st["time_since_step_s"] = float(st["time_since_step_s"]) + _timer.wait_time
	if float(st["time_since_step_s"]) >= float(st["step_period_s"]):
		st["time_since_step_s"] = 0.0
		var theme_index: int = st["theme_index"]
		theme_index =  1 - theme_index
		plot.theme = themes[theme_index]
		st["theme_index"] = theme_index

####################################################################################################
# Test 3
####################################################################################################

func _setup_test_3() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.0, 1.0, 1.5, 3.0, 4.5, 6.0])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot3.title = "[Policy = THEME][LINEAR] Toggle themes every 1s with bar_intragroup_gap_px = 0 and 10"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 13

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.THEME

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

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot3.plot_xy(dataset, config, bindings)

	_state.append(
		{
			"plot": %TestPlot3,
			"time_since_step_s": 0.0,
			"step_period_s": 1.0,
			"theme_index": THEME_30_0_INDEX
		}
	)

func _step_test_3() -> void:
	var st := _state[2]
	var plot: Control = st["plot"]

	st["time_since_step_s"] = float(st["time_since_step_s"]) + _timer.wait_time
	if float(st["time_since_step_s"]) >= float(st["step_period_s"]):
		st["time_since_step_s"] = 0.0
		var theme_index: int = st["theme_index"]
		theme_index = 3 - theme_index
		plot.theme = themes[theme_index]
		st["theme_index"] = theme_index

####################################################################################################
# Test 4
####################################################################################################

func _setup_test_4() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x.size())
	y_b.resize(x.size())
	for i in range(x.size()):
		y_a[i] = 5.0 + 3.0 * sin(float(i) * 0.5)
		y_b[i] = 5.0 + 2.0 * sin(float(i) * 0.4)

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot4.title = "[Policy = THEME][LOGARITHMIC] Toggle themes every 1s with bar_intragroup_gap_px = 0 and 10"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.THEME

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

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot4.plot_xy(dataset, config, bindings)

	_state.append(
		{
			"plot": %TestPlot4,
			"time_since_step_s": 0.0,
			"step_period_s": 1.0,
			"theme_index": THEME_30_0_INDEX
		}
	)

func _step_test_4() -> void:
	var st := _state[3]
	var plot: Control = st["plot"]

	st["time_since_step_s"] = float(st["time_since_step_s"]) + _timer.wait_time
	if float(st["time_since_step_s"]) >= float(st["step_period_s"]):
		st["time_since_step_s"] = 0.0
		var theme_index: int = st["theme_index"]
		theme_index =  3 - theme_index
		plot.theme = themes[theme_index]
		st["theme_index"] = theme_index

####################################################################################################
# Test 5
####################################################################################################

func _setup_test_5() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.0, 1.0, 1.5, 3.0, 4.5, 6.0])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot5.title = "[Policy = THEME][LINEAR] Override bar_width_px [0, 50]"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 13

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.THEME
	bar_config.style.bar_width_px = 25 # Overriden

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

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot5.plot_xy(dataset, config, bindings)
	%TestPlot5.theme = themes[THEME_10_0_INDEX]

	_state.append(
		{
			"plot": %TestPlot5,
			"bar_config": bar_config
		}
	)

func _step_test_5() -> void:
	var st := _state[4]
	var plot: Control = st["plot"]
	var bar_config: TauBarConfig = st["bar_config"]

	var animated_value := int(clampf(25.0 + 25.0 * sin(_t * 0.7), 0.0, 50.0))
	bar_config.style.bar_width_px = animated_value
	plot.refresh_now()

####################################################################################################
# Test 6
####################################################################################################

func _setup_test_6() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x.size())
	y_b.resize(x.size())
	for i in range(x.size()):
		y_a[i] = 5.0 + 3.0 * sin(float(i) * 0.5)
		y_b[i] = 5.0 + 2.0 * sin(float(i) * 0.4)

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot6.title = "[Policy = THEME][LOGARITHMIC] Override bar_width_px [0, 50]"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.THEME
	bar_config.style.bar_width_px = 25 # Overriden

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

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot6.plot_xy(dataset, config, bindings)
	%TestPlot6.theme = themes[THEME_10_0_INDEX]

	_state.append(
		{
			"plot": %TestPlot6,
			"bar_config": bar_config
		}
	)

func _step_test_6() -> void:
	var st := _state[5]
	var plot: Control = st["plot"]
	var bar_config: TauBarConfig = st["bar_config"]

	var animated_value := int(clampf(25.0 + 25.0 * sin(_t * 0.7), 0.0, 50.0))
	bar_config.style.bar_width_px = animated_value
	plot.refresh_now()

####################################################################################################
# Test 7
####################################################################################################

func _setup_test_7() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.0, 1.0, 1.5, 3.0, 4.5, 6.0])
	var y_a := PackedFloat64Array([1.0, 2.0, 1.4, 2.2, 1.1, 1.8])
	var y_b := PackedFloat64Array([1.5, 1.0, 1.6, 2.4, 0.5, 1.2])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot7.title = "[Policy = THEME][LINEAR] Override bar_intragroup_gap_px [0, 50] with width = 50 px"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LINEAR
	x_axis.tick_count_preferred = 13

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.THEME
	bar_config.style.bar_width_px = 50 # Overriden
	bar_config.style.bar_intragroup_gap_px = 25 # Overriden

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

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot7.plot_xy(dataset, config, bindings)

	_state.append(
		{
			"plot": %TestPlot7,
			"bar_config": bar_config
		}
	)

func _step_test_7() -> void:
	var st := _state[6]
	var plot: Control = st["plot"]
	var bar_config: TauBarConfig = st["bar_config"]

	var animated_value := int(clampf(25.0 + 25.0 * sin(_t * 0.7), 0.0, 50.0))
	bar_config.style.bar_intragroup_gap_px = animated_value
	plot.refresh_now()

####################################################################################################
# Test 8
####################################################################################################

func _setup_test_8() -> void:
	var series_names := PackedStringArray(["A", "B"])
	var x := PackedFloat64Array([0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0, 500.0, 1000.0])

	var y_a := PackedFloat64Array()
	var y_b := PackedFloat64Array()
	y_a.resize(x.size())
	y_b.resize(x.size())
	for i in range(x.size()):
		y_a[i] = 5.0 + 3.0 * sin(float(i) * 0.5)
		y_b[i] = 5.0 + 2.0 * sin(float(i) * 0.4)

	var dataset := TauPlot.Dataset.make_shared_x_continuous(series_names, x, [y_a, y_b])
	_datasets.append(dataset)

	%TestPlot8.title = "[Policy = THEME][LOGARITHMIC] Override bar_intragroup_gap_px [0, 50] with width = 10 px"

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.scale = TauAxisConfig.Scale.LOGARITHMIC

	var left_axis := TauAxisConfig.new()
	left_axis.type = TauAxisConfig.Type.CONTINUOUS
	left_axis.scale = TauAxisConfig.Scale.LINEAR
	left_axis.include_zero_in_domain = true

	var bar_config := TauBarConfig.new()
	bar_config.mode = TauBarConfig.BarMode.GROUPED
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.THEME
	bar_config.style.bar_width_px = 10 # Overriden
	bar_config.style.bar_intragroup_gap_px = 25 # Overriden

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

	var sb_b := TauXYSeriesBinding.new()
	sb_b.series_id = dataset.get_series_id_by_index(1)
	sb_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	sb_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [sb_a, sb_b]

	%TestPlot8.plot_xy(dataset, config, bindings)

	_state.append(
		{
			"plot": %TestPlot8,
			"bar_config": bar_config
		}
	)

func _step_test_8() -> void:
	var st := _state[7]
	var plot: Control = st["plot"]
	var bar_config: TauBarConfig = st["bar_config"]

	var animated_value := int(clampf(25.0 + 25.0 * sin(_t * 0.7), 0.0, 50.0))
	bar_config.style.bar_intragroup_gap_px = animated_value
	plot.refresh_now()
