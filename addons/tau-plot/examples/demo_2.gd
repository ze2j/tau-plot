extends VBoxContainer

const Dataset = TauPlot.Dataset
const AxisId = TauPlot.AxisId
const PaneOverlayType = TauPlot.PaneOverlayType
const MarkerShape = TauScatterStyle.MarkerShape
const LegendPosition = TauLegendConfig.Position
const ColorBuffer = TauPlot.ColorBuffer
const Float32Buffer = TauPlot.Float32Buffer
const ScatterVisualCallbacks = TauPlot.ScatterVisualCallbacks
const LineVisualCallbacks = TauPlot.LineVisualCallbacks
const BarVisualCallbacks = TauPlot.BarVisualCallbacks
const ScatterVisualAttributes = TauPlot.ScatterVisualAttributes


func _ready() -> void:
	_setup_demo_1(%DemoPlot1)
	_setup_demo_2(%DemoPlot2)
	_setup_demo_3(%DemoPlot3)


func _process(delta: float) -> void:
	_process_demo_2(delta)


####################################################################################################
# DEMO 1 -- Tour du Mont Blanc Altitude Profile
#
# The terrain is resampled every 500 m from published waypoint altitudes and
# roughened, so it reads at the resolution of a track while every named
# altitude stays exact.
#
# The waypoints sit in a scatter overlay above the terrain line, at a much
# coarser resolution. Hovering near one reads two positions at once: the
# altitude under the cursor, and the named altitude a few hundred metres away.
####################################################################################################

func _setup_demo_1(plot: TauPlot) -> void:
	plot.title = "[b]Tour du Mont Blanc[/b] [color=#888888]Altitude Profile[/color]"
	plot.legend_enabled = true
	plot.legend_config = TauLegendConfig.new()
	plot.legend_config.position = LegendPosition.INSIDE_BOTTOM_RIGHT

	# Low and high end of the y axis.
	var altitude_min := 600.0
	var altitude_max := 2800.0
	# Top of the temperature inversion.
	var fog_top := 1900.0

	# name, distance (km), altitude (m)
	var waypoints := [
		["Les Houches", 0.0, 1008.0],
		["Col de Voza", 6.0, 1653.0],
		["Les Contamines", 16.0, 1164.0],
		["Col du Bonhomme", 27.5, 2329.0],
		["Col de la Croix du Bonhomme", 29.0, 2479.0],
		["Les Chapieux", 34.0, 1554.0],
		["Col de la Seigne", 46.0, 2516.0],
		["Courmayeur", 67.0, 1224.0],
		["Grand Col Ferret", 92.0, 2537.0],
		["La Fouly", 99.0, 1600.0],
		["Champex", 114.0, 1466.0],
		["Col de Balme", 137.0, 2191.0],
		["Col du Br\u00e9vent", 156.0, 2368.0],
		["Les Houches", 168.0, 1008.0],
	]

	var waypoint_km := PackedFloat64Array()
	var waypoint_m := PackedFloat64Array()
	for wp in waypoints:
		waypoint_km.append(wp[1])
		waypoint_m.append(wp[2])

	# Terrain, resampled between the waypoints.
	var step_km := 0.5
	var noise_amplitude_m := 70.0
	var terrain_km := PackedFloat64Array()
	var terrain_m := PackedFloat64Array()
	for i in range(waypoints.size() - 1):
		var from_wp: Array = waypoints[i]
		var to_wp: Array = waypoints[i + 1]
		var from_km: float = from_wp[1]
		var to_km: float = to_wp[1]
		var steps := int((to_km - from_km) / step_km)
		for s in range(steps):
			var t := float(s) / steps
			var km: float = lerpf(from_km, to_km, t)
			var base: float = lerpf(from_wp[2], to_wp[2], t * t * (3.0 - 2.0 * t))
			var noise := sin(km * 0.55) * 0.5 + sin(km * 1.3 + 1.7) * 0.3 + sin(km * 2.4 + 0.4) * 0.2
			terrain_km.append(km)
			terrain_m.append(base + noise * sin(PI * t) * noise_amplitude_m)
	terrain_km.append(waypoint_km[waypoint_km.size() - 1])
	terrain_m.append(waypoint_m[waypoint_m.size() - 1])

	# The fog line is a slow sin with a coarse sampling.
	var fog_km := PackedFloat64Array()
	var fog_m := PackedFloat64Array()
	var route_km: float = waypoint_km[waypoint_km.size() - 1]
	var fog_distance := 0.0
	while fog_distance < route_km:
		fog_km.append(fog_distance)
		fog_m.append(fog_top + 45.0 * sin(fog_distance * 0.06))
		fog_distance += 2.0
	fog_km.append(route_km)
	fog_m.append(fog_top + 45.0 * sin(route_km * 0.06))

	var dataset := Dataset.make_per_series_x_continuous(
		PackedStringArray(["Terrain", "Valley fog", "Waypoints"]),
		[terrain_km, fog_km, waypoint_km] as Array[PackedFloat64Array],
		[terrain_m, fog_m, waypoint_m] as Array[PackedFloat64Array])

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.title = "Distance (km)"
	x_axis.include_zero_in_domain = false
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.NONE
	x_axis.tick_count_preferred = 9

	var y_axis := TauAxisConfig.new()
	y_axis.type = TauAxisConfig.Type.CONTINUOUS
	y_axis.title = "Altitude (m)"
	y_axis.include_zero_in_domain = false
	y_axis.range_override_enabled = true
	y_axis.min_override = altitude_min
	y_axis.max_override = altitude_max
	y_axis.tick_count_preferred = 6

	var terrain_fill := TauLineFill.new()
	terrain_fill.fill_baseline = altitude_min
	terrain_fill.stretch_range_policy = TauLineFill.StretchRangePolicy.CUSTOM
	terrain_fill.stretch_range = Vector2(altitude_min, altitude_max)

	var fog_fill := TauLineFill.new()
	fog_fill.fill_baseline = altitude_min
	fog_fill.stretch_range_policy = TauLineFill.StretchRangePolicy.CUSTOM
	fog_fill.stretch_range = Vector2(altitude_min, fog_top + 50.0)

	var line_cfg := TauLineConfig.new()
	line_cfg.interpolation_modes = [TauLineConfig.InterpolationMode.LINEAR]
	line_cfg.z_order = TauLineConfig.ZOrder.REVERSE_SERIES_ORDER
	line_cfg.style.fills = [terrain_fill, fog_fill]

	var scatter_cfg := TauScatterConfig.new()
	scatter_cfg.hover_max_distance_px = 20

	var grid := TauGridLineConfig.new()
	grid.y_major_enabled = true

	var pane := TauPaneConfig.new()
	pane.y_left_axis = y_axis
	pane.overlays = [line_cfg, scatter_cfg]
	pane.grid_line = grid

	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.panes = [pane]

	var terrain_id := dataset.get_series_id_by_index(0)
	var waypoint_id := dataset.get_series_id_by_index(2)

	var hover := TauHoverConfig.new()
	hover.hover_mode = TauHoverConfig.HoverMode.X_ALIGNED
	hover.crosshair_mode = TauHoverConfig.CrosshairMode.X_ONLY
	hover.format_tooltip_text = func(hits: Array[TauPlot.SampleHit]) -> String:
		var terrain_text := ""
		var waypoint_text := ""
		for hit in hits:
			var km: float = hit.x_value
			if hit.series_id == terrain_id:
				terrain_text = "%d m at %.1f km" % [int(hit.y_raw_value), km]
			elif hit.series_id == waypoint_id:
				waypoint_text = "[b]%s[/b]  %d m at %.1f km" % [waypoints[hit.sample_index][0], int(hit.y_raw_value), km]

		if waypoint_text.is_empty():
			return terrain_text
		return terrain_text + "\n" + waypoint_text
	hover.hover_highlight_callback = func(color: Color, hovered: bool) -> Color:
		return color.lightened(0.4) if hovered else color

	var b_terrain := TauXYSeriesBinding.new()
	b_terrain.series_id = terrain_id
	b_terrain.pane_index = 0
	b_terrain.overlay_type = PaneOverlayType.LINE
	b_terrain.y_axis_id = AxisId.LEFT
	b_terrain.show_in_legend = false

	var b_fog := TauXYSeriesBinding.new()
	b_fog.series_id = dataset.get_series_id_by_index(1)
	b_fog.pane_index = 0
	b_fog.overlay_type = PaneOverlayType.LINE
	b_fog.y_axis_id = AxisId.LEFT

	var b_waypoints := TauXYSeriesBinding.new()
	b_waypoints.series_id = waypoint_id
	b_waypoints.pane_index = 0
	b_waypoints.overlay_type = PaneOverlayType.SCATTER
	b_waypoints.y_axis_id = AxisId.LEFT

	plot.hover_config = hover
	plot.plot_xy(dataset, xy, [b_terrain, b_fog, b_waypoints])


####################################################################################################
# DEMO 2 -- Patient Monitor
#
# A five second window at 250 Hz, overwritten in place by a sweeping cursor.
# The dataset is built once and only its Y values are rewritten, so both
# domains are computed once and the frame never moves.
#
# The sweep reads through the alpha ramp behind the cursor and the blanking
# window ahead of it, so the trace stays legible at a glance without any
# rendering feature beyond the line overlay.
#
# Every beat differs slightly from the last, and all of it comes from one
# respiratory cycle rather than from noise: the RR interval, the ECG baseline,
# the R wave height and the pulse amplitude all follow the breath.
####################################################################################################

const ECG_SAMPLE_RATE := 250.0
const ECG_SAMPLE_COUNT := 1250

# Blanking window ahead of the sweep, the erase bar of a real monitor.
const ECG_BLANK_COUNT := 38

# Resting RR interval, 75 beats per minute, before respiratory modulation.
const ECG_BEAT_PERIOD := 0.8

# Where the R peak sits inside a beat, far enough from both ends that the P and
# T waves of one beat stay in the same interval.
const ECG_R_PHASE := 0.30

# Delay from the QRS to the systolic upstroke at the fingertip, which is what
# makes the two traces read as one patient.
const ECG_PULSE_TRANSIT := 0.20

# One breath, 15 per minute.
const ECG_RESP_PERIOD := 4.0

# Peak swing of the RR interval across a breath, as a fraction of ECG_BEAT_PERIOD.
const ECG_RSA_DEPTH := 0.06

const ECG_TRAIL_MIN_ALPHA := 0.35

var _ecg_dataset: Dataset
var _ecg_series_id: int
var _pleth_series_id: int

# Index of the next sample to write.
var _ecg_cursor: int = 0

# Fractional sample carried across frames.
var _ecg_remainder: float = 0.0

# Time of the next sample, running free of the sweep so beats land wherever
# they fall rather than in step with the window.
var _ecg_clock: float = 0.0

# Time since the current beat started, and the interval that beat was given.
var _ecg_beat_time: float = 0.0
var _ecg_rr: float = ECG_BEAT_PERIOD

# The pulse trails the QRS, so at the start of a beat the fingertip is still
# finishing the previous one and needs its interval.
var _ecg_rr_previous: float = ECG_BEAT_PERIOD

var _ecg_blank: PackedFloat64Array


# Every write is an overwrite at a known index, split in two when it crosses
# the end of the buffer.
func _write_wrapped(p_series_id: int, p_start_index: int, p_values: PackedFloat64Array) -> void:
	var start := p_start_index % ECG_SAMPLE_COUNT
	var head := ECG_SAMPLE_COUNT - start
	if p_values.size() <= head:
		_ecg_dataset.set_series_y_slice(p_series_id, start, p_values)
		return
	_ecg_dataset.set_series_y_slice(p_series_id, start, p_values.slice(0, head))
	_ecg_dataset.set_series_y_slice(p_series_id, 0, p_values.slice(head))


# Gaussian of unit height, p_width being the offset at which it falls to 1/e.
func _bell(p_offset: float, p_width: float) -> float:
	var n := p_offset / p_width
	return exp(-n * n)


# Gaussian with a steeper leading edge, for a wave that rises faster than it
# decays.
func _skewed_bell(p_offset: float, p_rise: float, p_fall: float) -> float:
	return _bell(p_offset, p_rise if p_offset < 0.0 else p_fall)


# Breathing, in [-1, 1], the single source of every slow variation here. The
# second component sits near the first in frequency so breath depth wanders
# instead of repeating on the dot.
func _respiration(p_time: float) -> float:
	return 0.8 * sin(TAU * p_time / ECG_RESP_PERIOD) + 0.2 * sin(TAU * p_time / (ECG_RESP_PERIOD * 1.31))


# Advances the sample clock and the beat clock by one sample period.
#
# The interval of the next beat is drawn once, when that beat starts, and the
# diastolic pause absorbs the difference. Waveform durations stay put, which is
# what respiratory sinus arrhythmia does at rest: the gap between beats moves,
# the complexes do not.
func _advance_heart(p_delta: float) -> void:
	_ecg_clock += p_delta
	_ecg_beat_time += p_delta
	if _ecg_beat_time >= _ecg_rr:
		_ecg_beat_time -= _ecg_rr
		_ecg_rr_previous = _ecg_rr
		_ecg_rr = ECG_BEAT_PERIOD * (1.0 + ECG_RSA_DEPTH * _respiration(_ecg_clock))


# Lead II in millivolts: P wave, QRS complex, T wave, on a baseline that drifts
# with the chest. The R wave grows and shrinks over the breath as well, the
# same effect ECG derived respiration reads a breathing rate from.
func _ecg_millivolts() -> float:
	var t := _ecg_beat_time - ECG_R_PHASE
	var breath := _respiration(_ecg_clock)
	var mv := 0.040 * breath
	mv += 0.14 * _bell(t + 0.160, 0.028)
	mv -= 0.12 * _bell(t + 0.025, 0.008)
	mv += 1.55 * (1.0 + 0.05 * breath) * _bell(t, 0.010)
	mv -= 0.28 * _bell(t - 0.028, 0.012)
	mv += 0.35 * _bell(t - 0.200, 0.045)
	return mv


# Fingertip plethysmograph: a fast systolic upstroke, a dicrotic notch, then a
# slow decay. Pulse amplitude rides the breath, the respiratory variation a
# monitor shows in the pleth channel.
func _pleth_level() -> float:
	var t := _ecg_beat_time - ECG_R_PHASE - ECG_PULSE_TRANSIT
	if t < 0.0:
		t += _ecg_rr_previous
	var breath := _respiration(_ecg_clock)
	var amplitude := 1.0 + 0.10 * breath
	var level := 0.10 + 0.03 * breath
	level += 0.72 * amplitude * _skewed_bell(t - 0.13, 0.045, 0.070)
	level += 0.22 * amplitude * _bell(t - 0.30, 0.090)
	return level


func _setup_demo_2(plot: TauPlot) -> void:
	plot.title = "[b]Patient Monitor[/b] [color=#4d7a68]Lead II and photoplethysmogram[/color]"
	plot.legend_enabled = false
	plot.hover_enabled = false

	var x := PackedFloat64Array()
	x.resize(ECG_SAMPLE_COUNT)
	for i in range(ECG_SAMPLE_COUNT):
		x[i] = float(i) / ECG_SAMPLE_RATE

	# The screen starts blank and fills in as the sweep runs.
	var blank := PackedFloat64Array()
	blank.resize(ECG_SAMPLE_COUNT)
	blank.fill(NAN)

	_ecg_blank = PackedFloat64Array()
	_ecg_blank.resize(ECG_BLANK_COUNT)
	_ecg_blank.fill(NAN)

	_ecg_dataset = Dataset.make_shared_x_continuous(
		PackedStringArray(["ECG II", "Pleth"]),
		x,
		[blank, blank] as Array[PackedFloat64Array])

	_ecg_series_id = _ecg_dataset.get_series_id_by_index(0)
	_pleth_series_id = _ecg_dataset.get_series_id_by_index(1)

	# The window is five seconds wide whatever the samples span, and 26
	# preferred ticks over it resolve to the 0.2 s big block of ECG paper.
	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.range_override_enabled = true
	x_axis.min_override = 0.0
	x_axis.max_override = 5.0
	x_axis.tick_count_preferred = 26

	# A monitor puts no numbers on the trace.
	var no_label := func(_label: String) -> String:
		return ""
	x_axis.format_tick_label = no_label

	var ecg_axis := TauAxisConfig.new()
	ecg_axis.type = TauAxisConfig.Type.CONTINUOUS
	ecg_axis.title = "ECG II (mV)"
	ecg_axis.range_override_enabled = true
	ecg_axis.min_override = -1.0
	ecg_axis.max_override = 2.0
	ecg_axis.tick_count_preferred = 7
	ecg_axis.format_tick_label = no_label

	var pleth_axis := TauAxisConfig.new()
	pleth_axis.type = TauAxisConfig.Type.CONTINUOUS
	pleth_axis.title = "Pleth"
	pleth_axis.range_override_enabled = true
	pleth_axis.min_override = 0.0
	pleth_axis.max_override = 1.0
	pleth_axis.tick_count_preferred = 3
	pleth_axis.format_tick_label = no_label

	# Age behind the cursor drives the phosphor fade. Reading nothing but the
	# cursor and the sample index, one instance serves both panes.
	var trail := LineVisualCallbacks.new()
	trail.alpha_callback = func(_series_index: int, sample_index: int, _x_value: Variant, _y_value: float) -> float:
		var age := (_ecg_cursor - sample_index + ECG_SAMPLE_COUNT) % ECG_SAMPLE_COUNT
		return lerpf(1.0, ECG_TRAIL_MIN_ALPHA, float(age) / float(ECG_SAMPLE_COUNT))

	# The blanking window is written as NaN, so SKIP is what opens the erase bar.
	var ecg_line := TauLineConfig.new()
	ecg_line.gap_policy = TauLineConfig.GapPolicy.SKIP
	ecg_line.line_visual_callbacks = trail

	var pleth_line := TauLineConfig.new()
	pleth_line.gap_policy = TauLineConfig.GapPolicy.SKIP
	pleth_line.line_visual_callbacks = trail

	var ecg_grid := TauGridLineConfig.new()
	ecg_grid.x_major_enabled = true
	ecg_grid.y_major_enabled = true

	var pleth_grid := TauGridLineConfig.new()
	pleth_grid.x_major_enabled = true
	pleth_grid.y_major_enabled = true

	var ecg_pane := TauPaneConfig.new()
	ecg_pane.y_left_axis = ecg_axis
	ecg_pane.overlays = [ecg_line]
	ecg_pane.grid_line = ecg_grid
	ecg_pane.stretch_ratio = 3.0

	var pleth_pane := TauPaneConfig.new()
	pleth_pane.y_left_axis = pleth_axis
	pleth_pane.overlays = [pleth_line]
	pleth_pane.grid_line = pleth_grid
	pleth_pane.stretch_ratio = 1.0

	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.panes = [ecg_pane, pleth_pane]

	var b_ecg := TauXYSeriesBinding.new()
	b_ecg.series_id = _ecg_series_id
	b_ecg.pane_index = 0
	b_ecg.overlay_type = PaneOverlayType.LINE
	b_ecg.y_axis_id = AxisId.LEFT

	var b_pleth := TauXYSeriesBinding.new()
	b_pleth.series_id = _pleth_series_id
	b_pleth.pane_index = 1
	b_pleth.overlay_type = PaneOverlayType.LINE
	b_pleth.y_axis_id = AxisId.LEFT

	plot.plot_xy(_ecg_dataset, xy, [b_ecg, b_pleth])


func _process_demo_2(delta: float) -> void:
	_ecg_remainder += ECG_SAMPLE_RATE * delta
	var steps := int(_ecg_remainder)
	if steps == 0:
		return
	_ecg_remainder -= float(steps)

	var sample_period := 1.0 / ECG_SAMPLE_RATE
	var ecg := PackedFloat64Array()
	var pleth := PackedFloat64Array()
	ecg.resize(steps)
	pleth.resize(steps)
	for i in range(steps):
		_advance_heart(sample_period)
		ecg[i] = _ecg_millivolts()
		pleth[i] = _pleth_level()

	# Fresh samples at the cursor, blanking window ahead of it.
	_ecg_dataset.begin_batch()
	_write_wrapped(_ecg_series_id, _ecg_cursor, ecg)
	_write_wrapped(_pleth_series_id, _ecg_cursor, pleth)
	_write_wrapped(_ecg_series_id, _ecg_cursor + steps, _ecg_blank)
	_write_wrapped(_pleth_series_id, _ecg_cursor + steps, _ecg_blank)
	_ecg_dataset.end_batch()

	_ecg_cursor = (_ecg_cursor + steps) % ECG_SAMPLE_COUNT


####################################################################################################
# DEMO 3 -- Frame Profile
#
# Seven of Godot's own monitors over one five second capture, one pane each. The
# timing panes and the memory panes are on unrelated scales, which is why every
# pane carries its own y axis and reads its name and unit off the axis title.
#
# One gradient serves all seven. Each fill stretches it over the budget of its
# own pane, so a color always means the same thing: how much of that budget the
# frame spent. A 1 ms navigation spike reads at the same point of the gradient
# as a 192 MB texture load reads of its own budget.
####################################################################################################

# Five seconds at the vsync rate below.
const PERF_FRAME_COUNT := 600

# Refresh rate the capture is vsynced to, and the floor of the frame rate pane.
const PERF_VSYNC_FPS := 120.0
const PERF_FPS_FLOOR := 45.0

# Axis title, floor and top of the y axis, preferred tick count, and the budget
# the fill texture saturates at. Top and budget differ on Physics alone, which
# is given room above its budget so the pile-up stays on screen.
const PERF_MONITORS := [
	["FPS", PERF_FPS_FLOOR, PERF_VSYNC_FPS, 4, PERF_VSYNC_FPS],
	["Process (ms)", 0.0, 8.0, 5, 8.0],
	["Physics (ms)", 0.0, 14.0, 3, 4.0],
	["Nav (ms)", 0.0, 2.0, 3, 2.0],
	["Video (MB)", 0.0, 512.0, 3, 512.0],
	["Texture (MB)", 0.0, 384.0, 4, 384.0],
	["Buffer (MB)", 0.0, 128.0, 3, 128.0],
]

const PERF_FPS_INDEX := 0
const PERF_PHYSICS_INDEX := 2

# Frames where a batch of assets is committed. Each one steps texture memory,
# raises the buffer memory target and costs one process spike.
const PERF_BATCH_FRAMES: Array[int] = [90, 128, 172, 210, 254, 300, 348, 392]
const PERF_BATCH_TEXTURE_MB: Array[float] = [38.0, 44.0, 30.0, 52.0, 41.0, 36.0, 48.0, 27.0]
const PERF_BATCH_BUFFER_MB: Array[float] = [9.0, 7.0, 11.0, 6.0, 10.0, 8.0, 12.0, 5.0]

# Frames where the navigation server rebuilds a path.
const PERF_REPATH_FRAMES: Array[int] = [150, 232, 305, 306, 362, 470]

# What the frame costs outside the three timing monitors: rendering, input and
# the swap. Held constant so the frame rate follows the monitors that are shown.
const PERF_RENDER_OVERHEAD_MS := 3.1

# Physics budget, the level the physics band is anchored at. Same value as the
# budget of the Physics row of PERF_MONITORS.
const PERF_PHYSICS_BUDGET_MS := 4.0

const PERF_PILEUP_FIRST_FRAME := 300
const PERF_PILEUP_LAST_FRAME := 372
const PERF_PILEUP_PEAK_MS := 11.0


# Frame to frame noise in [-0.8, 0.8]. Two sines whose periods do not divide
# each other, so the capture is reproducible without carrying a seed.
func _perf_jitter(p_frame: int) -> float:
	return 0.5 * sin(p_frame * 2.399) + 0.3 * sin(p_frame * 5.117)


# Physics cost added by the pile-up, a bell over the frames it lasts.
func _perf_pileup(p_frame: int) -> float:
	if p_frame < PERF_PILEUP_FIRST_FRAME or p_frame > PERF_PILEUP_LAST_FRAME:
		return 0.0
	var t := float(p_frame - PERF_PILEUP_FIRST_FRAME) / float(PERF_PILEUP_LAST_FRAME - PERF_PILEUP_FIRST_FRAME)
	return PERF_PILEUP_PEAK_MS * pow(sin(PI * t), 1.6)


# One capture, in the order of PERF_MONITORS. A level streams in: texture and
# video memory climb in steps, buffer memory follows, process time spikes on
# every allocation batch, navigation spikes on a repath, and a physics pile-up
# around frame 300 drags the frame rate far below the vsync cap.
#
# The frame rate is derived from the timing monitors rather than authored, so
# the dip lands on the frames that pay for it.
func _build_perf_capture() -> Array[PackedFloat64Array]:
	var fps := PackedFloat64Array()
	var process_ms := PackedFloat64Array()
	var physics_ms := PackedFloat64Array()
	var navigation_ms := PackedFloat64Array()
	var video_mb := PackedFloat64Array()
	var texture_mb := PackedFloat64Array()
	var buffer_mb := PackedFloat64Array()

	var texture_used := 42.0
	var buffer_used := 14.0
	var buffer_target := 14.0
	var process_spike := 0.0
	var navigation_spike := 0.0
	var batch_index := 0

	for frame in range(PERF_FRAME_COUNT):
		if batch_index < PERF_BATCH_FRAMES.size() and frame == PERF_BATCH_FRAMES[batch_index]:
			texture_used += PERF_BATCH_TEXTURE_MB[batch_index]
			buffer_target += PERF_BATCH_BUFFER_MB[batch_index]
			process_spike = 2.9
			batch_index += 1
		if frame in PERF_REPATH_FRAMES:
			navigation_spike = 1.35

		# Vertex and index buffers are uploaded after the textures they belong
		# to, so buffer memory trails the step instead of landing on it.
		buffer_used += (buffer_target - buffer_used) * 0.06
		process_spike *= 0.80
		navigation_spike *= 0.55

		var jitter := _perf_jitter(frame)
		var process := 3.55 + process_spike + 0.18 * jitter
		var physics := 1.75 + 0.12 * jitter + _perf_pileup(frame)
		var navigation := 0.22 + navigation_spike + 0.05 * jitter
		var frame_ms := process + physics + navigation + PERF_RENDER_OVERHEAD_MS

		fps.append(minf(PERF_VSYNC_FPS, 1000.0 / frame_ms))
		process_ms.append(process)
		physics_ms.append(physics)
		navigation_ms.append(navigation)
		video_mb.append(64.0 + texture_used + buffer_used + 2.0 * jitter)
		texture_mb.append(texture_used)
		buffer_mb.append(buffer_used)

	return [fps, process_ms, physics_ms, navigation_ms,
		video_mb, texture_mb, buffer_mb]


func _setup_demo_3(plot: TauPlot) -> void:
	plot.title = "[b]Frame Profile[/b] [color=#888888]600 frames of a level streaming in[/color]"
	plot.legend_enabled = false
	plot.hover_enabled = false

	var frames := PackedFloat64Array()
	frames.resize(PERF_FRAME_COUNT)
	for i in range(PERF_FRAME_COUNT):
		frames[i] = float(i)

	var dataset := Dataset.make_shared_x_continuous(
		PackedStringArray(["FPS", "Process", "Physics Process", "Navigation Process",
			"Video Mem", "Texture Mem", "Buffer Mem"]),
		frames,
		_build_perf_capture())

	var x_axis := TauAxisConfig.new()
	x_axis.type = TauAxisConfig.Type.CONTINUOUS
	x_axis.title = "Frame"
	x_axis.domain_padding_mode = TauAxisConfig.DomainPaddingMode.NONE
	x_axis.tick_count_preferred = 7

	var panes: Array[TauPaneConfig] = []
	var fills: Array[TauLineFill] = []
	var bindings: Array[TauXYSeriesBinding] = []

	for i in range(PERF_MONITORS.size()):
		var monitor: Array = PERF_MONITORS[i]
		var axis_title: String = monitor[0]
		var axis_floor: float = monitor[1]
		var axis_top: float = monitor[2]
		var tick_count: int = monitor[3]
		var budget: float = monitor[4]

		var y_axis := TauAxisConfig.new()
		y_axis.type = TauAxisConfig.Type.CONTINUOUS
		y_axis.title = axis_title
		y_axis.title_orientation = TauAxisConfig.TitleOrientation.HORIZONTAL
		y_axis.title_text_alignment = TauAxisConfig.TextAlignment.LEFT
		y_axis.range_override_enabled = true
		y_axis.min_override = axis_floor
		y_axis.max_override = axis_top
		y_axis.tick_count_preferred = tick_count

		var fill := TauLineFill.new()
		fill.fill_baseline = axis_floor
		fill.stretch_range_policy = TauLineFill.StretchRangePolicy.CUSTOM
		fill.stretch_range = Vector2(0.0, budget)
		fills.append(fill)

		var outline_px := 1.0 if i == PERF_FPS_INDEX else 0.0

		var line_cfg := TauLineConfig.new()
		line_cfg.style.line_widths_px = [outline_px]
		line_cfg.style.fills = [fill]

		var grid := TauGridLineConfig.new()
		grid.x_major_enabled = true
		grid.y_major_enabled = true

		var pane := TauPaneConfig.new()
		pane.y_left_axis = y_axis
		pane.overlays = [line_cfg]
		pane.grid_line = grid
		panes.append(pane)

		var binding := TauXYSeriesBinding.new()
		binding.series_id = dataset.get_series_id_by_index(i)
		binding.pane_index = i
		binding.overlay_type = PaneOverlayType.LINE
		binding.y_axis_id = AxisId.LEFT
		bindings.append(binding)

	# The frame rate is the one monitor where higher is better.
	fills[PERF_FPS_INDEX].fill_baseline = PERF_VSYNC_FPS
	fills[PERF_FPS_INDEX].stretch_range = Vector2(PERF_VSYNC_FPS, PERF_FPS_FLOOR)

	# Physics is anchored at its budget instead of at the floor.
	fills[PERF_PHYSICS_INDEX].fill_baseline = PERF_PHYSICS_BUDGET_MS
	fills[PERF_PHYSICS_INDEX].stretch_span = TauLineFill.FillStretchSpan.MAGNITUDE

	var xy := TauXYConfig.new()
	xy.x_axis_id = AxisId.BOTTOM
	xy.x_axis = x_axis
	xy.panes = panes

	plot.plot_xy(dataset, xy, bindings)
