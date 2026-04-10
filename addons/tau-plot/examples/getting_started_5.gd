extends CenterContainer

func _ready() -> void:
	var dataset := TauPlot.Dataset.make_shared_x_categorical(
		PackedStringArray(["Apples", "Oranges", "Bananas"]),
		PackedStringArray(["Spring", "Summer", "Autumn", "Winter"]),
		[
			PackedFloat64Array([30.0, 45.0, 50.0, 20.0]),
			PackedFloat64Array([15.0, 60.0, 35.0, 10.0]),
			PackedFloat64Array([25.0, 55.0, 40.0, 15.0]),
		]
	)

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL

	var y_axis := TauAxisConfig.new()
	y_axis.title = "Tons"

	var bar_cfg := TauBarConfig.new()
	bar_cfg.mode = TauBarConfig.BarMode.GROUPED

	# Rounded top corners on the bars. Bar appearance is controlled by a
	# StyleBox on bar_cfg.style. The bg_color is always overwritten by the
	# series color pipeline, so we only set the shape.
	var sb := StyleBoxFlat.new()
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	bar_cfg.style.style_box = sb

	# Grid lines are off by default. We enable horizontal major grid lines
	# so the reader can compare bar heights more easily.
	var grid := TauGridLineConfig.new()
	grid.y_major_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_cfg]
	pane.grid_line = grid

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	# The series color palette lives on the plot-wide style. Colors are
	# assigned to series in order. series_alpha controls the opacity of
	# all series uniformly.
	config.style.series_colors = [
		Color(0.85, 0.20, 0.20),
		Color(1.0, 0.60, 0.10),
		Color(0.95, 0.85, 0.20),
	]
	config.style.series_alpha = 0.9

	var bindings: Array[TauXYSeriesBinding] = []
	for i in dataset.get_series_count():
		var b := TauXYSeriesBinding.new()
		b.series_id = dataset.get_series_id_by_index(i)
		b.pane_index = 0
		b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
		b.y_axis_id = TauPlot.AxisId.LEFT
		bindings.append(b)

	# Move the legend inside the plot area, at the top-left corner.
	var legend := TauLegendConfig.new()
	legend.position = TauLegendConfig.Position.INSIDE_TOP_LEFT

	$MyPlot.title = "Fruit Harvest by Season"
	$MyPlot.legend_config = legend
	$MyPlot.plot_xy(dataset, config, bindings)
