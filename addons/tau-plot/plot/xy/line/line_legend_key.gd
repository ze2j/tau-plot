## Legend key picture for one series of a line overlay.
##
## The box is wider than tall. It carries a horizontal segment across its full
## width, with the series' fill band under it when the series fills. A series at
## width 0 shows the band alone, and a series that paints neither shows an empty
## box so its legend row still names it.
##
## The picture is the series' identity, not a preview of the pane. It shows the
## per-series color and ignores:
## - per-sample color and alpha from LineVisualAttributes and
##   LineVisualCallbacks
## - [member TauLineStyle.hovered_line_widths_px], so the key always shows the
##   normal state
## - the interpolation mode, unreadable at this size
## - the plot orientation, so the key stays horizontal on a transposed plot
##
## Axis inversion is followed, for the direction of a gradient fill only.
##
## Everything painted comes from the Spec, so the key resolves nothing on its
## own and draws the same picture wherever it sits.
class LineLegendKey extends Control:

	## Resolved appearance of one series, the whole input of the picture.
	##
	## [member fill_color] is the modulation color of the band: transparent when
	## the series does not fill, white when the fill is a texture, the flat fill
	## color otherwise. Its alpha alone decides whether a band is painted.
	##
	## [member gradient_reversed] is true when the gradient runs against its
	## default direction, axis inversion and a swapped custom range already
	## folded in.
	class Spec extends RefCounted:
		var stroke_color: Color = Color(1, 1, 1, 1)
		var stroke_width_px: float = 0.0
		var dash_px: int = 0

		var fill_color: Color = Color(0, 0, 0, 0)
		var fill_texture: Texture2D = null
		var texture_mode: TauLineFill.FillTextureMode = TauLineFill.FillTextureMode.STRETCH
		var stretch_span: TauLineFill.FillStretchSpan = TauLineFill.FillStretchSpan.LINE
		var gradient_reversed: bool = false

		var tile_scale: float = 1.0
		var tile_rotation_deg: float = 0.0
		var tile_offset_px: Vector2 = Vector2.ZERO

	# Height fraction the segment sits at when the series also fills, so the
	# band below it gets the larger share of the box.
	const _SEGMENT_Y_FRACTION_WITH_BAND: float = 1.0 / 3.0

	# Longest dash allowed, as a fraction of the box width. Two full on-off
	# cycles is the shortest pattern that still reads as dashed.
	const _MAX_DASH_WIDTH_FRACTION: float = 0.25

	var _spec: Spec = null


	func _init(p_spec: Spec) -> void:
		_spec = p_spec


	func _ready() -> void:
		# A TILE band samples UVs outside [0, 1]. The default clamp would fold
		# the whole tile grid into a single stretched copy.
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_RESIZED:
				queue_redraw()


	## Replaces the resolved appearance and repaints.
	func set_spec(p_spec: Spec) -> void:
		_spec = p_spec
		queue_redraw()


	####################################################################################################
	# Private
	####################################################################################################

	# The box size is only final once the legend has laid the key out, so every
	# coordinate is derived from `size` at draw time rather than at construction.
	func _draw() -> void:
		var strokes: bool = _spec.stroke_width_px > 0.0
		var fills: bool = _spec.fill_color.a > 0.0
		var segment_y: float = size.y * (_SEGMENT_Y_FRACTION_WITH_BAND if fills else 0.5)

		# A fill with no stroke owns the whole box, there is no segment to hang
		# the band under.
		if fills:
			_draw_band(segment_y if strokes else 0.0)
		if strokes:
			_draw_segment(segment_y, fills)


	# Draws the stroke across the full box width. The width is clamped so a
	# thick series neither spills out of the box nor swallows the band under it.
	# The clamp only ever shrinks, so an ordinary line is shown as configured.
	func _draw_segment(p_y: float, p_has_band: bool) -> void:
		var width: float = minf(_spec.stroke_width_px, size.y * (0.5 if p_has_band else 1.0))
		var from := Vector2(0.0, p_y)
		var to := Vector2(size.x, p_y)
		if _spec.dash_px <= 0:
			draw_line(from, to, _spec.stroke_color, width)
			return

		# A dash longer than the box renders solid and misnames the series, so
		# the pattern is squeezed to fit instead.
		var dash: float = minf(float(_spec.dash_px), size.x * _MAX_DASH_WIDTH_FRACTION)
		# The cycle starts at the segment origin, matching the draw path.
		draw_dashed_line(from, to, _spec.stroke_color, width, dash, false)


	# Draws the fill band from p_top down to the bottom edge of the box.
	func _draw_band(p_top: float) -> void:
		var rect := Rect2(0.0, p_top, size.x, size.y - p_top)
		if _spec.fill_texture == null:
			draw_rect(rect, _spec.fill_color)
			return

		# Clockwise from the top left, the order every UV builder here assumes.
		var corners := PackedVector2Array([
			rect.position,
			Vector2(rect.end.x, rect.position.y),
			rect.end,
			Vector2(rect.position.x, rect.end.y),
		])
		var uvs: PackedVector2Array
		if _spec.texture_mode == TauLineFill.FillTextureMode.TILE:
			uvs = _build_tile_uvs(corners)
		else:
			uvs = _build_stretch_uvs()
		draw_colored_polygon(corners, _spec.fill_color, uvs, _spec.fill_texture)


	# UVs for a STRETCH band. The spans read the same thin strip of the texture
	# as the draw path: the middle row for VALUE_X, which runs across the band,
	# the middle column for the three that run through it.
	func _build_stretch_uvs() -> PackedVector2Array:
		var half_texel: Vector2 = Vector2(0.5, 0.5) / _spec.fill_texture.get_size()
		if _spec.stretch_span == TauLineFill.FillStretchSpan.VALUE_X:
			var across := _stretch_uv_ends(half_texel.x)
			return PackedVector2Array([
				Vector2(across.x, 0.5),
				Vector2(across.y, 0.5),
				Vector2(across.y, 0.5),
				Vector2(across.x, 0.5),
			])

		var through := _stretch_uv_ends(half_texel.y)
		return PackedVector2Array([
			Vector2(0.5, through.x),
			Vector2(0.5, through.x),
			Vector2(0.5, through.y),
			Vector2(0.5, through.y),
		])


	# The two texture coordinates a STRETCH span spreads between, .x for the top
	# or left edge of the band and .y for the opposite one. Both are pulled in
	# by half a texel so sampling matches a clamped texture whatever the node's
	# texture_repeat, and swapped when the gradient runs against its default
	# direction.
	func _stretch_uv_ends(p_half_texel: float) -> Vector2:
		if _spec.gradient_reversed:
			return Vector2(1.0 - p_half_texel, p_half_texel)
		return Vector2(p_half_texel, 1.0 - p_half_texel)


	# UVs for a TILE band. Each corner is centered on the box, rotated into the
	# texture's frame, translated by the tile offset, then divided by the tile
	# size, the same construction the draw path runs around the pane center.
	# Anchoring the grid to the box makes a scrolling pattern move at the right
	# speed without being in phase with the chart.
	func _build_tile_uvs(p_corners: PackedVector2Array) -> PackedVector2Array:
		var center: Vector2 = size * 0.5
		# Rotating the corner into the texture's frame is the inverse of
		# rotating the tile grid on screen, hence the negated user angle.
		var theta: float = deg_to_rad(-_spec.tile_rotation_deg)
		var tile_size: Vector2 = _spec.fill_texture.get_size() * _spec.tile_scale
		var inv_tile_size := Vector2(
			1.0 / tile_size.x if tile_size.x > 0.0 else 0.0,
			1.0 / tile_size.y if tile_size.y > 0.0 else 0.0)

		var uvs := PackedVector2Array()
		uvs.resize(p_corners.size())
		for i in range(p_corners.size()):
			var rotated: Vector2 = (p_corners[i] - center).rotated(theta)
			uvs[i] = (rotated + _spec.tile_offset_px) * inv_tile_size
		return uvs
