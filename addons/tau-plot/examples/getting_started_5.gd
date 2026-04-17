extends CenterContainer

func _ready() -> void:
	# Two series sharing the same numeric X values (months 1 to 6).
	var months := PackedFloat64Array([1, 2, 3, 4, 5, 6])
	var visitors := PackedFloat64Array([1200.0, 1450.0, 1380.0, 1620.0, 1800.0, 1950.0])
	var rating := PackedFloat64Array([4.1, 4.3, 4.0, 4.5, 4.6, 4.8])

	var dataset := TauPlot.Dataset.make_shared_x_continuous(
		PackedStringArray(["Visitors", "Rating"]),
		months,
		[visitors, rating] as Array[PackedFloat64Array]
	)

	# The X axis uses a format_tick_label callback to turn 1.0 into "Jan",
	# 2.0 into "Feb", etc. In practice, using a categorical dataset with
	# month names as strings would be simpler here. We use a continuous
	# axis on purpose so you can see how format_tick_label works.
	var x_axis := TauAxisConfig.new()
	x_axis.include_zero_in_domain = false
	x_axis.tick_count_preferred = 6
	x_axis.format_tick_label = func(label: String) -> String:
		const names := ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
		var idx := int(label.to_float()) - 1
		if idx >= 0 and idx < names.size():
			return names[idx]
		return label

	# Top pane: visitors shown as bars.
	# stretch_ratio controls how much vertical space this pane gets compared
	# to the others. With ratios 3.0 and 1.0, this pane takes 75%.
	var visitors_y := TauAxisConfig.new()
	visitors_y.title = "Visitors"

	# The bar overlay. Since there is only one series in this pane, mode does
	# not change the visual result, but we set it explicitly for clarity.
	# bar_width_policy controls how wide the bars are. NEIGHBOR_SPACING_FRACTION
	# makes each bar take a fraction of the distance to its nearest neighbor,
	# so bars stay proportional even if the X values are not evenly spaced.
	# Here 0.80 means each bar fills 80% of that gap.
	var bar_cfg := TauBarConfig.new()
	bar_cfg.mode = TauBarConfig.BarMode.GROUPED
	bar_cfg.bar_width_policy = TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION
	bar_cfg.neighbor_spacing_fraction = 0.80

	var visitors_pane := TauPaneConfig.new()
	visitors_pane.y_left_axis = visitors_y
	visitors_pane.overlays = [bar_cfg]
	visitors_pane.stretch_ratio = 3.0

	# Bottom pane: rating shown as scatter markers.
	var rating_y := TauAxisConfig.new()
	rating_y.title = "Rating"
	rating_y.include_zero_in_domain = false

	var scatter_cfg := TauScatterConfig.new()

	var rating_pane := TauPaneConfig.new()
	rating_pane.y_left_axis = rating_y
	rating_pane.overlays = [scatter_cfg]
	rating_pane.stretch_ratio = 1.0

	# The panes array is ordered: index 0 is the top pane, index 1 is below it.
	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [visitors_pane, rating_pane]

	# Each binding's pane_index points to the right entry in config.panes.
	var b_visitors := TauXYSeriesBinding.new()
	b_visitors.series_id = dataset.get_series_id_by_index(0)
	b_visitors.pane_index = 0
	b_visitors.overlay_type = TauXYSeriesBinding.PaneOverlayType.BAR
	b_visitors.y_axis_id = TauPlot.AxisId.LEFT

	var b_rating := TauXYSeriesBinding.new()
	b_rating.series_id = dataset.get_series_id_by_index(1)
	b_rating.pane_index = 1
	b_rating.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	b_rating.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [b_visitors, b_rating]

	$MyPlot.title = "Restaurant: Visitors and Rating"
	$MyPlot.plot_xy(dataset, config, bindings)
