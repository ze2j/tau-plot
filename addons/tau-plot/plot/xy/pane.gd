const PaneRenderer := preload("res://addons/tau-plot/plot/xy/pane_renderer.gd").PaneRenderer
const OverlayRenderer := preload("res://addons/tau-plot/plot/xy/overlay_renderer.gd").OverlayRenderer
const PaneOverlayType := preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType


## A pane is one slot of the pane stack.
class Pane extends RefCounted:

	## The parent container of the renderers. It's a child of the pane stack.
	var container: MarginContainer = null

	## The pane renderer in charge of drawing the background, grid lines, axes,
	## ticks and tick labels.
	var renderer: PaneRenderer = null

	## In paint order, the one painted first coming first.
	var overlays: Array[OverlayRenderer] = []


	## Returns the overlay of the given type, null when the pane holds none.
	func find_overlay(p_overlay_type: PaneOverlayType) -> OverlayRenderer:
		for overlay: OverlayRenderer in overlays:
			if overlay.get_config().overlay_type == p_overlay_type:
				return overlay
		return null
