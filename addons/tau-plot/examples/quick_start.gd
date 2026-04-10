extends CenterContainer

func _ready() -> void:
	var dataset := TauPlot.Dataset.make_shared_x_categorical(
		PackedStringArray(["Revenue", "Costs"]),
		PackedStringArray(["Q1", "Q2", "Q3", "Q4"]),
		[
			PackedFloat64Array([120.0, 135.0, 148.0, 160.0]),
			PackedFloat64Array([90.0, 95.0, 100.0, 108.0]),
		]
	)

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL

	var y_axis := TauAxisConfig.new()
	y_axis.title = "EUR"

	var bar_overlay_config := TauBarConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_overlay_config]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var b0 := TauXYSeriesBinding.new()
	b0.series_id = dataset.get_series_id_by_index(0)
	b0.pane_index = 0
	b0.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	b0.y_axis_id = TauPlot.AxisId.LEFT

	var b1 := TauXYSeriesBinding.new()
	b1.series_id = dataset.get_series_id_by_index(1)
	b1.pane_index = 0
	b1.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	b1.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [b0, b1]

	$MyPlot.title = "Quick Start Example"
	$MyPlot.plot_xy(dataset, config, bindings)
