const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const XYLayout := preload("res://addons/tau-plot/plot/xy/xy_layout.gd").XYLayout
const SampleHit = preload("res://addons/tau-plot/plot/xy/hover/sample_hit.gd").SampleHit
const HoverMode = preload("res://addons/tau-plot/plot/xy/hover/hover_config.gd").HoverMode
const OverlayHitTester = preload("res://addons/tau-plot/plot/xy/hover/overlay_hit_tester.gd").OverlayHitTester
const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const BarRenderer := preload("res://addons/tau-plot/plot/xy/bar/bar_renderer.gd").BarRenderer
const BarHitRecord := preload("res://addons/tau-plot/plot/xy/bar/bar_hit_record.gd").BarHitRecord


## Bar overlay hit tester. Reads the renderer's BarHitRecord cache so the
## hit geometry cannot drift from the painted geometry.
class BarHitTester extends OverlayHitTester:
	var _pane_index: int
	var _bar_config: TauBarConfig
	var _bar_renderer: BarRenderer
	var _dataset: Dataset
	var _layout: XYLayout


	func _init(
			p_pane_index: int,
			p_bar_config: TauBarConfig,
			p_bar_renderer: BarRenderer,
			p_dataset: Dataset,
			p_layout: XYLayout) -> void:
		_pane_index = p_pane_index
		_bar_config = p_bar_config
		_bar_renderer = p_bar_renderer
		_dataset = p_dataset
		_layout = p_layout


	func is_hoverable() -> bool:
		return _bar_config.hoverable


	func get_preferred_hover_mode() -> int:
		return HoverMode.X_ALIGNED


	####################################################################
	# NEAREST mode
	####################################################################

	## Returns the first cached record whose rect contains the pointer.
	## Cache order is paint order (z_order applied), so an upper segment
	## wins over the segment beneath it when ranges happen to overlap.
	func hit_test_nearest(p_local_pos: Vector2) -> SampleHit:
		for record: BarHitRecord in _bar_renderer.get_hit_records():
			if record.rect.has_point(p_local_pos):
				return _build_hit(record, p_local_pos, true)
		return null


	####################################################################
	# X_ALIGNED mode
	####################################################################

	func collect_hits_at_category(p_category_index: int, _p_x_value: String, p_local_pos: Vector2) -> Array[SampleHit]:
		var hits: Array[SampleHit] = []
		for record: BarHitRecord in _bar_renderer.get_hit_records():
			if record.sample_index != p_category_index:
				continue
			hits.append(_build_hit(record, p_local_pos, record.rect.has_point(p_local_pos)))
		return hits


	func collect_hits_at_continuous_x(p_x_value: float, p_local_pos: Vector2) -> Array[SampleHit]:
		var hits: Array[SampleHit] = []
		for record: BarHitRecord in _bar_renderer.get_hit_records():
			if not OverlayHitTester.x_values_match(record.x_value, p_x_value):
				continue
			hits.append(_build_hit(record, p_local_pos, record.rect.has_point(p_local_pos)))
		return hits


	## Empty for categorical x: this path is for continuous x only.
	func find_nearest_x(p_along_x_px: float) -> Dictionary:
		if _layout.domain.config.x_axis.type == TauAxisConfig.Type.CATEGORICAL:
			return {}

		# TODO: drop x_is_horizontal once XYLayout exposes a logical-x projector.
		var x_is_horizontal: bool = _layout._x_is_horizontal
		var best_px := INF
		var best_val: float = 0.0
		var found := false

		for record: BarHitRecord in _bar_renderer.get_hit_records():
			var anchor_along_x: float = record.anchor.x if x_is_horizontal else record.anchor.y
			if absf(p_along_x_px - anchor_along_x) < absf(p_along_x_px - best_px):
				best_px = anchor_along_x
				best_val = record.x_value
				found = true

		if not found:
			return {}
		return { "x_px": best_px, "x_value": best_val }


	####################################################################
	# Private
	####################################################################

	func _build_hit(p_record: BarHitRecord, p_local_pos: Vector2, p_contains: bool) -> SampleHit:
		var hit := SampleHit.new()
		hit.series_id = p_record.series_id
		hit.series_name = _dataset.get_series_name(p_record.series_id)
		hit.sample_index = p_record.sample_index
		hit.x_value = p_record.x_value
		hit.y_value = p_record.y_value
		hit.screen_position = p_record.anchor
		hit.pane_index = _pane_index
		hit.overlay_type = PaneOverlayType.BAR
		hit.contains_pointer = p_contains

		var dx := p_local_pos.x - p_record.anchor.x
		var dy := p_local_pos.y - p_record.anchor.y
		hit.distance_px = sqrt(dx * dx + dy * dy)
		return hit
