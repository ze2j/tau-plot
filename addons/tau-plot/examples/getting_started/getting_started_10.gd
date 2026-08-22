extends CenterContainer

# Stretch ratios of the response time pane.
const INITIAL_STRETCH_RATIO := 0.05
const FINAL_STRETCH_RATIO := 3.0

# Alphas of the response time series.
const INITIAL_ALPHA := 0.0
const FINAL_ALPHA := 0.9

const ANIMATION_DURATION := 1.1

const REQUESTS_ALPHA := 1.0
const REQUESTS_STRETCH_RATIO := 3.0

var _config: TauXYConfig
var _response_time_pane: TauPaneConfig


func _ready() -> void:
	# One hour of a web service, one reading per minute.
	var minutes := PackedFloat64Array()
	var response_time := PackedFloat64Array()
	var requests := PackedFloat64Array()
	for i in 60:
		var minute := float(i)
		minutes.append(minute)
		response_time.append(120.0 + 45.0 * sin(minute * 0.31) + 18.0 * cos(minute * 0.13))
		requests.append(420.0 + 3.0 * minute + 90.0 * sin(minute * 0.22))

	var dataset := TauPlot.Dataset.make_shared_x_continuous(
		PackedStringArray(["Response time (ms)", "Requests per minute"]),
		minutes,
		[response_time, requests] as Array[PackedFloat64Array]
	)

	var x_axis := TauAxisConfig.new()
	x_axis.title = "Minute"

	# The response time pane starts nearly closed.
	_response_time_pane = TauPaneConfig.new()
	_response_time_pane.y_left_axis = TauAxisConfig.new()
	_response_time_pane.overlays = [TauLineConfig.new()]
	_response_time_pane.stretch_ratio = INITIAL_STRETCH_RATIO

	# The requests pane sits at the bottom.
	var requests_pane := TauPaneConfig.new()
	requests_pane.y_left_axis = TauAxisConfig.new()
	requests_pane.overlays = [TauLineConfig.new()]
	requests_pane.stretch_ratio = REQUESTS_STRETCH_RATIO

	_config = TauXYConfig.new()
	_config.x_axis = x_axis
	_config.panes = [_response_time_pane, requests_pane]

	# series_alphas is a cycle, one entry per series. The first entry is the
	# response time series, which starts fully transparent.
	_config.style.series_alphas = [INITIAL_ALPHA, REQUESTS_ALPHA]

	var b_response_time := TauXYSeriesBinding.new()
	b_response_time.series_id = dataset.get_series_id_by_index(0)
	b_response_time.pane_index = 0
	b_response_time.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	b_response_time.y_axis_id = TauPlot.AxisId.LEFT

	var b_requests := TauXYSeriesBinding.new()
	b_requests.series_id = dataset.get_series_id_by_index(1)
	b_requests.pane_index = 1
	b_requests.overlay_type = TauXYSeriesBinding.PaneOverlayType.LINE
	b_requests.y_axis_id = TauPlot.AxisId.LEFT

	var bindings: Array[TauXYSeriesBinding] = [b_response_time, b_requests]

	$MyPlot.title = "Web Service Health"

	var legend_config := TauLegendConfig.new()
	legend_config.position = TauLegendConfig.Position.OUTSIDE_RIGHT
	$MyPlot.legend_config = legend_config

	$MyPlot.plot_xy(dataset, _config, bindings)

	# The response time pane opens while its series fades in.
	var tween := create_tween()
	tween.set_parallel()
	tween.tween_method(_open_response_time_to, INITIAL_STRETCH_RATIO, FINAL_STRETCH_RATIO, ANIMATION_DURATION)
	tween.tween_method(_fade_response_time_to, INITIAL_ALPHA, FINAL_ALPHA, ANIMATION_DURATION)


func _open_response_time_to(ratio: float) -> void:
	# The plot must be refreshed explicitly after a configuration object is mutated.
	_response_time_pane.stretch_ratio = ratio
	$MyPlot.queue_refresh()


func _fade_response_time_to(alpha: float) -> void:
	# Style resource mutations are detected by the plot, which refreshes on its own.
	_config.style.series_alphas = [alpha, REQUESTS_ALPHA]
