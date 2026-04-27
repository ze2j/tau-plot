## Contains theme-driven visual parameters for line overlays.
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
## different value (e.g. 2.001 instead of 2.0).
class_name TauLineStyle extends Resource

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()`.
################################################################################################

const DEFAULT_LINE_WIDTH_PX: float = 2.0
@export var line_width_px: float = DEFAULT_LINE_WIDTH_PX

## Dash length in pixels. A value of 0 produces a solid line. Any positive
## value switches the line to dashed rendering with alternating on-off
## segments of that pixel length.
const DEFAULT_LINE_DASH_PX: int = 0
@export var dash_px: int = DEFAULT_LINE_DASH_PX


####################################################################################################
# Cascade: theme loading (layer 2)
####################################################################################################

## Loads properties from the Godot theme attached to [param p_control].
##
## For each property, the non-indexed theme key is fetched first (shared base
## for all panes), then the indexed key for [param p_pane_index] overwrites it
## if present.
##
## This method writes every property unconditionally because it is called on
## the resolved instance, not on the user-provided resource.
func load_from_theme(p_control: Control, p_pane_index: int) -> void:
	if p_control == null:
		push_error("TauLineStyle.load_from_theme(): control is null")
		return

	if p_control.has_theme_constant(&"line_width_px"):
		line_width_px = max(float(p_control.get_theme_constant(&"line_width_px")), 0.0)
	var indexed_width_key := StringName("line_width_px_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_width_key):
		line_width_px = max(float(p_control.get_theme_constant(indexed_width_key)), 0.0)

	if p_control.has_theme_constant(&"line_dash_px"):
		dash_px = max(int(p_control.get_theme_constant(&"line_dash_px")), 0)
	var indexed_dash_key := StringName("line_dash_px_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_dash_key):
		dash_px = max(int(p_control.get_theme_constant(indexed_dash_key)), 0)


####################################################################################################
# Cascade: user overrides (layer 3)
####################################################################################################

## Applies overridden properties from [param p_user_style] onto this resolved
## instance. A property is considered overridden when its value on the user
## resource differs from the matching DEFAULT_* constant.
func apply_overrides_from(p_user_style: TauLineStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.line_width_px != DEFAULT_LINE_WIDTH_PX:
		line_width_px = p_user_style.line_width_px

	if p_user_style.dash_px != DEFAULT_LINE_DASH_PX:
		dash_px = p_user_style.dash_px


####################################################################################################
# Full cascade resolution
####################################################################################################

## Produces a fully resolved TauLineStyle by applying all three cascade layers:
##   1. Start from defaults (a fresh TauLineStyle instance).
##   2. Load theme values (non-indexed, then indexed for this pane).
##   3. Apply user overrides from [param p_user_style] (may be null).
##
## The returned instance is a new TauLineStyle owned by the caller. It is
## separate from [param p_user_style] which is never mutated.
static func resolve(
	p_control: Control,
	p_pane_index: int,
	p_user_style: TauLineStyle
) -> TauLineStyle:
	# Layer 1: defaults.
	var resolved := TauLineStyle.new()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control, p_pane_index)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	return resolved


####################################################################################################
# Change detection
####################################################################################################

func is_equal_to(p_other: TauLineStyle) -> bool:
	if p_other == null:
		return false
	if line_width_px != p_other.line_width_px:
		return false
	if dash_px != p_other.dash_px:
		return false
	return true


# All TauLineStyle properties are visual-only. They control how lines are
# drawn within a fixed domain but do not affect domain, ticks, or pane rect.
func has_layout_affecting_change(p_other: TauLineStyle) -> bool:
	return false
