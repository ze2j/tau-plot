extends CenterContainer

func _ready() -> void:
	var x := PackedFloat64Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
	var downloads := PackedFloat64Array([120.0, 250.0, 310.0, 280.0, 420.0, 510.0, 480.0, 620.0, 590.0, 710.0])
	var uploads := PackedFloat64Array([80.0, 90.0, 110.0, 105.0, 130.0, 160.0, 150.0, 180.0, 175.0, 200.0])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(
		PackedStringArray(["Downloads", "Uploads"]),
		x,
		[downloads, uploads] as Array[PackedFloat64Array]
	)

	var x_axis := TauAxisConfig.new()
	x_axis.title = "Day"
	x_axis.include_zero_in_domain = false
	x_axis.tick_count_preferred = x.size()

	# The Y axis uses a format_tick_label callback to add units to the Y labels.
	var y_axis := TauAxisConfig.new()
	y_axis.format_tick_label = func(label: String) -> String:
		return label + " MB"

	var scatter_cfg := TauScatterConfig.new()

	var grid := TauGridLineConfig.new()
	grid.y_major_enabled = true
	grid.x_major_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_cfg]
	pane.grid_line = grid

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var bindings: Array[TauXYSeriesBinding] = []
	for i in dataset.get_series_count():
		var b := TauXYSeriesBinding.new()
		b.series_id = dataset.get_series_id_by_index(i)
		b.pane_index = 0
		b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
		b.y_axis_id = TauPlot.AxisId.LEFT
		bindings.append(b)

	# Activate the hover system and configure it.
	var hover := TauHoverConfig.new()

	# X_ALIGNED collects all series at the nearest X position, which is the
	# natural behavior for time series. NEAREST would pick the single closest
	# sample instead, which works better for pure scatter plots. AUTO picks
	# between the two automatically based on what overlays the pane contains.
	hover.hover_mode = TauHoverConfig.HoverMode.X_ALIGNED

	# Draw a vertical guide line at the hovered X position.
	hover.crosshair_mode = TauHoverConfig.CrosshairMode.X_ONLY

	# Replace the built-in tooltip text with our own.
	# The callback receives an array of SampleHit objects, one per hovered
	# sample. Each SampleHit carries the series name, the X and Y values,
	# the sample index, and more.
	hover.format_tooltip_text = func(hits: Array[TauPlot.SampleHit]) -> String:
		var lines := PackedStringArray()
		for hit in hits:
			lines.append("[b]%s[/b]: %.0f MB" % [hit.series_name, hit.y_value])
		return "\n".join(lines)

	$MyPlot.title = "Daily Network Traffic"
	$MyPlot.hover_enabled = true
	$MyPlot.hover_config = hover
	$MyPlot.plot_xy(dataset, config, bindings)

	# You can also react to hover and click events in your own code.
	# These signals fire even if the built-in tooltip is disabled.
	$MyPlot.sample_hovered.connect(_on_hovered)
	$MyPlot.sample_clicked.connect(_on_clicked)


func _on_hovered(hits: Array[TauPlot.SampleHit]) -> void:
	print("Hovered: %s = %.0f" % [hits[0].series_name, hits[0].y_value])


func _on_clicked(hits: Array[TauPlot.SampleHit]) -> void:
	print("Clicked: %s" % hits[0].series_name)
