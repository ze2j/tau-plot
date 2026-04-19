extends CenterContainer

func _ready() -> void:
	# The six most spoken languages in the world by number of native
	# speakers (in millions). Source: Wikipedia.
	var dataset := TauPlot.Dataset.make_shared_x_categorical(
		PackedStringArray(["Native speakers"]),
		PackedStringArray(["Mandarin Chinese", "Spanish", "English", "Hindi", "Portuguese", "Bengali"]),
		[
			PackedFloat64Array([988.0, 487.0, 372.0, 347.0, 252.0, 232.0]),
		]
	)

	# The X axis carries the language names.
	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL
	# We want the most spoken language to be displayed at the top.
	x_axis.inverted = true
	# We don't want to skip any labels.
	x_axis.overlap_strategy = TauAxisConfig.OverlapStrategy.NONE

	# The Y axis shows the number of speakers in millions.
	var y_axis := TauAxisConfig.new()
	y_axis.title = "Millions"

	var bar_cfg := TauBarConfig.new()

	var pane := TauPaneConfig.new()
	# The Y axis is on the BOTTOM edge.
	pane.y_bottom_axis = y_axis
	pane.overlays = [bar_cfg]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	# The X axis is on the LEFT edge.
	config.x_axis_id = TauPlot.AxisId.LEFT

	var b := TauXYSeriesBinding.new()
	b.series_id = dataset.get_series_id_by_index(0)
	b.pane_index = 0
	b.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	# The series is bound to the Y axis occupying the BOTTOM slot.
	b.y_axis_id = TauPlot.AxisId.BOTTOM

	var bindings: Array[TauXYSeriesBinding] = [b]

	# With only one series, the legend is not very useful.
	$MyPlot.legend_enabled = false
	$MyPlot.title = "Most Spoken Languages by population"
	$MyPlot.plot_xy(dataset, config, bindings)
