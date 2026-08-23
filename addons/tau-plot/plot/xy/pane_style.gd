@tool

## Visual style for a single pane.
##
## Properties are resolved from the built-in defaults, the theme, and the values
## set here, in that order. See [TauStyle] for the details.
##
## Multiple panes can share the same TauPaneStyle. Every pane that references it
## will pick up the changes.
##
## Theme type variation: TauPane
class_name TauPaneStyle extends TauStyle

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()` and `validate_resolved()`.
################################################################################################


####################################################################################################
# X axis major grid lines
####################################################################################################

## Color of the X major grid lines.
@export var x_major_grid_line_color: Color = Color(1.0, 1.0, 1.0, 0.15):
	set(value):
		x_major_grid_line_color = value
		_mark(&"x_major_grid_line_color")

## Thickness in pixels of the X major grid lines.
@export var x_major_grid_line_thickness_px: int = 1:
	set(value):
		x_major_grid_line_thickness_px = maxi(value, 0)
		_mark(&"x_major_grid_line_thickness_px")

## Length in pixels of one dash of the X major grid lines, with an equal gap
## between dashes. [code]0[/code] draws solid lines.
@export var x_major_grid_line_dash_px: int = 0:
	set(value):
		x_major_grid_line_dash_px = maxi(value, 0)
		_mark(&"x_major_grid_line_dash_px")


####################################################################################################
# X axis minor grid lines
####################################################################################################

## Color of the X minor grid lines.
@export var x_minor_grid_line_color: Color = Color(1.0, 1.0, 1.0, 0.08):
	set(value):
		x_minor_grid_line_color = value
		_mark(&"x_minor_grid_line_color")

## Thickness in pixels of the X minor grid lines.
@export var x_minor_grid_line_thickness_px: int = 1:
	set(value):
		x_minor_grid_line_thickness_px = maxi(value, 0)
		_mark(&"x_minor_grid_line_thickness_px")

## Length in pixels of one dash of the X minor grid lines, with an equal gap
## between dashes. [code]0[/code] draws solid lines.
@export var x_minor_grid_line_dash_px: int = 0:
	set(value):
		x_minor_grid_line_dash_px = maxi(value, 0)
		_mark(&"x_minor_grid_line_dash_px")


####################################################################################################
# Y axis major grid lines
####################################################################################################

## Color of the Y major grid lines.
@export var y_major_grid_line_color: Color = Color(1.0, 1.0, 1.0, 0.15):
	set(value):
		y_major_grid_line_color = value
		_mark(&"y_major_grid_line_color")

## Thickness in pixels of the Y major grid lines.
@export var y_major_grid_line_thickness_px: int = 1:
	set(value):
		y_major_grid_line_thickness_px = maxi(value, 0)
		_mark(&"y_major_grid_line_thickness_px")

## Length in pixels of one dash of the Y major grid lines, with an equal gap
## between dashes. [code]0[/code] draws solid lines.
@export var y_major_grid_line_dash_px: int = 0:
	set(value):
		y_major_grid_line_dash_px = maxi(value, 0)
		_mark(&"y_major_grid_line_dash_px")


####################################################################################################
# Y axis minor grid lines
####################################################################################################

## Color of the Y minor grid lines.
@export var y_minor_grid_line_color: Color = Color(1.0, 1.0, 1.0, 0.08):
	set(value):
		y_minor_grid_line_color = value
		_mark(&"y_minor_grid_line_color")

## Thickness in pixels of the Y minor grid lines.
@export var y_minor_grid_line_thickness_px: int = 1:
	set(value):
		y_minor_grid_line_thickness_px = maxi(value, 0)
		_mark(&"y_minor_grid_line_thickness_px")

## Length in pixels of one dash of the Y minor grid lines, with an equal gap
## between dashes. [code]0[/code] draws solid lines.
@export var y_minor_grid_line_dash_px: int = 0:
	set(value):
		y_minor_grid_line_dash_px = maxi(value, 0)
		_mark(&"y_minor_grid_line_dash_px")


#region Internal, not public API, may change without notice.

# Loads properties from the Godot theme attached to p_control.
#
# For each property, the non-indexed theme constant is fetched first (shared
# base for all panes), then the indexed constant for p_pane_index overwrites
# it if present. Values are written without consulting the override marks,
# because this runs on the resolved instance, not on the user-provided
# resource.
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


# Loads a theme color into the target property. Fetches the non-indexed key
# first, then the indexed key (e.g. "pane_x_major_grid_line_color_0") to allow
# per-pane overrides in the theme.
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


# Loads a theme constant (int) into the target property. Fetches the
# non-indexed key first, then the indexed key to allow per-pane overrides in
# the theme.
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


# Applies overridden properties from p_user_style onto this resolved
# instance.
func apply_overrides_from(p_user_style: TauPaneStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.is_overridden(&"x_major_grid_line_color"):
		x_major_grid_line_color = p_user_style.x_major_grid_line_color
	if p_user_style.is_overridden(&"x_major_grid_line_thickness_px"):
		x_major_grid_line_thickness_px = p_user_style.x_major_grid_line_thickness_px
	if p_user_style.is_overridden(&"x_major_grid_line_dash_px"):
		x_major_grid_line_dash_px = p_user_style.x_major_grid_line_dash_px

	if p_user_style.is_overridden(&"x_minor_grid_line_color"):
		x_minor_grid_line_color = p_user_style.x_minor_grid_line_color
	if p_user_style.is_overridden(&"x_minor_grid_line_thickness_px"):
		x_minor_grid_line_thickness_px = p_user_style.x_minor_grid_line_thickness_px
	if p_user_style.is_overridden(&"x_minor_grid_line_dash_px"):
		x_minor_grid_line_dash_px = p_user_style.x_minor_grid_line_dash_px

	if p_user_style.is_overridden(&"y_major_grid_line_color"):
		y_major_grid_line_color = p_user_style.y_major_grid_line_color
	if p_user_style.is_overridden(&"y_major_grid_line_thickness_px"):
		y_major_grid_line_thickness_px = p_user_style.y_major_grid_line_thickness_px
	if p_user_style.is_overridden(&"y_major_grid_line_dash_px"):
		y_major_grid_line_dash_px = p_user_style.y_major_grid_line_dash_px

	if p_user_style.is_overridden(&"y_minor_grid_line_color"):
		y_minor_grid_line_color = p_user_style.y_minor_grid_line_color
	if p_user_style.is_overridden(&"y_minor_grid_line_thickness_px"):
		y_minor_grid_line_thickness_px = p_user_style.y_minor_grid_line_thickness_px
	if p_user_style.is_overridden(&"y_minor_grid_line_dash_px"):
		y_minor_grid_line_dash_px = p_user_style.y_minor_grid_line_dash_px


# Produces a fully resolved TauPaneStyle by applying all three cascade layers:
#   1. Start from defaults (a fresh TauPaneStyle instance).
#   2. Load theme values (non-indexed, then indexed for this pane).
#   3. Apply user overrides from p_user_style (may be null).
#   4. Report what the resolved combination cannot draw.
#
# The returned instance is a new TauPaneStyle owned by the caller. It is
# separate from p_user_style, which is never mutated.
static func resolve(p_control: Control, p_pane_index: int, p_user_style: TauPaneStyle) -> TauPaneStyle:
	# Layer 1: defaults.
	var resolved := TauPaneStyle.new()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control, p_pane_index)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	# Layer 4: report what the resolved combination cannot draw.
	resolved.validate_resolved()
	return resolved


# Nothing spans two properties here. Every property stands on its own and its
# range is enforced on assignment, a zero thickness included: a hidden grid line
# is a setting, not a misconfiguration.
func validate_resolved() -> void:
	pass


# Returns a copy of this resource carrying the property values and the
# override flags. The flags are copied explicitly because
# Resource.duplicate() only copies stored properties.
func make_snapshot() -> TauPaneStyle:
	var copy := duplicate() as TauPaneStyle
	copy._copy_overrides_from(self)
	return copy


func is_equal_to(p_other: TauStyle) -> bool:
	var other := p_other as TauPaneStyle
	if other == null:
		return false
	if not super.is_equal_to(other):
		return false
	if x_major_grid_line_color != other.x_major_grid_line_color:
		return false
	if x_major_grid_line_thickness_px != other.x_major_grid_line_thickness_px:
		return false
	if x_major_grid_line_dash_px != other.x_major_grid_line_dash_px:
		return false
	if x_minor_grid_line_color != other.x_minor_grid_line_color:
		return false
	if x_minor_grid_line_thickness_px != other.x_minor_grid_line_thickness_px:
		return false
	if x_minor_grid_line_dash_px != other.x_minor_grid_line_dash_px:
		return false
	if y_major_grid_line_color != other.y_major_grid_line_color:
		return false
	if y_major_grid_line_thickness_px != other.y_major_grid_line_thickness_px:
		return false
	if y_major_grid_line_dash_px != other.y_major_grid_line_dash_px:
		return false
	if y_minor_grid_line_color != other.y_minor_grid_line_color:
		return false
	if y_minor_grid_line_thickness_px != other.y_minor_grid_line_thickness_px:
		return false
	if y_minor_grid_line_dash_px != other.y_minor_grid_line_dash_px:
		return false
	return true


# All current properties are visual-only and do not affect layout (pane rects,
# tick positions, or label measurement). This always returns false.
func has_layout_affecting_change(p_other: TauPaneStyle) -> bool:
	return false

#endregion
