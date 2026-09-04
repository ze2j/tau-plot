# Owns the full lifecycle of an XY plot: setup, per-frame refresh, and teardown.
#
# Attached to the xy_plot.tscn scene (root VBoxContainer). Manages the dataset,
# domain, layout, panes, renderers, stale artifacts, and change detection
# state. Delegates axis title management to XYAxisTitleLayout and legend
# management to XYLegendBuilder.
#
# A refresh runs in three phases: resolve, arrange and draw.
#
# Geometry is the size and the position of a Control, in pixels. A pane gets
# its own from the pane stack, a custom container, and only while Godot runs the
# container sort (the engine name for the layout pass).
#
# Resolve runs without geometry. It reads the user resources and recomputes
# what derives from them, the resolved styles and the domain among others.
#
# Arrange runs inside the sort, the one moment the pane rects exist. It
# recomputes the layout: how much of each pane rect the axes take, what data
# area is left, and how a value maps to a pixel inside it. No other phase
# touches a pane rect.
#
# Draw queues a redraw on the panes that changed, and queues a sort on the
# pane stack when the layout is stale. Godot runs the sort, which is where
# arrange happens, and paints after it. So the panes are painted against the
# layout arrange has just settled.

@tool
extends VBoxContainer

const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const Position = TauLegendConfig.Position

const DatasetChange := preload("res://addons/tau-plot/model/dataset_change.gd").DatasetChange
const DatasetChangeAnalyzer := preload("res://addons/tau-plot/plot/xy/dataset_change_analyzer.gd").DatasetChangeAnalyzer
const SeriesAxisAssignment := preload("res://addons/tau-plot/plot/xy/series_axis_assignment.gd").SeriesAxisAssignment
const AxisId := preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const Axis := preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis
const XYLegendBuilder := preload("res://addons/tau-plot/plot/xy/xy_legend_builder.gd").XYLegendBuilder

const Tracker := preload("res://addons/tau-plot/plot/tracker.gd").Tracker
const NotifiedTracker := preload("res://addons/tau-plot/plot/tracker.gd").NotifiedTracker
const PolledTracker := preload("res://addons/tau-plot/plot/tracker.gd").PolledTracker
const StaleArtifacts := preload("res://addons/tau-plot/plot/stale_artifacts.gd").StaleArtifacts
const XYAxisConfigSnapshot := preload("res://addons/tau-plot/plot/xy/xy_axis_config_snapshot.gd").XYAxisConfigSnapshot
const XYDomain := preload("res://addons/tau-plot/plot/xy/xy_domain.gd").XYDomain
const XYDomainOverrides := preload("res://addons/tau-plot/plot/xy/xy_domain_overrides.gd").XYDomainOverrides
const YDomainOverride := preload("res://addons/tau-plot/plot/xy/xy_domain_overrides.gd").YDomainOverride
const StackedPinnedRange := preload("res://addons/tau-plot/plot/xy/stacked_pinned_range.gd").StackedPinnedRange
const StackedNormalization := preload("res://addons/tau-plot/plot/xy/stacked_normalization.gd").StackedNormalization
const StackedNegativePolicy := preload("res://addons/tau-plot/plot/xy/stacked_negative_policy.gd").StackedNegativePolicy
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout
const PaneStack := preload("res://addons/tau-plot/plot/xy/pane_stack.gd").PaneStack
const XYAxisTitleLayout := preload("res://addons/tau-plot/plot/xy/xy_axis_title_layout.gd").XYAxisTitleLayout
const VisualAttributes := preload("res://addons/tau-plot/plot/xy/visual_attributes.gd").VisualAttributes
const VisualCallbacks := preload("res://addons/tau-plot/plot/xy/visual_callbacks.gd").VisualCallbacks
const HoverController := preload("res://addons/tau-plot/plot/xy/hover/hover_controller.gd").HoverController
const HoverFormatter := preload("res://addons/tau-plot/plot/xy/hover/hover_formatter.gd").HoverFormatter

const PaneOverlayType := preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const Pane := preload("res://addons/tau-plot/plot/xy/pane.gd").Pane
const PaneRenderer := preload("res://addons/tau-plot/plot/xy/pane_renderer.gd").PaneRenderer
const OverlayRenderer := preload("res://addons/tau-plot/plot/xy/overlay_renderer.gd").OverlayRenderer

const BarRenderer := preload("res://addons/tau-plot/plot/xy/bar/bar_renderer.gd").BarRenderer
const BarVisualAttributes := preload("res://addons/tau-plot/plot/xy/bar/bar_visual_attributes.gd").BarVisualAttributes

const ScatterRenderer := preload("res://addons/tau-plot/plot/xy/scatter/scatter_renderer.gd").ScatterRenderer
const ScatterVisualAttributes := preload("res://addons/tau-plot/plot/xy/scatter/scatter_visual_attributes.gd").ScatterVisualAttributes

const LineRenderer := preload("res://addons/tau-plot/plot/xy/line/line_renderer.gd").LineRenderer
const LineVisualAttributes := preload("res://addons/tau-plot/plot/xy/line/line_visual_attributes.gd").LineVisualAttributes


# External references (provided via setup)
var _plot: PanelContainer = null
var _queue_refresh: Callable

# True between the end of setup() and the start of clear().
var _is_setup := false

# Internal: legend management
var _legend_builder: XYLegendBuilder = null

# Internal: created from scene children in setup()
var _axis_title_layout: XYAxisTitleLayout = null

# XY state
var _dataset: Dataset = null
var _xy_domain: XYDomain = null
var _domain_config: TauXYConfig = null
var _xy_domain_overrides: XYDomainOverrides = null
var _xy_layout: XYLayout = null
var _bar_config_per_pane: Array[TauBarConfig] = []			# Elements may be null, one per pane
var _scatter_config_per_pane: Array[TauScatterConfig] = []	# Elements may be null, one per pane
var _line_config_per_pane: Array[TauLineConfig] = []		# Elements may be null, one per pane
var _series_bindings: Array[TauXYSeriesBinding] = []
var _series_assignment: SeriesAxisAssignment = null

# The PaneStack that holds all panes.
var _pane_stack: PaneStack = null

# Each pane, in stack order. Elements are never null.
var _panes: Array[Pane] = []

# Per-pane series partitioning
var _bar_series_ids_per_pane: Array[PackedInt64Array] = []
var _scatter_series_ids_per_pane: Array[PackedInt64Array] = []
var _line_series_ids_per_pane: Array[PackedInt64Array] = []

# Plot-wide resolved TauXYStyle instance (produced by the three-layer cascade).
# Every renderer holds a copy of it.
var _resolved_xy_style: TauXYStyle = null

# Plot-wide resolved TauLegendStyle instance (produced by the three-layer cascade).
# Pushed to the Legend via set_resolved_legend_style().
var _resolved_legend_style: TauLegendStyle = null

# User-provided TauLegendStyle resource (may be null when legend_config is null).
var _user_legend_style: TauLegendStyle = null

# What the axis configs looked like when a refresh last read them. No tracker
# watches TauAxisConfig.
var _axis_config_snapshot := XYAxisConfigSnapshot.new()

# Geometry the last sort settled on, in PaneStack-local coordinates: one rect
# per pane, and the union of the pane data areas. The two together cover both a
# pane moving and a pane keeping its rect while its insets change.
var _settled_pane_rects: Array[Rect2] = []
var _settled_data_area_union := Rect2()

# Stretch ratio applied to each pane. Kept here rather than read back from the
# Control, whose float is narrower than this one and would never compare equal
# to the config value it came from.
var _applied_stretch_ratio_per_pane: PackedFloat64Array = []

# One tracker per user resource a refresh watches, in no particular order.
var _trackers: Array[Tracker] = []
# The subset the theme feeds. A theme change re-resolves them whether or not
# the user resource changed.
var _style_trackers: Array[Tracker] = []

# What a refresh derives. StaleArtifacts.mark() marks one of them stale.
enum Artifact
{
	DOMAIN,			# The value range each axis maps from.
	LAYOUT,			# Pane rects, ticks and reservations, settled by the sort.
	LEGEND_KEYS,	# The picture drawn in front of each legend row.
	HOVER_STYLES,	# The tooltip and the crosshair, resolved by the hover controller.
	HIT_RECORDS,	# Whether a renderer caches what the hover tests against.
	DRAW,			# What the panes paint.
}

# What goes stale with an artifact, so that a call site names the artifact at
# its own level and nothing further down. An artifact absent from the table
# feeds nothing.
#
# The table is transitively minimal: an artifact names only what it feeds
# directly, since the propagation reaches the rest through it. Keeping it that
# way is the reason to have a table at all.
#
# It is acyclic, as the propagation has no cycle guard.
const _DEPENDENTS := {
	Artifact.DOMAIN: [Artifact.LAYOUT],
	Artifact.LAYOUT: [Artifact.LEGEND_KEYS, Artifact.DRAW],
}

# The artifacts waiting to be recomputed.
# Everything a plot needs before it can be drawn starts stale.
# DRAW is left out: it is held by the dirty flag of each renderer, and reached through the handler registered in _init().
var _stale_artifacts := StaleArtifacts.new(_DEPENDENTS,
	[Artifact.DOMAIN, Artifact.LAYOUT, Artifact.LEGEND_KEYS, Artifact.HOVER_STYLES] as Array[int])

# Hover controller (null when setup() has not been called or hover is not wired)
var _hover_controller: HoverController = null

# User-provided TauHoverConfig resource (may be null).
var _hover_config: TauHoverConfig = null


####################################################################################################
# Public
####################################################################################################

func _init() -> void:
	# DRAW has no flag of its own. Its state lives in the dirty flag every
	# renderer carries, and the handler raises them all.
	_stale_artifacts.set_handler(Artifact.DRAW, _mark_all_panes_dirty)


func setup(
		p_plot: PanelContainer,
		p_queue_refresh: Callable,
		p_dataset: Dataset,
		p_xy_config: TauXYConfig,
		p_series_bindings: Array[TauXYSeriesBinding],
		p_legend_enabled: bool,
		p_legend_config: TauLegendConfig,
		p_hover_enabled: bool = false,
		p_hover_config: TauHoverConfig = null) -> void:

	_plot = p_plot
	_legend_builder = XYLegendBuilder.new(p_plot, _attach_legend_outside)
	_queue_refresh = p_queue_refresh

	# Create the axis title layout from our own scene children.
	_axis_title_layout = XYAxisTitleLayout.new(
		%LeftAxisTitles, %RightAxisTitles, %TopAxisTitles, %BottomAxisTitles)

	_series_bindings = p_series_bindings
	_domain_config = p_xy_config

	# Dataset setup
	_reset_dataset()
	_dataset = p_dataset
	_dataset.changed.connect(_on_dataset_changed)

	# Per-pane partitioning structures
	var pane_count := p_xy_config.panes.size()
	_bar_config_per_pane.resize(pane_count)
	_bar_config_per_pane.fill(null)
	_scatter_config_per_pane.resize(pane_count)
	_scatter_config_per_pane.fill(null)
	_line_config_per_pane.resize(pane_count)
	_line_config_per_pane.fill(null)
	_bar_series_ids_per_pane.clear()
	_scatter_series_ids_per_pane.clear()
	_line_series_ids_per_pane.clear()

	# Visual attributes arrive in binding-iteration order, which is neither dense over
	# the pane's series nor in the order the renderers index them by. Key them by
	# series id here and lay them out once the series id order below is final.
	var bar_va_by_sid_per_pane: Array[Dictionary] = []
	var scatter_va_by_sid_per_pane: Array[Dictionary] = []
	var line_va_by_sid_per_pane: Array[Dictionary] = []
	for i in range(pane_count):
		_bar_series_ids_per_pane.append(PackedInt64Array())
		_scatter_series_ids_per_pane.append(PackedInt64Array())
		_line_series_ids_per_pane.append(PackedInt64Array())
		bar_va_by_sid_per_pane.append({})
		scatter_va_by_sid_per_pane.append({})
		line_va_by_sid_per_pane.append({})

	# Extract series bindings
	_series_assignment = SeriesAxisAssignment.new(pane_count)
	for binding in p_series_bindings:
		var sid := binding.series_id
		var pane_index := binding.pane_index
		_series_assignment.assign(sid, pane_index, binding.y_axis_id)

		match binding.overlay_type:
			PaneOverlayType.BAR:
				if sid not in _bar_series_ids_per_pane[pane_index]:
					_bar_series_ids_per_pane[pane_index].append(sid)

				if _bar_config_per_pane[pane_index] == null:
					var pane_config: TauPaneConfig = p_xy_config.panes[pane_index]
					# BarValidator rejects a bar binding whose pane holds no TauBarConfig.
					_bar_config_per_pane[pane_index] = pane_config.get_overlay_config(PaneOverlayType.BAR) as TauBarConfig

				if binding.visual_attributes != null:
					# Type is guaranteed by validation (BarValidator._validate_bar_visuals).
					bar_va_by_sid_per_pane[pane_index][sid] = binding.visual_attributes as BarVisualAttributes

			PaneOverlayType.SCATTER:
				if sid not in _scatter_series_ids_per_pane[pane_index]:
					_scatter_series_ids_per_pane[pane_index].append(sid)

				if _scatter_config_per_pane[pane_index] == null:
					var pane_config: TauPaneConfig = p_xy_config.panes[pane_index]
					# ScatterValidator rejects a scatter binding whose pane holds no TauScatterConfig.
					_scatter_config_per_pane[pane_index] = pane_config.get_overlay_config(PaneOverlayType.SCATTER) as TauScatterConfig

				if binding.visual_attributes != null:
					# Type is guaranteed by validation (ScatterValidator._validate_scatter_visuals).
					scatter_va_by_sid_per_pane[pane_index][sid] = binding.visual_attributes as ScatterVisualAttributes

			PaneOverlayType.LINE:
				if sid not in _line_series_ids_per_pane[pane_index]:
					_line_series_ids_per_pane[pane_index].append(sid)

				if _line_config_per_pane[pane_index] == null:
					var pane_config: TauPaneConfig = p_xy_config.panes[pane_index]
					# LineValidator rejects a line binding whose pane holds no TauLineConfig.
					_line_config_per_pane[pane_index] = pane_config.get_overlay_config(PaneOverlayType.LINE) as TauLineConfig

				if binding.visual_attributes != null:
					# Type is guaranteed by validation (LineValidator._validate_line_visuals).
					line_va_by_sid_per_pane[pane_index][sid] = binding.visual_attributes as LineVisualAttributes

			_:
				# Unknown overlay types are rejected by validation.
				pass

	# Bindings come in any order, so the ids gathered above are in no useful
	# order. Both z_order and the stacking layers are defined on dataset order,
	# so that is the order the renderers must get.
	for pane_index in range(pane_count):
		_sort_series_ids_by_dataset_index(_bar_series_ids_per_pane[pane_index])
		_sort_series_ids_by_dataset_index(_line_series_ids_per_pane[pane_index])
		_sort_series_ids_by_dataset_index(_scatter_series_ids_per_pane[pane_index])

	# The series id order is settled, so the visual attributes can be laid out against it.
	var bar_va_per_pane: Array = []     # Array of Array[BarVisualAttributes]. FIXME Godot 4.5 does not support nested typed collections.
	var scatter_va_per_pane: Array = [] # Array of Array[ScatterVisualAttributes]. FIXME Godot 4.5 does not support nested typed collections.
	var line_va_per_pane: Array = []    # Array of Array[LineVisualAttributes]. FIXME Godot 4.5 does not support nested typed collections.
	for pane_index in range(pane_count):
		var bar_va: Array[BarVisualAttributes] = []
		_align_visual_attributes(bar_va, _bar_series_ids_per_pane[pane_index], bar_va_by_sid_per_pane[pane_index], BarVisualAttributes.new)
		bar_va_per_pane.append(bar_va)

		var scatter_va: Array[ScatterVisualAttributes] = []
		_align_visual_attributes(scatter_va, _scatter_series_ids_per_pane[pane_index], scatter_va_by_sid_per_pane[pane_index], ScatterVisualAttributes.new)
		scatter_va_per_pane.append(scatter_va)

		var line_va: Array[LineVisualAttributes] = []
		_align_visual_attributes(line_va, _line_series_ids_per_pane[pane_index], line_va_by_sid_per_pane[pane_index], LineVisualAttributes.new)
		line_va_per_pane.append(line_va)

	# Domain + layout creation
	_xy_domain_overrides = XYDomainOverrides.new()
	_xy_domain_overrides.init_panes(pane_count)
	_xy_domain = XYDomain.new(_dataset, _domain_config, _series_assignment,
			_bar_series_ids_per_pane, _line_series_ids_per_pane, _xy_domain_overrides)
	_xy_layout = XYLayout.new(_xy_domain)

	# Create the pane stack, stacking along the direction the x axis implies.
	var x_is_horizontal := Axis.is_horizontal(p_xy_config.x_axis_id)
	_clear_panes()
	_create_pane_stack(x_is_horizontal)

	# Create panes dynamically inside _pane_stack
	_panes.resize(pane_count)

	# Resolve TauXYStyle cascade once against the TauPlot root so that theme
	# lookups use the TauPlot type variation.
	_resolved_xy_style = TauXYStyle.resolve(_plot, p_xy_config.style)

	# Pane 0 is top-most (vertical stack) or left-most (horizontal stack).
	for pane_index in range(pane_count):
		var pane_config: TauPaneConfig = p_xy_config.panes[pane_index]
		var pane := Pane.new()
		_panes[pane_index] = pane

		pane.container = MarginContainer.new()
		pane.container.name = "Pane_%d" % pane_index
		pane.container.clip_contents = true
		pane.container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pane.container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pane.container.size_flags_stretch_ratio = pane_config.stretch_ratio
		_pane_stack.add_child(pane.container)

		pane.renderer = PaneRenderer.new(pane_index, _xy_layout)
		pane.container.add_child(pane.renderer)
		pane.renderer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pane.renderer.set_resolved_xy_style(_resolved_xy_style)
		# The renderer is already in the tree at this point, so theme lookups work.
		pane.renderer.set_resolved_pane_style(TauPaneStyle.resolve(pane.renderer, pane_index, pane_config.style))
		pane.renderer.set_grid_line_config(pane_config.grid_line)

		# Overlay renderers are siblings under the pane and paint in
		# child order, so the creation order below is the paint order: bars,
		# then lines, then scatter. It goes from the widest footprint to the narrowest.
		# TauPaneConfig.overlays does not reorder this.
		if not _bar_series_ids_per_pane[pane_index].is_empty():
			_add_overlay(pane, BarRenderer.new(
				_xy_layout, _dataset, _bar_config_per_pane[pane_index],
				_series_assignment,
				pane_index, bar_va_per_pane[pane_index],
				_bar_series_ids_per_pane[pane_index]))

		if not _line_series_ids_per_pane[pane_index].is_empty():
			_add_overlay(pane, LineRenderer.new(
				_xy_layout, _dataset, _line_config_per_pane[pane_index],
				_series_assignment,
				pane_index, line_va_per_pane[pane_index],
				_line_series_ids_per_pane[pane_index]))

		if not _scatter_series_ids_per_pane[pane_index].is_empty():
			_add_overlay(pane, ScatterRenderer.new(
				_xy_layout, _dataset, _scatter_config_per_pane[pane_index],
				_series_assignment,
				pane_index, scatter_va_per_pane[pane_index],
				_scatter_series_ids_per_pane[pane_index]))

	# Axis titles
	_axis_title_layout.build(p_xy_config, _series_assignment)

	# Legend
	_user_legend_style = p_legend_config.style

	_hover_config = p_hover_config
	_connect_hover_style_signals()
	_build_trackers()

	# The builder creates the legend, places it in the tree, then resolves
	# the TauLegendStyle cascade against the in-tree legend (TauLegend type
	# variation) so that theme lookups work correctly.
	_resolved_legend_style = _legend_builder.build(p_dataset, p_series_bindings,
		_get_legend_key_factory,
		_get_legend_key_refresher,
		p_legend_config, p_legend_enabled)

	# The panes were created with these ratios, so the first refresh has
	# nothing to apply.
	_applied_stretch_ratio_per_pane.resize(pane_count)
	for pane_index in range(pane_count):
		_applied_stretch_ratio_per_pane[pane_index] = p_xy_config.panes[pane_index].stretch_ratio

	# Mark everything dirty for initial plot
	_mark_all_dirty()
	_queue_refresh.call()

	# Hover setup
	var tooltip_precision_digits := p_hover_config.tooltip_precision_digits if p_hover_config != null else 3
	var formatter := HoverFormatter.new(_xy_domain, _series_assignment, tooltip_precision_digits)

	_hover_controller = HoverController.new()
	_hover_controller.setup(
		_plot, _xy_layout, _domain_config, _dataset, _panes,
		_resolved_xy_style, formatter,
		p_hover_enabled, p_hover_config)

	_is_setup = true


func clear() -> void:
	_is_setup = false
	_clear_panes()
	_destroy_pane_stack()
	_axis_title_layout.clear()
	_legend_builder.destroy()
	_legend_builder = null
	_disconnect_hover_style_signals()
	_release_trackers()
	_reset_dataset()

	_plot = null
	_xy_domain = null
	_domain_config = null
	_xy_domain_overrides = null
	_xy_layout = null
	_series_assignment = null
	_bar_config_per_pane.clear()
	_scatter_config_per_pane.clear()
	_line_config_per_pane.clear()
	_bar_series_ids_per_pane.clear()
	_scatter_series_ids_per_pane.clear()
	_line_series_ids_per_pane.clear()
	_resolved_xy_style = null
	_resolved_legend_style = null
	_user_legend_style = null
	_series_bindings = []

	_hover_controller.clear()
	_hover_controller = null
	_hover_config = null

	_axis_config_snapshot.reset()
	_settled_pane_rects.clear()
	_settled_data_area_union = Rect2()
	_applied_stretch_ratio_per_pane.clear()
	_mark_all_dirty()


## Brings the plot back in line with the dataset, the user resources and the
## theme as they stand now. Only what changed is recomputed.
func refresh() -> void:
	if not _is_setup:
		return

	_phase_resolve()
	_phase_draw()


func on_theme_changed() -> void:
	# A themed font or tick size may change the layout.
	_stale_artifacts.mark(Artifact.LAYOUT)
	_stale_artifacts.mark(Artifact.HOVER_STYLES)
	# Force style resolution as the theme is one of three layer cascade.
	for tracker in _style_trackers:
		tracker.force_change()


func set_legend_enabled(p_enabled: bool) -> void:
	_legend_builder.controller.legend.visible = p_enabled


func set_legend_config(p_config: TauLegendConfig) -> void:
	_user_legend_style = p_config.style

	# Update position and flow direction.
	_legend_builder.controller.place(p_config.position)
	_legend_builder.controller.apply_flow_direction(p_config.position, p_config.flow_direction)


func set_hover_enabled(p_enabled: bool) -> void:
	_hover_controller.set_enabled(p_enabled)


func set_hover_config(p_config: TauHoverConfig) -> void:
	for style in _hover_styles():
		_unsubscribe_style(style, _on_hover_style_changed)
	_hover_config = p_config
	for style in _hover_styles():
		_subscribe_style(style, _on_hover_style_changed)

	_hover_controller.set_config(p_config)

####################################################################################################
# Private
####################################################################################################

# Resolve, the first phase. It runs without geometry: the sort has not run
# yet, so there is no pane rect to read.
#
# The user may have changed a config, a style, the theme or the dataset since
# the last refresh. _stale_artifacts says which artifacts those changes made
# stale. This phase recomputes those artifacts, as far as it can go without
# geometry, the domain among them, and marks stale every artifact that reads a
# value it just changed. A refresh recomputes an artifact only when it is
# marked stale.
#
# Once this returns, arrange has all it needs.
func _phase_resolve() -> void:
	for tracker in _trackers:
		tracker.update()

	if _stale_artifacts.is_stale(Artifact.HIT_RECORDS):
		_hover_controller.refresh_hit_records_enabled()
		_stale_artifacts.clear(Artifact.HIT_RECORDS)

	# A stretch ratio is a plain float rather than a resource, so no tracker
	# watches it.
	_apply_stretch_ratios()

	# The hover overlays resolve their own styles, and the theme feeds them the
	# same way it feeds the tracked ones.
	if _stale_artifacts.is_stale(Artifact.HOVER_STYLES):
		_hover_controller.refresh_tooltip_style()
		_hover_controller.refresh_crosshair_style()
		_stale_artifacts.clear(Artifact.HOVER_STYLES)

	# Tick counts, overlap strategy and label spacing are read when the ticks
	# are resolved against the axis length in pixels, which is layout rather
	# than domain.
	if _axis_config_snapshot.has_changed(_domain_config):
		_stale_artifacts.mark(Artifact.LAYOUT)
		_axis_config_snapshot.save(_domain_config)

	if _stale_artifacts.is_stale(Artifact.DOMAIN):
		# Bar and line stacked overlays write to the same per-axis entry, with
		# the cross-overlay validator guaranteeing they agree on the shared
		# fields.
		if _has_stackable_overlay():
			_apply_stacking_domain_overrides_y()

		if _xy_domain.update_from_dataset(_dataset):
			_stale_artifacts.mark_dependents(Artifact.DOMAIN)
			_hover_controller.invalidate()

		_stale_artifacts.clear(Artifact.DOMAIN)


# Arrange, the second phase, first half.
#
# Resolve has run, so the domain is final. The pane stack holds the size its
# parent gave it and proposes one rect per pane.
#
# This phase updates the layout from those rects. For each pane the layout
# resolves the ticks, takes out of the rect the space the axes, the tick marks
# and the tick labels need on each edge, and keeps what is left as the data
# area. The domain then maps onto that data area, which gives the value to
# pixel transforms the renderers draw with.
#
# The space a pane takes out of its rect along the stacking direction is its
# reservation, and this phase returns one per pane. The stack recomputes the
# rects from them and calls again, until the reservations stop changing or its
# round limit is reached.
#
# The rects come in as an argument because a pane node does not carry its new
# one yet. The sort applies them after this returns.
#
# This phase must not change a minimum size, on any node. Godot drops a sort
# that asks for another sort, so work that grows a node, such as measuring a
# legend key, waits for the next refresh.
#
# Once this returns, the layout matches the rects the panes are about to get.
func _phase_arrange(p_pane_rects: Array[Rect2]) -> PackedFloat32Array:
	var view_rects: Array[Rect2] = []
	var positions: Array[Vector2] = []
	for rect in p_pane_rects:
		view_rects.append(Rect2(Vector2.ZERO, rect.size))
		positions.append(rect.position)

	_xy_layout.style = _resolved_xy_style
	_xy_layout.set_pane_view_rects(view_rects)
	_xy_layout.set_pane_positions_in_stack(positions)
	_xy_layout.update()

	return _collect_stack_reservations()


# Arrange, second half.
#
# The rects are applied and the layout is settled. This is the last moment of
# the sort, and the only one where the final pane geometry is known, so what
# sits around the panes is placed here, and what builds itself from the layout
# rather than from a draw call is rebuilt.
#
# The minimum size rule of the first half still holds. A geometry that differs
# from the previous one is therefore not repaired on the spot. This raises the
# flags of what it made stale and asks for another refresh.
#
# Once this returns, the plot matches the geometry Godot settled, or a refresh
# is queued to make it match.
func _on_pane_geometry_settled(p_pane_rects: Array[Rect2], p_stack_global_position: Vector2) -> void:
	_axis_title_layout.update_insets(_xy_layout, p_pane_rects, p_stack_global_position)
	_legend_builder.controller.update_inside_rect(Rect2(
		p_stack_global_position + _xy_layout.data_area_union.position,
		_xy_layout.data_area_union.size))

	if p_pane_rects != _settled_pane_rects or _xy_layout.data_area_union != _settled_data_area_union:
		_settled_pane_rects = p_pane_rects.duplicate()
		_settled_data_area_union = _xy_layout.data_area_union
		_hover_controller.invalidate()
		# A pane that kept its rect gets no resize notification of its own, and
		# its insets may still differ.
		_stale_artifacts.mark(Artifact.DRAW)
		# A legend key is measured against the layout too, and a key
		# measurement changes minimum sizes, so it waits for the next refresh
		# rather than running inside the sort.
		_stale_artifacts.mark(Artifact.LEGEND_KEYS)
		_queue_refresh.call()

	_queue_dirty_paints()

	for pane in _panes:
		for overlay in pane.overlays:
			overlay.on_geometry_settled()


# Draw, the third phase.
#
# This phase paints nothing. It queues a redraw on the panes that changed, and
# a sort on the pane stack when the layout is stale. Godot runs the sort once
# the refresh returns, and paints after it, so the panes are painted against
# the layout arrange settles in between.
#
# Refreshing the legend keys is the one other thing done here. It belongs to
# this phase because measuring a key changes a minimum size, which arrange
# must not do.
func _phase_draw() -> void:
	if _stale_artifacts.is_stale(Artifact.LEGEND_KEYS):
		_legend_builder.controller.legend.refresh_keys()
		_stale_artifacts.clear(Artifact.LEGEND_KEYS)

	_queue_dirty_paints()

	# Queues a new sort (a re-layout pass) if one of these conditions is true:
	#  - the layout is stale, and only the sort recomputes it,
	#  - an overlay is still dirty although _queue_dirty_paints() has run.
	#    Such an overlay is rebuilt by on_geometry_settled(), inside the sort.
	if _stale_artifacts.is_stale(Artifact.LAYOUT) or _has_overlay_awaiting_sort():
		_pane_stack.queue_sort()
	_stale_artifacts.clear(Artifact.LAYOUT)


# Registers one tracker per user resource a refresh has to watch. A tracker
# reads its resource back on every update rather than holding it, so a style
# the user swaps for another one is followed without re-registering anything.
func _build_trackers() -> void:
	_track_style(_read_xy_style, _on_xy_style_changed)
	_track_style(_read_legend_style, _on_legend_style_changed)

	for pane_index in range(_panes.size()):
		_track_style(_read_pane_style.bind(pane_index), _on_pane_style_changed.bind(pane_index))
		_track_config(_read_grid_line_config.bind(pane_index), _on_grid_line_config_changed.bind(pane_index))

		for overlay in _panes[pane_index].overlays:
			_track_config(overlay.get_config, _on_overlay_config_changed.bind(overlay))
			_track_style(overlay.get_user_style, _on_overlay_style_changed.bind(overlay))


# A style emits changed on every assignment, so the tracker subscribes to it
# and the refresh it wakes up is the one that compares.
func _track_style(p_read: Callable, p_react: Callable) -> void:
	var tracker := NotifiedTracker.new(p_read, p_react, _queue_refresh)
	_trackers.append(tracker)
	_style_trackers.append(tracker)


# A config emits nothing, so it is compared on every update.
func _track_config(p_read: Callable, p_react: Callable) -> void:
	_trackers.append(PolledTracker.new(p_read, p_react))


func _release_trackers() -> void:
	for tracker in _trackers:
		tracker.release()
	_trackers.clear()
	_style_trackers.clear()


# The readers the plot-level and pane-level trackers read through. A style is
# read back every time rather than held, since the user may assign a different
# one to the config it hangs on at any moment. An overlay reads its own config
# and style back through get_config() and get_user_style().
func _read_xy_style() -> TauXYStyle:
	return _domain_config.style


func _read_legend_style() -> TauLegendStyle:
	return _user_legend_style


func _read_pane_style(p_pane_index: int) -> TauPaneStyle:
	return _domain_config.panes[p_pane_index].style


func _read_grid_line_config(p_pane_index: int) -> TauGridLineConfig:
	return _domain_config.panes[p_pane_index].grid_line


# TauXYStyle covers the whole plot: every renderer holds a copy, the pane gap
# comes from it, and a legend key is drawn from the values it resolves to.
func _on_xy_style_changed(_p_change: Tracker.Change) -> void:
	var previous := _resolved_xy_style
	_resolved_xy_style = TauXYStyle.resolve(_plot, _read_xy_style())

	for pane in _panes:
		pane.renderer.set_resolved_xy_style(_resolved_xy_style)
		for overlay in pane.overlays:
			overlay.set_resolved_xy_style(_resolved_xy_style)

	_apply_pane_gap()
	_stale_artifacts.mark(Artifact.DRAW)
	_stale_artifacts.mark(Artifact.LEGEND_KEYS)

	# The theme feeds the cascade too, so what the layout cares about is
	# whether the resolved values differ, not what the user resource reported.
	if _resolved_xy_style.has_layout_affecting_change(previous):
		_stale_artifacts.mark(Artifact.LAYOUT)


func _on_pane_style_changed(p_change: Tracker.Change, p_pane_index: int) -> void:
	var renderer := _panes[p_pane_index].renderer
	renderer.set_resolved_pane_style(TauPaneStyle.resolve(renderer, p_pane_index, _read_pane_style(p_pane_index)))
	renderer.dirty = true
	if p_change == Tracker.Change.LAYOUT:
		_stale_artifacts.mark(Artifact.LAYOUT)


func _on_overlay_style_changed(p_change: Tracker.Change, p_overlay: OverlayRenderer) -> void:
	p_overlay.resolve_style()
	p_overlay.dirty = true
	_stale_artifacts.mark(Artifact.LEGEND_KEYS)
	if p_change == Tracker.Change.LAYOUT:
		_stale_artifacts.mark(Artifact.LAYOUT)


func _on_legend_style_changed(_p_change: Tracker.Change) -> void:
	_resolved_legend_style = TauLegendStyle.resolve(_legend_builder.controller.legend, _read_legend_style())
	# The legend rebuilds itself.
	_legend_builder.controller.legend.set_resolved_legend_style(_resolved_legend_style)


func _on_overlay_config_changed(p_change: Tracker.Change, p_overlay: OverlayRenderer) -> void:
	_stale_artifacts.mark(Artifact.HIT_RECORDS)
	# An overlay config can change the domain
	if p_change == Tracker.Change.LAYOUT:
		_stale_artifacts.mark(Artifact.DOMAIN)
	else:
		p_overlay.dirty = true


# Grid lines are drawn by the pane renderer, and where they land comes from the
# ticks rather than from this config.
func _on_grid_line_config_changed(_p_change: Tracker.Change, p_pane_index: int) -> void:
	var renderer := _panes[p_pane_index].renderer
	renderer.set_grid_line_config(_read_grid_line_config(p_pane_index))
	renderer.dirty = true


# The stretch ratio decides how the stack splits itself, so a new one moves
# both the panes and the axis titles running alongside them.
func _apply_stretch_ratios() -> void:
	for pane_index in range(_panes.size()):
		var stretch_ratio: float = _domain_config.panes[pane_index].stretch_ratio
		if stretch_ratio == _applied_stretch_ratio_per_pane[pane_index]:
			continue

		# plot_xy() rejects a value below or equal to zero, a runtime change
		# does not go through it. The rejected value is stored so the error is
		# reported once and not on every refresh.
		_applied_stretch_ratio_per_pane[pane_index] = stretch_ratio
		if stretch_ratio <= 0.0:
			push_error("TauPaneConfig.stretch_ratio of pane %d is %f, expected a value greater than 0. The pane keeps its previous ratio." % [pane_index, stretch_ratio])
			continue

		_panes[pane_index].container.size_flags_stretch_ratio = stretch_ratio
		_axis_title_layout.set_stretch_ratio_for_pane(pane_index, stretch_ratio)
		_stale_artifacts.mark(Artifact.LAYOUT)


# Only a bar or a line overlay stacks.
func _has_stackable_overlay() -> bool:
	for pane in _panes:
		for overlay in pane.overlays:
			match overlay.get_config().overlay_type:
				PaneOverlayType.BAR, PaneOverlayType.LINE:
					return true
	return false


func _get_legend_key_factory(p_overlay_type: PaneOverlayType, p_pane_index: int) -> Callable:
	return _panes[p_pane_index].find_overlay(p_overlay_type).create_legend_key_control


func _get_legend_key_refresher(p_overlay_type: PaneOverlayType, p_pane_index: int) -> Callable:
	return _panes[p_pane_index].find_overlay(p_overlay_type).refresh_legend_key_control


## Callback for LegendController: attaches the legend node at the correct
## position in the XY scene tree for outside legend positions.
func _attach_legend_outside(p_legend: Control, p_position: Position) -> void:
	match p_position:
		Position.OUTSIDE_TOP:
			var vbox := _plot.get_node("PlotVBox")
			vbox.add_child(p_legend)
			# After Title (child 0).
			vbox.move_child(p_legend, 1)
		Position.OUTSIDE_BOTTOM:
			var vbox := _plot.get_node("PlotVBox")
			vbox.add_child(p_legend)
			vbox.move_child(p_legend, vbox.get_child_count() - 1)
		Position.OUTSIDE_LEFT:
			var hbox := $HBoxContainer
			hbox.add_child(p_legend)
			hbox.move_child(p_legend, 0)
		Position.OUTSIDE_RIGHT:
			var hbox := $HBoxContainer
			hbox.add_child(p_legend)
			hbox.move_child(p_legend, hbox.get_child_count() - 1)


func _sort_series_ids_by_dataset_index(p_ids: PackedInt64Array) -> void:
	# Insertion sort. PackedInt64Array exposes no sort_custom, and the per-pane
	# series count is small enough that anything more elaborate is overkill.
	var count := p_ids.size()
	for sorted_count in range(count):
		# Pick the next unsorted element and find where it belongs in the already-sorted [0, sorted_count) part.
		var current_sid := p_ids[sorted_count]
		var current_dataset_index := _dataset.get_series_index_by_id(current_sid)
		var insert_at := sorted_count
		while insert_at > 0 and _dataset.get_series_index_by_id(p_ids[insert_at - 1]) > current_dataset_index:
			p_ids[insert_at] = p_ids[insert_at - 1]
			insert_at -= 1
		p_ids[insert_at] = current_sid


# Lays visual attributes out in the pane's series id order, which is the order the
# renderers index them by. A series with no user-supplied attributes gets an empty
# instance rather than null: every buffer inside it is already null, so the existing
# per-buffer null checks cover the gap and the per-sample path needs no element check.
# Only one instance can exist per series, since xy_plot_validator rejects duplicate
# (pane_index, overlay_type, series_id) bindings.
#
# r_aligned carries the element type of the overlay, which p_make_empty produces
# an instance of. Godot 4.5 has no way to write that as a return type here.
func _align_visual_attributes(r_aligned: Array, p_series_ids: PackedInt64Array, p_va_by_sid: Dictionary, p_make_empty: Callable) -> void:
	r_aligned.resize(p_series_ids.size())
	for i in range(p_series_ids.size()):
		var sid := p_series_ids[i]
		r_aligned[i] = p_va_by_sid[sid] if p_va_by_sid.has(sid) else p_make_empty.call()


# Asks every dirty renderer to redraw, and lowers its flag.
#
# Godot draws after it has run the pending sorts. A redraw asked for here is
# therefore painted against the layout the next sort settles.
#
# A renderer that rebuilds against the layout instead of drawing cannot redraw
# now. It keeps its flag and waits for _on_pane_geometry_settled().
func _queue_dirty_paints() -> void:
	for pane in _panes:
		pane.renderer.queue_paint()
		for overlay in pane.overlays:
			overlay.queue_paint()


# An overlay still dirty once _queue_dirty_paints() has run needs a settled
# layout to catch up, and only the sort settles one.
func _has_overlay_awaiting_sort() -> bool:
	for pane in _panes:
		for overlay in pane.overlays:
			if overlay.dirty:
				return true
	return false


# Nothing is left standing: the domain heads the table, and the resolved
# styles are re-resolved from the layer under them rather than from a change
# the user made.
func _mark_all_dirty() -> void:
	_stale_artifacts.mark(Artifact.DOMAIN)
	_stale_artifacts.mark(Artifact.HOVER_STYLES)
	for tracker in _style_trackers:
		tracker.force_change()


func _mark_all_panes_dirty() -> void:
	for pane in _panes:
		pane.renderer.dirty = true
	_mark_overlays_dirty()


# The samples changed but nothing around them did, so the overlays repaint and
# the axes, ticks and tick labels stay.
func _mark_overlays_dirty() -> void:
	for pane in _panes:
		for overlay in pane.overlays:
			overlay.dirty = true


func _reset_dataset() -> void:
	if _dataset == null:
		return
	if _dataset.changed.is_connected(_on_dataset_changed):
		_dataset.changed.disconnect(_on_dataset_changed)
	_dataset = null


func _connect_hover_style_signals() -> void:
	for style in _hover_styles():
		_subscribe_style(style, _on_hover_style_changed)


func _disconnect_hover_style_signals() -> void:
	for style in _hover_styles():
		_unsubscribe_style(style, _on_hover_style_changed)


# The user styles feeding the hover overlays. They are resolved by the hover
# controller rather than by a refresh, so no tracker watches them.
func _hover_styles() -> Array[TauStyle]:
	if _hover_config == null:
		return []
	return [_hover_config.tooltip_style, _hover_config.crosshair_style]


func _subscribe_style(p_style: TauStyle, p_handler: Callable) -> void:
	if p_style != null and not p_style.changed.is_connected(p_handler):
		p_style.changed.connect(p_handler)


func _unsubscribe_style(p_style: TauStyle, p_handler: Callable) -> void:
	if p_style != null and p_style.changed.is_connected(p_handler):
		p_style.changed.disconnect(p_handler)


func _on_hover_style_changed() -> void:
	_hover_controller.refresh_tooltip_style()
	_hover_controller.refresh_crosshair_style()


func _on_dataset_changed(p_change: DatasetChange) -> void:
	var impact := DatasetChangeAnalyzer.classify(p_change, _xy_domain, _dataset, _domain_config, _xy_domain_overrides, _series_assignment)

	match impact:
		DatasetChangeAnalyzer.Impact.NONE:
			pass
		DatasetChangeAnalyzer.Impact.RENDERERS_ONLY:
			_mark_overlays_dirty()
		DatasetChangeAnalyzer.Impact.FULL_RECOMPUTE:
			_mark_all_dirty()

	_queue_refresh.call()


# Parents an overlay renderer to its pane and resolves its style. The renderer
# has to be in the tree before the cascade runs, since the theme is one of its
# layers.
func _add_overlay(p_pane: Pane, p_overlay: OverlayRenderer) -> void:
	p_pane.container.add_child(p_overlay)
	p_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p_pane.overlays.append(p_overlay)
	p_overlay.set_resolved_xy_style(_resolved_xy_style)
	p_overlay.resolve_style()


func _clear_panes() -> void:
	for pane in _panes:
		_pane_stack.remove_child(pane.container)
		pane.container.queue_free() # destroys the renderers too
	_panes.clear()


func _create_pane_stack(p_x_is_horizontal: bool) -> void:
	_destroy_pane_stack()
	_pane_stack = PaneStack.new()
	_pane_stack.setup(_phase_arrange, _on_pane_geometry_settled)
	_pane_stack.vertical = p_x_is_horizontal
	_pane_stack.name = "PaneStack"
	_pane_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pane_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Insert right after %LeftAxisTitles so the order is Left | Panes | Right.
	%LeftAxisTitles.add_sibling(_pane_stack)


func _destroy_pane_stack() -> void:
	if _pane_stack != null:
		_pane_stack.get_parent().remove_child(_pane_stack)
		_pane_stack.queue_free()
	_pane_stack = null


# The gap sits between the panes, so the stack and the four title containers
# running alongside it have to agree on it. It changes minimum sizes, which
# keeps it out of the sort.
func _apply_pane_gap() -> void:
	var gap := _resolved_xy_style.pane_gap_px
	_pane_stack.separation = gap
	_axis_title_layout.update_separation(gap)


# Returns the space each pane reserves along the stacking direction, in pane
# order.
func _collect_stack_reservations() -> PackedFloat32Array:
	var reservations := PackedFloat32Array()
	reservations.resize(_xy_layout.pane_layouts.size())
	for i in range(reservations.size()):
		reservations[i] = _xy_layout.pane_layouts[i].stack_reservation_px
	return reservations


func _apply_stacking_domain_overrides_y() -> void:
	var pane_count := _domain_config.panes.size()
	for pane_index in range(pane_count):
		_xy_domain_overrides.clear_pane(pane_index)
		_apply_bar_stacking_for_pane(pane_index)
		_apply_line_stacking_for_pane(pane_index)


func _apply_bar_stacking_for_pane(p_pane_index: int) -> void:
	if _bar_series_ids_per_pane[p_pane_index].is_empty():
		return

	var pane_bar_config: TauBarConfig = _bar_config_per_pane[p_pane_index]
	if pane_bar_config.mode != TauBarConfig.BarMode.STACKED:
		return

	# Stacked bar series in a pane share one y axis, so any series id resolves it.
	var first_bar_sid: int = _bar_series_ids_per_pane[p_pane_index][0]
	var stacked_y_axis_id: int = _series_assignment.get_y_axis_id_for_series(first_bar_sid, p_pane_index)

	var pane_config: TauPaneConfig = _domain_config.panes[p_pane_index]
	var stacked_y_cfg: TauAxisConfig = pane_config.get_y_axis_config(stacked_y_axis_id)
	# An explicit user range wins over any stacking-driven range.
	if stacked_y_cfg.range_override_enabled:
		return

	var y_domain_override: YDomainOverride = _xy_domain_overrides.get_or_create_override(p_pane_index, stacked_y_axis_id)

	y_domain_override.bar_stack_active = true
	y_domain_override.stacked_normalization = pane_bar_config.stacked_normalization
	y_domain_override.stacked_negative_policy = pane_bar_config.stacked_negative_policy

	_apply_pinned_range(y_domain_override, pane_bar_config.stacked_normalization, pane_bar_config.stacked_negative_policy)


func _apply_line_stacking_for_pane(p_pane_index: int) -> void:
	if _line_series_ids_per_pane[p_pane_index].is_empty():
		return

	var pane_line_config: TauLineConfig = _line_config_per_pane[p_pane_index]
	if pane_line_config.mode != TauLineConfig.LineMode.STACKED:
		return

	# Stacked line series in a pane share one y axis, so any series id resolves it.
	var first_line_sid: int = _line_series_ids_per_pane[p_pane_index][0]
	var stacked_y_axis_id: int = _series_assignment.get_y_axis_id_for_series(first_line_sid, p_pane_index)

	var pane_config: TauPaneConfig = _domain_config.panes[p_pane_index]
	var stacked_y_cfg: TauAxisConfig = pane_config.get_y_axis_config(stacked_y_axis_id)
	# An explicit user range wins over any stacking-driven range.
	if stacked_y_cfg.range_override_enabled:
		return

	var y_domain_override: YDomainOverride = _xy_domain_overrides.get_or_create_override(p_pane_index, stacked_y_axis_id)

	y_domain_override.line_stack_active = true
	y_domain_override.stacked_normalization = pane_line_config.stacked_normalization
	y_domain_override.stacked_negative_policy = pane_line_config.stacked_negative_policy

	_apply_pinned_range(y_domain_override, pane_line_config.stacked_normalization, pane_line_config.stacked_negative_policy)


# NONE keeps the range data-driven. FRACTION and PERCENT need a fixed
# range so every per-X stack fits exactly the available space.
func _apply_pinned_range(p_override: YDomainOverride,
		p_normalization: StackedNormalization, p_policy: StackedNegativePolicy) -> void:
	if p_normalization == StackedNormalization.NONE:
		return
	var pinned := StackedPinnedRange.compute(p_normalization, p_policy)
	p_override.force_y_range = true
	p_override.force_y_min = pinned.x
	p_override.force_y_max = pinned.y
