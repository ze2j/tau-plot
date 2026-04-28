const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout
const SampleHit = preload("res://addons/tau-plot/plot/xy/hover/sample_hit.gd").SampleHit
const HoverMode = preload("res://addons/tau-plot/plot/xy/hover/hover_config.gd").HoverMode
const OverlayHitTester = preload("res://addons/tau-plot/plot/xy/hover/overlay_hit_tester.gd").OverlayHitTester
const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const ScatterRenderer := preload("res://addons/tau-plot/plot/xy/scatter/scatter_renderer.gd").ScatterRenderer


## Hit tester for the scatter overlay. Uses the scatter renderer's hover
## cache (screen positions, series IDs, sample indices, and values) to
## find hits near the pointer.
##
## In NEAREST mode, performs a brute-force linear scan over all cached
## screen positions and returns the closest point within the configured
## maximum distance.
## In X_ALIGNED mode, collects all points whose x position (categorical
## index or continuous value) matches the target.
class ScatterHitTester extends OverlayHitTester:
	var _pane_index: int
	var _scatter_config: TauScatterConfig
	var _scatter_renderer: ScatterRenderer
	var _dataset: Dataset
	var _layout: XYLayout


	func _init(
			p_pane_index: int,
			p_scatter_config: TauScatterConfig,
			p_scatter_renderer: ScatterRenderer,
			p_dataset: Dataset,
			p_layout: XYLayout) -> void:
		_pane_index = p_pane_index
		_scatter_config = p_scatter_config
		_scatter_renderer = p_scatter_renderer
		_dataset = p_dataset
		_layout = p_layout


	## Returns true when the scatter config allows hover hit testing.
	func is_hoverable() -> bool:
		return _scatter_config.hoverable


	## Scatter points are best selected individually, so NEAREST is preferred.
	func get_preferred_hover_mode() -> int:
		return HoverMode.NEAREST


	## Brute-force linear scan over cached screen positions. Returns the
	## closest point within hover_max_distance_px, or null if nothing is
	## close enough.
	##
	## p_local_pos: pointer position in pane-local screen coordinates
	##   (x = rightward pixels, y = downward pixels from the pane origin).
	func hit_test_nearest(p_local_pos: Vector2) -> SampleHit:
		var cache_size: int = _scatter_renderer.get_hover_cache_size()
		if cache_size <= 0:
			return null

		var max_dist: float = float(_scatter_config.hover_max_distance_px)
		var max_dist_sq := max_dist * max_dist
		var best_index := -1
		var best_dist_sq := INF

		for i in range(cache_size):
			var screen_pos: Vector2 = _scatter_renderer.get_hover_screen_position(i)
			var dx := p_local_pos.x - screen_pos.x
			var dy := p_local_pos.y - screen_pos.y
			var dist_sq := dx * dx + dy * dy
			if dist_sq < best_dist_sq and dist_sq <= max_dist_sq:
				best_dist_sq = dist_sq
				best_index = i

		if best_index < 0:
			return null

		return _create_hit_from_cache(best_index, sqrt(best_dist_sq))


	## Collects all scatter points at the given category index
	## (X_ALIGNED mode).
	##
	## p_category_index: zero-based index into the category array.
	## p_x_value: the category label at that index (String).
	## p_local_pos: pointer position in pane-local screen coordinates.
	func collect_hits_at_category(p_category_index: int, p_x_value: String, p_local_pos: Vector2) -> Array[SampleHit]:
		var hits: Array[SampleHit] = []
		var cache_size: int = _scatter_renderer.get_hover_cache_size()
		var max_dist: float = float(_scatter_config.hover_max_distance_px)

		for i in range(cache_size):
			var sample_idx: int = _scatter_renderer.get_hover_sample_index(i)
			if sample_idx != p_category_index:
				continue

			var screen_pos: Vector2 = _scatter_renderer.get_hover_screen_position(i)
			var dx := p_local_pos.x - screen_pos.x
			var dy := p_local_pos.y - screen_pos.y
			var dist := sqrt(dx * dx + dy * dy)

			var hit := SampleHit.new()
			hit.series_id = _scatter_renderer.get_hover_series_id(i)
			hit.series_name = _dataset.get_series_name(hit.series_id)
			hit.sample_index = sample_idx
			hit.x_value = p_x_value
			hit.y_value = _scatter_renderer.get_hover_y_value(i)
			hit.screen_position = screen_pos
			hit.pane_index = _pane_index
			hit.overlay_type = PaneOverlayType.SCATTER
			hit.distance_px = dist
			hit.contains_pointer = dist <= max_dist
			hits.append(hit)

		return hits


	## Collects all scatter points at a continuous x value (X_ALIGNED mode).
	## Only includes points whose x pixel position is within
	## hover_max_distance_px of the target and whose x value is close
	## enough numerically.
	##
	## p_x_value: the continuous x data value to collect hits at.
	## p_local_pos: pointer position in pane-local screen coordinates.
	func collect_hits_at_continuous_x(p_x_value: float, p_local_pos: Vector2) -> Array[SampleHit]:
		var max_dist_x: float = float(_scatter_config.hover_max_distance_px)
		var hits: Array[SampleHit] = []
		var cache_size: int = _scatter_renderer.get_hover_cache_size()
		var x_is_horizontal: bool = _layout._x_is_horizontal

		var target_x_px := _layout.map_x_to_px(_pane_index, p_x_value)

		for i in range(cache_size):
			var screen_pos: Vector2 = _scatter_renderer.get_hover_screen_position(i)
			var marker_x_px: float = screen_pos.x if x_is_horizontal else screen_pos.y
			var x_dist := absf(marker_x_px - target_x_px)

			if x_dist > max_dist_x:
				continue

			# Verify the x value is numerically close to the target.
			var cached_x = _scatter_renderer.get_hover_x_value(i)
			if cached_x is float:
				if not OverlayHitTester.x_values_match(cached_x, p_x_value):
					continue

			var dx := p_local_pos.x - screen_pos.x
			var dy := p_local_pos.y - screen_pos.y
			var dist := sqrt(dx * dx + dy * dy)

			var hit := SampleHit.new()
			hit.series_id = _scatter_renderer.get_hover_series_id(i)
			hit.series_name = _dataset.get_series_name(hit.series_id)
			hit.sample_index = _scatter_renderer.get_hover_sample_index(i)
			hit.x_value = _scatter_renderer.get_hover_x_value(i)
			hit.y_value = _scatter_renderer.get_hover_y_value(i)
			hit.screen_position = screen_pos
			hit.pane_index = _pane_index
			hit.overlay_type = PaneOverlayType.SCATTER
			hit.distance_px = dist
			hit.contains_pointer = dist <= max_dist_x
			hits.append(hit)

		return hits


	## Returns the nearest x pixel position and data value from the hover
	## cache. Iterates all cached screen positions to find the closest x
	## coordinate to the given axis-logical x pixel.
	##
	## p_along_x_px: pointer position projected onto the data x axis,
	##   in pixels from the pane origin along that axis direction.
	##   When x is horizontal this equals screen x. When x is vertical
	##   this equals screen y.
	##
	## Returns { "x_px": float, "x_value": float } or empty dict if
	## no data is available.
	func find_nearest_x(p_along_x_px: float) -> Dictionary:
		var cache_size: int = _scatter_renderer.get_hover_cache_size()
		if cache_size <= 0:
			return {}

		var x_is_horizontal: bool = _layout._x_is_horizontal
		var best_px := INF
		var best_val: float = 0.0
		var found := false

		for i in range(cache_size):
			var screen_pos: Vector2 = _scatter_renderer.get_hover_screen_position(i)
			var x_px: float = screen_pos.x if x_is_horizontal else screen_pos.y
			if absf(p_along_x_px - x_px) < absf(p_along_x_px - best_px):
				best_px = x_px
				var x_val = _scatter_renderer.get_hover_x_value(i)
				if x_val is float:
					best_val = x_val
				else:
					best_val = float(x_val)
				found = true

		if not found:
			return {}
		return { "x_px": best_px, "x_value": best_val }


	############################################################################
	# Private
	############################################################################

	## Builds a SampleHit from hover cache data at the given index.
	func _create_hit_from_cache(p_cache_index: int, p_distance: float) -> SampleHit:
		var hit := SampleHit.new()
		hit.series_id = _scatter_renderer.get_hover_series_id(p_cache_index)
		hit.series_name = _dataset.get_series_name(hit.series_id)
		hit.sample_index = _scatter_renderer.get_hover_sample_index(p_cache_index)
		hit.x_value = _scatter_renderer.get_hover_x_value(p_cache_index)
		hit.y_value = _scatter_renderer.get_hover_y_value(p_cache_index)
		hit.screen_position = _scatter_renderer.get_hover_screen_position(p_cache_index)
		hit.pane_index = _pane_index
		hit.overlay_type = PaneOverlayType.SCATTER
		hit.distance_px = p_distance
		hit.contains_pointer = true
		return hit
