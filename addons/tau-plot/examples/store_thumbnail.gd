extends CenterContainer

func _ready() -> void:
	var series_names := PackedStringArray(["Nothing"])

	# TODO: add and use TauAxisConfig.tick_labels_enabled instead
	var x := PackedStringArray(["", "", "", "", ""])
	var y := PackedFloat64Array([0.1, 0.3, 0.47, 0.63, 0.75])

	var dataset := TauPlot.Dataset.make_shared_x_categorical(series_names, x, [y])

	$TauPlot.legend_enabled = false

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL

	var y_axis := TauAxisConfig.new()
	y_axis.title = ""
	y_axis.range_override_enabled = true
	y_axis.min_override = 0.0
	y_axis.max_override = 0.8
	# TODO: add and use TauAxisConfig.tick_labels_enabled instead
	y_axis.format_tick_label = func(label: String) -> String:
		return ""

	var bar_config := TauBarConfig.new()
	bar_config.bar_width_policy = TauBarConfig.BarWidthPolicy.CATEGORY_WIDTH_FRACTION
	bar_config.category_width_fraction = 0.7

	var grid_line_config: TauGridLineConfig = TauGridLineConfig.new()
	grid_line_config.y_major_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_config]
	pane.grid_line = grid_line_config

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var color_buffer = TauPlot.VisualAttributes.ColorBuffer.new(x.size())
	color_buffer.append_values([Color("1f2d91ff"), Color("83abc0ff"), Color("f2e8afff"), Color("f3753dff"), Color("f43c23ff")])

	var visual_attributes := TauPlot.BarVisualAttributes.new()
	visual_attributes.color_buffer = color_buffer

	var b0 := TauXYSeriesBinding.new()
	b0.series_id = dataset.get_series_id_by_index(0)
	b0.pane_index = 0
	b0.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	b0.y_axis_id = TauPlot.AxisId.LEFT
	b0.visual_attributes = visual_attributes

	var bindings: Array[TauXYSeriesBinding] = [b0]

	$TauPlot.plot_xy(dataset, config, bindings)
