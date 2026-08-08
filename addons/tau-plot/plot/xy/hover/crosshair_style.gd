@tool

## Visual styling for crosshair guide lines drawn at the hovered position.
##
## Properties are resolved from the built-in defaults, the theme, and the values
## set here, in that order. See [TauStyle] for the details.
##
## Theme type variation: TauCrosshair
class_name TauCrosshairStyle extends TauStyle

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`.
################################################################################################

## Color of the crosshair guide lines.
@export var color: Color = Color(1.0, 1.0, 1.0, 0.4):
	set(value):
		color = value
		_overridden[&"color"] = true

## Thickness of the crosshair guide lines in pixels. Values below 1 are
## clamped to 1.
@export var thickness_px: int = 1:
	set(value):
		thickness_px = value
		_overridden[&"thickness_px"] = true

## Length in pixels of one dash of the crosshair guide lines, with an equal
## gap between dashes. [code]0[/code] draws a solid line. Negative values are
## clamped to 0.
@export var dash_px: int = 4:
	set(value):
		dash_px = value
		_overridden[&"dash_px"] = true


#region Internal, not public API, may change without notice.

func load_from_theme(p_control: Control) -> void:
	if p_control == null:
		push_error("TauCrosshairStyle.load_from_theme(): control is null")
		return

	if p_control.has_theme_color(&"crosshair_color"):
		color = p_control.get_theme_color(&"crosshair_color")

	if p_control.has_theme_constant(&"crosshair_thickness"):
		thickness_px = max(p_control.get_theme_constant(&"crosshair_thickness"), 1)

	if p_control.has_theme_constant(&"crosshair_dash"):
		dash_px = max(p_control.get_theme_constant(&"crosshair_dash"), 0)


func apply_overrides_from(p_user_style: TauCrosshairStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.is_overridden(&"color"):
		color = p_user_style.color
	if p_user_style.is_overridden(&"thickness_px"):
		thickness_px = p_user_style.thickness_px
	if p_user_style.is_overridden(&"dash_px"):
		dash_px = p_user_style.dash_px


static func resolve(p_control: Control, p_user_style: TauCrosshairStyle) -> TauCrosshairStyle:
	# Layer 1: defaults.
	var resolved := TauCrosshairStyle.new()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	return resolved


func is_equal_to(p_other: TauStyle) -> bool:
	var other := p_other as TauCrosshairStyle
	if other == null:
		return false
	if not super.is_equal_to(other):
		return false
	if color != other.color:
		return false
	if thickness_px != other.thickness_px:
		return false
	if dash_px != other.dash_px:
		return false
	return true

#endregion
