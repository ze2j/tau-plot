const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout
const SampleHit := preload("res://addons/tau-plot/plot/xy/hover/sample_hit.gd").SampleHit
const HoverMode := preload("res://addons/tau-plot/plot/xy/hover/hover_config.gd").HoverMode
const OverlayHitTester := preload("res://addons/tau-plot/plot/xy/hover/overlay_hit_tester.gd").OverlayHitTester
const PaneOverlayType := preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const LineRenderer := preload("res://addons/tau-plot/plot/xy/line/line_renderer.gd").LineRenderer
const LineHitRecord := preload("res://addons/tau-plot/plot/xy/line/line_hit_record.gd").LineHitRecord


## Hit tester for the line overlay. Reads the renderer's LineHitRecord cache
## so the hit geometry cannot drift from the painted geometry.
##
## In NEAREST mode, performs a brute-force linear scan over all records and
## returns the closest sample within the configured hover pixel gate.
## In X_ALIGNED mode, collects all samples whose x position (categorical
## index or continuous value) matches the target.
##
## Line overlays prefer X_ALIGNED in TauHoverConfig.HoverMode.AUTO because
## line charts are typically read along the x axis.
class LineHitTester extends OverlayHitTester:
	var _pane_index: int
	var _line_config: TauLineConfig
	var _line_renderer: LineRenderer
	var _dataset: Dataset
	var _layout: XYLayout


	func _init(
			p_pane_index: int,
			p_line_config: TauLineConfig,
			p_line_renderer: LineRenderer,
			p_dataset: Dataset,
			p_layout: XYLayout) -> void:
		_pane_index = p_pane_index
		_line_config = p_line_config
		_line_renderer = p_line_renderer
		_dataset = p_dataset
		_layout = p_layout


	func is_hoverable() -> bool:
		return _line_config.hoverable


	func get_preferred_hover_mode() -> HoverMode:
		return HoverMode.X_ALIGNED


	####################################################################
	# NEAREST mode
	####################################################################

	## Brute-force linear scan. Returns the closest record within
	## hover_max_distance_px, or null.
	func hit_test_nearest(p_local_pos: Vector2) -> SampleHit:
		var max_dist: float = float(_line_config.hover_max_distance_px)
		var max_dist_sq: float = max_dist * max_dist
		var best_record: LineHitRecord = null
		var best_dist_sq: float = INF

		for record: LineHitRecord in _line_renderer.get_hit_records():
			var dx: float = p_local_pos.x - record.screen_position.x
			var dy: float = p_local_pos.y - record.screen_position.y
			var dist_sq: float = dx * dx + dy * dy
			if dist_sq < best_dist_sq and dist_sq <= max_dist_sq:
				best_dist_sq = dist_sq
				best_record = record

		if best_record == null:
			return null
		return _build_hit(best_record, sqrt(best_dist_sq), true)


	####################################################################
	# X_ALIGNED mode
	####################################################################

	func collect_hits_at_category(p_category_index: int, p_x_value: String, p_local_pos: Vector2) -> Array[SampleHit]:
		var hits: Array[SampleHit] = []
		var max_dist: float = float(_line_config.hover_max_distance_px)

		for record: LineHitRecord in _line_renderer.get_hit_records():
			if record.sample_index != p_category_index:
				continue
			var dx: float = p_local_pos.x - record.screen_position.x
			var dy: float = p_local_pos.y - record.screen_position.y
			var dist: float = sqrt(dx * dx + dy * dy)
			# Categorical hits override the cached x_value with the resolved
			# category label so the hit reads consistently with bars and
			# scatter at the same X.
			var hit := _build_hit(record, dist, dist <= max_dist)
			hit.x_value = p_x_value
			hits.append(hit)

		return hits


	func collect_hits_at_continuous_x(p_anchor_x_value: float, p_local_pos: Vector2) -> Array[SampleHit]:
		var anchor_x_px: float = _layout.map_x_to_px(_pane_index, p_anchor_x_value)
		var nearest: Dictionary = find_nearest_x(anchor_x_px)
		if nearest.is_empty():
			return []

		var max_dist_x: float = float(_line_config.hover_max_distance_px)
		if absf(nearest["x_px"] - anchor_x_px) > max_dist_x:
			return []

		var own_x_value: float = nearest["x_value"]
		var hits: Array[SampleHit] = []
		for record: LineHitRecord in _line_renderer.get_hit_records():
			if not OverlayHitTester.x_values_match(record.x_value, own_x_value):
				continue

			var dx: float = p_local_pos.x - record.screen_position.x
			var dy: float = p_local_pos.y - record.screen_position.y
			var dist: float = sqrt(dx * dx + dy * dy)
			hits.append(_build_hit(record, dist, dist <= max_dist_x))

		return hits


	## Returns the nearest x pixel position and data value across all
	## records, or an empty dictionary when no records exist.
	func find_nearest_x(p_along_x_px: float) -> Dictionary:
		var x_is_horizontal: bool = _layout._x_is_horizontal
		var best_px: float = INF
		var best_val: float = 0.0
		var found: bool = false

		for record: LineHitRecord in _line_renderer.get_hit_records():
			var x_px: float = record.screen_position.x if x_is_horizontal else record.screen_position.y
			if absf(p_along_x_px - x_px) < absf(p_along_x_px - best_px):
				best_px = x_px
				best_val = record.x_value
				found = true

		if not found:
			return {}
		return { "x_px": best_px, "x_value": best_val }


	####################################################################
	# Private
	####################################################################

	func _build_hit(p_record: LineHitRecord, p_distance: float, p_contains: bool) -> SampleHit:
		var hit := SampleHit.new()
		hit.series_id = p_record.series_id
		hit.series_name = _dataset.get_series_name(p_record.series_id)
		hit.sample_index = p_record.sample_index
		hit.x_value = p_record.x_value
		hit.y_plotted_value = p_record.y_plotted_value
		hit.y_raw_value = p_record.y_raw_value
		hit.screen_position = p_record.screen_position
		hit.pane_index = _pane_index
		hit.overlay_type = PaneOverlayType.LINE
		hit.distance_px = p_distance
		hit.contains_pointer = p_contains
		return hit
