const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout
const SeriesAxisAssignment := preload("res://addons/tau-plot/plot/xy/series_axis_assignment.gd").SeriesAxisAssignment
const BarGeometry := preload("res://addons/tau-plot/plot/xy/bar/bar_geometry.gd").BarGeometry
const SampleHit = preload("res://addons/tau-plot/plot/xy/hover/sample_hit.gd").SampleHit
const HoverMode = preload("res://addons/tau-plot/plot/xy/hover/hover_config.gd").HoverMode
const OverlayHitTester = preload("res://addons/tau-plot/plot/xy/hover/overlay_hit_tester.gd").OverlayHitTester
const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType


## Hit tester for the bar overlay. Checks whether the pointer falls inside
## a rendered bar rect (NEAREST mode) or collects all bar samples at a
## given x position (X_ALIGNED mode).
##
## Supports categorical and continuous x axes, as well as grouped, stacked,
## and independent bar modes. Bar widths and offsets come from a private
## BarGeometry instance for both categorical and continuous x.
class BarHitTester extends OverlayHitTester:
	var _pane_index: int
	var _bar_config: TauBarConfig
	var _bar_style: TauBarStyle
	var _dataset: Dataset
	var _layout: XYLayout
	var _series_assignment: SeriesAxisAssignment
	var _bar_series_ids: PackedInt64Array
	var _geometry: BarGeometry


	func _init(
			p_pane_index: int,
			p_bar_config: TauBarConfig,
			p_bar_style: TauBarStyle,
			p_dataset: Dataset,
			p_layout: XYLayout,
			p_series_assignment: SeriesAxisAssignment,
			p_bar_series_ids: PackedInt64Array) -> void:
		_pane_index = p_pane_index
		_bar_config = p_bar_config
		_bar_style = p_bar_style
		_dataset = p_dataset
		_layout = p_layout
		_series_assignment = p_series_assignment
		_bar_series_ids = p_bar_series_ids

		var x_axis_config := _layout.domain.config.x_axis
		_geometry = BarGeometry.new(
			_layout, _dataset, _bar_config, _bar_style,
			_bar_series_ids.size(), _pane_index, x_axis_config)


	## Returns true when the bar config allows hover hit testing.
	func is_hoverable() -> bool:
		return _bar_config.hoverable


	## Bars naturally align along the x axis, so X_ALIGNED is preferred.
	func get_preferred_hover_mode() -> int:
		return HoverMode.X_ALIGNED


	## Finds the single bar closest to the pointer position.
	##
	## p_local_pos: pointer position in pane-local screen coordinates
	##   (x = rightward pixels, y = downward pixels from the pane origin).
	##
	## For categorical x the category is determined from the pointer
	## position and each series bar is checked for containment. For
	## continuous x a linear scan finds the nearest x and then checks
	## bar rects.
	func hit_test_nearest(p_local_pos: Vector2) -> SampleHit:
		var x_config := _layout.domain.config.x_axis
		var pane_rect := _layout.get_pane_rect(_pane_index)
		if pane_rect.size.x <= 0.0 or pane_rect.size.y <= 0.0:
			return null

		var x_is_horizontal: bool = _layout._x_is_horizontal

		# Convert pane-local screen coords to axis-logical coords where
		# along_x runs along the data x axis and along_y runs along the
		# data y axis, regardless of orientation.
		var along_x_px: float
		var along_y_px: float
		if x_is_horizontal:
			along_x_px = p_local_pos.x
			along_y_px = p_local_pos.y
		else:
			along_x_px = p_local_pos.y
			along_y_px = p_local_pos.x

		if _bar_series_ids.is_empty():
			return null

		if x_config.type == TauAxisConfig.Type.CATEGORICAL:
			return _hit_test_categorical(pane_rect, along_x_px, along_y_px, x_is_horizontal)
		return _hit_test_continuous(pane_rect, along_x_px, along_y_px, x_is_horizontal)


	## Collects all bar hits at the given category index (X_ALIGNED mode).
	##
	## p_category_index: zero-based index into the category array.
	## p_x_value: the category label at that index (String).
	## p_local_pos: pointer position in pane-local screen coordinates.
	func collect_hits_at_category(
			p_category_index: int,
			p_x_value: Variant,
			p_local_pos: Vector2) -> Array[SampleHit]:
		var hits: Array[SampleHit] = []
		var x_is_horizontal: bool = _layout._x_is_horizontal

		var pane_rect := _layout.get_pane_rect(_pane_index)
		var categories := _layout.domain.x_categories
		var n := categories.size()

		# Convert screen coords to axis-logical coords for containment checks.
		var along_x_px: float
		var along_y_px: float
		if x_is_horizontal:
			along_x_px = p_local_pos.x
			along_y_px = p_local_pos.y
		else:
			along_x_px = p_local_pos.y
			along_y_px = p_local_pos.x

		var bar_width_px := _geometry.compute_categorical_bar_width_px(pane_rect, n) if n > 0 else 0.0
		var series_count := _bar_series_ids.size()
		var is_grouped := _bar_config.mode == TauBarConfig.BarMode.GROUPED

		for series_local_idx in range(series_count):
			var series_id: int = _bar_series_ids[series_local_idx]
			if p_category_index >= _dataset.get_series_sample_count(series_id):
				continue
			var y_value := _dataset.get_series_y(series_id, p_category_index)
			if is_nan(y_value) or is_inf(y_value):
				continue

			var y_axis_id: int = _series_assignment.get_y_axis_id_for_series(series_id, _pane_index)
			var y_px := _layout.map_y_to_px(_pane_index, y_value, y_axis_id)
			var center_px := _layout.map_x_category_center_to_px(_pane_index, p_category_index)

			# For GROUPED bars, offset the screen_position to the actual bar
			# center so that each hit reflects its real on-screen location.
			var hit_center_px := center_px
			if is_grouped and series_count > 1:
				hit_center_px += _geometry.compute_grouped_bar_center_offset_px(series_local_idx, pane_rect, n)

			var hit := _create_hit(series_id, p_category_index, p_x_value, y_value, hit_center_px, y_px, p_local_pos, x_is_horizontal)

			# Compute containment for this bar rect.
			hit.contains_pointer = _check_categorical_containment(
				series_local_idx, series_count, p_category_index,
				y_value, y_axis_id, center_px, bar_width_px,
				pane_rect, n, along_x_px, along_y_px)

			hits.append(hit)

		return hits


	## Collects all bar hits at a continuous x value (X_ALIGNED mode).
	##
	## p_x_value: the continuous x data value to collect hits at.
	## p_local_pos: pointer position in pane-local screen coordinates.
	func collect_hits_at_continuous_x(
			p_x_value: float,
			p_local_pos: Vector2) -> Array[SampleHit]:
		var hits: Array[SampleHit] = []
		var x_is_horizontal: bool = _layout._x_is_horizontal

		# Convert screen coords to axis-logical coords for containment checks.
		var along_x_px: float
		var along_y_px: float
		if x_is_horizontal:
			along_x_px = p_local_pos.x
			along_y_px = p_local_pos.y
		else:
			along_x_px = p_local_pos.y
			along_y_px = p_local_pos.x

		if _dataset.get_mode() == Dataset.Mode.SHARED_X:
			var n := _dataset.get_shared_sample_count()
			var best_index := -1
			var best_dist := INF
			for i in range(n):
				var x_val := float(_dataset.get_shared_x(i))
				if is_nan(x_val) or is_inf(x_val):
					continue
				var dist := absf(x_val - p_x_value)
				if dist < best_dist:
					best_dist = dist
					best_index = i

			if best_index < 0:
				return []

			for series_local_idx in range(_bar_series_ids.size()):
				var series_id: int = _bar_series_ids[series_local_idx]
				if best_index >= _dataset.get_series_sample_count(series_id):
					continue
				var y_value := _dataset.get_series_y(series_id, best_index)
				if is_nan(y_value) or is_inf(y_value):
					continue

				var y_axis_id: int = _series_assignment.get_y_axis_id_for_series(series_id, _pane_index)
				var y_px := _layout.map_y_to_px(_pane_index, y_value, y_axis_id)
				var center_px := _layout.map_x_to_px(_pane_index, p_x_value)

				var hit := _create_hit(series_id, best_index, p_x_value, y_value, center_px, y_px, p_local_pos, x_is_horizontal)

				# Compute containment for this bar rect.
				var base_px := _get_bar_base_px(y_axis_id)
				var bar_width_px := _geometry.compute_bar_width_px_for_shared_x_index(best_index, n)
				hit.contains_pointer = _check_rect_containment(
					center_px, y_px, base_px, bar_width_px,
					along_x_px, along_y_px)

				hits.append(hit)

		else:
			# PER_SERIES_X: find the closest sample per series, but only
			# include it if its x value actually matches the target. This
			# ensures the tooltip only shows series that have a data point
			# at (or virtually at) the globally nearest x.
			for series_local_idx in range(_bar_series_ids.size()):
				var series_id: int = _bar_series_ids[series_local_idx]
				var count := _dataset.get_series_sample_count(series_id)
				if count <= 0:
					continue

				var best_index := -1
				var best_dist := INF
				for i in range(count):
					var x_val := float(_dataset.get_series_x(series_id, i))
					if is_nan(x_val) or is_inf(x_val):
						continue
					var dist := absf(x_val - p_x_value)
					if dist < best_dist:
						best_dist = dist
						best_index = i

				if best_index < 0:
					continue

				var matched_x := float(_dataset.get_series_x(series_id, best_index))

				# Skip this series if its closest x is not at the target x.
				if not OverlayHitTester.x_values_match(matched_x, p_x_value):
					continue

				var y_value := _dataset.get_series_y(series_id, best_index)
				if is_nan(y_value) or is_inf(y_value):
					continue

				var y_axis_id: int = _series_assignment.get_y_axis_id_for_series(series_id, _pane_index)
				var y_px := _layout.map_y_to_px(_pane_index, y_value, y_axis_id)
				var center_px := _layout.map_x_to_px(_pane_index, matched_x)

				var hit := _create_hit(series_id, best_index, matched_x, y_value, center_px, y_px, p_local_pos, x_is_horizontal)

				# Compute containment for this bar rect.
				var base_px := _get_bar_base_px(y_axis_id)
				var bar_width_px := _geometry.compute_bar_width_px_for_series_sample(series_id, best_index, count)
				hit.contains_pointer = _check_rect_containment(
					center_px, y_px, base_px, bar_width_px,
					along_x_px, along_y_px)

				hits.append(hit)

		return hits


	## Returns the nearest x pixel position and data value for continuous
	## x axes. Used by the coordinator to find the globally nearest x
	## before collecting hits from all testers.
	##
	## p_along_x_px: pointer position projected onto the data x axis,
	##   in pixels from the pane origin along that axis direction.
	##   When x is horizontal this equals screen x. When x is vertical
	##   this equals screen y.
	##
	## Returns { "x_px": float, "x_value": float } or empty dict if
	## no data is available.
	func find_nearest_x(p_along_x_px: float) -> Dictionary:
		var x_config := _layout.domain.config.x_axis
		if x_config.type == TauAxisConfig.Type.CATEGORICAL:
			return {}

		var best_px := INF
		var best_val: float = 0.0
		var found := false

		if _dataset.get_mode() == Dataset.Mode.SHARED_X:
			var n := _dataset.get_shared_sample_count()
			for i in range(n):
				var x_val := float(_dataset.get_shared_x(i))
				if is_nan(x_val) or is_inf(x_val):
					continue
				var x_px := _layout.map_x_to_px(_pane_index, x_val)
				if absf(p_along_x_px - x_px) < absf(p_along_x_px - best_px):
					best_px = x_px
					best_val = x_val
					found = true
		else:
			for sid in _bar_series_ids:
				var count := _dataset.get_series_sample_count(sid)
				for i in range(count):
					var x_val := float(_dataset.get_series_x(sid, i))
					if is_nan(x_val) or is_inf(x_val):
						continue
					var x_px := _layout.map_x_to_px(_pane_index, x_val)
					if absf(p_along_x_px - x_px) < absf(p_along_x_px - best_px):
						best_px = x_px
						best_val = x_val
						found = true

		if not found:
			return {}
		return { "x_px": best_px, "x_value": best_val }


	############################################################################
	# Private: NEAREST mode helpers
	############################################################################

	## Categorical nearest: determines the category from the pointer's
	## axis-logical position, then checks each series bar rect for
	## containment.
	##
	## All pixel parameters are in axis-logical space (along_x runs along
	## the data x axis, along_y runs along the data y axis), already
	## transposed from screen coords by hit_test_nearest.
	##
	## p_pane_rect: pane rectangle in screen coordinates.
	## p_along_x_px: pointer x in axis-logical pixels.
	## p_along_y_px: pointer y in axis-logical pixels.
	## p_x_is_horizontal: true when the data x axis is the screen x axis.
	func _hit_test_categorical(
			p_pane_rect: Rect2,
			p_along_x_px: float,
			p_along_y_px: float,
			p_x_is_horizontal: bool) -> SampleHit:

		var categories := _layout.domain.x_categories
		var n := categories.size()
		if n <= 0:
			return null

		var x_extent: float = p_pane_rect.size.x if p_x_is_horizontal else p_pane_rect.size.y
		var x_origin: float = p_pane_rect.position.x if p_x_is_horizontal else p_pane_rect.position.y

		var step_px := x_extent / float(n)
		var rel_x := p_along_x_px - x_origin
		var category_index := int(rel_x / step_px)
		if category_index < 0 or category_index >= n:
			return null

		var series_count := _bar_series_ids.size()
		var center_px := _layout.map_x_category_center_to_px(_pane_index, category_index)

		var bar_width_px := _geometry.compute_categorical_bar_width_px(p_pane_rect, n)

		for series_local_idx in range(series_count):
			var series_id: int = _bar_series_ids[series_local_idx]
			if category_index >= _dataset.get_series_sample_count(series_id):
				continue

			var y_value := _dataset.get_series_y(series_id, category_index)
			if is_nan(y_value) or is_inf(y_value):
				continue

			var y_axis_id: int = _series_assignment.get_y_axis_id_for_series(series_id, _pane_index)
			var y_px := _layout.map_y_to_px(_pane_index, y_value, y_axis_id)
			var zero_px := _layout.get_y_zero_px(_pane_index, y_axis_id)

			match _bar_config.mode:
				TauBarConfig.BarMode.GROUPED:
					var offset := _geometry.compute_grouped_bar_center_offset_px(series_local_idx, p_pane_rect, n)
					var bar_center := center_px + offset

					var bar_left := bar_center - bar_width_px * 0.5
					var bar_right := bar_center + bar_width_px * 0.5
					var bar_top := min(y_px, zero_px)
					var bar_bottom := max(y_px, zero_px)

					if p_along_x_px >= bar_left and p_along_x_px <= bar_right and p_along_y_px >= bar_top and p_along_y_px <= bar_bottom:
						return _create_hit_from_axis_logical(series_id, category_index, categories[category_index], y_value, bar_center, y_px, p_along_x_px, p_along_y_px, p_x_is_horizontal)

				TauBarConfig.BarMode.INDEPENDENT:
					var bar_left := center_px - bar_width_px * 0.5
					var bar_right := center_px + bar_width_px * 0.5
					var bar_top := min(y_px, zero_px)
					var bar_bottom := max(y_px, zero_px)

					if p_along_x_px >= bar_left and p_along_x_px <= bar_right and p_along_y_px >= bar_top and p_along_y_px <= bar_bottom:
						return _create_hit_from_axis_logical(series_id, category_index, categories[category_index], y_value, center_px, y_px, p_along_x_px, p_along_y_px, p_x_is_horizontal)

				TauBarConfig.BarMode.STACKED:
					var bar_left := center_px - bar_width_px * 0.5
					var bar_right := center_px + bar_width_px * 0.5

					if p_along_x_px < bar_left or p_along_x_px > bar_right:
						continue

					# Walk the cumulative stack to find which segment contains the pointer.
					var cumulative: float = 0.0
					for stack_idx in range(series_count):
						var stack_sid: int = _bar_series_ids[stack_idx]
						if category_index >= _dataset.get_series_sample_count(stack_sid):
							continue
						var stack_y := _dataset.get_series_y(stack_sid, category_index)
						if is_nan(stack_y) or is_inf(stack_y) or stack_y < 0.0:
							continue
						var y0 := cumulative
						cumulative += stack_y
						var y1 := cumulative

						var y0_px := _layout.map_y_to_px(_pane_index, y0, y_axis_id)
						var y1_px := _layout.map_y_to_px(_pane_index, y1, y_axis_id)
						var seg_top := min(y0_px, y1_px)
						var seg_bottom := max(y0_px, y1_px)

						if p_along_y_px >= seg_top and p_along_y_px <= seg_bottom:
							return _create_hit_from_axis_logical(stack_sid, category_index, categories[category_index], stack_y, center_px, y1_px, p_along_x_px, p_along_y_px, p_x_is_horizontal)

				_:
					push_error("BarHitTester: unexpected bar mode %d" % int(_bar_config.mode))
					return null

		return null


	## Continuous nearest: linear scan over x values, then checks bar
	## rects for containment at the nearest x position.
	##
	## Parameters use the same axis-logical convention as
	## _hit_test_categorical (see its documentation).
	func _hit_test_continuous(
			p_pane_rect: Rect2,
			p_along_x_px: float,
			p_along_y_px: float,
			p_x_is_horizontal: bool) -> SampleHit:

		var series_count := _bar_series_ids.size()

		if _dataset.get_mode() == Dataset.Mode.SHARED_X:
			var n := _dataset.get_shared_sample_count()
			if n <= 0:
				return null

			var best_x_index := -1
			var best_x_dist := INF
			for i in range(n):
				var x_val := float(_dataset.get_shared_x(i))
				if is_nan(x_val) or is_inf(x_val):
					continue
				var x_px := _layout.map_x_to_px(_pane_index, x_val)
				var dist := absf(p_along_x_px - x_px)
				if dist < best_x_dist:
					best_x_dist = dist
					best_x_index = i

			if best_x_index < 0:
				return null

			var x_value := float(_dataset.get_shared_x(best_x_index))
			var center_px := _layout.map_x_to_px(_pane_index, x_value)

			for series_local_idx in range(series_count):
				var series_id: int = _bar_series_ids[series_local_idx]
				if best_x_index >= _dataset.get_series_sample_count(series_id):
					continue
				var y_value := _dataset.get_series_y(series_id, best_x_index)
				if is_nan(y_value) or is_inf(y_value):
					continue

				var y_axis_id: int = _series_assignment.get_y_axis_id_for_series(series_id, _pane_index)
				var y_px := _layout.map_y_to_px(_pane_index, y_value, y_axis_id)
				var zero_px := _layout.get_y_zero_px(_pane_index, y_axis_id)

				var bar_width_px: float = float(_bar_style.bar_width_px)

				var bar_left := center_px - bar_width_px * 0.5
				var bar_right := center_px + bar_width_px * 0.5
				var bar_top := min(y_px, zero_px)
				var bar_bottom := max(y_px, zero_px)

				if p_along_x_px >= bar_left and p_along_x_px <= bar_right and p_along_y_px >= bar_top and p_along_y_px <= bar_bottom:
					return _create_hit_from_axis_logical(series_id, best_x_index, x_value, y_value, center_px, y_px, p_along_x_px, p_along_y_px, p_x_is_horizontal)

		else:
			# PER_SERIES_X: check each series independently.
			for series_local_idx in range(series_count):
				var series_id: int = _bar_series_ids[series_local_idx]
				var count := _dataset.get_series_sample_count(series_id)
				for i in range(count):
					var x_val := float(_dataset.get_series_x(series_id, i))
					if is_nan(x_val) or is_inf(x_val):
						continue
					var y_value := _dataset.get_series_y(series_id, i)
					if is_nan(y_value) or is_inf(y_value):
						continue

					var y_axis_id: int = _series_assignment.get_y_axis_id_for_series(series_id, _pane_index)
					var center_px := _layout.map_x_to_px(_pane_index, x_val)
					var y_px := _layout.map_y_to_px(_pane_index, y_value, y_axis_id)
					var zero_px := _layout.get_y_zero_px(_pane_index, y_axis_id)

					var bar_width_px: float = float(_bar_style.bar_width_px)

					var bar_left := center_px - bar_width_px * 0.5
					var bar_right := center_px + bar_width_px * 0.5
					var bar_top := min(y_px, zero_px)
					var bar_bottom := max(y_px, zero_px)

					if p_along_x_px >= bar_left and p_along_x_px <= bar_right and p_along_y_px >= bar_top and p_along_y_px <= bar_bottom:
						return _create_hit_from_axis_logical(series_id, i, x_val, y_value, center_px, y_px, p_along_x_px, p_along_y_px, p_x_is_horizontal)

		return null


	############################################################################
	# Private: hit construction
	############################################################################

	## Builds a SampleHit from axis-logical pixel coordinates. Converts the
	## bar center and y pixel back to pane-local screen coordinates for the
	## screen_position field, and computes distance from the pointer in
	## screen space. Called from _hit_test_categorical and _hit_test_continuous
	## which only return a hit when the pointer is inside the bar rect, so
	## contains_pointer is always true.
	##
	## p_bar_center_along_x_px: bar center in axis-logical x pixels.
	## p_bar_y_along_y_px: bar tip (top for upward bars) in axis-logical y pixels.
	## p_along_x_px / p_along_y_px: pointer in axis-logical pixels.
	## p_x_is_horizontal: true when the data x axis is the screen x axis.
	func _create_hit_from_axis_logical(
			p_series_id: int,
			p_sample_index: int,
			p_x_value: Variant,
			p_y_value: float,
			p_bar_center_along_x_px: float,
			p_bar_y_along_y_px: float,
			p_along_x_px: float,
			p_along_y_px: float,
			p_x_is_horizontal: bool) -> SampleHit:

		var hit := SampleHit.new()
		hit.series_id = p_series_id
		hit.series_name = _dataset.get_series_name(p_series_id)
		hit.sample_index = p_sample_index
		hit.x_value = p_x_value
		hit.y_value = p_y_value
		hit.pane_index = _pane_index
		hit.overlay_type = PaneOverlayType.BAR
		hit.contains_pointer = true

		# Convert axis-logical back to pane-local screen coords for screen_position.
		if p_x_is_horizontal:
			hit.screen_position = Vector2(p_bar_center_along_x_px, p_bar_y_along_y_px)
		else:
			hit.screen_position = Vector2(p_bar_y_along_y_px, p_bar_center_along_x_px)

		# Distance in screen space.
		var screen_pointer_x: float
		var screen_pointer_y: float
		if p_x_is_horizontal:
			screen_pointer_x = p_along_x_px
			screen_pointer_y = p_along_y_px
		else:
			screen_pointer_x = p_along_y_px
			screen_pointer_y = p_along_x_px

		var dx := screen_pointer_x - hit.screen_position.x
		var dy := screen_pointer_y - hit.screen_position.y
		hit.distance_px = sqrt(dx * dx + dy * dy)
		return hit


	## Builds a SampleHit from pane-local screen coordinates. Used by the
	## public collect_hits_* methods which receive p_local_pos in screen
	## space and do not transpose into axis-logical space.
	##
	## p_bar_center_along_x_px: bar center in axis-logical x pixels
	##   (from map_x_to_px / map_x_category_center_to_px).
	## p_bar_y_along_y_px: bar tip in axis-logical y pixels
	##   (from map_y_to_px).
	## p_local_pos: pointer position in pane-local screen coordinates.
	## p_x_is_horizontal: true when the data x axis is the screen x axis.
	func _create_hit(
			p_series_id: int,
			p_sample_index: int,
			p_x_value: Variant,
			p_y_value: float,
			p_bar_center_along_x_px: float,
			p_bar_y_along_y_px: float,
			p_local_pos: Vector2,
			p_x_is_horizontal: bool) -> SampleHit:

		var hit := SampleHit.new()
		hit.series_id = p_series_id
		hit.series_name = _dataset.get_series_name(p_series_id)
		hit.sample_index = p_sample_index
		hit.x_value = p_x_value
		hit.y_value = p_y_value
		hit.pane_index = _pane_index
		hit.overlay_type = PaneOverlayType.BAR

		if p_x_is_horizontal:
			hit.screen_position = Vector2(p_bar_center_along_x_px, p_bar_y_along_y_px)
		else:
			hit.screen_position = Vector2(p_bar_y_along_y_px, p_bar_center_along_x_px)

		var dx := p_local_pos.x - hit.screen_position.x
		var dy := p_local_pos.y - hit.screen_position.y
		hit.distance_px = sqrt(dx * dx + dy * dy)
		return hit


	############################################################################
	# Private: containment helpers for X_ALIGNED collect methods
	############################################################################

	## Returns the bar base pixel for the given y axis, handling logarithmic
	## scales where y=0 is invalid. For log scales the bar base is the domain
	## minimum (matching the bar renderer's _get_zero_px_for_series logic).
	func _get_bar_base_px(p_y_axis_id: int) -> float:
		var pane_domain := _layout.domain.get_pane_domain(_pane_index)
		var y_axis_domain := pane_domain.get_y_axis_domain(p_y_axis_id)
		if y_axis_domain != null and y_axis_domain.scale == TauAxisConfig.Scale.LOGARITHMIC:
			return _layout.map_y_to_px(_pane_index, y_axis_domain.min_val, p_y_axis_id)
		return _layout.get_y_zero_px(_pane_index, p_y_axis_id)


	## Checks whether the pointer (in axis-logical pixels) falls inside a
	## simple rectangular bar defined by its center, y extent, and width.
	## Used for INDEPENDENT and continuous-x bars.
	func _check_rect_containment(
			p_center_px: float,
			p_y_px: float,
			p_base_px: float,
			p_bar_width_px: float,
			p_along_x_px: float,
			p_along_y_px: float) -> bool:
		var bar_left := p_center_px - p_bar_width_px * 0.5
		var bar_right := p_center_px + p_bar_width_px * 0.5
		var bar_top := min(p_y_px, p_base_px)
		var bar_bottom := max(p_y_px, p_base_px)
		return (p_along_x_px >= bar_left and p_along_x_px <= bar_right
			and p_along_y_px >= bar_top and p_along_y_px <= bar_bottom)


	## Checks whether the pointer falls inside a bar rect for categorical x,
	## accounting for the bar mode (GROUPED, STACKED, INDEPENDENT).
	##
	## All pixel parameters are in axis-logical space.
	func _check_categorical_containment(
			p_series_local_idx: int,
			p_series_count: int,
			p_category_index: int,
			p_y_value: float,
			p_y_axis_id: int,
			p_center_px: float,
			p_bar_width_px: float,
			p_pane_rect: Rect2,
			p_category_count: int,
			p_along_x_px: float,
			p_along_y_px: float) -> bool:

		var base_px := _get_bar_base_px(p_y_axis_id)

		match _bar_config.mode:
			TauBarConfig.BarMode.GROUPED:
				var offset := _geometry.compute_grouped_bar_center_offset_px(
					p_series_local_idx, p_pane_rect, p_category_count)
				var bar_center := p_center_px + offset
				var y_px := _layout.map_y_to_px(_pane_index, p_y_value, p_y_axis_id)
				return _check_rect_containment(
					bar_center, y_px, base_px, p_bar_width_px,
					p_along_x_px, p_along_y_px)

			TauBarConfig.BarMode.INDEPENDENT:
				var y_px := _layout.map_y_to_px(_pane_index, p_y_value, p_y_axis_id)
				return _check_rect_containment(
					p_center_px, y_px, base_px, p_bar_width_px,
					p_along_x_px, p_along_y_px)

			TauBarConfig.BarMode.STACKED:
				var bar_left := p_center_px - p_bar_width_px * 0.5
				var bar_right := p_center_px + p_bar_width_px * 0.5
				if p_along_x_px < bar_left or p_along_x_px > bar_right:
					return false

				# Walk the cumulative stack to find the segment for this series.
				var cumulative: float = 0.0
				for stack_idx in range(p_series_count):
					var stack_sid: int = _bar_series_ids[stack_idx]
					if p_category_index >= _dataset.get_series_sample_count(stack_sid):
						continue
					var stack_y := _dataset.get_series_y(stack_sid, p_category_index)
					if is_nan(stack_y) or is_inf(stack_y) or stack_y < 0.0:
						continue
					var y0 := cumulative
					cumulative += stack_y
					var y1 := cumulative

					if stack_sid == _bar_series_ids[p_series_local_idx]:
						var y0_px := _layout.map_y_to_px(_pane_index, y0, p_y_axis_id)
						var y1_px := _layout.map_y_to_px(_pane_index, y1, p_y_axis_id)
						var seg_top := min(y0_px, y1_px)
						var seg_bottom := max(y0_px, y1_px)
						return p_along_y_px >= seg_top and p_along_y_px <= seg_bottom

		return false
