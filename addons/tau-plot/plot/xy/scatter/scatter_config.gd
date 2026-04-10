## Scatter-overlay specific rendering config.
class_name TauScatterConfig extends TauPaneOverlayConfig

const ScatterVisualCallbacks = preload("res://addons/tau-plot/plot/xy/scatter/scatter_visual_callbacks.gd").ScatterVisualCallbacks

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`
#          and, if applicable, in `has_layout_affecting_change()`.
################################################################################################

## Theme-driven visual and sizing parameters for scatter markers.
## Never null. Modify properties directly: scatter_config.style.marker_size_px = 8.0.
## Properties set this way are automatically guarded from theme overwriting.
@export var style: TauScatterStyle = TauScatterStyle.new()

enum MarkerSizePolicy
{
	AUTO,           ## Resolves to THEME
	THEME,          ## Uses theme constants if provided, otherwise TauScatterStyle defaults
	DATA_UNITS      ## Size expressed in X data units
}
@export var marker_size_policy: MarkerSizePolicy = MarkerSizePolicy.AUTO
@export var marker_size_data_units: float = 1.0   # Used when policy is DATA_UNITS

## Maximum pixel distance from the cursor to a scatter marker center
## for the marker to be considered a hit.
##
## In NEAREST mode, this is a 2D Euclidean distance gate. Markers farther
## than this value from the cursor are excluded entirely.
##
## In X_ALIGNED mode with a continuous x axis, this is an x-axis-only pixel
## gate. Markers whose x screen position differs from the target x by more
## than this value are excluded. The same threshold sets [member SampleHit.contains_pointer]
## on included hits.
##
## In X_ALIGNED mode with a categorical x axis, this property does not gate
## which markers are returned. All markers at the matching category are
## included. The distance is still compared against this threshold to set
## [member SampleHit.contains_pointer], which controls whether the marker
## receives the visual hover highlight.
@export var hover_max_distance_px: int = 20


####################################################################################################
# Typed visual_callbacks accessor
####################################################################################################

## Typed accessor for scatter-specific visual callbacks.
## Shadows the base [member TauPaneOverlayConfig.visual_callbacks] with the concrete type.
var scatter_visual_callbacks: ScatterVisualCallbacks:
	get:
		return visual_callbacks as ScatterVisualCallbacks
	set(value):
		visual_callbacks = value


####################################################################################################
# Helpers
####################################################################################################

func _init() -> void:
	overlay_type = PaneOverlayType.SCATTER


func get_resolved_marker_size_policy() -> MarkerSizePolicy:
	if marker_size_policy != MarkerSizePolicy.AUTO:
		return marker_size_policy
	return MarkerSizePolicy.THEME


func is_equal_to(p_other: TauPaneOverlayConfig) -> bool:
	var other := p_other as TauScatterConfig
	if other == null:
		return false

	if not super.is_equal_to(other):
		return false

	if marker_size_policy != other.marker_size_policy:
		return false
	if marker_size_data_units != other.marker_size_data_units:
		return false
	if hover_max_distance_px != other.hover_max_distance_px:
		return false

	return true


# Returns true if the change between this and p_other affects layout/domain.
# Returns false if the change only affects visual appearance.
#
# No scatter config property affects the domain or layout. Marker size
# controls how markers are drawn within a fixed domain but does not feed
# into domain or tick computation.
func has_layout_affecting_change(p_other: TauPaneOverlayConfig) -> bool:
	var other := p_other as TauScatterConfig
	if other == null:
		return false

	if not super.has_layout_affecting_change(other):
		return false

	return false
