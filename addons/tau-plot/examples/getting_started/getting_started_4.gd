extends CenterContainer

func _ready() -> void:
	# One reading per hour, at the same hours for the three series.
	var hours := PackedFloat64Array([
		0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
		12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23,
	])
	var setpoint := PackedFloat64Array([
		17.0, 17.0, 17.0, 17.0, 17.0, 17.0, 20.5, 20.5, 20.5, 18.0, 18.0, 18.0,
		18.0, 18.0, 18.0, 18.0, 18.0, 21.0, 21.0, 21.0, 21.0, 21.0, 17.0, 17.0,
	])
	var room := PackedFloat64Array([
		17.4, 17.2, 17.1, 17.0, 17.0, 16.9, 17.3, 19.1, 20.3, 20.1, 19.2, 18.5,
		18.2, 18.1, 18.3, 18.4, 18.3, 18.9, 20.2, 20.9, 21.0, 20.8, 19.9, 18.6,
	])
	var outdoor := PackedFloat64Array([
		4.0, 3.5, 3.1, 2.8, 2.6, 2.9, 3.8, 5.2, 7.0, 8.8, 10.3, 11.6,
		12.5, 13.1, 13.4, 13.0, 12.1, 10.6, 9.0, 7.6, 6.5, 5.7, 5.0, 4.4,
	])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(
		PackedStringArray(["Setpoint", "Room", "Outdoor"]),
		hours,
		[setpoint, room, outdoor] as Array[PackedFloat64Array]
	)

	var x_axis := TauAxisConfig.new()
	x_axis.title = "Hour"
	x_axis.tick_count_preferred = 7

	var y_axis := TauAxisConfig.new()
	y_axis.title = "Temperature (°C)"

	var line_cfg := TauLineConfig.new()

	# The first cycle: the interpolation mode is the shape of a curve between
	# two samples. One entry per series, in dataset order.
	line_cfg.interpolation_modes = [
		# setpoint holds its value until the next change.
		TauLineConfig.InterpolationMode.STEP_AFTER,
		# room temperature moves slowly and never jumps.
		TauLineConfig.InterpolationMode.SMOOTH_MONOTONE,
		# outdoor temperature is unknown between two readings:
		# a straight segment says all you know.
		TauLineConfig.InterpolationMode.LINEAR,
	]

	# Another cycle: dash length in pixels, with a gap of the same length
	# between two dashes. 0 draws a solid line.
	line_cfg.style.dash_lengths_px = [6, 0, 0]

	# The area between the curve and the baseline.
	var area := TauLineFill.new()
	area.fill_mode = TauLineFill.FillMode.TO_BASELINE
	area.fill_baseline = 10.0
	area.color = Color(0.2, 0.7, 0.55)
	area.alpha = 0.25

	# fills is a cycle as well: it takes one entry per series.
	# Only the outdoor temperature curve is filled.
	line_cfg.style.fills = [null, null, area]

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [line_cfg]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	var bindings: Array[TauXYSeriesBinding] = []
	for i in dataset.get_series_count():
		var b := TauXYSeriesBinding.new()
		b.series_id = dataset.get_series_id_by_index(i)
		b.pane_index = 0
		b.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
		b.y_axis_id = TauPlot.AxisId.LEFT
		bindings.append(b)

	$MyPlot.title = "Thermostat"
	$MyPlot.plot_xy(dataset, config, bindings)
