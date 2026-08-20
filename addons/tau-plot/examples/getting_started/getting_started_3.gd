extends CenterContainer

func _ready() -> void:
	# A categorical dataset where both series share the same X labels.
	var dataset := TauPlot.Dataset.make_shared_x_categorical(
		PackedStringArray(["Actual", "Target"]),
		PackedStringArray(["Week 1", "Week 2", "Week 3", "Week 4"]),
		[
			PackedFloat64Array([42.0, 58.0, 65.0, 71.0]),
			PackedFloat64Array([50.0, 50.0, 60.0, 70.0]),
		]
	)

	# A categorical X axis shows string labels instead of numbers.
	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL

	var y_axis := TauAxisConfig.new()
	y_axis.title = "Units Sold"

	# Two overlay descriptions in one pane: bars and scatter.
	# mode = GROUPED places bars from different series side by side.
	var bar_cfg := TauBarConfig.new()
	bar_cfg.mode = TauBarConfig.BarMode.GROUPED
	var scatter_cfg := TauScatterConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_cfg, scatter_cfg]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	# The binding's overlay_type decides which overlay draws the series.
	# "Actual" goes to bars, "Target" goes to scatter markers.
	var b_bar := TauXYSeriesBinding.new()
	b_bar.series_id = dataset.get_series_id_by_index(0)
	b_bar.pane_index = 0
	b_bar.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	b_bar.y_axis_id = TauPlot.AxisId.LEFT

	var b_scatter := TauXYSeriesBinding.new()
	b_scatter.series_id = dataset.get_series_id_by_index(1)
	b_scatter.pane_index = 0
	b_scatter.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	b_scatter.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [b_bar, b_scatter]

	$MyPlot.title = "Weekly Sales vs. Target"
	$MyPlot.plot_xy(dataset, config, bindings)
