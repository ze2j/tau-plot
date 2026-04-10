## Visual styling for crosshair guide lines drawn at the hovered position.
##
## Resolved through the same three-layer cascade (defaults, theme, user
## overrides) as TauBarStyle, TauScatterStyle, TauPaneStyle.
##
## Theme type variation: TauCrosshair
class_name TauCrosshairStyle extends Resource

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`.
################################################################################################

const DEFAULT_COLOR: Color = Color(1.0, 1.0, 1.0, 0.4)
## Crosshair line color.
@export var color: Color = DEFAULT_COLOR

const DEFAULT_THICKNESS_PX: int = 1
## Crosshair line thickness (px).
@export var thickness_px: int = DEFAULT_THICKNESS_PX

const DEFAULT_DASH_PX: int = 4
## Crosshair dash length. 0 = solid line.
@export var dash_px: int = DEFAULT_DASH_PX


####################################################################################################
# Cascade: theme loading (layer 2)
####################################################################################################

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


####################################################################################################
# Cascade: user overrides (layer 3)
####################################################################################################

func apply_overrides_from(p_user_style: TauCrosshairStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.color != DEFAULT_COLOR:
		color = p_user_style.color
	if p_user_style.thickness_px != DEFAULT_THICKNESS_PX:
		thickness_px = p_user_style.thickness_px
	if p_user_style.dash_px != DEFAULT_DASH_PX:
		dash_px = p_user_style.dash_px


####################################################################################################
# Full cascade resolution
####################################################################################################

static func resolve(p_control: Control, p_user_style: TauCrosshairStyle) -> TauCrosshairStyle:
	# Layer 1: defaults.
	var resolved := TauCrosshairStyle.new()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	return resolved


####################################################################################################
# Change detection
####################################################################################################

func is_equal_to(p_other: TauCrosshairStyle) -> bool:
	if p_other == null:
		return false
	if color != p_other.color:
		return false
	if thickness_px != p_other.thickness_px:
		return false
	if dash_px != p_other.dash_px:
		return false
	return true
