extends VBoxContainer

const Dataset = TauPlot.Dataset
const AxisId = TauPlot.AxisId
const PaneOverlayType = TauPlot.PaneOverlayType
const MarkerShape = TauScatterStyle.MarkerShape
const LegendPosition = TauLegendConfig.Position
const ColorBuffer = TauPlot.ColorBuffer
const Float32Buffer = TauPlot.Float32Buffer
const ScatterVisualCallbacks = TauPlot.ScatterVisualCallbacks
const BarVisualCallbacks = TauPlot.BarVisualCallbacks
const ScatterVisualAttributes = TauPlot.ScatterVisualAttributes


func _ready() -> void:
	_setup_demo_1(%DemoPlot1)
	_setup_demo_2(%DemoPlot2)
	_setup_demo_3(%DemoPlot3)
	_setup_demo_4(%DemoPlot4)
	_setup_demo_5(%DemoPlot5)
	_setup_demo_6(%DemoPlot6)
	_setup_demo_7(%DemoPlot7)
	_setup_demo_8(%DemoPlot8)
	_setup_demo_9(%DemoPlot9)


####################################################################################################
# DEMO 1: Hertzsprung-Russell Diagram
#
# Astrophysics scatter. ~175 synthetic stars along the main sequence, red
# giant branch, white dwarf region, and supergiant locus.
# color_callback maps B-V to realistic star hue. size_callback maps
# absolute magnitude to marker radius.
####################################################################################################

func _setup_demo_1(plot: TauPlot) -> void:
	plot.title = "[b]Hertzsprung-Russell Diagram[/b]"
	plot.legend_enabled = false

	# Synthetic star data
	var bv := PackedFloat64Array()
	var mag := PackedFloat64Array()

	# Main sequence (~120 points)
	for i in range(120):
		var t := float(i) / 119.0
		var b := -0.33 + t * 2.13
		var m := -6.0 + t * 22.0
		var noise_b := sin(float(i) * 7.3) * 0.06 + cos(float(i) * 11.1) * 0.04
		var noise_m := sin(float(i) * 3.1) * 1.2 + cos(float(i) * 5.7) * 0.7
		bv.append(b + noise_b)
		mag.append(m + noise_m)

	# Red giant branch (~30 points)
	for i in range(30):
		var t := float(i) / 29.0
		bv.append(0.80 + t * 0.90 + sin(float(i) * 4.2) * 0.08)
		mag.append(-2.5 + t * 4.0 + cos(float(i) * 3.7) * 0.6)

	# White dwarfs (~15 points)
	for i in range(15):
		var t := float(i) / 14.0
		bv.append(-0.05 + t * 0.60 + sin(float(i) * 5.1) * 0.04)
		mag.append(10.0 + t * 4.5 + sin(float(i) * 2.3) * 0.5)

	# Supergiants (~10 points)
	for i in range(10):
		var t := float(i) / 9.0
		bv.append(-0.20 + t * 1.90 + cos(float(i) * 3.3) * 0.08)
		mag.append(-7.0 + sin(float(i) * 1.7) * 1.2)

	var dataset := Dataset.make_per_series_x_continuous(["Stars"], [bv], [mag])

	# Axes
	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.title = "B-V Color Index"
	x_axis.include_zero_in_domain = false
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.FRACTION
	x_axis.domain_padding_min = 0.04
	x_axis.domain_padding_max = 0.04
	x_axis.tick_count_preferred = 7

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.title = "Absolute Magnitude (Mv)"
	y_axis.inverted = true # Minimum magnitudes (bright) go to the top
	y_axis.include_zero_in_domain = false
	y_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.FRACTION
	y_axis.domain_padding_min = 0.04
	y_axis.domain_padding_max = 0.04
	y_axis.tick_count_preferred = 8

	# Scatter with callbacks
	var scatter_cfg := TauScatterConfig.new()
	var callbacks := ScatterVisualCallbacks.new()

	# Colors
	callbacks.color_callback = func(_si: int, _i: int, x_val: Variant, _y: float) -> Color:
		var bv_val: float = x_val as float
		bv_val = clampf(bv_val, -0.4, 2.0)
		var t2 := (bv_val + 0.4) / 2.4
		if t2 < 0.15:
			return Color(0.62, 0.71, 1.0)
		elif t2 < 0.30:
			return Color(0.78, 0.84, 1.0)
		elif t2 < 0.42:
			return Color(1.0, 0.97, 0.90)
		elif t2 < 0.52:
			return Color(1.0, 0.92, 0.65)
		elif t2 < 0.65:
			return Color(1.0, 0.78, 0.42)
		else:
			return Color(1.0, 0.50, 0.25)

	# Sizes
	callbacks.size_callback = func(_si: int, _i: int, _x: Variant, y: float) -> float:
		var brightness := clampf((-y + 15.0) / 23.0, 0.0, 1.0)
		return 3.0 + brightness * 11.0

	scatter_cfg.visual_callbacks = callbacks

	var grid := TauGridLineConfig.new()
	grid.y_major_enabled = true
	grid.x_major_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_cfg]
	pane.grid_line = grid

	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.panes = [pane]

	var binding := TauXYSeriesBinding.new()
	binding.series_id = 1
	binding.pane_index = 0
	binding.overlay_type = PaneOverlayType.SCATTER
	binding.y_axis_id = AxisId.LEFT

	plot.plot_xy(dataset, xy, [binding])


####################################################################################################
# DEMO 2: Global Temperature Anomaly (1880-2023)
#
# Climate science bar chart. 144 annual bars colored blue-to-red via a
# per-sample color_callback. Inspired by the warming stripes of Ed Hawkins.
####################################################################################################

func _setup_demo_2(plot: TauPlot) -> void:
	plot.title = "[b]Global Temperature Anomaly[/b] [color=#888888](\u00b0C vs 1951-1980)[/color]"
	plot.legend_enabled = false

	var years := PackedFloat64Array()
	for y in range(1880, 2024):
		years.append(float(y))

	var anomaly := PackedFloat64Array([
		-0.16,-0.08,-0.10,-0.17,-0.27,-0.24,-0.23,-0.35,-0.14,-0.10,
		-0.33,-0.25,-0.30,-0.31,-0.32,-0.22,-0.10,-0.11,-0.26,-0.17,
		-0.08,-0.15,-0.27,-0.36,-0.46,-0.26,-0.22,-0.38,-0.43,-0.45,
		-0.42,-0.44,-0.35,-0.34,-0.15,-0.12,-0.34,-0.39,-0.30,-0.22,
		-0.23,-0.28,-0.16,-0.27,-0.25,-0.18,-0.16,-0.30,-0.24,-0.28,
		-0.17,-0.07, 0.01, 0.08,-0.13,-0.14,-0.18, 0.07, 0.11, 0.06,
		 0.01, 0.08,-0.01, 0.06,-0.12,-0.04,-0.07,-0.01,-0.04, 0.08,
		-0.03,-0.08,-0.12, 0.04, 0.05,-0.07, 0.04, 0.10,-0.13,-0.15,
		 0.05, 0.07, 0.04,-0.17,-0.07,-0.01,-0.04,-0.06,-0.20,-0.10,
		-0.04,-0.27,-0.15,-0.14,-0.12, 0.02, 0.03, 0.00,-0.04, 0.12,
		 0.17, 0.13, 0.08, 0.23, 0.25, 0.10, 0.01, 0.07, 0.09,-0.06,
		 0.22, 0.24, 0.16, 0.29, 0.13, 0.37, 0.33, 0.46, 0.32, 0.39,
		 0.40, 0.54, 0.63, 0.62, 0.55, 0.68, 0.40, 0.43, 0.57, 0.62,
		 0.64, 0.66, 0.56, 0.66, 0.72, 0.80, 1.01, 0.92, 0.85, 0.98,
		 1.02, 0.85, 0.90, 1.17])

	var dataset := Dataset.make_shared_x_continuous(["Anomaly"], years, [anomaly])

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.include_zero_in_domain = false
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.DATA_UNITS
	x_axis.domain_padding_min = 1.0
	x_axis.domain_padding_max = 1.0
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.title = "\u00b0C"
	y_axis.title_alignment = TauAxisConfig.TitleAlignment.END
	y_axis.include_zero_in_domain = true
	y_axis.tick_count_preferred = 6

	var bar_cfg := TauBarConfig.new()
	bar_cfg.bar_width_policy = TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION
	bar_cfg.neighbor_spacing_fraction = 0.92

	var bar_callbacks := BarVisualCallbacks.new()
	bar_callbacks.color_callback = func(_si: int, _i: int, _x: Variant, y: float) -> Color:
		var t2 := clampf((y + 0.5) / 1.7, 0.0, 1.0)
		if t2 < 0.35:
			var u := t2 / 0.35
			return Color(0.10 + u * 0.35, 0.15 + u * 0.40, 0.55 + u * 0.30)
		elif t2 < 0.50:
			var u := (t2 - 0.35) / 0.15
			return Color(0.45 + u * 0.50, 0.55 + u * 0.40, 0.85 - u * 0.10)
		elif t2 < 0.65:
			var u := (t2 - 0.50) / 0.15
			return Color(0.95, 0.95 - u * 0.20, 0.75 - u * 0.35)
		else:
			var u := (t2 - 0.65) / 0.35
			return Color(0.90 + u * 0.10, 0.75 - u * 0.55, 0.40 - u * 0.30)
	bar_cfg.visual_callbacks = bar_callbacks

	var grid := TauGridLineConfig.new()
	grid.y_major_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_cfg]
	pane.grid_line = grid

	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.panes = [pane]

	var binding := TauXYSeriesBinding.new()
	binding.series_id = 1
	binding.pane_index = 0
	binding.overlay_type = PaneOverlayType.BAR
	binding.y_axis_id = AxisId.LEFT

	plot.plot_xy(dataset, xy, [binding])


####################################################################################################
# DEMO 3: GDP Composition by Sector (Stacked % Bar, Categorical)
####################################################################################################

func _setup_demo_3(plot: TauPlot) -> void:
	plot.title = "[b]GDP by Sector[/b] [color=#888888](% of GDP, 2022)[/color]"
	plot.legend_enabled = true
	plot.legend_config = TauLegendConfig.new()
	plot.legend_config.position = LegendPosition.OUTSIDE_BOTTOM

	var countries := PackedStringArray(["USA", "China", "India", "Germany", "Brazil", "Nigeria", "Japan", "France"])
	var agriculture := PackedFloat64Array([1.0, 7.3, 16.7, 0.8, 5.8, 21.1, 1.0, 1.7])
	var industry := PackedFloat64Array([18.2, 39.4, 25.7, 26.6, 18.3, 22.3, 29.1, 16.8])
	var services := PackedFloat64Array([80.8, 53.3, 57.6, 72.6, 75.9, 56.6, 69.9, 81.5])

	var dataset := Dataset.make_shared_x_categorical(
		PackedStringArray(["Agriculture", "Industry", "Services"]),
		countries,
		[agriculture, industry, services])

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CATEGORICAL

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.title_alignment = TauAxisConfig.TitleAlignment.END
	y_axis.tick_count_preferred = 5
	y_axis.format_tick_label = func(label: String) -> String:
		return label + "%"

	var bar_cfg := TauBarConfig.new()
	bar_cfg.mode = TauBarConfig.BarMode.STACKED
	bar_cfg.stacked_normalization = TauBarConfig.StackedNormalization.PERCENT
	bar_cfg.category_width_fraction = 0.70

	var grid := TauGridLineConfig.new()
	grid.y_major_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [bar_cfg]
	pane.grid_line = grid

	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.panes = [pane]

	var bindings: Array[TauXYSeriesBinding] = []
	for series_id in [1, 2, 3]:
		var b := TauXYSeriesBinding.new()
		b.series_id = series_id
		b.pane_index = 0
		b.overlay_type = PaneOverlayType.BAR
		b.y_axis_id = AxisId.LEFT
		bindings.append(b)

	plot.plot_xy(dataset, xy, bindings)


####################################################################################################
# DEMO 4 -- Fisher's Iris Dataset (Sepal Dimensions)
####################################################################################################

func _setup_demo_4(plot: TauPlot) -> void:
	plot.title = "[b]Iris Dataset[/b] [color=#666666](Fisher, 1936)[/color]"
	plot.legend_enabled = true
	plot.legend_config = TauLegendConfig.new()
	plot.legend_config.position = LegendPosition.INSIDE_TOP_LEFT

	var set_x := PackedFloat64Array([
		5.1,4.9,4.7,4.6,5.0,5.4,4.6,5.0,4.4,4.9,5.4,4.8,4.8,4.3,5.8,
		5.7,5.4,5.1,5.7,5.1,5.4,5.1,4.6,5.1,4.8,5.0,5.0,5.2,5.2,4.7,
		4.8,5.4,5.2,5.5,4.9,5.0,5.5,4.9,4.4,5.1,5.0,4.5,4.4,5.0,5.1,
		4.8,5.1,4.6,5.3,5.0])
	var set_y := PackedFloat64Array([
		3.5,3.0,3.2,3.1,3.6,3.9,3.4,3.4,2.9,3.1,3.7,3.4,3.0,3.0,4.0,
		4.4,3.9,3.5,3.8,3.8,3.4,3.7,3.6,3.3,3.4,3.0,3.4,3.5,3.4,3.2,
		3.1,3.4,4.1,4.2,3.1,3.2,3.5,3.6,3.0,3.4,3.5,2.3,3.2,3.5,3.8,
		3.0,3.8,3.2,3.7,3.3])
	var ver_x := PackedFloat64Array([
		7.0,6.4,6.9,5.5,6.5,5.7,6.3,4.9,6.6,5.2,5.0,5.9,6.0,6.1,5.6,
		6.7,5.6,5.8,6.2,5.6,5.9,6.1,6.3,6.1,6.4,6.6,6.8,6.7,6.0,5.7,
		5.5,5.5,5.8,6.0,5.4,6.0,6.7,6.3,5.6,5.5,5.5,6.1,5.8,5.0,5.6,
		5.7,5.7,6.2,5.1,5.7])
	var ver_y := PackedFloat64Array([
		3.2,3.2,3.1,2.3,2.8,2.8,3.3,2.4,2.9,2.7,2.0,3.0,2.2,2.9,2.9,
		3.1,3.0,2.7,2.2,2.5,3.2,2.8,2.5,2.8,3.2,3.0,2.8,3.0,2.9,2.6,
		2.4,2.4,2.7,2.7,3.0,3.4,3.1,2.3,3.0,2.5,2.6,3.0,2.6,2.3,2.7,
		3.0,2.9,2.9,2.5,2.8])
	var vir_x := PackedFloat64Array([
		6.3,5.8,7.1,6.3,6.5,7.6,4.9,7.3,6.7,7.2,6.5,6.4,6.8,5.7,5.8,
		6.4,6.5,7.7,7.7,6.0,6.9,5.6,7.7,6.3,6.7,7.2,6.2,6.1,6.4,7.2,
		7.4,7.9,6.4,6.3,6.1,7.7,6.3,6.4,6.0,6.9,6.7,6.9,5.8,6.8,6.7,
		6.7,6.3,6.5,6.2,5.9])
	var vir_y := PackedFloat64Array([
		3.3,2.7,3.0,2.9,3.0,3.0,2.5,2.9,2.5,3.6,3.2,2.7,3.0,2.5,2.8,
		3.2,3.0,3.8,2.6,2.2,3.2,2.8,2.8,2.7,3.3,3.2,2.8,3.0,2.8,3.0,
		2.8,3.8,2.8,2.8,2.6,3.0,3.4,3.1,3.0,3.1,3.1,3.1,2.7,3.2,3.3,
		3.0,2.5,3.0,3.4,3.0])

	var dataset := Dataset.make_per_series_x_continuous(
		PackedStringArray(["I. setosa", "I. versicolor", "I. virginica"]),
		[set_x, ver_x, vir_x] as Array[PackedFloat64Array],
		[set_y, ver_y, vir_y] as Array[PackedFloat64Array])

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.title = "Sepal Length (cm)"
	x_axis.include_zero_in_domain = false
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.FRACTION
	x_axis.domain_padding_min = 0.06
	x_axis.domain_padding_max = 0.06

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.title = "Sepal Width (cm)"
	y_axis.include_zero_in_domain = false
	y_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.FRACTION
	y_axis.domain_padding_min = 0.06
	y_axis.domain_padding_max = 0.06

	var scatter_cfg := TauScatterConfig.new()

	var grid := TauGridLineConfig.new()
	grid.y_major_enabled = true
	grid.x_major_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_cfg]
	pane.grid_line = grid

	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.panes = [pane]

	var bindings: Array[TauXYSeriesBinding] = []
	for series_id in [1, 2, 3]:
		var b := TauXYSeriesBinding.new()
		b.series_id = series_id
		b.pane_index = 0
		b.overlay_type = PaneOverlayType.SCATTER
		b.y_axis_id = AxisId.LEFT
		bindings.append(b)

	plot.plot_xy(dataset, xy, bindings)


####################################################################################################
# DEMO 5 -- MSFT Stock Price + Volume (Two Panes)
####################################################################################################

func _setup_demo_5(plot: TauPlot) -> void:
	plot.title = "[b]MSFT[/b] [color=#888888]Monthly, 2022-2026[/color]"
	plot.legend_enabled = true
	plot.legend_config = TauLegendConfig.new()
	plot.legend_config.position = LegendPosition.INSIDE_TOP

	# --- MSFT monthly close (USD) Jan2022 → Mar2026 ---
	var close := PackedFloat64Array([
		310.98, 298.79, 308.31, 277.52, 271.87, 256.83,
		280.74, 261.47, 232.90, 232.13, 255.14, 239.82,
		247.81, 249.42, 288.30, 307.26, 328.39, 340.54,
		335.92, 327.76, 315.75, 338.11, 376.04, 397.58,
		413.64, 389.33, 415.13, 446.95, 418.35, 417.14,
		430.30, 406.35, 423.46, 421.50, 415.06, 396.99,
		375.39, 395.26, 460.36, 497.41, 533.50, 506.69,
		517.95, 517.81, 492.01, 483.62, 430.29, 392.74,
		365.14
	])

	# --- MSFT monthly volume (in M) Jan2022 → Mar2026 ---
	var volume := PackedFloat64Array([
		743.92, 852.55, 755.21, 680.44, 710.77, 697.12,
		639.55, 598.34, 620.11, 582.65, 601.88, 579.43,
		588.17, 574.09, 612.32, 635.14, 648.95, 660.33,
		659.02, 648.41, 629.87, 618.29, 601.75, 589.96,
		580.23, 567.84, 590.11, 605.47, 612.99, 604.22,
		617.54, 605.33, 590.12, 580.67, 572.43, 565.89,
		550.22, 563.78, 619.44, 628.30, 623.57, 610.48,
		602.89, 599.75, 585.43, 580.12, 560.34, 800.17,
		144.55
	])

	const N := 49

	var months := PackedFloat64Array()
	for i in range(N):
		months.append(i + 1)

	var dataset := Dataset.make_shared_x_continuous(
		PackedStringArray(["Close (USD)", "Volume (M)"]),
		months,
		[close, volume] as Array[PackedFloat64Array])

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.include_zero_in_domain = false
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.DATA_UNITS
	x_axis.domain_padding_min = 0.5
	x_axis.domain_padding_max = 0.5
	x_axis.tick_count_preferred = 8
	x_axis.format_tick_label = func(label: String) -> String:
		var idx := int(label.to_float()) - 1
		if idx < 0 or idx >= N:
			return ""
		const month_labels := ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
		var year := 2022 + idx / 12
		return "%s '%d" % [month_labels[idx % 12], year % 100]

	var price_y := TauAxisConfig.new()
	price_y.type = TauAxisConfig.Type.CONTINUOUS
	price_y.title = "USD"
	price_y.include_zero_in_domain = false
	price_y.domain_padding_mode = TauAxisConfig.DomainPaddingMode.FRACTION
	price_y.domain_padding_min = 0.05
	price_y.domain_padding_max = 0.08
	price_y.tick_count_preferred = 6

	var vol_y := TauAxisConfig.new()
	vol_y.type = TauAxisConfig.Type.CONTINUOUS
	vol_y.include_zero_in_domain = true
	vol_y.tick_count_preferred = 4
	vol_y.format_tick_label = func(label: String) -> String:
		return "%dM" % int(label.to_float())

	var scatter_cfg := TauScatterConfig.new()

	var bar_cfg := TauBarConfig.new()
	bar_cfg.bar_width_policy = TauBarConfig.BarWidthPolicy.NEIGHBOR_SPACING_FRACTION
	bar_cfg.neighbor_spacing_fraction = 0.80

	var price_grid := TauGridLineConfig.new()
	price_grid.y_major_enabled = true

	var price_pane := TauPaneConfig.new()
	price_pane.y_left_axis = price_y
	price_pane.overlays = [scatter_cfg]
	price_pane.grid_line = price_grid
	price_pane.stretch_ratio = 3.0

	var vol_pane := TauPaneConfig.new()
	vol_pane.y_left_axis = vol_y
	vol_pane.overlays = [bar_cfg]
	vol_pane.stretch_ratio = 1.0

	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.panes = [price_pane, vol_pane]

	var b_price := TauXYSeriesBinding.new()
	b_price.series_id = dataset.get_series_id_by_index(0)
	b_price.pane_index = 0
	b_price.overlay_type = PaneOverlayType.SCATTER
	b_price.y_axis_id = AxisId.LEFT

	var b_vol := TauXYSeriesBinding.new()
	b_vol.series_id = dataset.get_series_id_by_index(1)
	b_vol.pane_index = 1
	b_vol.overlay_type = PaneOverlayType.BAR
	b_vol.y_axis_id = AxisId.LEFT

	plot.plot_xy(dataset, xy, [b_price, b_vol])


####################################################################################################
# DEMO 6 -- Keeling Curve (Atmospheric CO2)
####################################################################################################

func _setup_demo_6(plot: TauPlot) -> void:
	plot.title = "[b]Keeling Curve[/b] [color=#666666]Mauna Loa CO\u2082[/color]"
	plot.legend_enabled = false

	var x_years := PackedFloat64Array()
	var co2_ppm := PackedFloat64Array()
	for month_idx in range(792):
		var year := 1958.25 + float(month_idx) / 12.0
		x_years.append(year)
		var elapsed := year - 1958.0
		var trend := 315.0 + 0.85 * elapsed + 0.0115 * elapsed * elapsed
		var seasonal := 3.1 * sin(TAU * (year - 1958.2))
		var minor := 0.6 * sin(TAU * 2.0 * (year - 1958.0))
		co2_ppm.append(trend + seasonal + minor)

	var dataset := Dataset.make_shared_x_continuous(
		PackedStringArray(["CO\u2082"]),
		x_years, [co2_ppm] as Array[PackedFloat64Array])

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.include_zero_in_domain = false
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.FRACTION
	x_axis.domain_padding_min = 0.02
	x_axis.domain_padding_max = 0.02
	x_axis.tick_count_preferred = 8

	var sec_x := TauAxisConfig.new()
	sec_x.type = TauAxisConfig.Type.CONTINUOUS
	sec_x.title = "Years Since 1958"
	sec_x.title_alignment = TauAxisConfig.TitleAlignment.CENTER
	sec_x.tick_count_preferred = 7

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.title = "CO\u2082 (ppm)"
	y_axis.include_zero_in_domain = false
	y_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.FRACTION
	y_axis.domain_padding_min = 0.04
	y_axis.domain_padding_max = 0.04
	y_axis.tick_count_preferred = 7

	var scatter_cfg := TauScatterConfig.new()

	var grid := TauGridLineConfig.new()
	grid.y_major_enabled = true
	grid.x_major_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_cfg]
	pane.grid_line = grid

	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.secondary_x_axis = sec_x
	xy.secondary_x_axis_transform = func(primary_year: float) -> float:
		return primary_year - 1958.0
	xy.panes = [pane]

	var binding := TauXYSeriesBinding.new()
	binding.series_id = 1
	binding.pane_index = 0
	binding.overlay_type = PaneOverlayType.SCATTER
	binding.y_axis_id = AxisId.LEFT

	plot.plot_xy(dataset, xy, [binding])


####################################################################################################
# DEMO 7 -- Blackbody Radiation (Planck Curves)
####################################################################################################

func _setup_demo_7(plot: TauPlot) -> void:
	plot.title = "[b]Blackbody Radiation[/b]"
	plot.legend_enabled = true
	plot.legend_config = TauLegendConfig.new()
	plot.legend_config.position = LegendPosition.INSIDE_RIGHT

	var h := 6.626e-34
	var c := 2.998e8
	var k := 1.381e-23
	var temps := [3000.0, 4000.0, 5000.0, 6500.0]
	var names := PackedStringArray(["3000 K", "4000 K", "5000 K", "6500 K"])
	var n_pts := 120

	var all_x: Array[PackedFloat64Array] = []
	var all_y: Array[PackedFloat64Array] = []
	for temp in temps:
		var xs := PackedFloat64Array()
		var ys := PackedFloat64Array()
		for i in range(n_pts):
			var t2 := float(i) / float(n_pts - 1)
			var lam_um := 0.10 + t2 * 3.90
			var lam_m := lam_um * 1e-6
			var exponent: float = h * c / (lam_m * k * temp)
			var radiance := 0.0
			if exponent < 500.0:
				var denom := exp(exponent) - 1.0
				if denom > 1e-30:
					radiance = (2.0 * h * c * c / pow(lam_m, 5.0)) / denom * 1e-6
			xs.append(lam_um)
			ys.append(radiance)
		all_x.append(xs)
		all_y.append(ys)

	var dataset := Dataset.make_per_series_x_continuous(names, all_x, all_y)

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.title = "Wavelength (\u03bcm)"
	x_axis.include_zero_in_domain = false
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.NONE
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.scale = TauAxisConfig.Scale.LOGARITHMIC
	y_axis.title = "Spectral Radiance"
	y_axis.include_zero_in_domain = false

	var scatter_cfg := TauScatterConfig.new()

	var grid := TauGridLineConfig.new()
	grid.y_major_enabled = true
	grid.x_major_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_cfg]
	pane.grid_line = grid

	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.panes = [pane]

	var bindings: Array[TauXYSeriesBinding] = []
	for series_id in [1, 2, 3, 4]:
		var b := TauXYSeriesBinding.new()
		b.series_id = series_id
		b.pane_index = 0
		b.overlay_type = PaneOverlayType.SCATTER
		b.y_axis_id = AxisId.LEFT
		bindings.append(b)

	plot.plot_xy(dataset, xy, bindings)


####################################################################################################
# DEMO 8 -- Olympic 100m Sprint Records (Men, 1896-2024)
####################################################################################################

func _setup_demo_8(plot: TauPlot) -> void:
	plot.title = "[b]Olympic 100m Sprint[/b] [color=#c8a84e]Gold Medal Times[/color]"
	plot.legend_enabled = false

	var year := PackedFloat64Array([
		1896,1900,1904,1908,1912,1920,1924,1928,1932,1936,
		1948,1952,1956,1960,1964,1968,1972,1976,1980,1984,
		1988,1992,1996,2000,2004,2008,2012,2016,2020,2024])
	var time_s := PackedFloat64Array([
		12.00,11.00,11.00,10.80,10.80,10.80,10.60,10.80,10.30,10.30,
		10.30,10.40,10.50,10.20,10.00, 9.95, 10.14, 10.06, 10.25, 9.99,
		 9.92, 9.96, 9.84, 9.87, 9.85, 9.69, 9.63, 9.81, 9.80, 9.79])

	var dataset := Dataset.make_shared_x_continuous(
		PackedStringArray(["Gold"]),
		year, [time_s] as Array[PackedFloat64Array])

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.include_zero_in_domain = false
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.DATA_UNITS
	x_axis.domain_padding_min = 4.0
	x_axis.domain_padding_max = 4.0
	x_axis.tick_count_preferred = 8

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.title = "Time"
	y_axis.include_zero_in_domain = false
	y_axis.range_override_enabled = true
	y_axis.min_override = 9.0
	y_axis.max_override = 12.5
	y_axis.tick_count_preferred = 7
	y_axis.format_tick_label = func(label: String) -> String:
		return "%ss" % label

	var scatter_cfg := TauScatterConfig.new()

	var grid := TauGridLineConfig.new()
	grid.y_major_enabled = true
	grid.x_major_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_cfg]
	pane.grid_line = grid

	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.panes = [pane]

	var binding := TauXYSeriesBinding.new()
	binding.series_id = 1
	binding.pane_index = 0
	binding.overlay_type = PaneOverlayType.SCATTER
	binding.y_axis_id = AxisId.LEFT

	plot.plot_xy(dataset, xy, [binding])


####################################################################################################
# DEMO 9 -- Ionization Energy Across the Periodic Table
####################################################################################################

func _setup_demo_9(plot: TauPlot) -> void:
	plot.title = "[b]Ionization Energy[/b] [color=#666666]Across the Periodic Table[/color]"
	plot.legend_enabled = false

	var z := PackedFloat64Array()
	for i in range(1, 87):
		z.append(float(i))

	var ie := PackedFloat64Array([
		13.60,24.59, 5.39, 9.32, 8.30,11.26,14.53,13.62,17.42,21.56,
		 5.14, 7.65, 5.99, 8.15,10.49,10.36,12.97,15.76, 4.34, 6.11,
		 6.56, 6.83, 6.75, 6.77, 7.43, 7.90, 7.88, 7.64, 7.73, 9.39,
		 6.00, 7.90, 9.79, 9.75,11.81,14.00, 4.18, 5.69, 6.22, 6.63,
		 6.76, 7.09, 7.28, 7.36, 7.46, 8.34, 7.58, 8.99, 5.79, 7.34,
		 8.61, 9.01,10.45,12.13, 3.89, 5.21, 5.58, 5.54, 5.47, 5.53,
		 5.58, 5.64, 5.67, 6.15, 5.86, 5.94, 6.02, 6.10, 6.18, 6.25,
		 5.43, 6.83, 7.55, 7.86, 7.83, 8.44, 8.97, 8.96, 9.23, 10.44,
		 6.11, 7.42, 7.29, 8.41, 9.30,10.75])

	var dataset := Dataset.make_shared_x_continuous(
		PackedStringArray(["1st IE"]),
		z, [ie] as Array[PackedFloat64Array])

	# Per-sample visual attributes
	var va := ScatterVisualAttributes.new()

	var c_alkali := Color(0.85, 0.25, 0.25)
	var c_alkaline := Color(0.92, 0.55, 0.20)
	var c_transition := Color(0.35, 0.55, 0.75)
	var c_post_trans := Color(0.50, 0.70, 0.45)
	var c_metalloid := Color(0.65, 0.50, 0.70)
	var c_nonmetal := Color(0.25, 0.65, 0.55)
	var c_halogen := Color(0.70, 0.60, 0.20)
	var c_noble := Color(0.55, 0.35, 0.70)
	var c_lanthanide := Color(0.60, 0.68, 0.42)

	var group_for_z: Array[int] = [
		5,  7,  0,  1,  4,  5,  5,  5,  6,  7,
		0,  1,  3,  4,  5,  5,  6,  7,  0,  1,
		2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
		3,  4,  4,  5,  6,  7,  0,  1,  2,  2,
		2,  2,  2,  2,  2,  2,  2,  2,  3,  4,
		4,  4,  6,  7,  0,  1,  8,  8,  8,  8,
		8,  8,  8,  8,  8,  8,  8,  8,  8,  8,
		2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
		3,  3,  3,  3,  6,  7]
	var group_colors: Array[Color] = [
		c_alkali, c_alkaline, c_transition, c_post_trans,
		c_metalloid, c_nonmetal, c_halogen, c_noble, c_lanthanide]

	var colors := ColorBuffer.new(86)
	for i in range(86):
		colors.append_value(group_colors[group_for_z[i]])
	va.color_buffer = colors

	var period_for_z: Array[int] = [
		1,1,
		2,2,2,2,2,2,2,2,
		3,3,3,3,3,3,3,3,
		4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
		5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
		6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6]

	var sizes := Float32Buffer.new(86)
	for i in range(86):
		sizes.append_value(5.0 + float(period_for_z[i]) * 1.8)
	va.size_buffer = sizes

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.title = "Atomic Number (Z)"
	x_axis.include_zero_in_domain = false
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.DATA_UNITS
	x_axis.domain_padding_min = 2.0
	x_axis.domain_padding_max = 2.0
	x_axis.tick_count_preferred = 9

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.title = "1st Ionization Energy (eV)"
	y_axis.include_zero_in_domain = true
	y_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.FRACTION
	y_axis.domain_padding_min = 0.0
	y_axis.domain_padding_max = 0.06
	y_axis.tick_count_preferred = 7

	var scatter_cfg := TauScatterConfig.new()

	var grid := TauGridLineConfig.new()
	grid.y_major_enabled = true
	grid.x_major_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_cfg]
	pane.grid_line = grid

	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.panes = [pane]

	var binding := TauXYSeriesBinding.new()
	binding.series_id = 1
	binding.pane_index = 0
	binding.overlay_type = PaneOverlayType.SCATTER
	binding.y_axis_id = AxisId.LEFT
	binding.visual_attributes = va

	plot.plot_xy(dataset, xy, [binding])
