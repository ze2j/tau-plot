@abstract class_name TauPaneOverlayConfig extends Resource

const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const VisualCallbacks = preload("res://addons/tau-plot/plot/xy/visual_callbacks.gd").VisualCallbacks

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`
#          and, if applicable, in `has_layout_affecting_change()`.
################################################################################################

## Identifies the overlay kind (BAR, SCATTER, etc.).
## Concrete subclasses set the appropriate default. For lookup purposes only.
@export var overlay_type: PaneOverlayType = PaneOverlayType.SCATTER

enum ZOrder
{
	SERIES_ORDER,          # Series drawn in dataset order (0..N-1), last on top
	REVERSE_SERIES_ORDER   # Series drawn in reverse order, first on top
}
@export var z_order: ZOrder = ZOrder.REVERSE_SERIES_ORDER

## Per-overlay visual callbacks (e.g. [BarVisualCallbacks] or [ScatterVisualCallbacks]).
## Not exported because [Callable] is not serializable.
var visual_callbacks: VisualCallbacks = null

## Whether this overlay participates in hover hit testing. When false,
## samples from this overlay are invisible to the hover system.
## Signals, tooltip, and highlight skip this overlay entirely.
@export var hoverable: bool = true


####################################################################################################
# Helpers
####################################################################################################

func is_equal_to(p_other: TauPaneOverlayConfig) -> bool:
	if p_other == null:
		return false

	if z_order != p_other.z_order:
		return false

	if hoverable != p_other.hoverable:
		return false

	return true


# Returns true if the change between this and p_other affects layout/domain
# Returns false if the change only affects visual appearance
func has_layout_affecting_change(p_other: TauPaneOverlayConfig) -> bool:
	return p_other == null
