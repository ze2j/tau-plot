## Visual style for a single pane.
##
## Properties set on this resource take the highest priority, always winning
## over the theme and the built-in defaults.
##
## Properties left untouched fall back to the Godot theme. If the theme does
## not define them either, the built-in defaults apply.
##
## Multiple panes can share the same TauPaneStyle. Every pane that references it
## will pick up the changes.
##
## [b]Limitation:[/b] because "untouched" means "still equal to the built-in
## default", setting a property to exactly its default value has no visible
## effect. To force the default value to win over a theme, use an imperceptibly
## different value (e.g. alpha 0.1501 instead of 0.15).
class_name TauPaneStyle extends Resource

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()`.
################################################################################################


####################################################################################################
# X axis major grid lines
####################################################################################################

const DEFAULT_X_MAJOR_GRIDLINE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.15)
@export var x_major_grid_line_color: Color = DEFAULT_X_MAJOR_GRIDLINE_COLOR

const DEFAULT_X_MAJOR_GRIDLINE_THICKNESS_PX: int = 1
@export var x_major_grid_line_thickness_px: int = DEFAULT_X_MAJOR_GRIDLINE_THICKNESS_PX

const DEFAULT_X_MAJOR_GRIDLINE_DASH_PX: int = 0
@export var x_major_grid_line_dash_px: int = DEFAULT_X_MAJOR_GRIDLINE_DASH_PX


####################################################################################################
# X axis minor grid lines
####################################################################################################

const DEFAULT_X_MINOR_GRIDLINE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.08)
@export var x_minor_grid_line_color: Color = DEFAULT_X_MINOR_GRIDLINE_COLOR

const DEFAULT_X_MINOR_GRIDLINE_THICKNESS_PX: int = 1
@export var x_minor_grid_line_thickness_px: int = DEFAULT_X_MINOR_GRIDLINE_THICKNESS_PX

const DEFAULT_X_MINOR_GRIDLINE_DASH_PX: int = 0
@export var x_minor_grid_line_dash_px: int = DEFAULT_X_MINOR_GRIDLINE_DASH_PX


####################################################################################################
# Y axis major grid lines
####################################################################################################

const DEFAULT_Y_MAJOR_GRIDLINE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.15)
@export var y_major_grid_line_color: Color = DEFAULT_Y_MAJOR_GRIDLINE_COLOR

const DEFAULT_Y_MAJOR_GRIDLINE_THICKNESS_PX: int = 1
@export var y_major_grid_line_thickness_px: int = DEFAULT_Y_MAJOR_GRIDLINE_THICKNESS_PX

const DEFAULT_Y_MAJOR_GRIDLINE_DASH_PX: int = 0
@export var y_major_grid_line_dash_px: int = DEFAULT_Y_MAJOR_GRIDLINE_DASH_PX


####################################################################################################
# Y axis minor grid lines
####################################################################################################

const DEFAULT_Y_MINOR_GRIDLINE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.08)
@export var y_minor_grid_line_color: Color = DEFAULT_Y_MINOR_GRIDLINE_COLOR

const DEFAULT_Y_MINOR_GRIDLINE_THICKNESS_PX: int = 1
@export var y_minor_grid_line_thickness_px: int = DEFAULT_Y_MINOR_GRIDLINE_THICKNESS_PX

const DEFAULT_Y_MINOR_GRIDLINE_DASH_PX: int = 0
@export var y_minor_grid_line_dash_px: int = DEFAULT_Y_MINOR_GRIDLINE_DASH_PX


####################################################################################################
# Cascade: theme loading (layer 2)
####################################################################################################

## Loads properties from the Godot theme attached to [param p_control].
##
## For each property, the non-indexed theme constant is fetched first (shared base
## for all panes), then the indexed constant for [param p_pane_index] overwrites it
## if present. This method writes every property unconditionally because it is
## called on the resolved instance, not on the user-provided resource.
func load_from_theme(p_control: Control, p_pane_index: int) -> void:
	if p_control == null:
		push_error("TauPaneStyle.load_from_theme(): control is null")
		return

	# X major
	_load_color_from_theme(p_control, &"pane_x_major_grid_line_color", &"x_major_grid_line_color", p_pane_index)
	_load_constant_from_theme(p_control, &"pane_x_major_grid_line_thickness", &"x_major_grid_line_thickness_px", p_pane_index)
	_load_constant_from_theme(p_control, &"pane_x_major_grid_line_dash", &"x_major_grid_line_dash_px", p_pane_index)

	# X minor
	_load_color_from_theme(p_control, &"pane_x_minor_grid_line_color", &"x_minor_grid_line_color", p_pane_index)
	_load_constant_from_theme(p_control, &"pane_x_minor_grid_line_thickness", &"x_minor_grid_line_thickness_px", p_pane_index)
	_load_constant_from_theme(p_control, &"pane_x_minor_grid_line_dash", &"x_minor_grid_line_dash_px", p_pane_index)

	# Y major
	_load_color_from_theme(p_control, &"pane_y_major_grid_line_color", &"y_major_grid_line_color", p_pane_index)
	_load_constant_from_theme(p_control, &"pane_y_major_grid_line_thickness", &"y_major_grid_line_thickness_px", p_pane_index)
	_load_constant_from_theme(p_control, &"pane_y_major_grid_line_dash", &"y_major_grid_line_dash_px", p_pane_index)

	# Y minor
	_load_color_from_theme(p_control, &"pane_y_minor_grid_line_color", &"y_minor_grid_line_color", p_pane_index)
	_load_constant_from_theme(p_control, &"pane_y_minor_grid_line_thickness", &"y_minor_grid_line_thickness_px", p_pane_index)
	_load_constant_from_theme(p_control, &"pane_y_minor_grid_line_dash", &"y_minor_grid_line_dash_px", p_pane_index)


## Loads a theme color into the target property. Fetches the non-indexed key first,
## then the indexed key (e.g. "pane_x_major_grid_line_color_0") to allow per-pane
## overrides in the theme.
func _load_color_from_theme(
	p_control: Control,
	p_theme_key: StringName,
	p_property: StringName,
	p_pane_index: int
) -> void:
	if p_control.has_theme_color(p_theme_key):
		set(p_property, p_control.get_theme_color(p_theme_key))
	var indexed_key := StringName("%s_%d" % [p_theme_key, p_pane_index])
	if p_control.has_theme_color(indexed_key):
		set(p_property, p_control.get_theme_color(indexed_key))


## Loads a theme constant (int) into the target property. Fetches the non-indexed
## key first, then the indexed key to allow per-pane overrides in the theme.
func _load_constant_from_theme(
	p_control: Control,
	p_theme_key: StringName,
	p_property: StringName,
	p_pane_index: int
) -> void:
	if p_control.has_theme_constant(p_theme_key):
		set(p_property, p_control.get_theme_constant(p_theme_key))
	var indexed_key := StringName("%s_%d" % [p_theme_key, p_pane_index])
	if p_control.has_theme_constant(indexed_key):
		set(p_property, p_control.get_theme_constant(indexed_key))


####################################################################################################
# Cascade: user overrides (layer 3)
####################################################################################################

## Applies overridden properties from [param p_user_style] onto this resolved
## instance. A property is considered overridden when its value on the user
## resource differs from the matching DEFAULT_* constant.
func apply_overrides_from(p_user_style: TauPaneStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.x_major_grid_line_color != DEFAULT_X_MAJOR_GRIDLINE_COLOR:
		x_major_grid_line_color = p_user_style.x_major_grid_line_color
	if p_user_style.x_major_grid_line_thickness_px != DEFAULT_X_MAJOR_GRIDLINE_THICKNESS_PX:
		x_major_grid_line_thickness_px = p_user_style.x_major_grid_line_thickness_px
	if p_user_style.x_major_grid_line_dash_px != DEFAULT_X_MAJOR_GRIDLINE_DASH_PX:
		x_major_grid_line_dash_px = p_user_style.x_major_grid_line_dash_px

	if p_user_style.x_minor_grid_line_color != DEFAULT_X_MINOR_GRIDLINE_COLOR:
		x_minor_grid_line_color = p_user_style.x_minor_grid_line_color
	if p_user_style.x_minor_grid_line_thickness_px != DEFAULT_X_MINOR_GRIDLINE_THICKNESS_PX:
		x_minor_grid_line_thickness_px = p_user_style.x_minor_grid_line_thickness_px
	if p_user_style.x_minor_grid_line_dash_px != DEFAULT_X_MINOR_GRIDLINE_DASH_PX:
		x_minor_grid_line_dash_px = p_user_style.x_minor_grid_line_dash_px

	if p_user_style.y_major_grid_line_color != DEFAULT_Y_MAJOR_GRIDLINE_COLOR:
		y_major_grid_line_color = p_user_style.y_major_grid_line_color
	if p_user_style.y_major_grid_line_thickness_px != DEFAULT_Y_MAJOR_GRIDLINE_THICKNESS_PX:
		y_major_grid_line_thickness_px = p_user_style.y_major_grid_line_thickness_px
	if p_user_style.y_major_grid_line_dash_px != DEFAULT_Y_MAJOR_GRIDLINE_DASH_PX:
		y_major_grid_line_dash_px = p_user_style.y_major_grid_line_dash_px

	if p_user_style.y_minor_grid_line_color != DEFAULT_Y_MINOR_GRIDLINE_COLOR:
		y_minor_grid_line_color = p_user_style.y_minor_grid_line_color
	if p_user_style.y_minor_grid_line_thickness_px != DEFAULT_Y_MINOR_GRIDLINE_THICKNESS_PX:
		y_minor_grid_line_thickness_px = p_user_style.y_minor_grid_line_thickness_px
	if p_user_style.y_minor_grid_line_dash_px != DEFAULT_Y_MINOR_GRIDLINE_DASH_PX:
		y_minor_grid_line_dash_px = p_user_style.y_minor_grid_line_dash_px


####################################################################################################
# Full cascade resolution
####################################################################################################

## Produces a fully resolved TauPaneStyle by applying all three cascade layers:
##   1. Start from defaults (a fresh TauPaneStyle instance).
##   2. Load theme values (non-indexed, then indexed for this pane).
##   3. Apply user overrides from [param p_user_style] (may be null).
##
## The returned instance is a new TauPaneStyle owned by the caller. It is separate
## from [param p_user_style] which is never mutated.
static func resolve(
	p_control: Control,
	p_pane_index: int,
	p_user_style: TauPaneStyle
) -> TauPaneStyle:
	# Layer 1: defaults.
	var resolved := TauPaneStyle.new()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control, p_pane_index)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	return resolved


####################################################################################################
# Change detection
####################################################################################################

func is_equal_to(p_other: TauPaneStyle) -> bool:
	if p_other == null:
		return false
	if x_major_grid_line_color != p_other.x_major_grid_line_color:
		return false
	if x_major_grid_line_thickness_px != p_other.x_major_grid_line_thickness_px:
		return false
	if x_major_grid_line_dash_px != p_other.x_major_grid_line_dash_px:
		return false
	if x_minor_grid_line_color != p_other.x_minor_grid_line_color:
		return false
	if x_minor_grid_line_thickness_px != p_other.x_minor_grid_line_thickness_px:
		return false
	if x_minor_grid_line_dash_px != p_other.x_minor_grid_line_dash_px:
		return false
	if y_major_grid_line_color != p_other.y_major_grid_line_color:
		return false
	if y_major_grid_line_thickness_px != p_other.y_major_grid_line_thickness_px:
		return false
	if y_major_grid_line_dash_px != p_other.y_major_grid_line_dash_px:
		return false
	if y_minor_grid_line_color != p_other.y_minor_grid_line_color:
		return false
	if y_minor_grid_line_thickness_px != p_other.y_minor_grid_line_thickness_px:
		return false
	if y_minor_grid_line_dash_px != p_other.y_minor_grid_line_dash_px:
		return false
	return true


## All current properties are visual-only and do not affect layout (pane rects,
## tick positions, or label measurement). This always returns false.
func has_layout_affecting_change(p_other: TauPaneStyle) -> bool:
	return false
