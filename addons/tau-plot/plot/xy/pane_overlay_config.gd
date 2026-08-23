## Base class of the overlay configs.
##
## A pane holds at most one overlay of each kind. The concrete subclass decides
## how the samples are painted, and carries the properties that only that kind
## of drawing has.
##
## [b]Varying an appearance per series or per sample[/b]
##
## Some appearance properties vary per series. They live on the style resource
## of the overlay as cycles, arrays holding one entry per series. See
## [TauStyle]. For example, line width, marker shape, and series color are
## cycles.
##
## Varying an appearance per sample takes one of two routes:
##
## - [b]Visual attributes[/b] are buffers handed over with the data, holding
##   one entry per sample and read by sample index. See
##   [member TauXYSeriesBinding.visual_attributes]. A buffer shorter than the
##   series covers its first samples only.
## - [b]Visual callbacks[/b] are functions called once per sample while the
##   pane is drawn, returning the value for that sample. See
##   [member visual_callbacks]. Nothing is stored, so a callback also covers
##   an appearance that has to be recomputed on every frame.
##
## Where an appearance is reachable by more than one of the three, the most
## specific one wins: an attribute buffer entry first, then a callback, then
## the cycle. An entry left unset in a buffer, and a callback that declines to
## answer, both fall through to the next one.
##
@abstract class_name TauPaneOverlayConfig extends Resource

const PaneOverlayType := preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const VisualCallbacks := preload("res://addons/tau-plot/plot/xy/visual_callbacks.gd").VisualCallbacks

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`
#          and, if applicable, in `has_layout_affecting_change()`.
################################################################################################

## Identifies the overlay kind (BAR, SCATTER, etc.).
## Concrete subclasses set the appropriate default. For reflection purposes only.
@export var overlay_type: PaneOverlayType = PaneOverlayType.SCATTER

## Order the series of the overlay are drawn in, which decides what covers
## what where they overlap.
enum ZOrder
{
	## Draw in dataset order, so the last series of the overlay ends up on top.
	SERIES_ORDER,

	## Draw in reverse dataset order, so the first series of the overlay ends up on top.
	REVERSE_SERIES_ORDER
}

## Order the series of the overlay are drawn in. See [enum ZOrder]. Only
## matters where series overlap.
@export var z_order: ZOrder = ZOrder.REVERSE_SERIES_ORDER

## Per-overlay visual callbacks (e.g. [BarVisualCallbacks] or [ScatterVisualCallbacks]).
## Not exported because [Callable] is not serializable.
var visual_callbacks: VisualCallbacks = null

## Whether this overlay participates in hover hit testing. When false,
## samples from this overlay are invisible to the hover system.
## Signals, tooltip, and highlight skip this overlay entirely.
@export var hoverable: bool = true


#region Internal, not public API, may change without notice.

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
#
# No base property affects layout, so the only case left is a missing previous
# config, where nothing can be proven unchanged and the conservative answer is
# a full recompute. Subclasses chain this as a disjunction: any part reporting
# a layout-affecting change wins.
func has_layout_affecting_change(p_other: TauPaneOverlayConfig) -> bool:
	return p_other == null

#endregion
