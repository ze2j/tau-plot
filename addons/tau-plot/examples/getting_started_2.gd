extends CenterContainer

func _ready() -> void:
	# Create a dataset with three cities. Each city has its own temperature
	# and rainfall readings, so we use PER_SERIES_X: each series brings
	# its own X values. Notice that Paris only has 5 readings while the
	# others have 6. That is fine with PER_SERIES_X.
	var dataset := TauPlot.Dataset.make_per_series_x_continuous(
		PackedStringArray(["Tokyo", "Paris", "Cairo"]),
		# X values: temperature in °C for each city
		[
			PackedFloat64Array([5.0, 10.0, 15.0, 20.0, 25.0, 30.0]),
			PackedFloat64Array([3.0, 8.0, 13.0, 18.0, 23.0]),
			PackedFloat64Array([12.0, 18.0, 25.0, 32.0, 36.0, 40.0]),
		] as Array[PackedFloat64Array],
		# Y values: rainfall in mm for each city
		[
			PackedFloat64Array([50.0, 120.0, 130.0, 170.0, 140.0, 180.0]),
			PackedFloat64Array([45.0, 55.0, 60.0, 65.0, 55.0]),
			PackedFloat64Array([5.0, 3.0, 2.0, 0.5, 0.0, 0.0]),
		] as Array[PackedFloat64Array],
	)

	# The X axis. We turn off include_zero_in_domain because the lowest
	# temperature is 3 and stretching the axis down to 0 would waste space.
	var x_axis := TauAxisConfig.new()
	x_axis.title = "Temperature (°C)"
	x_axis.include_zero_in_domain = false

	# The Y axis. Same idea: rainfall values start around 0 but we still
	# disable include_zero_in_domain so the axis fits the data tightly.
	var y_axis := TauAxisConfig.new()
	y_axis.title = "Rainfall (mm)"
	y_axis.include_zero_in_domain = false

	# A scatter overlay: this tells the pane to draw markers.
	var scatter_cfg := TauScatterConfig.new()

	# One pane with a left Y axis and the scatter overlay.
	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_cfg]

	# The plot configuration ties together the X axis and our single pane.
	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	# One binding per series. Each one says "draw this series in pane 0
	# as scatter markers on the left Y axis".
	var bindings: Array[TauXYSeriesBinding] = []
	for i in dataset.get_series_count():
		var b := TauXYSeriesBinding.new()
		b.series_id = dataset.get_series_id_by_index(i)
		b.pane_index = 0
		b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
		b.y_axis_id = TauPlot.AxisId.LEFT
		bindings.append(b)

	# Finally, give the plot a title and call plot_xy() with our three pieces:
	# the dataset, the configuration, and the bindings.
	$MyPlot.title = "Temperature vs. Rainfall"
	$MyPlot.plot_xy(dataset, config, bindings)
