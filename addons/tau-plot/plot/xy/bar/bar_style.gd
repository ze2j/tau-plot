@tool

## Contains theme-driven visual and spacing parameters for the bars.
##
## Properties set on this resource take the highest priority, always winning
## over the theme and the built-in defaults. A property counts as set as soon
## as it is assigned, whatever the value, so assigning a built-in default from
## code still beats the theme.
##
## Properties left untouched fall back to the Godot theme. If the theme does
## not define them either, the built-in defaults apply.
##
## Assign a new [StyleBox] rather than mutating the one already assigned. An
## in-place change is not detected.
##
## [b]Limitation:[/b] a property set from the inspector to exactly its built-in
## default is not written to the saved resource, so it reads as untouched on
## load and the theme still wins. Assign it from code instead.
class_name TauBarStyle extends Resource

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()`.
################################################################################################

@export var bar_width_px: int = 64:
	set(value):
		bar_width_px = value
		_overridden[&"bar_width_px"] = true

@export var bar_intragroup_gap_px: int = 0:
	set(value):
		bar_intragroup_gap_px = value
		_overridden[&"bar_intragroup_gap_px"] = true

@export var style_box: StyleBox = null:
	set(value):
		style_box = value
		_overridden[&"style_box"] = true

## StyleBox used for the hovered bar. When null, the renderer uses the normal
## style_box (no shape change on hover). The fill color is still determined by
## the color pipeline and the hover_highlight_callback.
@export var hovered_style_box: StyleBox = null:
	set(value):
		hovered_style_box = value
		_overridden[&"hovered_style_box"] = true


# Exported property names assigned at least once, whatever the value. Member
# initializers bypass the setters, so a fresh instance starts empty.
var _overridden: Dictionary[StringName, bool] = {}


####################################################################################################
# Cascade: built-in default (layer 1)
####################################################################################################

## Creates a plain StyleBoxFlat with default values.
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


## Creates a StyleBoxFlat for the hovered state: same corner radii as the
## default normal StyleBox, plus a 2px white border on all sides.
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


####################################################################################################
# Cascade: user overrides (layer 3)
####################################################################################################

## Returns [code]true[/code] when [param p_property] has been assigned on this
## resource, whatever the assigned value.
func is_overridden(p_property: StringName) -> bool:
	return _overridden.has(p_property)


## Applies overridden properties from [param p_user_style] onto this resolved
## instance.
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


####################################################################################################
# Full cascade resolution
####################################################################################################

## Produces a fully resolved TauBarStyle by applying all three cascade layers:
##   1. Start from defaults (a fresh TauBarStyle instance).
##   2. Load theme values (non-indexed, then indexed for this pane).
##   3. Apply user overrides from [param p_user_style] (may be null).
##
## The returned instance is a new TauBarStyle owned by the caller. It is separate
## from [param p_user_style] which is never mutated.
static func resolve(
	p_control: Control,
	p_pane_index: int,
	p_user_style: TauBarStyle
) -> TauBarStyle:
	# Layer 1: defaults.
	var resolved := TauBarStyle.new()
	resolved.style_box = _create_default_style_box()
	resolved.hovered_style_box = _create_default_hovered_style_box()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control, p_pane_index)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	return resolved


####################################################################################################
# Change detection
####################################################################################################

## Returns a copy of this resource carrying the property values and the
## override flags. The flags are copied explicitly because
## [method Resource.duplicate] only copies stored properties.
func make_snapshot() -> TauBarStyle:
	var copy := duplicate() as TauBarStyle
	copy._copy_overrides_from(self)
	return copy


# Writing a typed collection into another instance through a property is
# rejected at runtime, so the copy is made from inside the target.
func _copy_overrides_from(p_source: TauBarStyle) -> void:
	_overridden = p_source._overridden.duplicate()


func is_equal_to(p_other: TauBarStyle) -> bool:
	if p_other == null:
		return false
	if _overridden != p_other._overridden:
		return false
	if bar_width_px != p_other.bar_width_px:
		return false
	if bar_intragroup_gap_px != p_other.bar_intragroup_gap_px:
		return false
	if style_box != p_other.style_box:
		return false
	if hovered_style_box != p_other.hovered_style_box:
		return false
	return true


# All TauBarStyle properties are visual-only. They control how bars are drawn
# within a fixed domain but do not affect domain, ticks, or pane rect.
func has_layout_affecting_change(p_other: TauBarStyle) -> bool:
	return false
