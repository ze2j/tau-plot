# Dependencies
const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const XYDomain := preload("res://addons/tau-plot/plot/xy/xy_domain.gd").XYDomain
const PaneYDomains := preload("res://addons/tau-plot/plot/xy/xy_domain.gd").PaneYDomains
const AxisDomain := preload("res://addons/tau-plot/plot/xy/xy_domain.gd").AxisDomain


# Per-pane state.
class _PaneState extends RefCounted:
	# Domain bounds from last refresh: (min, max) per y-axis
	var y_axis_domains: Dictionary[AxisId, Vector2] = {}

	# Per-pane per-axis config snapshots (bottom, top, left, right)
	var bottom_tick_count_preferred: int = -1
	var bottom_overlap_strategy: int = -1
	var bottom_min_label_spacing_px: int = -1
	var bottom_inverted: int = -1

	var top_tick_count_preferred: int = -1
	var top_overlap_strategy: int = -1
	var top_min_label_spacing_px: int = -1
	var top_inverted: int = -1

	var left_tick_count_preferred: int = -1
	var left_overlap_strategy: int = -1
	var left_min_label_spacing_px: int = -1
	var left_inverted: int = -1

	var right_tick_count_preferred: int = -1
	var right_overlap_strategy: int = -1
	var right_min_label_spacing_px: int = -1
	var right_inverted: int = -1


	func reset() -> void:
		y_axis_domains.clear()

		bottom_tick_count_preferred = -1
		bottom_overlap_strategy = -1
		bottom_min_label_spacing_px = -1
		bottom_inverted = -1

		top_tick_count_preferred = -1
		top_overlap_strategy = -1
		top_min_label_spacing_px = -1
		top_inverted = -1

		left_tick_count_preferred = -1
		left_overlap_strategy = -1
		left_min_label_spacing_px = -1
		left_inverted = -1

		right_tick_count_preferred = -1
		right_overlap_strategy = -1
		right_min_label_spacing_px = -1
		right_inverted = -1


# Snapshot of the state that _refresh() uses for change detection between frames.
class XYState extends RefCounted:

	# Shared x domain bounds
	var domain_x_min: float = INF
	var domain_x_max: float = -INF

	# Shared x axis config snapshot from last refresh
	var x_axis_tick_count_preferred: int = -1
	var x_axis_overlap_strategy: int = -1
	var x_axis_min_label_spacing_px: int = -1
	var x_axis_inverted: int = -1

	# Categorical x labels from last refresh
	var domain_x_categories: PackedStringArray = []

	# Per-pane view rects from last refresh
	var pane_view_rects: Array[Rect2] = []

	# Per-pane config snapshots from last refresh
	var bar_config_per_pane: Array[TauBarConfig] = []
	var scatter_config_per_pane: Array[TauScatterConfig] = []

	# Per-pane grid_line config snapshots
	var grid_line_config_per_pane: Array[TauGridLineConfig] = []

	# Per-pane TauPaneStyle resource references (not duplicates, just the ref for
	# detecting when the user assigns a different TauPaneStyle to TauPaneConfig.style).
	var pane_style_ref_per_pane: Array = []

	# Per-pane TauPaneStyle content snapshots (duplicates for mutation detection).
	var pane_style_per_pane: Array[TauPaneStyle] = []

	# Style snapshots from last refresh
	var xy_style_snapshot: TauXYStyle = null
	var xy_style_ref: TauXYStyle = null
	var bar_style_per_pane: Array[TauBarStyle] = []
	var scatter_style_per_pane: Array[TauScatterStyle] = []

	# Per-pane overlay style resource references (for detecting when the user
	# assigns a different style resource to the config).
	var bar_style_ref_per_pane: Array = []
	var scatter_style_ref_per_pane: Array = []

	# TauLegendStyle ref + content tracking
	var legend_style_ref: TauLegendStyle = null
	var legend_style_snapshot: TauLegendStyle = null

	# Per-pane state
	const PaneState := _PaneState
	var pane_states: Array[PaneState] = []


	# Initializes per-pane state storage.
	func init_panes(p_pane_count: int) -> void:
		while pane_states.size() > p_pane_count:
			pane_states.pop_back()
		while pane_states.size() < p_pane_count:
			pane_states.append(PaneState.new())

		while bar_config_per_pane.size() > p_pane_count:
			bar_config_per_pane.pop_back()
		while bar_config_per_pane.size() < p_pane_count:
			bar_config_per_pane.append(null)

		while scatter_config_per_pane.size() > p_pane_count:
			scatter_config_per_pane.pop_back()
		while scatter_config_per_pane.size() < p_pane_count:
			scatter_config_per_pane.append(null)

		while grid_line_config_per_pane.size() > p_pane_count:
			grid_line_config_per_pane.pop_back()
		while grid_line_config_per_pane.size() < p_pane_count:
			grid_line_config_per_pane.append(null)

		while pane_style_ref_per_pane.size() > p_pane_count:
			pane_style_ref_per_pane.pop_back()
		while pane_style_ref_per_pane.size() < p_pane_count:
			pane_style_ref_per_pane.append(null)

		while pane_style_per_pane.size() > p_pane_count:
			pane_style_per_pane.pop_back()
		while pane_style_per_pane.size() < p_pane_count:
			pane_style_per_pane.append(null)

		while bar_style_per_pane.size() > p_pane_count:
			bar_style_per_pane.pop_back()
		while bar_style_per_pane.size() < p_pane_count:
			bar_style_per_pane.append(null)

		while scatter_style_per_pane.size() > p_pane_count:
			scatter_style_per_pane.pop_back()
		while scatter_style_per_pane.size() < p_pane_count:
			scatter_style_per_pane.append(null)

		while bar_style_ref_per_pane.size() > p_pane_count:
			bar_style_ref_per_pane.pop_back()
		while bar_style_ref_per_pane.size() < p_pane_count:
			bar_style_ref_per_pane.append(null)

		while scatter_style_ref_per_pane.size() > p_pane_count:
			scatter_style_ref_per_pane.pop_back()
		while scatter_style_ref_per_pane.size() < p_pane_count:
			scatter_style_ref_per_pane.append(null)


	func reset() -> void:
		domain_x_min = INF
		domain_x_max = -INF
		domain_x_categories = []

		x_axis_tick_count_preferred = -1
		x_axis_overlap_strategy = -1
		x_axis_min_label_spacing_px = -1
		x_axis_inverted = -1

		pane_view_rects = []

		bar_config_per_pane.clear()
		scatter_config_per_pane.clear()

		grid_line_config_per_pane.clear()
		pane_style_ref_per_pane.clear()
		pane_style_per_pane.clear()

		xy_style_snapshot = null
		xy_style_ref = null
		bar_style_per_pane.clear()
		scatter_style_per_pane.clear()

		bar_style_ref_per_pane.clear()
		scatter_style_ref_per_pane.clear()

		legend_style_ref = null
		legend_style_snapshot = null

		for pane_state: PaneState in pane_states:
			pane_state.reset()


	func have_pane_view_rects_changed(p_rects: Array[Rect2]) -> bool:
		if p_rects.size() != pane_view_rects.size():
			return true
		for i in range(p_rects.size()):
			if p_rects[i] != pane_view_rects[i]:
				return true
		return false


	func save_pane_view_rects(p_rects: Array[Rect2]) -> void:
		pane_view_rects = p_rects.duplicate()


	func save_domain(p_domain: XYDomain) -> void:
		# Save x domain
		domain_x_min = p_domain.x_axis_domain.min_val
		domain_x_max = p_domain.x_axis_domain.max_val
		domain_x_categories = p_domain.x_categories.duplicate()

		# Save per-pane y domains
		var pane_count: int = p_domain.get_pane_count()
		init_panes(pane_count)
		for i in range(pane_count):
			var pane_domain: PaneYDomains = p_domain.get_pane_domain(i)
			var pane_state: PaneState = pane_states[i]
			pane_state.y_axis_domains.clear()
			for axis_id in pane_domain.y_axis_domains:
				var y_axis_domain: AxisDomain = pane_domain.y_axis_domains[axis_id]
				pane_state.y_axis_domains[axis_id] = Vector2(y_axis_domain.min_val, y_axis_domain.max_val)


	func has_domain_changed(p_domain: XYDomain) -> bool:
		# Use exact comparison: false positives (unnecessary recompute) are better
		# than false negatives (stale rendering).

		# X domain
		if (p_domain.x_axis_domain.min_val != domain_x_min or p_domain.x_axis_domain.max_val != domain_x_max):
			return true

		# X categories
		if p_domain.x_categories != domain_x_categories:
			return true

		# Per-pane domains
		var pane_count: int = p_domain.get_pane_count()
		if pane_count != pane_states.size():
			return true

		for i in range(pane_count):
			var pane_domain: PaneYDomains = p_domain.get_pane_domain(i)
			var pane_state: PaneState = pane_states[i]
			for y_axis_id in pane_domain.y_axis_domains:
				var y_axis_domain: AxisDomain = pane_domain.y_axis_domains[y_axis_id]
				if y_axis_id not in pane_state.y_axis_domains:
					return true
				var y_axis_domain_state: Vector2 = pane_state.y_axis_domains[y_axis_id]
				if y_axis_domain.min_val != y_axis_domain_state.x or y_axis_domain.max_val != y_axis_domain_state.y:
					return true

		return false

	# ==================================================================================
	# Config snapshots
	# ==================================================================================

	func save_config(p_config: TauXYConfig) -> void:
		var pane_count := p_config.panes.size()
		init_panes(pane_count)

		if p_config.x_axis != null:
			x_axis_tick_count_preferred = p_config.x_axis.tick_count_preferred
			x_axis_overlap_strategy = int(p_config.x_axis.overlap_strategy)
			x_axis_min_label_spacing_px = p_config.x_axis.min_label_spacing_px
			x_axis_inverted = int(p_config.x_axis.inverted)
		else:
			x_axis_tick_count_preferred = -1
			x_axis_overlap_strategy = -1
			x_axis_min_label_spacing_px = -1
			x_axis_inverted = -1

		for i in range(pane_count):
			var pane: TauPaneConfig = p_config.panes[i]
			var pane_state: PaneState = pane_states[i]
			_save_axis_to(pane_state, "bottom", pane.y_bottom_axis)
			_save_axis_to(pane_state, "top", pane.y_top_axis)
			_save_axis_to(pane_state, "left", pane.y_left_axis)
			_save_axis_to(pane_state, "right", pane.y_right_axis)


	func has_config_changed(p_config: TauXYConfig) -> bool:
		if p_config.panes.is_empty():
			return false

		# Check shared x axis config fields.
		if _axis_changed(p_config.x_axis, x_axis_tick_count_preferred, x_axis_overlap_strategy, x_axis_min_label_spacing_px, x_axis_inverted):
			return true

		var pane_count := p_config.panes.size()
		if pane_count != pane_states.size():
			return true

		for i in range(pane_count):
			var pane: TauPaneConfig = p_config.panes[i]
			var ps: PaneState = pane_states[i]
			if (_axis_changed(pane.y_bottom_axis, ps.bottom_tick_count_preferred, ps.bottom_overlap_strategy, ps.bottom_min_label_spacing_px, ps.bottom_inverted) or
					_axis_changed(pane.y_top_axis, ps.top_tick_count_preferred, ps.top_overlap_strategy, ps.top_min_label_spacing_px, ps.top_inverted) or
					_axis_changed(pane.y_left_axis, ps.left_tick_count_preferred, ps.left_overlap_strategy, ps.left_min_label_spacing_px, ps.left_inverted) or
					_axis_changed(pane.y_right_axis, ps.right_tick_count_preferred, ps.right_overlap_strategy, ps.right_min_label_spacing_px, ps.right_inverted)):
				return true

		return false


	func save_bar_config_for_pane(p_pane_index: int, p_bar_config: TauBarConfig) -> void:
		if p_pane_index < 0 or p_pane_index >= bar_config_per_pane.size():
			return
		bar_config_per_pane[p_pane_index] = p_bar_config.duplicate() if p_bar_config != null else null


	func save_scatter_config_for_pane(p_pane_index: int, p_scatter_config: TauScatterConfig) -> void:
		if p_pane_index < 0 or p_pane_index >= scatter_config_per_pane.size():
			return
		scatter_config_per_pane[p_pane_index] = p_scatter_config.duplicate() if p_scatter_config != null else null


	func save_grid_line_config_for_pane(p_pane_index: int, p_grid_line_config: TauGridLineConfig) -> void:
		if p_pane_index < 0 or p_pane_index >= grid_line_config_per_pane.size():
			return
		grid_line_config_per_pane[p_pane_index] = p_grid_line_config.duplicate() if p_grid_line_config != null else null


	func has_grid_line_config_changed_for_pane(p_pane_index: int, p_grid_line_config: TauGridLineConfig) -> bool:
		if p_pane_index < 0 or p_pane_index >= grid_line_config_per_pane.size():
			return true
		var prev: TauGridLineConfig = grid_line_config_per_pane[p_pane_index]
		if prev == null and p_grid_line_config == null:
			return false
		if prev == null or p_grid_line_config == null:
			return true
		return not p_grid_line_config.is_equal_to(prev)

	# ==================================================================================
	# Style snapshots
	# ==================================================================================

	func save_xy_style(p_style: TauXYStyle) -> void:
		if p_style == null:
			xy_style_snapshot = null
			return
		xy_style_snapshot = p_style.duplicate()


	func save_xy_style_ref(p_style_ref: TauXYStyle) -> void:
		xy_style_ref = p_style_ref


	func has_xy_style_ref_changed(p_style_ref: TauXYStyle) -> bool:
		return xy_style_ref != p_style_ref


	func has_xy_style_changed(p_style: TauXYStyle) -> bool:
		if p_style == null and xy_style_snapshot == null:
			return false
		if p_style == null or xy_style_snapshot == null:
			return true
		return not p_style.is_equal_to(xy_style_snapshot)


	func has_xy_style_layout_change(p_style: TauXYStyle) -> bool:
		if p_style == null or xy_style_snapshot == null:
			return true
		return p_style.has_layout_affecting_change(xy_style_snapshot)


	func save_bar_style_for_pane(p_pane_index: int, p_style: TauBarStyle) -> void:
		if p_pane_index < 0 or p_pane_index >= bar_style_per_pane.size():
			return
		bar_style_per_pane[p_pane_index] = p_style.duplicate() if p_style != null else null


	func save_bar_style_ref_for_pane(p_pane_index: int, p_style_ref: TauBarStyle) -> void:
		if p_pane_index < 0 or p_pane_index >= bar_style_ref_per_pane.size():
			return
		bar_style_ref_per_pane[p_pane_index] = p_style_ref


	func has_bar_style_ref_changed_for_pane(p_pane_index: int, p_style_ref: TauBarStyle) -> bool:
		if p_pane_index < 0 or p_pane_index >= bar_style_ref_per_pane.size():
			return true
		return bar_style_ref_per_pane[p_pane_index] != p_style_ref


	func save_scatter_style_for_pane(p_pane_index: int, p_style: TauScatterStyle) -> void:
		if p_pane_index < 0 or p_pane_index >= scatter_style_per_pane.size():
			return
		scatter_style_per_pane[p_pane_index] = p_style.duplicate() if p_style != null else null


	func save_scatter_style_ref_for_pane(p_pane_index: int, p_style_ref: TauScatterStyle) -> void:
		if p_pane_index < 0 or p_pane_index >= scatter_style_ref_per_pane.size():
			return
		scatter_style_ref_per_pane[p_pane_index] = p_style_ref


	func has_scatter_style_ref_changed_for_pane(p_pane_index: int, p_style_ref: TauScatterStyle) -> bool:
		if p_pane_index < 0 or p_pane_index >= scatter_style_ref_per_pane.size():
			return true
		return scatter_style_ref_per_pane[p_pane_index] != p_style_ref


	func save_pane_style_for_pane(p_pane_index: int, p_style: TauPaneStyle) -> void:
		if p_pane_index < 0 or p_pane_index >= pane_style_per_pane.size():
			return
		pane_style_per_pane[p_pane_index] = p_style.duplicate() if p_style != null else null


	func save_pane_style_ref_for_pane(p_pane_index: int, p_style_ref: TauPaneStyle) -> void:
		if p_pane_index < 0 or p_pane_index >= pane_style_ref_per_pane.size():
			return
		pane_style_ref_per_pane[p_pane_index] = p_style_ref


	func has_pane_style_ref_changed_for_pane(p_pane_index: int, p_style_ref: TauPaneStyle) -> bool:
		if p_pane_index < 0 or p_pane_index >= pane_style_ref_per_pane.size():
			return true
		return pane_style_ref_per_pane[p_pane_index] != p_style_ref


	func save_legend_style(p_style: TauLegendStyle) -> void:
		if p_style == null:
			legend_style_snapshot = null
			return
		legend_style_snapshot = p_style.duplicate()


	func save_legend_style_ref(p_style_ref: TauLegendStyle) -> void:
		legend_style_ref = p_style_ref


	func has_legend_style_ref_changed(p_style_ref: TauLegendStyle) -> bool:
		return legend_style_ref != p_style_ref


	func has_legend_style_changed(p_style: TauLegendStyle) -> bool:
		if p_style == null and legend_style_snapshot == null:
			return false
		if p_style == null or legend_style_snapshot == null:
			return true
		return not p_style.is_equal_to(legend_style_snapshot)


	# ==================================================================================
	# PRIVATE
	# ==================================================================================

	static func _axis_changed(p_axis_cfg: TauAxisConfig, p_tick_count_preferred: int, p_overlap_strategy: TauAxisConfig.OverlapStrategy, p_spacing: int, p_inverted: int) -> bool:
		if p_axis_cfg == null:
			# If the axis was previously tracked (any value != -1), it has changed (was removed).
			return p_tick_count_preferred != -1

		return (p_axis_cfg.tick_count_preferred != p_tick_count_preferred or
				p_axis_cfg.overlap_strategy != p_overlap_strategy or
				p_axis_cfg.min_label_spacing_px != p_spacing or
				int(p_axis_cfg.inverted) != p_inverted)


	# Saves axis config snapshot into a PaneState for a given side.
	static func _save_axis_to(p_pane_state: PaneState, p_edge: String, p_axis_cfg: TauAxisConfig) -> void:
		if p_axis_cfg == null:
			p_pane_state.set(p_edge + "_tick_count_preferred", -1)
			p_pane_state.set(p_edge + "_overlap_strategy", -1)
			p_pane_state.set(p_edge + "_min_label_spacing_px", -1)
			p_pane_state.set(p_edge + "_inverted", -1)
			return

		p_pane_state.set(p_edge + "_tick_count_preferred", p_axis_cfg.tick_count_preferred)
		p_pane_state.set(p_edge + "_overlap_strategy", int(p_axis_cfg.overlap_strategy))
		p_pane_state.set(p_edge + "_min_label_spacing_px", p_axis_cfg.min_label_spacing_px)
		p_pane_state.set(p_edge + "_inverted", int(p_axis_cfg.inverted))
