## Lightweight overlay Control that draws crosshair guide lines at the
## hovered data position within a single pane.
##
## One instance per pane, created by HoverController and added as the last
## child of each pane container so it draws on top of all data renderers.
## mouse_filter = MOUSE_FILTER_IGNORE so input passes through to PaneRenderer.
##
## The HoverController sets position properties and calls queue_redraw().
## This never triggers a redraw on any data renderer.

const CrosshairMode = preload("res://addons/tau-plot/plot/xy/hover/hover_config.gd").CrosshairMode


class CrosshairOverlay extends Control:
	## Whether the crosshair is currently shown. Set by HoverController.
	var _visible: bool = false

	## Along-x pixel in pane-local coords. Snapped to the hovered data point.
	var _x_px: float = 0.0

	## Along-y pixel in pane-local coords. Follows the raw mouse position.
	var _y_px: float = 0.0

	## Active crosshair mode for this overlay. May differ from the configured
	## mode on non-active panes (set to X_ONLY when configured BOTH, so that
	## only the x line appears on non-active panes).
	var _mode: int = CrosshairMode.NONE

	## Resolved crosshair style from the three-layer cascade.
	var _style: TauCrosshairStyle = null

	## True when the x axis runs along screen-X. Determines line orientation.
	var _x_is_horizontal: bool = true

	## The data-area rectangle for this pane in pane-local coordinates.
	## Updated by HoverController before each show call.
	var _pane_rect: Rect2 = Rect2()


	func _init() -> void:
		theme_type_variation = &"TauCrosshair"
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	## Updates the crosshair position, mode, style, and geometry, then
	## triggers a redraw. Called by HoverController on hover motion.
	func show_crosshair(
			p_x_px: float,
			p_y_px: float,
			p_mode: int,
			p_style: TauCrosshairStyle,
			p_x_is_horizontal: bool,
			p_pane_rect: Rect2) -> void:
		_x_px = p_x_px
		_y_px = p_y_px
		_mode = p_mode
		_style = p_style
		_x_is_horizontal = p_x_is_horizontal
		_pane_rect = p_pane_rect
		_visible = true
		queue_redraw()


	## Hides the crosshair and triggers a redraw to clear it.
	func hide_crosshair() -> void:
		if not _visible:
			return
		_visible = false
		queue_redraw()


	func _draw() -> void:
		if not _visible:
			return
		if _mode == CrosshairMode.NONE:
			return

		var color: Color = _style.color
		var thickness: float = float(_style.thickness_px)
		var dash: int = _style.dash_px

		var x_left: float = _pane_rect.position.x
		var x_right: float = _pane_rect.position.x + _pane_rect.size.x
		var y_top: float = _pane_rect.position.y
		var y_bottom: float = _pane_rect.position.y + _pane_rect.size.y

		# X line: perpendicular to the x axis at _x_px, spanning the full
		# pane extent along the y direction.
		if _mode == CrosshairMode.X_ONLY or _mode == CrosshairMode.BOTH:
			var from: Vector2
			var to: Vector2
			if _x_is_horizontal:
				# X axis is horizontal, so the x line is vertical.
				from = Vector2(_x_px, y_top)
				to = Vector2(_x_px, y_bottom)
			else:
				# X axis is vertical, so the x line is horizontal.
				from = Vector2(x_left, _x_px)
				to = Vector2(x_right, _x_px)
			_draw_crosshair_line(from, to, color, thickness, dash)

		# Y line: perpendicular to the y axis at _y_px, spanning the full
		# pane extent along the x direction.
		if _mode == CrosshairMode.Y_ONLY or _mode == CrosshairMode.BOTH:
			var from: Vector2
			var to: Vector2
			if _x_is_horizontal:
				# Y axis is vertical, so the y line is horizontal.
				from = Vector2(x_left, _y_px)
				to = Vector2(x_right, _y_px)
			else:
				# Y axis is horizontal, so the y line is vertical.
				from = Vector2(_y_px, y_top)
				to = Vector2(_y_px, y_bottom)
			_draw_crosshair_line(from, to, color, thickness, dash)


	func _draw_crosshair_line(
			p_from: Vector2,
			p_to: Vector2,
			p_color: Color,
			p_thickness: float,
			p_dash: int) -> void:
		if p_dash > 0:
			draw_dashed_line(p_from, p_to, p_color, p_thickness, float(p_dash))
		else:
			draw_line(p_from, p_to, p_color, p_thickness)
