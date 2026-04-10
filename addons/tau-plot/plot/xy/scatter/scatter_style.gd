## Contains theme-driven visual and sizing parameters for scatter markers.
##
## Properties set on this resource take the highest priority, always winning
## over the theme and the built-in defaults.
##
## Properties left untouched fall back to the Godot theme. If the theme does
## not define them either, the built-in defaults apply.
##
## [b]Limitation:[/b] because "untouched" means "still equal to the built-in
## default", setting a property to exactly its default value has no visible
## effect. To force the default value to win over a theme, use an imperceptibly
## different value (e.g. 12.001 instead of 12.0).
class_name TauScatterStyle extends Resource

enum MarkerShape
{
	CIRCLE = 0,
	SQUARE = 1,
	TRIANGLE_UP = 2,
	TRIANGLE_DOWN = 3,
	DIAMOND = 4,
	CROSS = 5,
	PLUS = 6,
	COUNT = 7,  # Number of available shapes
	NONE = 8    # Marker is invisible (useful for hiding specific markers without removing data)
}

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()`.
################################################################################################

const DEFAULT_MARKER_SIZE_PX: float = 12.0
@export var marker_size_px: float = DEFAULT_MARKER_SIZE_PX

const DEFAULT_OUTLINE_WIDTH_PX: float = 1.0
@export var outline_width_px: float = DEFAULT_OUTLINE_WIDTH_PX

const DEFAULT_OUTLINE_COLOR: Color = Color(0, 0, 0, 1)
@export var outline_color: Color = DEFAULT_OUTLINE_COLOR

const DEFAULT_HOVERED_MARKER_SIZE_PX: float = 16.0
## Marker size when hovered (px).
@export var hovered_marker_size_px: float = DEFAULT_HOVERED_MARKER_SIZE_PX

const DEFAULT_HOVERED_OUTLINE_WIDTH_PX: float = 2.0
## Outline width when hovered (px).
@export var hovered_outline_width_px: float = DEFAULT_HOVERED_OUTLINE_WIDTH_PX

const DEFAULT_HOVERED_OUTLINE_COLOR: Color = Color(1, 1, 1, 1)
## Outline color when hovered.
@export var hovered_outline_color: Color = DEFAULT_HOVERED_OUTLINE_COLOR

const DEFAULT_MARKER_SHAPES: Array[MarkerShape] = [
	MarkerShape.CIRCLE,
	MarkerShape.SQUARE,
	MarkerShape.TRIANGLE_UP,
	MarkerShape.TRIANGLE_DOWN,
	MarkerShape.DIAMOND,
	MarkerShape.CROSS,
	MarkerShape.PLUS,
]
@export var marker_shapes: Array[MarkerShape] = [
	MarkerShape.CIRCLE,
	MarkerShape.SQUARE,
	MarkerShape.TRIANGLE_UP,
	MarkerShape.TRIANGLE_DOWN,
	MarkerShape.DIAMOND,
	MarkerShape.CROSS,
	MarkerShape.PLUS,
]

####################################################################################################
# Helpers
####################################################################################################

func get_series_shape(p_series_index: int) -> MarkerShape:
	if marker_shapes.is_empty():
		return MarkerShape.CIRCLE
	return marker_shapes[p_series_index % marker_shapes.size()]


####################################################################################################
# Cascade: theme loading (layer 2)
####################################################################################################

## Loads properties from the Godot theme attached to [param p_control].
##
## For scalar properties, the non-indexed theme key is fetched first (shared base
## for all panes), then the indexed key for [param p_pane_index] overwrites it
## if present.
##
## For marker shapes, the same convention applies:
##   1. scatter_marker_shape_N sets the shape for series N across all panes.
##   2. scatter_marker_shape_N_P overrides series N in pane P only.
##
## This method writes every property unconditionally because it is called on
## the resolved instance, not on the user-provided resource.
func load_from_theme(p_control: Control, p_pane_index: int) -> void:
	if p_control == null:
		push_error("TauScatterStyle.load_from_theme(): control is null")
		return

	# marker_size_px
	if p_control.has_theme_constant(&"scatter_marker_size_px"):
		marker_size_px = max(float(p_control.get_theme_constant(&"scatter_marker_size_px")), 1.0)
	var indexed_size_key := StringName("scatter_marker_size_px_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_size_key):
		marker_size_px = max(float(p_control.get_theme_constant(indexed_size_key)), 1.0)

	# outline_width_px
	if p_control.has_theme_constant(&"scatter_outline_width_px"):
		outline_width_px = max(float(p_control.get_theme_constant(&"scatter_outline_width_px")), 0.0)
	var indexed_outline_key := StringName("scatter_outline_width_px_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_outline_key):
		outline_width_px = max(float(p_control.get_theme_constant(indexed_outline_key)), 0.0)

	# outline_color
	if p_control.has_theme_color(&"scatter_outline_color"):
		outline_color = p_control.get_theme_color(&"scatter_outline_color")
	var indexed_color_key := StringName("scatter_outline_color_%d" % p_pane_index)
	if p_control.has_theme_color(indexed_color_key):
		outline_color = p_control.get_theme_color(indexed_color_key)

	# hovered_marker_size_px
	if p_control.has_theme_constant(&"scatter_hovered_marker_size_px"):
		hovered_marker_size_px = max(float(p_control.get_theme_constant(&"scatter_hovered_marker_size_px")), 1.0)
	var indexed_hovered_size_key := StringName("scatter_hovered_marker_size_px_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_hovered_size_key):
		hovered_marker_size_px = max(float(p_control.get_theme_constant(indexed_hovered_size_key)), 1.0)

	# hovered_outline_width_px
	if p_control.has_theme_constant(&"scatter_hovered_outline_width_px"):
		hovered_outline_width_px = max(float(p_control.get_theme_constant(&"scatter_hovered_outline_width_px")), 0.0)
	var indexed_hovered_ow_key := StringName("scatter_hovered_outline_width_px_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_hovered_ow_key):
		hovered_outline_width_px = max(float(p_control.get_theme_constant(indexed_hovered_ow_key)), 0.0)

	# hovered_outline_color
	if p_control.has_theme_color(&"scatter_hovered_outline_color"):
		hovered_outline_color = p_control.get_theme_color(&"scatter_hovered_outline_color")
	var indexed_hovered_color_key := StringName("scatter_hovered_outline_color_%d" % p_pane_index)
	if p_control.has_theme_color(indexed_hovered_color_key):
		hovered_outline_color = p_control.get_theme_color(indexed_hovered_color_key)

	# marker_shapes: two-level indexed lookup.
	# Level 1 (global): scatter_marker_shape_N
	var global_shapes: Array[MarkerShape] = []
	var shape_index := 0
	while true:
		var key := "scatter_marker_shape_%d" % shape_index
		if not p_control.has_theme_constant(key):
			break
		global_shapes.append(p_control.get_theme_constant(key) as MarkerShape)
		shape_index += 1

	if not global_shapes.is_empty():
		marker_shapes = global_shapes

	# Level 2 (per-pane): scatter_marker_shape_N_P overrides series N in pane P.
	var pane_shape_index := 0
	while true:
		var key := "scatter_marker_shape_%d_%d" % [pane_shape_index, p_pane_index]
		if not p_control.has_theme_constant(key):
			break
		# Grow the array if the per-pane theme defines more shapes than the
		# global theme (or the default).
		if pane_shape_index >= marker_shapes.size():
			marker_shapes.resize(pane_shape_index + 1)
		marker_shapes[pane_shape_index] = p_control.get_theme_constant(key) as MarkerShape
		pane_shape_index += 1


####################################################################################################
# Cascade: user overrides (layer 3)
####################################################################################################

## Applies overridden properties from [param p_user_style] onto this resolved
## instance. A property is considered overridden when its value on the user
## resource differs from the matching DEFAULT_* constant.
func apply_overrides_from(p_user_style: TauScatterStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.marker_size_px != DEFAULT_MARKER_SIZE_PX:
		marker_size_px = p_user_style.marker_size_px
	if p_user_style.outline_width_px != DEFAULT_OUTLINE_WIDTH_PX:
		outline_width_px = p_user_style.outline_width_px
	if p_user_style.outline_color != DEFAULT_OUTLINE_COLOR:
		outline_color = p_user_style.outline_color
	if p_user_style.hovered_marker_size_px != DEFAULT_HOVERED_MARKER_SIZE_PX:
		hovered_marker_size_px = p_user_style.hovered_marker_size_px
	if p_user_style.hovered_outline_width_px != DEFAULT_HOVERED_OUTLINE_WIDTH_PX:
		hovered_outline_width_px = p_user_style.hovered_outline_width_px
	if p_user_style.hovered_outline_color != DEFAULT_HOVERED_OUTLINE_COLOR:
		hovered_outline_color = p_user_style.hovered_outline_color

	# marker_shapes: element-wise comparison against the default array.
	if _is_marker_shapes_overridden(p_user_style.marker_shapes):
		marker_shapes = p_user_style.marker_shapes.duplicate()


####################################################################################################
# Full cascade resolution
####################################################################################################

## Produces a fully resolved TauScatterStyle by applying all three cascade layers:
##   1. Start from defaults (a fresh TauScatterStyle instance).
##   2. Load theme values (non-indexed, then indexed for this pane).
##   3. Apply user overrides from [param p_user_style] (may be null).
##
## The returned instance is a new TauScatterStyle owned by the caller. It is separate
## from [param p_user_style] which is never mutated.
static func resolve(
	p_control: Control,
	p_pane_index: int,
	p_user_style: TauScatterStyle
) -> TauScatterStyle:
	# Layer 1: defaults.
	var resolved := TauScatterStyle.new()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control, p_pane_index)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	return resolved


####################################################################################################
# Change detection
####################################################################################################

func is_equal_to(p_other: TauScatterStyle) -> bool:
	if p_other == null:
		return false
	if marker_size_px != p_other.marker_size_px:
		return false
	if outline_width_px != p_other.outline_width_px:
		return false
	if outline_color != p_other.outline_color:
		return false
	if hovered_marker_size_px != p_other.hovered_marker_size_px:
		return false
	if hovered_outline_width_px != p_other.hovered_outline_width_px:
		return false
	if hovered_outline_color != p_other.hovered_outline_color:
		return false
	if marker_shapes.size() != p_other.marker_shapes.size():
		return false
	for i in range(marker_shapes.size()):
		if marker_shapes[i] != p_other.marker_shapes[i]:
			return false
	return true


# All TauScatterStyle properties are visual-only. They control how markers are
# drawn within a fixed domain but do not affect domain, ticks, or pane rect.
func has_layout_affecting_change(p_other: TauScatterStyle) -> bool:
	return false


####################################################################################################
# Private
####################################################################################################

## Returns true if [param p_shapes] differs from DEFAULT_MARKER_SHAPES using
## a size + element loop (safest approach for typed arrays in GDScript).
static func _is_marker_shapes_overridden(p_shapes: Array[MarkerShape]) -> bool:
	if p_shapes.size() != DEFAULT_MARKER_SHAPES.size():
		return true
	for i in range(p_shapes.size()):
		if p_shapes[i] != DEFAULT_MARKER_SHAPES[i]:
			return true
	return false
