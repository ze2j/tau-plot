# Owns the full lifecycle of an XY plot: setup, per-frame refresh, and teardown.
#
# Attached to the xy_plot.tscn scene (root VBoxContainer). Manages the dataset,
# domain, layout, pane containers, renderers, dirty flags, and change detection
# state. Delegates axis title management to XYAxisTitleLayout and legend
# management to XYLegendBuilder.

@tool
extends VBoxContainer

const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const Position = TauLegendConfig.Position
const FlowDirection = TauLegendConfig.FlowDirection

const DatasetChange := preload("res://addons/tau-plot/model/dataset_change.gd").DatasetChange
const DatasetChangeAnalyzer := preload("res://addons/tau-plot/plot/xy/dataset_change_analyzer.gd").DatasetChangeAnalyzer
const SeriesAxisAssignment := preload("res://addons/tau-plot/plot/xy/series_axis_assignment.gd").SeriesAxisAssignment
const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const Axis = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").Axis
const XYLegendBuilder := preload("res://addons/tau-plot/plot/xy/xy_legend_builder.gd").XYLegendBuilder

const XYState := preload("res://addons/tau-plot/plot/xy/xy_state.gd").XYState
const XYDomain := preload("res://addons/tau-plot/plot/xy/xy_domain.gd").XYDomain
const XYDomainOverrides := preload("res://addons/tau-plot/plot/xy/xy_domain_overrides.gd").XYDomainOverrides
const YDomainOverride := preload("res://addons/tau-plot/plot/xy/xy_domain_overrides.gd").YDomainOverride
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout
const XYAxisTitleLayout := preload("res://addons/tau-plot/plot/xy/xy_axis_title_layout.gd").XYAxisTitleLayout
const VisualAttributes = preload("res://addons/tau-plot/plot/xy/visual_attributes.gd").VisualAttributes
const VisualCallbacks = preload("res://addons/tau-plot/plot/xy/visual_callbacks.gd").VisualCallbacks
const HoverController = preload("res://addons/tau-plot/plot/xy/hover/hover_controller.gd").HoverController
const HoverFormatter = preload("res://addons/tau-plot/plot/xy/hover/hover_formatter.gd").HoverFormatter
const OverlayHitTester = preload("res://addons/tau-plot/plot/xy/hover/overlay_hit_tester.gd").OverlayHitTester

const PaneRenderer := preload("res://addons/tau-plot/plot/xy/pane_renderer.gd").PaneRenderer

const BarRenderer := preload("res://addons/tau-plot/plot/xy/bar/bar_renderer.gd").BarRenderer
const BarVisualAttributes := preload("res://addons/tau-plot/plot/xy/bar/bar_visual_attributes.gd").BarVisualAttributes
const BarHitTester = preload("res://addons/tau-plot/plot/xy/bar/bar_hit_tester.gd").BarHitTester

const ScatterRenderer := preload("res://addons/tau-plot/plot/xy/scatter/scatter_renderer.gd").ScatterRenderer
const ScatterVisualAttributes = preload("res://addons/tau-plot/plot/xy/scatter/scatter_visual_attributes.gd").ScatterVisualAttributes
const ScatterHitTester = preload("res://addons/tau-plot/plot/xy/scatter/scatter_hit_tester.gd").ScatterHitTester


# External references (provided via setup)
var _plot: PanelContainer = null
var _queue_refresh: Callable

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
var _series_bindings: Array[TauXYSeriesBinding] = []
var _series_assignment: SeriesAxisAssignment = null

# Per-pane renderer arrays
var _pane_renderers: Array[PaneRenderer] = []		# Elements are never null, one per pane
var _bar_renderers: Array[BarRenderer] = []			# Elements may be null, one per pane
var _scatter_renderers: Array[ScatterRenderer] = []	# Elements may be null, one per pane

# The BoxContainer that holds all pane containers. Created as VBoxContainer
# (x horizontal) or HBoxContainer (x vertical) by _create_pane_stack().
var _pane_stack: BoxContainer = null

# Per-pane containers (nodes inside _pane_stack)
var _pane_containers: Array[Container] = []			# Elements are never null, one per pane

# Per-pane series partitioning
var _bar_series_ids_per_pane: Array[PackedInt64Array] = []
var _scatter_series_ids_per_pane: Array[PackedInt64Array] = []

# Per-pane resolved TauPaneStyle instances (produced by the three-layer cascade).
# One entry per pane, always non-null after setup().
var _resolved_pane_styles: Array[TauPaneStyle] = []

# Per-pane resolved overlay style instances (produced by the three-layer cascade).
var _resolved_bar_styles: Array[TauBarStyle] = []
var _resolved_scatter_styles: Array[TauScatterStyle] = []

# Plot-wide resolved TauXYStyle instance (produced by the three-layer cascade).
# Distributed to all renderers (PaneRenderer, BarRenderer, ScatterRenderer).
var _resolved_xy_style: TauXYStyle = null

# Plot-wide resolved TauLegendStyle instance (produced by the three-layer cascade).
# Pushed to the Legend via set_resolved_legend_style().
var _resolved_legend_style: TauLegendStyle = null

# User-provided TauLegendStyle resource (may be null when legend_config is null).
var _user_legend_style: TauLegendStyle = null

# State tracking for change detection between refreshes
var _state := XYState.new()

# Global dirty flags (affect all panes)
var _domain_dirty: bool = true
var _ticks_dirty: bool = true
var _pane_rect_dirty: bool = true
var _styles_dirty: bool = true

# Per-pane dirty flags
var _xy_dirty_panes: Array[bool] = []
var _bars_dirty_panes: Array[bool] = []
var _scatter_dirty_panes: Array[bool] = []

# Hover controller (null when setup() has not been called or hover is not wired)
var _hover_controller: HoverController = null


####################################################################################################
# Public
####################################################################################################

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
	_bar_series_ids_per_pane.clear()
	_scatter_series_ids_per_pane.clear()
	var bar_va_per_pane: Array = []     # Array of Array[BarVisualAttributes]. FIXME Godot 4.5 does not support nested typed collections.
	var scatter_va_per_pane: Array = [] # Array of Array[ScatterVisualAttributes]. FIXME Godot 4.5 does not support nested typed collections.
	for i in range(pane_count):
		_bar_series_ids_per_pane.append(PackedInt64Array())
		_scatter_series_ids_per_pane.append(PackedInt64Array())
		bar_va_per_pane.append([] as Array[BarVisualAttributes])
		scatter_va_per_pane.append([] as Array[ScatterVisualAttributes])

	# Extract series bindings
	_series_assignment = SeriesAxisAssignment.new(pane_count)
	for binding in p_series_bindings:
		var sid := binding.series_id
		var pane_index := binding.pane_index
		_series_assignment.assign(sid, pane_index, binding.y_axis_id)

		match binding.overlay_type:
			TauXYSeriesBinding.PaneOverlayType.BAR:
				if sid not in _bar_series_ids_per_pane[pane_index]:
					_bar_series_ids_per_pane[pane_index].append(sid)

				if _bar_config_per_pane[pane_index] == null:
					var pane_config: TauPaneConfig = p_xy_config.panes[pane_index]
					var bar_cfg := pane_config.get_overlay_config(TauXYSeriesBinding.PaneOverlayType.BAR) as TauBarConfig
					if bar_cfg != null:
						_bar_config_per_pane[pane_index] = bar_cfg

				if binding.visual_attributes != null:
					# Type is guaranteed by validation (BarValidator._validate_bar_visuals).
					bar_va_per_pane[pane_index].append(binding.visual_attributes as BarVisualAttributes)

			TauXYSeriesBinding.PaneOverlayType.SCATTER:
				if sid not in _scatter_series_ids_per_pane[pane_index]:
					_scatter_series_ids_per_pane[pane_index].append(sid)

				if _scatter_config_per_pane[pane_index] == null:
					var pane_config: TauPaneConfig = p_xy_config.panes[pane_index]
					var scatter_cfg := pane_config.get_overlay_config(TauXYSeriesBinding.PaneOverlayType.SCATTER) as TauScatterConfig
					if scatter_cfg != null:
						_scatter_config_per_pane[pane_index] = scatter_cfg

				if binding.visual_attributes != null:
					# Type is guaranteed by validation (ScatterValidator._validate_scatter_visuals).
					scatter_va_per_pane[pane_index].append(binding.visual_attributes as ScatterVisualAttributes)

			_:
				# Unknown overlay types are rejected by validation.
				pass

	# Domain + layout creation
	_xy_domain_overrides = XYDomainOverrides.new()
	_xy_domain_overrides.init_panes(pane_count)
	_xy_domain = XYDomain.new(_dataset, _domain_config, _series_assignment, _xy_domain_overrides)
	_xy_layout = XYLayout.new(_xy_domain)

	# Connect style changed signals for programmatic mutation detection.
	_disconnect_style_signals()
	p_xy_config.style.changed.connect(_on_style_changed)
	for pane_index in range(pane_count):
		if _bar_config_per_pane[pane_index] != null and not _bar_config_per_pane[pane_index].style.changed.is_connected(_on_style_changed):
			_bar_config_per_pane[pane_index].style.changed.connect(_on_style_changed)
		if _scatter_config_per_pane[pane_index] != null and not _scatter_config_per_pane[pane_index].style.changed.is_connected(_on_style_changed):
			_scatter_config_per_pane[pane_index].style.changed.connect(_on_style_changed)
		var pane_config: TauPaneConfig = p_xy_config.panes[pane_index]
		if pane_config.style != null and not pane_config.style.changed.is_connected(_on_style_changed):
			pane_config.style.changed.connect(_on_style_changed)

	# Create the pane stack container (VBox or HBox) based on x axis orientation.
	var x_is_horizontal := Axis.is_horizontal(p_xy_config.x_axis_id)
	_clear_pane_containers()
	_create_pane_stack(x_is_horizontal)

	# Create pane containers dynamically inside _pane_stack
	_pane_renderers.clear()
	_bar_renderers.clear()
	_scatter_renderers.clear()
	_resolved_pane_styles.clear()
	_resolved_bar_styles.clear()
	_resolved_scatter_styles.clear()

	_pane_renderers.resize(pane_count)
	_bar_renderers.resize(pane_count)
	_scatter_renderers.resize(pane_count)
	_resolved_pane_styles.resize(pane_count)
	_resolved_bar_styles.resize(pane_count)
	_resolved_scatter_styles.resize(pane_count)
	_pane_containers.resize(pane_count)

	# Resolve TauXYStyle cascade once against the TauPlot root so that theme
	# lookups use the TauPlot type variation.
	_resolved_xy_style = TauXYStyle.resolve(_plot, p_xy_config.style)

	# Pane 0 is top-most (vertical stack) or left-most (horizontal stack).
	for pane_index in range(pane_count):
		var pane_config: TauPaneConfig = p_xy_config.panes[pane_index]

		# Create MarginContainer for this pane
		var pane_container := MarginContainer.new()
		pane_container.name = "PaneContainer_%d" % pane_index
		pane_container.clip_contents = true
		pane_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pane_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pane_container.size_flags_stretch_ratio = pane_config.stretch_ratio
		_pane_stack.add_child(pane_container)
		_pane_containers[pane_index] = pane_container

		# Create PaneRenderer for this pane.
		var pane_renderer := PaneRenderer.new(pane_index, _xy_layout, p_xy_config.style)
		pane_container.add_child(pane_renderer)
		pane_renderer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_pane_renderers[pane_index] = pane_renderer
		pane_renderer.set_resolved_xy_style(_resolved_xy_style)

		# Resolve TauPaneStyle cascade and push it to the renderer.
		# The renderer is already in the tree at this point, so theme lookups work.
		var resolved_style := TauPaneStyle.resolve(pane_renderer, pane_index, pane_config.style)
		_resolved_pane_styles[pane_index] = resolved_style
		pane_renderer.set_resolved_pane_style(resolved_style)
		pane_renderer.set_grid_line_config(pane_config.grid_line)

		# Create BarRenderer for this pane if it has bar series
		if not _bar_series_ids_per_pane[pane_index].is_empty():
			var bar_renderer := BarRenderer.new(
				_xy_layout, _dataset, _bar_config_per_pane[pane_index], p_xy_config.style,
				_series_assignment,
				pane_index, bar_va_per_pane[pane_index],
				_bar_series_ids_per_pane[pane_index])
			pane_container.add_child(bar_renderer)
			bar_renderer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_bar_renderers[pane_index] = bar_renderer

			# Resolve TauBarStyle cascade and push it to the renderer.
			var bar_user_style: TauBarStyle = _bar_config_per_pane[pane_index].style
			var resolved_bar_style := TauBarStyle.resolve(bar_renderer, pane_index, bar_user_style)
			_resolved_bar_styles[pane_index] = resolved_bar_style
			bar_renderer.set_resolved_bar_style(resolved_bar_style)
			bar_renderer.set_resolved_xy_style(_resolved_xy_style)

		# Create ScatterRenderer for this pane if it has scatter series
		if not _scatter_series_ids_per_pane[pane_index].is_empty():
			var scatter_renderer := ScatterRenderer.new(
				_xy_layout, _dataset, _scatter_config_per_pane[pane_index], p_xy_config.style,
				_series_assignment,
				pane_index, scatter_va_per_pane[pane_index],
				_scatter_series_ids_per_pane[pane_index])
			pane_container.add_child(scatter_renderer)
			scatter_renderer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_scatter_renderers[pane_index] = scatter_renderer

			# Resolve TauScatterStyle cascade and push it to the renderer.
			var scatter_user_style: TauScatterStyle = _scatter_config_per_pane[pane_index].style
			var resolved_scatter_style := TauScatterStyle.resolve(scatter_renderer, pane_index, scatter_user_style)
			_resolved_scatter_styles[pane_index] = resolved_scatter_style
			scatter_renderer.set_resolved_scatter_style(resolved_scatter_style)
			scatter_renderer.set_resolved_xy_style(_resolved_xy_style)

	# Axis titles
	_axis_title_layout.build(p_xy_config, _series_assignment)

	# Legend
	_user_legend_style = p_legend_config.style if p_legend_config != null else null
	if _user_legend_style != null and not _user_legend_style.changed.is_connected(_on_style_changed):
		_user_legend_style.changed.connect(_on_style_changed)

	# The builder creates the legend, places it in the tree, then resolves
	# the TauLegendStyle cascade against the in-tree legend (TauLegend type
	# variation) so that theme lookups work correctly.
	_resolved_legend_style = _legend_builder.build(p_dataset, p_series_bindings, p_xy_config,
		_get_legend_key_factory,
		p_legend_config, p_legend_enabled)

	# Initialize per-pane dirty flags
	_init_pane_dirty_flags(pane_count)

	# Initialize state for per-pane tracking
	_state.init_panes(pane_count)

	# Mark everything dirty for initial plot
	_mark_all_dirty()
	_queue_refresh.call()

	# Hover setup
	var tooltip_precision_digits := p_hover_config.tooltip_precision_digits if p_hover_config != null else 3
	var formatter := HoverFormatter.new(_xy_domain, _domain_config, _series_assignment, tooltip_precision_digits)

	# Create per-pane hit testers.
	var hit_testers_per_pane: Array = []
	for pane_index in range(pane_count):
		var testers: Array[OverlayHitTester] = []

		if _bar_renderers[pane_index] != null:
			testers.append(BarHitTester.new(
				pane_index,
				_bar_config_per_pane[pane_index],
				_bar_renderers[pane_index],
				_dataset,
				_xy_layout))

		if _scatter_renderers[pane_index] != null:
			testers.append(ScatterHitTester.new(
				pane_index,
				_scatter_config_per_pane[pane_index],
				_scatter_renderers[pane_index],
				_dataset, _xy_layout))

		hit_testers_per_pane.append(testers)

	_hover_controller = HoverController.new()
	_hover_controller.setup(
		_plot, _xy_layout, _domain_config,
		_pane_containers, _pane_renderers,
		_bar_renderers, _scatter_renderers,
		_resolved_xy_style, formatter, hit_testers_per_pane,
		p_hover_enabled, p_hover_config)


func clear() -> void:
	_clear_pane_containers()
	_destroy_pane_stack()
	if _axis_title_layout != null:
		_axis_title_layout.clear()
	if _legend_builder != null:
		_legend_builder.destroy()
		_legend_builder = null
	_disconnect_style_signals()
	_reset_dataset()

	_plot = null
	_xy_domain = null
	_domain_config = null
	_xy_domain_overrides = null
	_xy_layout = null
	_series_assignment = null
	_bar_config_per_pane.clear()
	_scatter_config_per_pane.clear()
	_bar_series_ids_per_pane.clear()
	_scatter_series_ids_per_pane.clear()
	_resolved_pane_styles.clear()
	_resolved_bar_styles.clear()
	_resolved_scatter_styles.clear()
	_resolved_xy_style = null
	_resolved_legend_style = null
	_user_legend_style = null
	_series_bindings = []

	if _hover_controller != null:
		_hover_controller.clear()
		_hover_controller = null

	_state.reset()
	_mark_all_dirty()


func refresh(p_plot_global_position: Vector2, p_legend_position: Position) -> void:
	if _dataset == null or _xy_domain == null or _xy_layout == null:
		return
	if _pane_renderers.is_empty():
		return
	if not _has_any_data_renderer():
		return
	if _domain_config == null:
		return
	if _xy_domain_overrides == null:
		return

	var pane_count := _pane_containers.size()
	if pane_count == 0:
		return

	# Step 1: Collect pane view rects and pane positions, check for changes
	var any_valid_rect := false
	var pane_view_rects: Array[Rect2] = []
	var pane_positions: Array[Vector2] = []
	for i in range(pane_count):
		if _pane_containers[i] != null:
			var r := Rect2(Vector2.ZERO, _pane_containers[i].size)
			pane_view_rects.append(r)
			pane_positions.append(_pane_containers[i].position)
			if r.size.x > 0.0 and r.size.y > 0.0:
				any_valid_rect = true
		else:
			pane_view_rects.append(Rect2())
			pane_positions.append(Vector2.ZERO)
	if not any_valid_rect:
		return

	var view_rects_changed := _state.have_pane_view_rects_changed(pane_view_rects)

	# Step 2: Check if bar config changed (for animation support) per pane
	var has_any_bar := false
	for renderer in _bar_renderers:
		if renderer != null:
			has_any_bar = true
			break

	if has_any_bar:
		for pane_index in range(pane_count):
			var pane_bar_config: TauBarConfig = _bar_config_per_pane[pane_index] if pane_index < _bar_config_per_pane.size() else null
			if pane_bar_config == null:
				continue
			var prev_bar_config: TauBarConfig = _state.bar_config_per_pane[pane_index] if pane_index < _state.bar_config_per_pane.size() else null
			if not pane_bar_config.is_equal_to(prev_bar_config):
				if pane_bar_config.has_layout_affecting_change(prev_bar_config):
					_domain_dirty = true
					_ticks_dirty = true
					_pane_rect_dirty = true
					_set_all_pane_flags(_xy_dirty_panes, true)
					_set_all_pane_flags(_bars_dirty_panes, true)
				else:
					_bars_dirty_panes[pane_index] = true
				_state.save_bar_config_for_pane(pane_index, pane_bar_config)

	# Step 3: Check if scatter config changed per pane
	var has_any_scatter := false
	for renderer in _scatter_renderers:
		if renderer != null:
			has_any_scatter = true
			break

	if has_any_scatter:
		for pane_index in range(pane_count):
			var pane_scatter_config: TauScatterConfig = _scatter_config_per_pane[pane_index] if pane_index < _scatter_config_per_pane.size() else null
			if pane_scatter_config == null:
				continue
			var prev_scatter_config: TauScatterConfig = _state.scatter_config_per_pane[pane_index] if pane_index < _state.scatter_config_per_pane.size() else null
			if not pane_scatter_config.is_equal_to(prev_scatter_config):
				if pane_scatter_config.has_layout_affecting_change(prev_scatter_config):
					_domain_dirty = true
					_ticks_dirty = true
					_pane_rect_dirty = true
					_set_all_pane_flags(_xy_dirty_panes, true)
					_set_all_pane_flags(_scatter_dirty_panes, true)
				else:
					_scatter_dirty_panes[pane_index] = true
				_state.save_scatter_config_for_pane(pane_index, pane_scatter_config)

	# Step 3b: Check if styles changed (programmatic mutations via config.style.*)
	# XY style: three-layer change detection (theme dirty, ref change, content mutation).
	#  - layout-affecting properties trigger ticks + pane rect recompute,
	#  - visual-only properties (colors, alpha) trigger data renderer redraws.
	var _legend_rebuild_needed := false

	if _domain_config != null:
		var xy_user_style := _domain_config.style
		var needs_xy_re_resolve := _styles_dirty

		# Reference change: user assigned a different TauXYStyle resource.
		if _state.has_xy_style_ref_changed(xy_user_style):
			needs_xy_re_resolve = true
			_state.save_xy_style_ref(xy_user_style)

		# Content mutation: user changed a property on the existing TauXYStyle.
		if not needs_xy_re_resolve:
			if _state.has_xy_style_changed(xy_user_style):
				needs_xy_re_resolve = true

		if needs_xy_re_resolve:
			var prev_resolved := _resolved_xy_style
			_resolved_xy_style = TauXYStyle.resolve(_plot, xy_user_style)

			# Push the resolved copy to all renderers.
			for renderer in _pane_renderers:
				if renderer != null:
					renderer.set_resolved_xy_style(_resolved_xy_style)
			for renderer in _bar_renderers:
				if renderer != null:
					renderer.set_resolved_xy_style(_resolved_xy_style)
			for renderer in _scatter_renderers:
				if renderer != null:
					renderer.set_resolved_xy_style(_resolved_xy_style)

			# Legend keys read visual properties from renderer instances.
			# When the resolved TauXYStyle changes (colors, alpha), keys become stale.
			_legend_rebuild_needed = true

			# Determine the scope of dirtying based on what changed.
			if prev_resolved == null or _resolved_xy_style.has_layout_affecting_change(prev_resolved):
				_ticks_dirty = true
				_pane_rect_dirty = true
				_mark_visual_dirty()
			else:
				_mark_visual_dirty()

			_state.save_xy_style(xy_user_style)

	# Bar style: three-layer change detection (theme dirty, ref change, content mutation).
	# All TauBarStyle properties are visual-only, so only dirty the owning bar pane.
	if has_any_bar:
		for pane_index in range(pane_count):
			var bar_config: TauBarConfig = _bar_config_per_pane[pane_index] if pane_index < _bar_config_per_pane.size() else null
			if bar_config == null:
				continue
			var needs_bar_re_resolve := _styles_dirty

			# Reference change: user assigned a different TauBarStyle resource.
			if _state.has_bar_style_ref_changed_for_pane(pane_index, bar_config.style):
				needs_bar_re_resolve = true
				_state.save_bar_style_ref_for_pane(pane_index, bar_config.style)

			# Content mutation: user changed a property on the existing TauBarStyle.
			if not needs_bar_re_resolve:
				var prev_bar_style: TauBarStyle = _state.bar_style_per_pane[pane_index] if pane_index < _state.bar_style_per_pane.size() else null
				if not bar_config.style.is_equal_to(prev_bar_style):
					needs_bar_re_resolve = true

			if needs_bar_re_resolve and _bar_renderers[pane_index] != null:
				var resolved_bar := TauBarStyle.resolve(_bar_renderers[pane_index], pane_index, bar_config.style)
				_resolved_bar_styles[pane_index] = resolved_bar
				_bar_renderers[pane_index].set_resolved_bar_style(resolved_bar)
				_state.save_bar_style_for_pane(pane_index, bar_config.style)
				_bars_dirty_panes[pane_index] = true
				_legend_rebuild_needed = true

	# Scatter style: three-layer change detection (theme dirty, ref change, content mutation).
	# All TauScatterStyle properties are visual-only, so only dirty the owning scatter pane.
	if has_any_scatter:
		for pane_index in range(pane_count):
			var scatter_config: TauScatterConfig = _scatter_config_per_pane[pane_index] if pane_index < _scatter_config_per_pane.size() else null
			if scatter_config == null:
				continue
			var needs_scatter_re_resolve := _styles_dirty

			# Reference change: user assigned a different TauScatterStyle resource.
			if _state.has_scatter_style_ref_changed_for_pane(pane_index, scatter_config.style):
				needs_scatter_re_resolve = true
				_state.save_scatter_style_ref_for_pane(pane_index, scatter_config.style)

			# Content mutation: user changed a property on the existing TauScatterStyle.
			if not needs_scatter_re_resolve:
				var prev_scatter_style: TauScatterStyle = _state.scatter_style_per_pane[pane_index] if pane_index < _state.scatter_style_per_pane.size() else null
				if not scatter_config.style.is_equal_to(prev_scatter_style):
					needs_scatter_re_resolve = true

			if needs_scatter_re_resolve and _scatter_renderers[pane_index] != null:
				var resolved_scatter := TauScatterStyle.resolve(_scatter_renderers[pane_index], pane_index, scatter_config.style)
				_resolved_scatter_styles[pane_index] = resolved_scatter
				_scatter_renderers[pane_index].set_resolved_scatter_style(resolved_scatter)
				_state.save_scatter_style_for_pane(pane_index, scatter_config.style)
				_scatter_dirty_panes[pane_index] = true
				_legend_rebuild_needed = true

	# Step 3c: Check grid_line config changes, style reference changes,
	# and pane style mutations. All visual-only.
	for pane_index in range(pane_count):
		var pane_config: TauPaneConfig = _domain_config.panes[pane_index]
		var needs_re_resolve := _styles_dirty

		# TauGridLineConfig changes (enabled flags, y_axis selection).
		if _state.has_grid_line_config_changed_for_pane(pane_index, pane_config.grid_line):
			_state.save_grid_line_config_for_pane(pane_index, pane_config.grid_line)
			if _pane_renderers[pane_index] != null:
				_pane_renderers[pane_index].set_grid_line_config(pane_config.grid_line)
			_xy_dirty_panes[pane_index] = true

		# Style resource reference change (user assigned a different TauPaneStyle).
		if _state.has_pane_style_ref_changed_for_pane(pane_index, pane_config.style):
			needs_re_resolve = true
			_state.save_pane_style_ref_for_pane(pane_index, pane_config.style)

		# TauPaneStyle resource mutation (user changed a property on the assigned style).
		if not needs_re_resolve:
			var prev_pane_style: TauPaneStyle = _state.pane_style_per_pane[pane_index] if pane_index < _state.pane_style_per_pane.size() else null
			var user_style_check: TauPaneStyle = pane_config.style
			if user_style_check != null:
				if not user_style_check.is_equal_to(prev_pane_style):
					needs_re_resolve = true
			else:
				if prev_pane_style != null:
					needs_re_resolve = true

		if needs_re_resolve and _pane_renderers[pane_index] != null:
			var user_style: TauPaneStyle = pane_config.style
			var resolved := TauPaneStyle.resolve(_pane_renderers[pane_index], pane_index, user_style)
			_resolved_pane_styles[pane_index] = resolved
			_pane_renderers[pane_index].set_resolved_pane_style(resolved)
			_state.save_pane_style_for_pane(pane_index, user_style)
			_xy_dirty_panes[pane_index] = true

	# Step 3d: TauLegendStyle three-layer change detection (theme dirty, ref change, content mutation).
	var needs_legend_re_resolve := _styles_dirty

	# Reference change: user assigned a different TauLegendStyle resource.
	if _state.has_legend_style_ref_changed(_user_legend_style):
		needs_legend_re_resolve = true
		_state.save_legend_style_ref(_user_legend_style)

	# Content mutation: user changed a property on the existing TauLegendStyle.
	if not needs_legend_re_resolve:
		if _state.has_legend_style_changed(_user_legend_style):
			needs_legend_re_resolve = true

	if needs_legend_re_resolve:
		_resolved_legend_style = TauLegendStyle.resolve(_legend_builder.controller.legend, _user_legend_style)
		_legend_builder.controller.legend.set_resolved_legend_style(_resolved_legend_style)
		_state.save_legend_style(_user_legend_style)

		# If the legend style has a layout-affecting change, the legend
		# controller may need to recompute inside overlay sizing.
		# The legend itself handles its own rebuild in set_resolved_legend_style.

	# Re-resolve tooltip and crosshair styles if styles changed (theme or user overrides).
	if _styles_dirty and _hover_controller != null:
		_hover_controller.refresh_tooltip_style()
		_hover_controller.refresh_crosshair_style()

	_styles_dirty = false

	# Step 4: Check if domain config changed (tick counts, overlap strategy, spacing)
	if _domain_config != null and _state.has_config_changed(_domain_config):
		_mark_domain_dependents_dirty()
		_state.save_config(_domain_config)

	if view_rects_changed:
		# View rect change requires plot rect recomputation
		_pane_rect_dirty = true
		_mark_visual_dirty()
		# Hover state is invalid after layout change.
		if _hover_controller != null:
			_hover_controller.invalidate()

	# Step 5: Apply bar-specific Y overrides (stacking normalization) only if bars active
	if _domain_dirty and has_any_bar:
		_apply_bar_domain_overrides_y()

	# Step 6: Recompute domain from dataset if needed
	if _domain_dirty:
		_xy_domain.update_from_dataset(_dataset)

		# Check if domain actually changed
		if _state.has_domain_changed(_xy_domain):
			_mark_domain_dependents_dirty()
			if _hover_controller != null:
				_hover_controller.invalidate()

		_state.save_domain(_xy_domain)
		_domain_dirty = false

	# Step 7: Update layout (ticks and plot rect) if needed
	if _ticks_dirty or _pane_rect_dirty:
		_update_xy_layout(pane_view_rects, pane_positions)
		_axis_title_layout.update_insets(_xy_layout, _pane_containers)
		_pane_rect_dirty = false
		_ticks_dirty = false

	# Rebuild legend keys once if any overlay or plot-wide style changed.
	# Must run after the layout update as some legend keys depends on the
	# layout (e.g. scatter with DATA_UNITS marker size policy, which uses
	# map_x_to_px).
	if _legend_rebuild_needed:
		_legend_builder.controller.legend.rebuild()

	# Step 7b: Update legend overlay if INSIDE position
	if _is_inside_legend_position(p_legend_position):
		var union_global := _pane_stack.global_position + _xy_layout.data_area_union.position
		var union_in_plot := Rect2(
			union_global - p_plot_global_position,
			_xy_layout.data_area_union.size)
		_legend_builder.controller.update_inside_rect(union_in_plot)

	# Step 8: Redraw only dirty panes
	for i in range(pane_count):
		if _xy_dirty_panes[i] and _pane_renderers[i] != null:
			_pane_renderers[i].queue_redraw()
			_xy_dirty_panes[i] = false
		if _bars_dirty_panes[i] and _bar_renderers[i] != null:
			_bar_renderers[i].queue_redraw()
			_bars_dirty_panes[i] = false
		if _scatter_dirty_panes[i] and _scatter_renderers[i] != null:
			_scatter_renderers[i].update_scatter()
			_scatter_dirty_panes[i] = false

	_state.save_pane_view_rects(pane_view_rects)


## Called by TauPlot when NOTIFICATION_THEME_CHANGED fires.
func on_theme_changed() -> void:
	_mark_domain_dependents_dirty()
	_styles_dirty = true


func set_legend_enabled(p_enabled: bool) -> void:
	_legend_builder.controller.legend.visible = p_enabled


func set_legend_config(p_config: TauLegendConfig) -> void:
	var new_style: TauLegendStyle = p_config.style if p_config != null else null
	var new_position: Position = p_config.position if p_config != null else Position.OUTSIDE_TOP
	var new_flow: FlowDirection = p_config.flow_direction if p_config != null else FlowDirection.AUTO

	# Update style tracking.
	if _user_legend_style != new_style:
		# Disconnect old signal.
		if _user_legend_style != null and _user_legend_style.changed.is_connected(_on_style_changed):
			_user_legend_style.changed.disconnect(_on_style_changed)
		_user_legend_style = new_style
		# Connect new signal.
		if _user_legend_style != null and not _user_legend_style.changed.is_connected(_on_style_changed):
			_user_legend_style.changed.connect(_on_style_changed)

	# Update position and flow direction.
	_legend_builder.controller.place(new_position)
	_legend_builder.controller.apply_flow_direction(new_position, new_flow)


func set_hover_enabled(p_enabled: bool) -> void:
	if _hover_controller != null:
		_hover_controller.set_enabled(p_enabled)


func set_hover_config(p_config: TauHoverConfig) -> void:
	if _hover_controller != null:
		_hover_controller.set_config(p_config)

####################################################################################################
# Private
####################################################################################################

static func _is_inside_legend_position(p_pos: Position) -> bool:
	return p_pos >= Position.INSIDE_TOP


## Returns the create_legend_key_control callable for the renderer that owns
## the given overlay type on the given pane. Used by XYLegendBuilder as a
## resolver so that the legend system never imports any renderer class.
func _get_legend_key_factory(p_overlay_type: int, p_pane_index: int) -> Callable:
	match p_overlay_type:
		TauXYSeriesBinding.PaneOverlayType.BAR:
			if p_pane_index >= 0 and p_pane_index < _bar_renderers.size():
				var r = _bar_renderers[p_pane_index]
				if r != null:
					return r.create_legend_key_control
		TauXYSeriesBinding.PaneOverlayType.SCATTER:
			if p_pane_index >= 0 and p_pane_index < _scatter_renderers.size():
				var r = _scatter_renderers[p_pane_index]
				if r != null:
					return r.create_legend_key_control
	return Callable()


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


func _init_pane_dirty_flags(p_pane_count: int) -> void:
	_xy_dirty_panes.resize(p_pane_count)
	_bars_dirty_panes.resize(p_pane_count)
	_scatter_dirty_panes.resize(p_pane_count)
	_xy_dirty_panes.fill(true)
	_bars_dirty_panes.fill(true)
	_scatter_dirty_panes.fill(true)


func _set_all_pane_flags(p_flags: Array[bool], p_value: bool) -> void:
	for i in range(p_flags.size()):
		p_flags[i] = p_value


func _mark_all_dirty() -> void:
	_domain_dirty = true
	_ticks_dirty = true
	_pane_rect_dirty = true
	_styles_dirty = true
	_set_all_pane_flags(_xy_dirty_panes, true)
	_set_all_pane_flags(_bars_dirty_panes, true)
	_set_all_pane_flags(_scatter_dirty_panes, true)


func _mark_domain_dependents_dirty() -> void:
	_ticks_dirty = true
	_pane_rect_dirty = true
	_set_all_pane_flags(_xy_dirty_panes, true)
	_set_all_pane_flags(_bars_dirty_panes, true)
	_set_all_pane_flags(_scatter_dirty_panes, true)


func _mark_renderers_dirty() -> void:
	_set_all_pane_flags(_bars_dirty_panes, true)
	_set_all_pane_flags(_scatter_dirty_panes, true)


func _mark_visual_dirty() -> void:
	_set_all_pane_flags(_xy_dirty_panes, true)
	_set_all_pane_flags(_bars_dirty_panes, true)
	_set_all_pane_flags(_scatter_dirty_panes, true)


func _reset_dataset() -> void:
	if _dataset == null:
		return
	if _dataset.changed.is_connected(_on_dataset_changed):
		_dataset.changed.disconnect(_on_dataset_changed)
	_dataset = null


func _disconnect_style_signals() -> void:
	if _domain_config != null and _domain_config.style != null:
		if _domain_config.style.changed.is_connected(_on_style_changed):
			_domain_config.style.changed.disconnect(_on_style_changed)
	for bar_cfg in _bar_config_per_pane:
		if bar_cfg != null and bar_cfg.style != null:
			if bar_cfg.style.changed.is_connected(_on_style_changed):
				bar_cfg.style.changed.disconnect(_on_style_changed)
	for scatter_cfg in _scatter_config_per_pane:
		if scatter_cfg != null and scatter_cfg.style != null:
			if scatter_cfg.style.changed.is_connected(_on_style_changed):
				scatter_cfg.style.changed.disconnect(_on_style_changed)
	if _domain_config != null:
		for pane_config in _domain_config.panes:
			if pane_config != null and pane_config.style != null:
				if pane_config.style.changed.is_connected(_on_style_changed):
					pane_config.style.changed.disconnect(_on_style_changed)
	if _user_legend_style != null:
		if _user_legend_style.changed.is_connected(_on_style_changed):
			_user_legend_style.changed.disconnect(_on_style_changed)


func _on_style_changed() -> void:
	_queue_refresh.call()


func _on_dataset_changed(p_change: DatasetChange) -> void:
	var impact := DatasetChangeAnalyzer.classify(p_change, _xy_domain, _dataset, _domain_config, _xy_domain_overrides, _series_assignment)

	match impact:
		DatasetChangeAnalyzer.Impact.NONE:
			pass
		DatasetChangeAnalyzer.Impact.RENDERERS_ONLY:
			_mark_renderers_dirty()
		DatasetChangeAnalyzer.Impact.FULL_RECOMPUTE:
			_mark_all_dirty()

	_queue_refresh.call()


func _has_any_data_renderer() -> bool:
	for renderer in _bar_renderers:
		if renderer != null:
			return true
	for renderer in _scatter_renderers:
		if renderer != null:
			return true
	return false


func _clear_pane_containers() -> void:
	for renderer in _pane_renderers:
		if renderer != null and is_instance_valid(renderer):
			renderer.queue_free()
	_pane_renderers.clear()

	for renderer in _bar_renderers:
		if renderer != null and is_instance_valid(renderer):
			renderer.queue_free()
	_bar_renderers.clear()

	for renderer in _scatter_renderers:
		if renderer != null and is_instance_valid(renderer):
			renderer.queue_free()
	_scatter_renderers.clear()

	if _pane_stack != null:
		for container in _pane_containers:
			if container != null and is_instance_valid(container):
				_pane_stack.remove_child(container)
				container.queue_free()
	_pane_containers.clear()


func _create_pane_stack(p_x_is_horizontal: bool) -> void:
	_destroy_pane_stack()
	if p_x_is_horizontal:
		_pane_stack = VBoxContainer.new()
	else:
		_pane_stack = HBoxContainer.new()
	_pane_stack.name = "PaneStack"
	_pane_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pane_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pane_stack.add_theme_constant_override(&"separation", 0)
	# Insert right after %LeftAxisTitles so the order is Left | Panes | Right.
	%LeftAxisTitles.add_sibling(_pane_stack)


func _destroy_pane_stack() -> void:
	if _pane_stack != null and is_instance_valid(_pane_stack):
		_pane_stack.get_parent().remove_child(_pane_stack)
		_pane_stack.queue_free()
	_pane_stack = null


func _update_xy_layout(p_pane_view_rects: Array[Rect2], p_pane_positions: Array[Vector2]) -> void:
	if _domain_config == null:
		return
	if _resolved_xy_style == null:
		return

	_xy_layout.style = _resolved_xy_style

	# Apply pane gap from style to the pane stack and title containers.
	var gap := _resolved_xy_style.pane_gap_px
	_pane_stack.add_theme_constant_override(&"separation", gap)
	_axis_title_layout.update_separation(gap)

	_xy_layout.set_pane_view_rects(p_pane_view_rects)
	_xy_layout.set_pane_positions_in_stack(p_pane_positions)
	_xy_layout.update()


func _apply_bar_domain_overrides_y() -> void:
	var pane_count := _domain_config.panes.size()
	for pane_index in range(pane_count):
		if pane_index >= _bar_series_ids_per_pane.size():
			continue
		if _bar_series_ids_per_pane[pane_index].is_empty():
			continue

		var pane_bar_config: TauBarConfig = _bar_config_per_pane[pane_index] if pane_index < _bar_config_per_pane.size() else null
		if pane_bar_config == null:
			continue

		var y_domain_override: YDomainOverride = _xy_domain_overrides.y_domain_overrides[pane_index]

		# Reset vertical overrides each recompute then re-apply if needed.
		y_domain_override.reset()

		if pane_bar_config.mode != TauBarConfig.BarMode.STACKED:
			continue

		# Resolve the y-axis actually used by the stacked bar series.
		# The validator enforces that all stacked bar series share the same y_axis_id,
		# so checking the first one is enough.
		var first_bar_sid: int = _bar_series_ids_per_pane[pane_index][0]
		var stacked_y_axis_id: int = _series_assignment.get_y_axis_id_for_series(first_bar_sid, pane_index)
		if stacked_y_axis_id == -1:
			continue

		# Only check the axis that the stacked bars are bound to.
		var pane_config: TauPaneConfig = _domain_config.panes[pane_index]
		var stacked_y_cfg: TauAxisConfig = pane_config.get_y_axis_config(stacked_y_axis_id)
		if stacked_y_cfg != null and stacked_y_cfg.range_override_enabled:
			continue

		y_domain_override.target_y_axis_id = stacked_y_axis_id

		match pane_bar_config.stacked_normalization:
			TauBarConfig.StackedNormalization.NONE:
				y_domain_override.stack_y_values = true

			TauBarConfig.StackedNormalization.FRACTION:
				y_domain_override.force_y_range = true
				y_domain_override.force_y_min = 0.0
				y_domain_override.force_y_max = 1.0

			TauBarConfig.StackedNormalization.PERCENT:
				y_domain_override.force_y_range = true
				y_domain_override.force_y_min = 0.0
				y_domain_override.force_y_max = 100.0

			_:
				push_error("_apply_bar_domain_overrides_y(): unexpected stacked normalization")
