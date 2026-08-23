@tool

## Contains theme-driven visual and spacing parameters for the bars.
##
## Properties are resolved from the built-in defaults, the theme, and the values
## set here, in that order. See [TauStyle] for the details.
##
## Assign a new [StyleBox] rather than mutating the one already assigned. An
## in-place change is not detected.
##
## Theme type variation: TauBar
class_name TauBarStyle extends TauStyle

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()` and `validate_resolved()`.
################################################################################################

## Width of one bar in pixels. Only read under
## [constant TauBarConfig.BarWidthPolicy.THEME]. The other width policies
## derive the width from the category slot or from the local sample spacing
## and ignore this property. Values below 1 are clamped to 1.
@export var bar_width_px: int = 64:
	set(value):
		bar_width_px = maxi(value, 1)
		_mark(&"bar_width_px")

## Gap in pixels between two bars of the same group. Only read under
## [constant TauBarConfig.BarWidthPolicy.THEME], and only in
## [constant TauBarConfig.BarMode.GROUPED], the one mode where several
## series share an x position. Negative values are clamped to 0.
@export var bar_intragroup_gap_px: int = 0:
	set(value):
		bar_intragroup_gap_px = maxi(value, 0)
		_mark(&"bar_intragroup_gap_px")

## StyleBox drawn for every bar in the normal state. Only [StyleBoxFlat]
## and [StyleBoxTexture] are supported.
##
## Corner radii and borders are authored as if the bar grew upward from the
## baseline, and are remapped to the direction the bar actually grows in.
##
## The fill color is overwritten at draw time by the resolved series color,
## so [member StyleBoxFlat.bg_color] and
## [member StyleBoxTexture.modulate_color] carry no value here.
##
## Left alone, or assigned [code]null[/code], the bars are drawn with a
## square-cornered [StyleBoxFlat] with no border and no content margin.
@export var style_box: StyleBox = null:
	set(value):
		style_box = value
		_mark(&"style_box")

## StyleBox drawn for the hovered bar, following the same rules as
## [member style_box]. It replaces the StyleBox the bar would otherwise be
## drawn with.
##
## Left alone, or assigned [code]null[/code], the hovered bar is drawn with
## the [member style_box] default plus a 2 pixel white border on all sides.
@export var hovered_style_box: StyleBox = null:
	set(value):
		hovered_style_box = value
		_mark(&"hovered_style_box")


#region Internal, not public API, may change without notice.

static var _SHARED_DEFAULT_STYLE_BOX: StyleBoxFlat = null
static var _SHARED_DEFAULT_HOVERED_STYLE_BOX: StyleBoxFlat = null


# Returns the StyleBox every bar is drawn with, never null.
func get_effective_style_box() -> StyleBox:
	if _is_supported_style_box(style_box, &"style_box"):
		return style_box
	if _SHARED_DEFAULT_STYLE_BOX == null:
		_SHARED_DEFAULT_STYLE_BOX = _create_default_style_box()
	return _SHARED_DEFAULT_STYLE_BOX


# Returns the StyleBox the hovered bar is drawn with, never null.
func get_effective_hovered_style_box() -> StyleBox:
	if _is_supported_style_box(hovered_style_box, &"hovered_style_box"):
		return hovered_style_box
	if _SHARED_DEFAULT_HOVERED_STYLE_BOX == null:
		_SHARED_DEFAULT_HOVERED_STYLE_BOX = _create_default_hovered_style_box()
	return _SHARED_DEFAULT_HOVERED_STYLE_BOX


# Null is a legal value carrying the built-in default, so only a wrong subclass is reported.
static func _is_supported_style_box(p_style_box: StyleBox, p_property: StringName) -> bool:
	if p_style_box == null:
		return false
	if p_style_box is StyleBoxFlat or p_style_box is StyleBoxTexture:
		return true
	push_error("TauBarStyle.%s must be a StyleBoxFlat or a StyleBoxTexture, got %s. Falling back to the built-in default." % [p_property, p_style_box.get_class()])
	return false


# Creates a plain StyleBoxFlat with default values.
static func _create_default_style_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE  # Overwritten by renderer at draw time
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	sb.border_width_top = 0
	sb.border_width_bottom = 0
	sb.border_width_left = 0
	sb.border_width_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	return sb


# Creates a StyleBoxFlat for the hovered state: same corner radii as the
# default normal StyleBox, plus a 2px white border on all sides.
static func _create_default_hovered_style_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE  # Overwritten by renderer at draw time
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_color = Color(1, 1, 1, 1)
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	return sb


# Loads properties from the Godot theme attached to p_control.
#
# For each property, the non-indexed theme constant is fetched first (shared
# base for all panes), then the indexed constant for p_pane_index overwrites
# it if present. Values are written without consulting the override marks,
# because this runs on the resolved instance, not on the user-provided
# resource.
func load_from_theme(p_control: Control, p_pane_index: int) -> void:
	if p_control == null:
		push_error("TauBarStyle.load_from_theme(): control is null")
		return

	# Non-indexed key first, then per-pane indexed key overwrites.
	if p_control.has_theme_constant(&"bar_width_px"):
		bar_width_px = p_control.get_theme_constant(&"bar_width_px")
	var indexed_width_key := StringName("bar_width_px_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_width_key):
		bar_width_px = p_control.get_theme_constant(indexed_width_key)

	if p_control.has_theme_constant(&"bar_intragroup_gap_px"):
		bar_intragroup_gap_px = p_control.get_theme_constant(&"bar_intragroup_gap_px")
	var indexed_gap_key := StringName("bar_intragroup_gap_px_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_gap_key):
		bar_intragroup_gap_px = p_control.get_theme_constant(indexed_gap_key)

	if p_control.has_theme_stylebox(&"bar_style_box"):
		style_box = p_control.get_theme_stylebox(&"bar_style_box")
	var indexed_sb_key := StringName("bar_style_box_%d" % p_pane_index)
	if p_control.has_theme_stylebox(indexed_sb_key):
		style_box = p_control.get_theme_stylebox(indexed_sb_key)

	if p_control.has_theme_stylebox(&"bar_hovered_style_box"):
		hovered_style_box = p_control.get_theme_stylebox(&"bar_hovered_style_box")
	var indexed_hovered_sb_key := StringName("bar_hovered_style_box_%d" % p_pane_index)
	if p_control.has_theme_stylebox(indexed_hovered_sb_key):
		hovered_style_box = p_control.get_theme_stylebox(indexed_hovered_sb_key)


# Applies overridden properties from p_user_style onto this resolved
# instance.
func apply_overrides_from(p_user_style: TauBarStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.is_overridden(&"bar_width_px"):
		bar_width_px = p_user_style.bar_width_px
	if p_user_style.is_overridden(&"bar_intragroup_gap_px"):
		bar_intragroup_gap_px = p_user_style.bar_intragroup_gap_px
	if p_user_style.is_overridden(&"style_box"):
		style_box = p_user_style.style_box
	if p_user_style.is_overridden(&"hovered_style_box"):
		hovered_style_box = p_user_style.hovered_style_box


# Produces a fully resolved TauBarStyle by applying all three cascade layers:
#   1. Start from defaults (a fresh TauBarStyle instance).
#   2. Load theme values (non-indexed, then indexed for this pane).
#   3. Apply user overrides from p_user_style (may be null).
#   4. Report what the resolved combination cannot draw.
#
# The returned instance is a new TauBarStyle owned by the caller. It is
# separate from p_user_style, which is never mutated.
static func resolve(p_control: Control, p_pane_index: int, p_user_style: TauBarStyle) -> TauBarStyle:
	# Layer 1: defaults.
	var resolved := TauBarStyle.new()
	resolved.style_box = _create_default_style_box()
	resolved.hovered_style_box = _create_default_hovered_style_box()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control, p_pane_index)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	# Layer 4: report what the resolved combination cannot draw.
	resolved.validate_resolved()
	return resolved


# Nothing spans two properties here. The scalar ranges are enforced on
# assignment, and an unsupported style box is reported by
# _is_supported_style_box(), which also supplies the replacement.
func validate_resolved() -> void:
	pass


# Returns a copy of this resource carrying the property values and the
# override flags. The flags are copied explicitly because
# Resource.duplicate() only copies stored properties.
func make_snapshot() -> TauBarStyle:
	var copy := duplicate() as TauBarStyle
	copy._copy_overrides_from(self)
	return copy


func is_equal_to(p_other: TauStyle) -> bool:
	var other := p_other as TauBarStyle
	if other == null:
		return false
	if not super.is_equal_to(other):
		return false
	if bar_width_px != other.bar_width_px:
		return false
	if bar_intragroup_gap_px != other.bar_intragroup_gap_px:
		return false
	if style_box != other.style_box:
		return false
	if hovered_style_box != other.hovered_style_box:
		return false
	return true


# All TauBarStyle properties are visual-only. They control how bars are drawn
# within a fixed domain but do not affect domain, ticks, or pane rect.
func has_layout_affecting_change(p_other: TauBarStyle) -> bool:
	return false

#endregion
