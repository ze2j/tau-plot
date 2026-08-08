@tool

## Contains theme-driven visual and sizing parameters for scatter markers.
##
## Properties set on this resource take the highest priority, always winning
## over the theme and the built-in defaults. A property counts as set as soon
## as it is assigned, whatever the value, so assigning a built-in default from
## code still beats the theme.
##
## Properties left untouched fall back to the Godot theme. If the theme does
## not define them either, the built-in defaults apply.
##
## For array properties, assign a new array to mark the property as set.
## Mutating the existing array in place does not.
##
## [b]Limitation:[/b] a property set from the inspector to exactly its built-in
## default is not written to the saved resource, so it reads as untouched on
## load and the theme still wins. Assign it from code instead.
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

const DEFAULT_MARKER_SIZE_PX := 12.0

## Per-series cycle of marker sizes in pixels. Each entry sets the marker size
## for one series, with the array indexed cyclically by series index using
## modulo: series [code]i[/code] reads entry
## [code]i % marker_sizes_px.size()[/code]. An empty array is treated as all
## series drawn at [constant DEFAULT_MARKER_SIZE_PX].
##
## Only read under [constant TauScatterConfig.MarkerSizePolicy.THEME]. Under
## [constant TauScatterConfig.MarkerSizePolicy.DATA_UNITS] the size comes from
## [member TauScatterConfig.marker_size_data_units], except on a categorical x
## axis where there is no data span to convert and this cycle applies again.
@export var marker_sizes_px: Array[float] = [DEFAULT_MARKER_SIZE_PX]:
	set(value):
		marker_sizes_px = value
		_overridden[&"marker_sizes_px"] = true

@export var outline_width_px: float = 1.0:
	set(value):
		outline_width_px = value
		_overridden[&"outline_width_px"] = true

@export var outline_color: Color = Color(0, 0, 0, 1):
	set(value):
		outline_color = value
		_overridden[&"outline_color"] = true

## Per-series cycle of marker sizes in pixels for the hovered marker. Each
## entry sets the hovered size for one series, with the array indexed
## cyclically by series index using modulo: series [code]i[/code] reads entry
## [code]i % hovered_marker_sizes_px.size()[/code]. An empty array means no
## size change on hover: the hovered marker keeps its resolved base size.
##
## The hovered size replaces the base size instead of being clamped against
## it, so it may be smaller. Under
## [constant TauScatterConfig.MarkerSizePolicy.DATA_UNITS] the base size comes
## from the data, and comparing it against a pixel value has no meaning.
@export var hovered_marker_sizes_px: Array[float] = [16.0]:
	set(value):
		hovered_marker_sizes_px = value
		_overridden[&"hovered_marker_sizes_px"] = true

## Outline width when hovered (px).
@export var hovered_outline_width_px: float = 2.0:
	set(value):
		hovered_outline_width_px = value
		_overridden[&"hovered_outline_width_px"] = true

## Outline color when hovered.
@export var hovered_outline_color: Color = Color(1, 1, 1, 1):
	set(value):
		hovered_outline_color = value
		_overridden[&"hovered_outline_color"] = true

@export var marker_shapes: Array[MarkerShape] = [
	MarkerShape.CIRCLE,
	MarkerShape.SQUARE,
	MarkerShape.TRIANGLE_UP,
	MarkerShape.TRIANGLE_DOWN,
	MarkerShape.DIAMOND,
	MarkerShape.CROSS,
	MarkerShape.PLUS,
]:
	set(value):
		marker_shapes = value
		_overridden[&"marker_shapes"] = true


# Exported property names assigned at least once, whatever the value. Member
# initializers bypass the setters, so a fresh instance starts empty.
var _overridden: Dictionary[StringName, bool] = {}


####################################################################################################
# Helpers
####################################################################################################

## Returns the resolved marker size in pixels for the given series index.
##
## An empty [member marker_sizes_px] returns [constant DEFAULT_MARKER_SIZE_PX].
## The result is floored at [code]1.0[/code], the smallest size that still
## paints a marker.
func get_series_size_px(p_series_index: int) -> float:
	if marker_sizes_px.is_empty():
		return DEFAULT_MARKER_SIZE_PX
	return max(marker_sizes_px[p_series_index % marker_sizes_px.size()], 1.0)


## Returns the resolved hovered marker size in pixels for the given series
## index. An empty [member hovered_marker_sizes_px] returns [code]0.0[/code] as
## a "no size change" sentinel, leaving the hovered marker at its base size.
func get_series_hovered_size_px(p_series_index: int) -> float:
	if hovered_marker_sizes_px.is_empty():
		return 0.0
	return max(hovered_marker_sizes_px[p_series_index % hovered_marker_sizes_px.size()], 0.0)


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
## The per-series cycles use a two-level indexed lookup at series granularity:
##   1. [code]<key>_N[/code] sets the value for series N across all panes.
##   2. [code]<key>_N_P[/code] overrides series N in pane P only.
##
## Theme key prefixes for the per-series cycles:
##   - [member marker_sizes_px]:         [code]scatter_marker_size_px[/code]
##   - [member hovered_marker_sizes_px]: [code]scatter_hovered_marker_size_px[/code]
##   - [member marker_shapes]:           [code]scatter_marker_shape[/code]
##
## This method writes every property unconditionally because it is called on
## the resolved instance, not on the user-provided resource.
##
## A shape constant holding a value outside [enum MarkerShape] is reported and
## replaced by [code]CIRCLE[/code], keeping the cycle the length the theme
## declared.
func load_from_theme(p_control: Control, p_pane_index: int) -> void:
	if p_control == null:
		push_error("TauScatterStyle.load_from_theme(): control is null")
		return

	# marker_sizes_px: two-level indexed lookup.
	# Level 1 (global): scatter_marker_size_px_N
	var global_sizes: Array[float] = []
	var size_index := 0
	while true:
		var key := StringName("scatter_marker_size_px_%d" % size_index)
		if not p_control.has_theme_constant(key):
			break
		global_sizes.append(float(p_control.get_theme_constant(key)))
		size_index += 1

	if not global_sizes.is_empty():
		marker_sizes_px = global_sizes

	# Level 2 (per-pane): scatter_marker_size_px_N_P overrides series N in pane P.
	var pane_size_index := 0
	while true:
		var key := StringName("scatter_marker_size_px_%d_%d" % [pane_size_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		# Grow the array if the per-pane theme defines more sizes than the
		# global theme (or the default).
		if pane_size_index >= marker_sizes_px.size():
			marker_sizes_px.resize(pane_size_index + 1)
		marker_sizes_px[pane_size_index] = float(p_control.get_theme_constant(key))
		pane_size_index += 1

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

	# hovered_marker_sizes_px: two-level indexed lookup, same pattern as
	# marker_sizes_px.
	var global_hovered_sizes: Array[float] = []
	var hovered_size_index := 0
	while true:
		var key := StringName("scatter_hovered_marker_size_px_%d" % hovered_size_index)
		if not p_control.has_theme_constant(key):
			break
		global_hovered_sizes.append(float(p_control.get_theme_constant(key)))
		hovered_size_index += 1

	if not global_hovered_sizes.is_empty():
		hovered_marker_sizes_px = global_hovered_sizes

	var pane_hovered_size_index := 0
	while true:
		var key := StringName("scatter_hovered_marker_size_px_%d_%d" % [pane_hovered_size_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		if pane_hovered_size_index >= hovered_marker_sizes_px.size():
			hovered_marker_sizes_px.resize(pane_hovered_size_index + 1)
		hovered_marker_sizes_px[pane_hovered_size_index] = float(p_control.get_theme_constant(key))
		pane_hovered_size_index += 1

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
		var key := StringName("scatter_marker_shape_%d" % shape_index)
		if not p_control.has_theme_constant(key):
			break
		global_shapes.append(_resolve_theme_marker_shape(key, p_control.get_theme_constant(key)))
		shape_index += 1

	if not global_shapes.is_empty():
		marker_shapes = global_shapes

	# Level 2 (per-pane): scatter_marker_shape_N_P overrides series N in pane P.
	var pane_shape_index := 0
	while true:
		var key := StringName("scatter_marker_shape_%d_%d" % [pane_shape_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		# Grow the array if the per-pane theme defines more shapes than the
		# global theme (or the default).
		if pane_shape_index >= marker_shapes.size():
			marker_shapes.resize(pane_shape_index + 1)
		marker_shapes[pane_shape_index] = _resolve_theme_marker_shape(key, p_control.get_theme_constant(key))
		pane_shape_index += 1


####################################################################################################
# Cascade: user overrides (layer 3)
####################################################################################################

## Returns [code]true[/code] when [param p_property] has been assigned on this
## resource, whatever the assigned value.
func is_overridden(p_property: StringName) -> bool:
	return _overridden.has(p_property)


## Applies overridden properties from [param p_user_style] onto this resolved
## instance.
func apply_overrides_from(p_user_style: TauScatterStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.is_overridden(&"marker_sizes_px"):
		marker_sizes_px = p_user_style.marker_sizes_px.duplicate()
	if p_user_style.is_overridden(&"outline_width_px"):
		outline_width_px = p_user_style.outline_width_px
	if p_user_style.is_overridden(&"outline_color"):
		outline_color = p_user_style.outline_color
	if p_user_style.is_overridden(&"hovered_marker_sizes_px"):
		hovered_marker_sizes_px = p_user_style.hovered_marker_sizes_px.duplicate()
	if p_user_style.is_overridden(&"hovered_outline_width_px"):
		hovered_outline_width_px = p_user_style.hovered_outline_width_px
	if p_user_style.is_overridden(&"hovered_outline_color"):
		hovered_outline_color = p_user_style.hovered_outline_color
	if p_user_style.is_overridden(&"marker_shapes"):
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

## Returns a copy of this resource carrying the property values and the
## override flags. The flags are copied explicitly because
## [method Resource.duplicate] only copies stored properties.
func make_snapshot() -> TauScatterStyle:
	var copy := duplicate() as TauScatterStyle
	copy._copy_overrides_from(self)
	return copy


# Writing a typed collection into another instance through a property is
# rejected at runtime, so the copy is made from inside the target.
func _copy_overrides_from(p_source: TauScatterStyle) -> void:
	_overridden = p_source._overridden.duplicate()


func is_equal_to(p_other: TauScatterStyle) -> bool:
	if p_other == null:
		return false
	if _overridden != p_other._overridden:
		return false
	if marker_sizes_px != p_other.marker_sizes_px:
		return false
	if outline_width_px != p_other.outline_width_px:
		return false
	if outline_color != p_other.outline_color:
		return false
	if hovered_marker_sizes_px != p_other.hovered_marker_sizes_px:
		return false
	if hovered_outline_width_px != p_other.hovered_outline_width_px:
		return false
	if hovered_outline_color != p_other.hovered_outline_color:
		return false
	if marker_shapes != p_other.marker_shapes:
		return false
	return true


# All TauScatterStyle properties are visual-only. They control how markers are
# drawn within a fixed domain but do not affect domain, ticks, or pane rect.
func has_layout_affecting_change(p_other: TauScatterStyle) -> bool:
	return false


####################################################################################################
# Private
####################################################################################################

# Theme constants are free-form integers, so a shape key may hold anything.
# COUNT is the shape count, not a shape, which rules out a plain range check
# over MarkerShape.values(). NONE must stay the last member for this to hold.
#
# An invalid value falls back to CIRCLE rather than skipping the position, so
# the surrounding scan keeps the index run the theme declared.
static func _resolve_theme_marker_shape(p_key: StringName, p_value: int) -> MarkerShape:
	if (p_value >= 0 and p_value < MarkerShape.COUNT) or p_value == MarkerShape.NONE:
		return p_value as MarkerShape

	push_error("TauScatterStyle.load_from_theme(): theme constant '%s' is %d, not a MarkerShape value. Using CIRCLE." % [p_key, p_value])
	return MarkerShape.CIRCLE
