const SampleHit = preload("res://addons/tau-plot/plot/xy/hover/sample_hit.gd").SampleHit
const HoverMode = preload("res://addons/tau-plot/plot/xy/hover/hover_config.gd").HoverMode
const CrosshairMode = preload("res://addons/tau-plot/plot/xy/hover/hover_config.gd").CrosshairMode
const TooltipPanel = preload("res://addons/tau-plot/plot/xy/hover/tooltip_panel.gd").TooltipPanel
const HoverFormatter = preload("res://addons/tau-plot/plot/xy/hover/hover_formatter.gd").HoverFormatter
const OverlayHitTester = preload("res://addons/tau-plot/plot/xy/hover/overlay_hit_tester.gd").OverlayHitTester
const CrosshairOverlay := preload("res://addons/tau-plot/plot/xy/hover/crosshair_overlay.gd").CrosshairOverlay
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout
const PaneRenderer := preload("res://addons/tau-plot/plot/xy/pane_renderer.gd").PaneRenderer
const BarRenderer := preload("res://addons/tau-plot/plot/xy/bar/bar_renderer.gd").BarRenderer
const ScatterRenderer := preload("res://addons/tau-plot/plot/xy/scatter/scatter_renderer.gd").ScatterRenderer


## Handles input dispatch, hover mode resolution, hit aggregation across
## overlays, tooltip lifecycle (create/position/show/hide/destroy), and
## signal emission. Works exclusively through the OverlayHitTester interface
## and never inspects overlay internals directly.
class HoverController extends RefCounted:
	# External references (provided via setup).
	var _plot: PanelContainer = null
	var _layout: XYLayout = null
	var _domain_config: TauXYConfig = null
	var _pane_containers: Array[Container] = []
	var _pane_renderers: Array[PaneRenderer] = []
	var _bar_renderers: Array[BarRenderer] = []
	var _scatter_renderers: Array[ScatterRenderer] = []
	var _resolved_xy_style: TauXYStyle = null

	# Hover state.
	var _enabled: bool = false
	var _hover_config: TauHoverConfig = null
	var _current_hits: Array[SampleHit] = []
	var _current_pane: int = -1
	var _pinned_hits: Array[SampleHit] = []

	# Tooltip state.
	var _tooltip_transient: TooltipPanel = null
	var _tooltip_pinned: TooltipPanel = null
	var _resolved_tooltip_style: TauTooltipStyle = null
	var _last_mouse_pos: Vector2 = Vector2.ZERO

	# Crosshair state.
	var _crosshair_overlays: Array[CrosshairOverlay] = []
	var _resolved_crosshair_style: TauCrosshairStyle = null

	# Formatter and hit testers.
	var _formatter: HoverFormatter = null
	var _hit_testers_per_pane: Array = []  # Array[Array[OverlayHitTester]] FIXME Godot 4.5 does not support nested typed collections.


	## Configures the controller with all the references it needs to operate.
	## Called once from xy_plot.setup() after renderers and styles are created.
	func setup(
			p_plot: Control,
			p_layout: XYLayout,
			p_domain_config: TauXYConfig,
			p_pane_containers: Array[Container],
			p_pane_renderers: Array[PaneRenderer],
			p_bar_renderers: Array[BarRenderer],
			p_scatter_renderers: Array[ScatterRenderer],
			p_resolved_xy_style: TauXYStyle,
			p_formatter: HoverFormatter,
			p_hit_testers_per_pane: Array, # Array[Array[OverlayHitTester]] FIXME Godot 4.5 does not support nested typed collections.
			p_enabled: bool,
			p_config: TauHoverConfig) -> void:
		_plot = p_plot
		_layout = p_layout
		_domain_config = p_domain_config
		_pane_containers = p_pane_containers
		_pane_renderers = p_pane_renderers
		_bar_renderers = p_bar_renderers
		_scatter_renderers = p_scatter_renderers
		_resolved_xy_style = p_resolved_xy_style
		_formatter = p_formatter
		_hit_testers_per_pane = p_hit_testers_per_pane
		_enabled = p_enabled
		_hover_config = p_config

		_apply_to_pane_renderers()
		_resolve_tooltip_style()
		_resolve_crosshair_style()
		_create_crosshair_overlays()


	## Destroys both tooltips, clears all state, and releases references.
	## Null checks on tooltips are warranted here because teardown order
	## is not guaranteed.
	func clear() -> void:
		_destroy_tooltip(_tooltip_transient)
		_tooltip_transient = null
		_destroy_tooltip(_tooltip_pinned)
		_tooltip_pinned = null
		_destroy_crosshair_overlays()
		_current_hits.clear()
		_pinned_hits.clear()
		_current_pane = -1
		_hit_testers_per_pane.clear()
		_plot = null
		_layout = null
		_domain_config = null
		_pane_containers = []
		_pane_renderers = []
		_bar_renderers = []
		_scatter_renderers = []
		_resolved_xy_style = null
		_formatter = null
		_hover_config = null
		_resolved_tooltip_style = null
		_resolved_crosshair_style = null


	## Enables or disables hover inspection at runtime.
	func set_enabled(p_enabled: bool) -> void:
		if _enabled == p_enabled:
			return
		_enabled = p_enabled
		_apply_to_pane_renderers()
		if not _enabled:
			invalidate()


	## Replaces the TauHoverConfig at runtime and re-resolves styles.
	func set_config(p_config: TauHoverConfig) -> void:
		_hover_config = p_config
		_resolve_tooltip_style()
		_resolve_crosshair_style()


	## Clears current hover state and emits sample_hover_exited if needed.
	## Called by xy_plot when layout or data changes invalidate screen positions.
	func invalidate() -> void:
		var was_hovering := not _current_hits.is_empty()
		_current_hits.clear()
		_current_pane = -1
		_hide_transient_tooltip()
		_hide_all_crosshairs()
		_clear_highlight_state_on_renderers()
		# Also hide pinned tooltip since screen positions are stale.
		if not _pinned_hits.is_empty():
			_pinned_hits.clear()
			_hide_pinned_tooltip()
			_plot.sample_click_dismissed.emit()
		if was_hovering:
			_plot.sample_hover_exited.emit()


	## Re-resolves the tooltip style. Called when styles change globally.
	func refresh_tooltip_style() -> void:
		_resolve_tooltip_style()


	## Re-resolves the crosshair style. Called when styles change globally.
	func refresh_crosshair_style() -> void:
		_resolve_crosshair_style()


	####################################################################
	# Private: pane renderer wiring
	####################################################################

	## Activates or deactivates mouse capture on all pane renderers based
	## on the current _enabled state.
	func _apply_to_pane_renderers() -> void:
		for pane_renderer: PaneRenderer in _pane_renderers:
			if _enabled:
				pane_renderer.set_hover_active(true, _on_pane_input)
				if not pane_renderer.mouse_exited.is_connected(pane_renderer.on_mouse_exited):
					pane_renderer.mouse_exited.connect(pane_renderer.on_mouse_exited)
			else:
				pane_renderer.set_hover_active(false)
				if pane_renderer.mouse_exited.is_connected(pane_renderer.on_mouse_exited):
					pane_renderer.mouse_exited.disconnect(pane_renderer.on_mouse_exited)


	####################################################################
	# Private: input dispatch
	####################################################################

	## Central input handler called by PaneRenderer when hover is active.
	## p_event is null when the mouse exits the pane.
	func _on_pane_input(p_pane_index: int, p_event: InputEvent, p_local_pos: Vector2) -> void:
		if not _enabled:
			return

		# Mouse exited the pane.
		if p_event == null:
			invalidate()
			return

		if p_event is InputEventMouseMotion:
			_process_motion(p_pane_index, p_local_pos)

		elif p_event is InputEventMouseButton:
			var mb := p_event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				_process_click(p_pane_index, p_local_pos)

		elif p_event is InputEventKey:
			var ke := p_event as InputEventKey
			if ke.keycode == KEY_ESCAPE and ke.pressed and not ke.echo:
				if not _pinned_hits.is_empty():
					_pinned_hits.clear()
					_hide_pinned_tooltip()
					_plot.sample_click_dismissed.emit()


	## Processes mouse motion: runs hit testing and emits hover signals.
	func _process_motion(p_pane_index: int, p_local_pos: Vector2) -> void:
		# Convert pane-local position to plot-local for tooltip positioning.
		_last_mouse_pos = _pane_to_plot_local(p_pane_index, p_local_pos)

		var resolved_mode := _resolve_mode(p_pane_index)
		var hits: Array[SampleHit] = []

		if resolved_mode == HoverMode.NEAREST:
			hits = _hit_test_nearest(p_pane_index, p_local_pos)
		else:
			hits = _hit_test_x_aligned(p_pane_index, p_local_pos)

		if hits.is_empty():
			if not _current_hits.is_empty():
				_current_hits.clear()
				_current_pane = -1
				_hide_transient_tooltip()
				_hide_all_crosshairs()
				_clear_highlight_state_on_renderers()
				_plot.sample_hover_exited.emit()
			return

		_current_hits = hits
		_current_pane = p_pane_index
		_show_transient_tooltip(hits, p_pane_index)
		_show_crosshairs(hits, p_pane_index, p_local_pos)
		_push_highlight_state_to_renderers(hits)
		_plot.sample_hovered.emit(hits)


	## Processes mouse click: emits click signals or dismisses pinned tooltip.
	func _process_click(p_pane_index: int, p_local_pos: Vector2) -> void:
		var resolved_mode := _resolve_mode(p_pane_index)
		var hits: Array[SampleHit] = []

		if resolved_mode == HoverMode.NEAREST:
			hits = _hit_test_nearest(p_pane_index, p_local_pos)
		else:
			hits = _hit_test_x_aligned(p_pane_index, p_local_pos)

		if hits.is_empty():
			# Click on empty space dismisses pinned tooltip.
			if not _pinned_hits.is_empty():
				_pinned_hits.clear()
				_hide_pinned_tooltip()
				_plot.sample_click_dismissed.emit()
			return

		_pinned_hits = hits
		_show_pinned_tooltip(hits, p_pane_index)
		_plot.sample_clicked.emit(hits)


	####################################################################
	# Private: hover mode resolution
	####################################################################

	## Resolves the effective HoverMode for a given pane, applying AUTO logic.
	## Iterates the hit testers for this pane: if all hoverable testers agree
	## on a preferred mode, that mode wins. If they disagree, NEAREST wins.
	func _resolve_mode(p_pane_index: int) -> HoverMode:
		var config_mode := _hover_config.hover_mode if _hover_config != null else HoverMode.AUTO

		if config_mode != HoverMode.AUTO:
			return config_mode

		var hit_testers := _hit_testers_per_pane[p_pane_index] as Array[OverlayHitTester]
		var agreed_mode: int = -1

		for hit_tester: OverlayHitTester in hit_testers:
			if not hit_tester.is_hoverable():
				continue
			var preferred: int = hit_tester.get_preferred_hover_mode()
			if agreed_mode == -1:
				agreed_mode = preferred
			elif agreed_mode != preferred:
				return HoverMode.NEAREST

		if agreed_mode == -1:
			return HoverMode.NEAREST
		return agreed_mode as HoverMode


	####################################################################
	# Private: hit testing
	####################################################################

	## Finds the single closest sample across all hoverable overlays in
	## the pane. Iterates per-pane hit testers, calls hit_test_nearest on
	## each, and keeps the hit with the smallest distance_px.
	func _hit_test_nearest(p_pane_index: int, p_local_pos: Vector2) -> Array[SampleHit]:
		var best_hit: SampleHit = null
		var best_dist_sq: float = INF

		var hit_testers: Array[OverlayHitTester] = _hit_testers_per_pane[p_pane_index]
		for hit_tester: OverlayHitTester in hit_testers:
			if not hit_tester.is_hoverable():
				continue
			var hit: SampleHit = hit_tester.hit_test_nearest(p_local_pos)
			if hit == null:
				continue
			var d_sq := hit.distance_px * hit.distance_px
			if d_sq < best_dist_sq:
				best_dist_sq = d_sq
				best_hit = hit

		if best_hit != null:
			return [best_hit]
		return []


	## Collects all samples at the nearest x position across all hoverable
	## overlays in the pane. For categorical x, determines the category from
	## the pointer position and collects hits from each tester. For continuous
	## x, finds the globally nearest x across all testers, then collects hits
	## at that x from each tester.
	func _hit_test_x_aligned(p_pane_index: int, p_local_pos: Vector2) -> Array[SampleHit]:
		var x_is_horizontal: bool = _layout._x_is_horizontal
		var along_x_px: float = p_local_pos.x if x_is_horizontal else p_local_pos.y

		var x_config := _layout.domain.config.x_axis

		var hit_testers: Array[OverlayHitTester] = _hit_testers_per_pane[p_pane_index]
		var hits: Array[SampleHit] = []

		if x_config.type == TauAxisConfig.Type.CATEGORICAL:
			var categories := _layout.domain.x_categories
			var n := categories.size()
			if n <= 0:
				return []

			var pane_rect := _layout.get_pane_rect(p_pane_index)
			var x_extent: float = pane_rect.size.x if x_is_horizontal else pane_rect.size.y
			var x_origin: float = pane_rect.position.x if x_is_horizontal else pane_rect.position.y

			var step_px := x_extent / float(n)
			var rel_x := along_x_px - x_origin
			var category_index := int(rel_x / step_px)
			if category_index < 0 or category_index >= n:
				return []

			var x_value: Variant = categories[category_index]

			for hit_tester: OverlayHitTester in hit_testers:
				if not hit_tester.is_hoverable():
					continue
				hits.append_array(hit_tester.collect_hits_at_category(category_index, x_value, p_local_pos))

		else:
			# Continuous x: find the globally nearest x across all testers.
			var nearest_x_px := INF
			var nearest_x_val: float = 0.0
			var found := false

			for hit_tester: OverlayHitTester in hit_testers:
				if not hit_tester.is_hoverable():
					continue
				var result: Dictionary = hit_tester.find_nearest_x(along_x_px)
				if result.is_empty():
					continue
				var candidate_px: float = result["x_px"]
				if absf(along_x_px - candidate_px) < absf(along_x_px - nearest_x_px):
					nearest_x_px = candidate_px
					nearest_x_val = result["x_value"]
					found = true

			if not found:
				return []

			for hit_tester: OverlayHitTester in hit_testers:
				if not hit_tester.is_hoverable():
					continue
				hits.append_array(hit_tester.collect_hits_at_continuous_x(nearest_x_val, p_local_pos))

		return hits


	####################################################################
	# Private: tooltip style
	####################################################################

	## Resolves the TauTooltipStyle through the three-layer cascade.
	func _resolve_tooltip_style() -> void:
		var user_style: TauTooltipStyle = _hover_config.tooltip_style if _hover_config != null else null
		_tooltip_transient = _ensure_tooltip(_tooltip_transient)
		_resolved_tooltip_style = TauTooltipStyle.resolve(_tooltip_transient, user_style)


	## Returns true when the tooltip should be shown based on config.
	func _is_tooltip_enabled() -> bool:
		if _hover_config == null:
			return true  # Default: tooltip enabled.
		return _hover_config.tooltip_enabled


	####################################################################
	# Private: crosshair style and lifecycle
	####################################################################

	## Resolves the TauCrosshairStyle through the three-layer cascade.
	func _resolve_crosshair_style() -> void:
		var user_style: TauCrosshairStyle = _hover_config.crosshair_style if _hover_config != null else null
		_resolved_crosshair_style = TauCrosshairStyle.resolve(_plot, user_style)


	## Returns the configured CrosshairMode, defaulting to NONE.
	func _get_crosshair_mode() -> CrosshairMode:
		if _hover_config == null:
			return CrosshairMode.NONE
		return _hover_config.crosshair_mode


	## Creates one CrosshairOverlay per pane and adds it as the last child
	## of each pane container so it draws on top of all data renderers.
	func _create_crosshair_overlays() -> void:
		_crosshair_overlays.clear()
		for pane_index: int in range(_pane_containers.size()):
			var overlay := CrosshairOverlay.new()
			overlay.name = "CrosshairOverlay_%d" % pane_index
			_pane_containers[pane_index].add_child(overlay)
			overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_crosshair_overlays.append(overlay)


	## Removes and frees all crosshair overlays.
	func _destroy_crosshair_overlays() -> void:
		for overlay: CrosshairOverlay in _crosshair_overlays:
			if not is_instance_valid(overlay):
				continue
			overlay.get_parent().remove_child(overlay)
			overlay.queue_free()
		_crosshair_overlays.clear()


	## Shows crosshair lines on all panes with multi-pane synchronization.
	##
	## The x crosshair line appears on ALL panes (snapped to the hovered
	## data point's x pixel position). The y crosshair line appears only
	## on the active pane (following the raw mouse y position).
	func _show_crosshairs(p_hits: Array[SampleHit], p_active_pane: int, p_local_pos: Vector2) -> void:
		var configured_mode: CrosshairMode = _get_crosshair_mode()
		if configured_mode == CrosshairMode.NONE:
			_hide_all_crosshairs()
			return

		var x_is_horizontal: bool = _layout._x_is_horizontal
		var primary_hit: SampleHit = p_hits[0]

		# X pixel: snapped to the hovered data point's screen position.
		# For GROUPED bars, snap to the category/data center instead of
		# the individual bar's offset position.
		var x_px: float
		if _is_grouped_bar_x_aligned(p_active_pane):
			var x_config := _layout.domain.config.x_axis
			if x_config.type == TauAxisConfig.Type.CATEGORICAL:
				x_px = _layout.map_x_category_center_to_px(p_active_pane, primary_hit.sample_index)
			else:
				x_px = _layout.map_x_to_px(p_active_pane, float(primary_hit.x_value))
		elif x_is_horizontal:
			x_px = primary_hit.screen_position.x
		else:
			x_px = primary_hit.screen_position.y

		# Y pixel: raw mouse position.
		var y_px: float
		if x_is_horizontal:
			y_px = p_local_pos.y
		else:
			y_px = p_local_pos.x

		for pane_index: int in range(_crosshair_overlays.size()):
			var overlay: CrosshairOverlay = _crosshair_overlays[pane_index]
			var pane_rect: Rect2 = _layout.get_pane_rect(pane_index)

			if pane_index == p_active_pane:
				# Active pane: show both x and y lines (or whichever the configured mode requests).
				overlay.show_crosshair(x_px, y_px, configured_mode, _resolved_crosshair_style, x_is_horizontal, pane_rect)
			else:
				# Non-active pane: show only the x line.
				# If configured mode is Y_ONLY, hide entirely.
				if configured_mode == CrosshairMode.X_ONLY or configured_mode == CrosshairMode.BOTH:
					overlay.show_crosshair(x_px, 0.0, CrosshairMode.X_ONLY, _resolved_crosshair_style, x_is_horizontal, pane_rect)
				else:
					overlay.hide_crosshair()


	## Hides crosshair overlays on all panes.
	func _hide_all_crosshairs() -> void:
		for overlay: CrosshairOverlay in _crosshair_overlays:
			overlay.hide_crosshair()


	####################################################################
	# Private: highlight (renderer hover state)
	####################################################################

	## Returns true when the highlight feature should be active.
	func _is_highlight_enabled() -> bool:
		if _hover_config == null:
			return true  # Default: highlight enabled.
		return _hover_config.highlight_enabled


	## Returns the hover color callback from config, or an invalid Callable.
	func _get_hover_highlight_callback() -> Callable:
		if _hover_config == null:
			return Callable()
		return _hover_config.hover_highlight_callback


	## Returns true when the bar renderer at p_pane_index is in GROUPED mode
	## and the resolved hover mode is X_ALIGNED. Used to decide whether to
	## highlight the whole group and center the tooltip on the category.
	func _is_grouped_bar_x_aligned(p_pane_index: int) -> bool:
		if p_pane_index < 0 or p_pane_index >= _bar_renderers.size():
			return false
		var renderer: BarRenderer = _bar_renderers[p_pane_index]
		if renderer == null:
			return false   # Pane has no bar overlay.
		if renderer.get_config().mode != TauBarConfig.BarMode.GROUPED:
			return false
		return _resolve_mode(p_pane_index) == HoverMode.X_ALIGNED


	## Pushes highlight state to all bar and scatter renderers based on the
	## current set of hits. Each renderer receives set_hover_state with the
	## hit that belongs to it (matched by pane index and overlay type). If a
	## renderer has no hit, it still receives p_active = true so that the
	## color callback dims its samples, but p_series_id = -1 so no sample
	## gets hovered-state style properties.
	##
	## For GROUPED bars in X_ALIGNED mode, the entire group at the hovered
	## sample index is highlighted together via set_hover_state_group.
	func _push_highlight_state_to_renderers(p_hits: Array[SampleHit]) -> void:
		if not _is_highlight_enabled():
			_clear_highlight_state_on_renderers()
			return

		var highlight_cb: Callable = _get_hover_highlight_callback()

		# Build a lookup from pane_index to the best hit for that pane, per
		# overlay type. Selection priority:
		#   1. Hits where contains_pointer is true (cursor inside the visual
		#      element). Among those, pick the one with the smallest distance_px.
		#   2. If no hit contains the pointer, no sample is highlighted for that
		#      overlay (series_id = -1). The tooltip still shows all hits, but
		#      the visual highlight is suppressed because the cursor is not
		#      physically inside any element.
		var bar_hits_by_pane: Dictionary[int, SampleHit] = {}
		var scatter_hits_by_pane: Dictionary[int, SampleHit] = {}

		# Also track the sample_index for group highlighting (any bar hit,
		# even without contains_pointer, tells us the hovered category).
		var bar_sample_index_by_pane: Dictionary[int, int] = {}

		const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
		for hit: SampleHit in p_hits:
			if hit.overlay_type == PaneOverlayType.BAR:
				if not bar_sample_index_by_pane.has(hit.pane_index):
					bar_sample_index_by_pane[hit.pane_index] = hit.sample_index
				if hit.contains_pointer:
					var existing: SampleHit = bar_hits_by_pane.get(hit.pane_index)
					if existing == null or hit.distance_px < existing.distance_px:
						bar_hits_by_pane[hit.pane_index] = hit
			elif hit.overlay_type == PaneOverlayType.SCATTER:
				if hit.contains_pointer:
					var existing: SampleHit = scatter_hits_by_pane.get(hit.pane_index)
					if existing == null or hit.distance_px < existing.distance_px:
						scatter_hits_by_pane[hit.pane_index] = hit

		for pane_index: int in range(_bar_renderers.size()):
			var renderer: BarRenderer = _bar_renderers[pane_index]
			if renderer == null:
				continue  # Pane has no bar overlay.

			# Use group highlight for GROUPED bars in X_ALIGNED mode.
			if _is_grouped_bar_x_aligned(pane_index):
				var sample_idx: int = bar_sample_index_by_pane.get(pane_index, -1)
				if sample_idx >= 0:
					renderer.set_hover_state_group(true, sample_idx, highlight_cb)
				else:
					renderer.set_hover_state(true, -1, -1, highlight_cb)
			else:
				var hit: SampleHit = bar_hits_by_pane.get(pane_index)
				if hit != null:
					renderer.set_hover_state(true, hit.series_id, hit.sample_index, highlight_cb)
				else:
					renderer.set_hover_state(true, -1, -1, highlight_cb)

		for pane_index: int in range(_scatter_renderers.size()):
			var renderer: ScatterRenderer = _scatter_renderers[pane_index]
			if renderer == null:
				continue  # Pane has no scatter overlay.
			var hit: SampleHit = scatter_hits_by_pane.get(pane_index)
			if hit != null:
				renderer.set_hover_state(true, hit.series_id, hit.sample_index, highlight_cb)
			else:
				renderer.set_hover_state(true, -1, -1, highlight_cb)


	## Clears highlight state on all bar and scatter renderers, returning
	## them to normal (non-highlighted) drawing.
	func _clear_highlight_state_on_renderers() -> void:
		for pane_index: int in range(_bar_renderers.size()):
			var renderer: BarRenderer = _bar_renderers[pane_index]
			if renderer == null:
				continue  # Pane has no bar overlay.
			renderer.set_hover_state(false, -1, -1, Callable())

		for pane_index: int in range(_scatter_renderers.size()):
			var renderer: ScatterRenderer = _scatter_renderers[pane_index]
			if renderer == null:
				continue  # Pane has no scatter overlay.
			renderer.set_hover_state(false, -1, -1, Callable())


	####################################################################
	# Private: coordinate conversion
	####################################################################

	## Converts a pane-local position to plot-local coordinates (relative
	## to the TauPlot root PanelContainer).
	func _pane_to_plot_local(p_pane_index: int, p_local_pos: Vector2) -> Vector2:
		# Convert from pane-local to global, then from global to plot-local.
		var global_pos := _pane_containers[p_pane_index].global_position + p_local_pos
		return global_pos - _plot.global_position


	## Converts a SampleHit screen_position (pane-local) to plot-local coordinates.
	func _hit_to_plot_local(p_hit: SampleHit) -> Vector2:
		return _pane_to_plot_local(p_hit.pane_index, p_hit.screen_position)


	####################################################################
	# Private: tooltip lifecycle
	####################################################################

	## Builds the tooltip content by consulting the config callback chain.
	## Priority: create_tooltip_control > format_tooltip_text > default formatter.
	## Returns [text_content, custom_control] where exactly one is populated.
	func _build_tooltip_content(p_hits: Array) -> Array:
		if _hover_config != null and _hover_config.create_tooltip_control.is_valid():
			return ["", _hover_config.create_tooltip_control.call(p_hits)]
		if _hover_config != null and _hover_config.format_tooltip_text.is_valid():
			return [_hover_config.format_tooltip_text.call(p_hits), null]
		return [_formatter.format_default_tooltip(p_hits), null]


	## Shows or updates the transient (hover-following) tooltip.
	func _show_transient_tooltip(p_hits: Array, p_pane_index: int) -> void:
		if not _is_tooltip_enabled():
			_hide_transient_tooltip()
			return

		var content := _build_tooltip_content(p_hits)
		_tooltip_transient = _ensure_tooltip(_tooltip_transient)
		_apply_tooltip_node_style(_tooltip_transient, false)

		if content[1] != null:
			_tooltip_transient.set_custom_control(content[1])
		else:
			_tooltip_transient.set_text_content(content[0])

		_tooltip_transient.visible = true
		_position_tooltip(_tooltip_transient, p_hits, p_pane_index)


	## Hides the transient tooltip and frees any custom content it holds.
	func _hide_transient_tooltip() -> void:
		if _tooltip_transient != null and is_instance_valid(_tooltip_transient):
			_tooltip_transient.dismiss()


	## Shows or updates the pinned tooltip.
	func _show_pinned_tooltip(p_hits: Array, p_pane_index: int) -> void:
		if not _is_tooltip_enabled():
			return

		var content := _build_tooltip_content(p_hits)
		_tooltip_pinned = _ensure_tooltip(_tooltip_pinned)
		_apply_tooltip_node_style(_tooltip_pinned, true)

		if content[1] != null:
			_tooltip_pinned.set_custom_control(content[1])
		else:
			_tooltip_pinned.set_text_content(content[0])

		_tooltip_pinned.visible = true
		# Pinned tooltip always uses SNAP_TO_POINT positioning.
		_position_snap(_tooltip_pinned, p_hits, p_pane_index)


	## Hides the pinned tooltip and frees any custom content it holds.
	func _hide_pinned_tooltip() -> void:
		if _tooltip_pinned != null and is_instance_valid(_tooltip_pinned):
			_tooltip_pinned.dismiss()


	## Returns the given tooltip node if it is still valid, or creates a
	## new one. The tooltip is added as a child of TauPlot with
	## top_level = true so it can be positioned in global coordinates
	## without being constrained by the plot's layout.
	func _ensure_tooltip(p_existing: TooltipPanel) -> TooltipPanel:
		if p_existing != null and is_instance_valid(p_existing):
			return p_existing
		var tooltip := TooltipPanel.new()
		tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tooltip.top_level = true
		tooltip.visible = false
		_plot.add_child(tooltip)
		return tooltip


	## Applies the resolved style to an existing tooltip node. Called on
	## every show so that runtime style changes are picked up immediately.
	func _apply_tooltip_node_style(p_tooltip: TooltipPanel, p_pinned: bool) -> void:
		var style := _resolved_tooltip_style

		var sb: StyleBox
		if p_pinned and style.pinned_style_box != null:
			sb = style.pinned_style_box
		elif style.style_box != null:
			sb = style.style_box
		else:
			sb = TauTooltipStyle._create_default_style_box()

		p_tooltip.apply_style(sb, style.font, style.font_size,
				style.font_color, style.padding_px, style.max_width_px)


	## Destroys a tooltip node. Used only during teardown in clear(), not
	## during normal hover updates (which reuse existing nodes).
	func _destroy_tooltip(p_tooltip: Control) -> void:
		if p_tooltip == null:
			return
		if not is_instance_valid(p_tooltip):
			push_error("HoverController._destroy_tooltip: tooltip reference is stale (already freed).")
			return
		p_tooltip.get_parent().remove_child(p_tooltip)
		p_tooltip.queue_free()


	####################################################################
	# Private: tooltip positioning
	####################################################################

	## Positions a tooltip based on the configured position mode.
	func _position_tooltip(p_tooltip: Control, p_hits: Array, p_pane_index: int) -> void:
		var position_mode := _hover_config.tooltip_position_mode if _hover_config != null else TauHoverConfig.TooltipPositionMode.SNAP_TO_POINT

		if position_mode == TauHoverConfig.TooltipPositionMode.FOLLOW_MOUSE:
			_position_follow_mouse(p_tooltip)
		else:
			_position_snap(p_tooltip, p_hits, p_pane_index)


	## Positions the tooltip at the data point (SNAP_TO_POINT mode).
	## For GROUPED bars in X_ALIGNED mode, the anchor is the category center
	## on X and the top of the tallest bar on Y, so the tooltip sits centered
	## above the whole group rather than tracking a single bar.
	func _position_snap(p_tooltip: Control, p_hits: Array, p_pane_index: int) -> void:
		if p_hits.is_empty():
			return

		# Check if we should use group-centered positioning.
		if _is_grouped_bar_x_aligned(p_pane_index):
			var anchor := _compute_grouped_bar_anchor(p_hits, p_pane_index)
			if anchor != Vector2.INF:
				_apply_position(p_tooltip, anchor)
				return

		var primary_hit: SampleHit = p_hits[0]
		var anchor := _hit_to_plot_local(primary_hit)
		_apply_position(p_tooltip, anchor)


	## Computes the tooltip anchor for a GROUPED bar cluster.
	## X is the category center (or the data-x center for continuous axes).
	## Y is the top of the tallest bar in the group (smallest Y pixel value
	## since screen Y grows downward).
	## Returns Vector2.INF if no bar hits are found.
	func _compute_grouped_bar_anchor(p_hits: Array, p_pane_index: int) -> Vector2:
		const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType

		var min_y_px: float = INF  # Smallest screen Y = top of tallest bar.
		var has_bar_hit := false
		var first_bar_hit: SampleHit = null

		for hit in p_hits:
			var sample_hit: SampleHit = hit as SampleHit
			if sample_hit == null:
				continue
			if sample_hit.overlay_type != PaneOverlayType.BAR:
				continue
			if not has_bar_hit:
				first_bar_hit = sample_hit
				has_bar_hit = true

			# screen_position.y holds the bar tip pixel in pane-local space.
			var x_is_horizontal: bool = _layout._x_is_horizontal
			var bar_tip_y: float
			if x_is_horizontal:
				bar_tip_y = sample_hit.screen_position.y
			else:
				bar_tip_y = sample_hit.screen_position.x
			if bar_tip_y < min_y_px:
				min_y_px = bar_tip_y

		if not has_bar_hit:
			return Vector2.INF

		# X: use the category center, not any individual bar's offset position.
		# For categorical axes, map the sample_index back to the category center.
		# For continuous axes, map the x_value to pixel position.
		var x_config := _layout.domain.config.x_axis
		var center_x_px: float
		if x_config.type == TauAxisConfig.Type.CATEGORICAL:
			center_x_px = _layout.map_x_category_center_to_px(p_pane_index, first_bar_hit.sample_index)
		else:
			center_x_px = _layout.map_x_to_px(p_pane_index, float(first_bar_hit.x_value))

		# Build the pane-local anchor, then convert to plot-local.
		var pane_local: Vector2
		var x_is_horizontal: bool = _layout._x_is_horizontal
		if x_is_horizontal:
			pane_local = Vector2(center_x_px, min_y_px)
		else:
			pane_local = Vector2(min_y_px, center_x_px)

		return _pane_to_plot_local(p_pane_index, pane_local)


	## Positions the tooltip at the mouse cursor (FOLLOW_MOUSE mode).
	func _position_follow_mouse(p_tooltip: Control) -> void:
		_apply_position(p_tooltip, _last_mouse_pos)


	## Applies the final tooltip position with offset and edge-flip logic.
	## p_anchor is in plot-local coordinates. Because the tooltip uses
	## top_level = true, we convert to global coordinates for final placement.
	func _apply_position(p_tooltip: Control, p_anchor: Vector2) -> void:
		var style := _resolved_tooltip_style

		var offset := Vector2(style.offset_px)
		var tooltip_size := p_tooltip.size
		var plot_size := _plot.size

		# Candidate position in plot-local space: anchor + offset.
		var pos := p_anchor + offset

		# Edge-flip: if the tooltip overflows the TauPlot bounds, flip to the
		# opposite side of the anchor point.
		# Horizontal flip.
		if pos.x + tooltip_size.x > plot_size.x:
			pos.x = p_anchor.x - offset.x - tooltip_size.x
		if pos.x < 0.0:
			pos.x = max(0.0, p_anchor.x + absf(offset.x))

		# Vertical flip.
		if pos.y < 0.0:
			pos.y = p_anchor.y + absf(offset.y)
		if pos.y + tooltip_size.y > plot_size.y:
			pos.y = max(0.0, p_anchor.y - absf(offset.y) - tooltip_size.y)

		# Convert from plot-local to global because the tooltip has top_level = true.
		p_tooltip.global_position = _plot.global_position + pos
