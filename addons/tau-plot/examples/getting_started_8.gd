extends CenterContainer

var _dataset: TauPlot.Dataset
var _elapsed: float = 0.0

func _ready() -> void:
	# Create an empty dataset with room for 200 samples. When sample 201
	# arrives, the oldest sample is dropped automatically.
	_dataset = TauPlot.Dataset.new(
		TauPlot.Dataset.Mode.SHARED_X,
		TauPlot.Dataset.XElementType.NUMERIC,
		200
	)

	# add_series() returns a stable ID that we will use in the bindings.
	var id_a := _dataset.add_series("Sensor A")
	var id_b := _dataset.add_series("Sensor B")

	var x_axis := TauAxisConfig.new()
	x_axis.title = "Time (s)"
	x_axis.include_zero_in_domain = false
	# Padding adds visual space beyond the data bounds and acts as a
	# performance buffer. When new samples arrive, the plot checks whether
	# their values fall inside the padded domain before deciding to recompute
	# the axis domain and ticks. A larger domain_padding_max means the domain
	# stays valid longer, so recomputes happen less often. The tradeoff:
	#   - domain_padding_max = 0.0 => recompute on almost every frame (smooth, costly)
	#   - domain_padding_max = 1.0 => recompute every ~1 s (jumps, cheap)
	# DATA_UNITS mode is used here so the lookahead is expressed in seconds,
	# matching the X axis unit directly.
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.DATA_UNITS
	x_axis.domain_padding_min = 0.0
	x_axis.domain_padding_max = 0.0

	var y_axis := TauAxisConfig.new()
	y_axis.title = "Value"

	var scatter_cfg := TauScatterConfig.new()

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [scatter_cfg]

	var config := TauXYConfig.new()
	config.x_axis = x_axis
	config.panes = [pane]

	# Use the IDs returned by add_series() to create the bindings.
	var b_a := TauXYSeriesBinding.new()
	b_a.series_id = id_a
	b_a.pane_index = 0
	b_a.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	b_a.y_axis_id = TauPlot.AxisId.LEFT

	var b_b := TauXYSeriesBinding.new()
	b_b.series_id = id_b
	b_b.pane_index = 0
	b_b.overlay_type = TauXYSeriesBinding.PaneOverlayType.SCATTER
	b_b.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [b_a, b_b]

	$MyPlot.title = "Live Sensor Data"
	$MyPlot.plot_xy(_dataset, config, bindings)


func _process(delta: float) -> void:
	_elapsed += delta

	# Push one X value and one Y value per series. The dataset tells the
	# plot that data changed, and the plot redraws on its own.
	var a := sin(_elapsed * 2.0) * 10.0 + 20.0
	var b := cos(_elapsed * 1.5) * 8.0 + 22.0
	_dataset.append_shared_sample(_elapsed, PackedFloat64Array([a, b]))
