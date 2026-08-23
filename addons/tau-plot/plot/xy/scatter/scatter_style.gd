@tool

## Contains theme-driven visual and sizing parameters for scatter markers.
##
## Properties are resolved from the built-in defaults, the theme, and the values
## set here, in that order. The per-series arrays are read as cycles. See
## [TauStyle] for the details.
##
## Theme type variation: TauScatter
class_name TauScatterStyle extends TauStyle

## Shape drawn at a sample position. See [member marker_shapes].
enum MarkerShape
{
	CIRCLE = 0,        ## Filled disc.
	SQUARE = 1,        ## Filled axis-aligned square.
	TRIANGLE_UP = 2,   ## Filled triangle pointing up.
	TRIANGLE_DOWN = 3, ## Filled triangle pointing down.
	DIAMOND = 4,       ## Filled square turned 45 degrees.
	CROSS = 5,         ## Two diagonal strokes.
	PLUS = 6,          ## One horizontal and one vertical stroke.
	COUNT = 7,         ## Number of drawable shapes. Not a shape itself.
	NONE = 8           ## Draws nothing, hiding the markers of a series without removing its samples from the dataset.
}

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()` and `validate_resolved()`.
################################################################################################

## Marker size in pixels applied when [member marker_sizes_px] is empty.
const DEFAULT_MARKER_SIZE_PX := 12.0

## Per-series cycle of marker sizes in pixels. See [TauStyle] for how a cycle
## is indexed. An empty array is treated as all series drawn at
## [constant DEFAULT_MARKER_SIZE_PX].
##
## Only read under [constant TauScatterConfig.MarkerSizePolicy.THEME]. Under
## [constant TauScatterConfig.MarkerSizePolicy.DATA_UNITS] the size comes from
## [member TauScatterConfig.marker_size_data_units], except on a categorical x
## axis where there is no data span to convert and this cycle applies again.
@export var marker_sizes_px: Array[float] = [DEFAULT_MARKER_SIZE_PX]:
	set(value):
		marker_sizes_px = _floored_floats(value, 1.0)
		_mark(&"marker_sizes_px")

## Thickness in pixels of the outline stroked around every marker.
## [code]0[/code] leaves the markers unoutlined. Negative values are clamped
## to 0.
@export var outline_width_px: float = 1.0:
	set(value):
		outline_width_px = maxf(value, 0.0)
		_mark(&"outline_width_px")

## Color of the outline stroked around every marker.
@export var outline_color: Color = Color(0, 0, 0, 1):
	set(value):
		outline_color = value
		_mark(&"outline_color")

## Per-series cycle of marker sizes in pixels for the hovered marker. See
## [TauStyle] for how a cycle is indexed. An empty array means no size change
## on hover: the hovered marker keeps its resolved base size.
##
## The hovered size replaces the base size instead of being clamped against
## it, so it may be smaller. Under
## [constant TauScatterConfig.MarkerSizePolicy.DATA_UNITS] the base size comes
## from the data, and comparing it against a pixel value has no meaning.
@export var hovered_marker_sizes_px: Array[float] = [16.0]:
	set(value):
		hovered_marker_sizes_px = _floored_floats(value, 0.0)
		_mark(&"hovered_marker_sizes_px")

## Thickness in pixels of the outline stroked around the hovered marker.
## Negative values are clamped to 0.
@export var hovered_outline_width_px: float = 2.0:
	set(value):
		hovered_outline_width_px = maxf(value, 0.0)
		_mark(&"hovered_outline_width_px")

## Color of the outline stroked around the hovered marker.
@export var hovered_outline_color: Color = Color(1, 1, 1, 1):
	set(value):
		hovered_outline_color = value
		_mark(&"hovered_outline_color")

## Per-series cycle of marker shapes. See [TauStyle] for how a cycle is
## indexed. An empty array is treated as all series drawn as
## [constant MarkerShape.CIRCLE].
##
## An entry that answers to no [enum MarkerShape] member is reported and drawn
## as [constant MarkerShape.CIRCLE].
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
		marker_shapes = value.duplicate()
		_mark(&"marker_shapes")


#region Internal, not public API, may change without notice.

# Returns the resolved marker size in pixels for the given series index.
#
# An empty marker_sizes_px returns DEFAULT_MARKER_SIZE_PX.
func get_series_size_px(p_series_index: int) -> float:
	if marker_sizes_px.is_empty():
		return DEFAULT_MARKER_SIZE_PX
	return marker_sizes_px[p_series_index % marker_sizes_px.size()]


# Returns the resolved hovered marker size in pixels for the given series
# index. An empty hovered_marker_sizes_px returns 0.0 as a "no size change"
# sentinel, leaving the hovered marker at its base size.
func get_series_hovered_size_px(p_series_index: int) -> float:
	if hovered_marker_sizes_px.is_empty():
		return 0.0
	return hovered_marker_sizes_px[p_series_index % hovered_marker_sizes_px.size()]


func get_series_shape(p_series_index: int) -> MarkerShape:
	if marker_shapes.is_empty():
		return MarkerShape.CIRCLE
	return resolve_marker_shape(marker_shapes[p_series_index % marker_shapes.size()])


# Loads properties from the Godot theme attached to p_control.
#
# For scalar properties, the non-indexed theme key is fetched first (shared
# base for all panes), then the indexed key for p_pane_index overwrites it if
# present.
#
# The per-series cycles use the two-level cycle keys described in TauStyle.
#
# Theme key prefixes for the per-series cycles:
#   - marker_sizes_px:         scatter_marker_size_px
#   - hovered_marker_sizes_px: scatter_hovered_marker_size_px
#   - marker_shapes:           scatter_marker_shape
#
# Values are written without consulting the override marks, because this runs
# on the resolved instance, not on the user-provided resource.
#
# A shape constant holding a value outside MarkerShape is reported and
# replaced by CIRCLE, keeping the cycle the length the theme declared.
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
	# Built aside and assigned whole, so the entries pass through the setter.
	var pane_sizes := marker_sizes_px.duplicate()
	var pane_size_index := 0
	while true:
		var key := StringName("scatter_marker_size_px_%d_%d" % [pane_size_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		# Grow the array if the per-pane theme defines more sizes than the
		# global theme (or the default).
		if pane_size_index >= pane_sizes.size():
			pane_sizes.resize(pane_size_index + 1)
		pane_sizes[pane_size_index] = float(p_control.get_theme_constant(key))
		pane_size_index += 1

	if pane_size_index > 0:
		marker_sizes_px = pane_sizes

	# outline_width_px
	if p_control.has_theme_constant(&"scatter_outline_width_px"):
		outline_width_px = float(p_control.get_theme_constant(&"scatter_outline_width_px"))
	var indexed_outline_key := StringName("scatter_outline_width_px_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_outline_key):
		outline_width_px = float(p_control.get_theme_constant(indexed_outline_key))

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

	var pane_hovered_sizes := hovered_marker_sizes_px.duplicate()
	var pane_hovered_size_index := 0
	while true:
		var key := StringName("scatter_hovered_marker_size_px_%d_%d" % [pane_hovered_size_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		if pane_hovered_size_index >= pane_hovered_sizes.size():
			pane_hovered_sizes.resize(pane_hovered_size_index + 1)
		pane_hovered_sizes[pane_hovered_size_index] = float(p_control.get_theme_constant(key))
		pane_hovered_size_index += 1

	if pane_hovered_size_index > 0:
		hovered_marker_sizes_px = pane_hovered_sizes

	# hovered_outline_width_px
	if p_control.has_theme_constant(&"scatter_hovered_outline_width_px"):
		hovered_outline_width_px = float(p_control.get_theme_constant(&"scatter_hovered_outline_width_px"))
	var indexed_hovered_ow_key := StringName("scatter_hovered_outline_width_px_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_hovered_ow_key):
		hovered_outline_width_px = float(p_control.get_theme_constant(indexed_hovered_ow_key))

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
	var pane_shapes := marker_shapes.duplicate()
	var pane_shape_index := 0
	while true:
		var key := StringName("scatter_marker_shape_%d_%d" % [pane_shape_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		# Grow the array if the per-pane theme defines more shapes than the
		# global theme (or the default).
		if pane_shape_index >= pane_shapes.size():
			pane_shapes.resize(pane_shape_index + 1)
		pane_shapes[pane_shape_index] = _resolve_theme_marker_shape(key, p_control.get_theme_constant(key))
		pane_shape_index += 1

	if pane_shape_index > 0:
		marker_shapes = pane_shapes


# Applies overridden properties from p_user_style onto this resolved
# instance.
func apply_overrides_from(p_user_style: TauScatterStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.is_overridden(&"marker_sizes_px"):
		marker_sizes_px = p_user_style.marker_sizes_px
	if p_user_style.is_overridden(&"outline_width_px"):
		outline_width_px = p_user_style.outline_width_px
	if p_user_style.is_overridden(&"outline_color"):
		outline_color = p_user_style.outline_color
	if p_user_style.is_overridden(&"hovered_marker_sizes_px"):
		hovered_marker_sizes_px = p_user_style.hovered_marker_sizes_px
	if p_user_style.is_overridden(&"hovered_outline_width_px"):
		hovered_outline_width_px = p_user_style.hovered_outline_width_px
	if p_user_style.is_overridden(&"hovered_outline_color"):
		hovered_outline_color = p_user_style.hovered_outline_color
	if p_user_style.is_overridden(&"marker_shapes"):
		marker_shapes = p_user_style.marker_shapes


# Produces a fully resolved TauScatterStyle by applying all three cascade
# layers:
#   1. Start from defaults (a fresh TauScatterStyle instance).
#   2. Load theme values (non-indexed, then indexed for this pane).
#   3. Apply user overrides from p_user_style (may be null).
#   4. Report what the resolved combination cannot draw.
#
# The returned instance is a new TauScatterStyle owned by the caller. It is
# separate from p_user_style, which is never mutated.
static func resolve(p_control: Control, p_pane_index: int, p_user_style: TauScatterStyle) -> TauScatterStyle:
	# Layer 1: defaults.
	var resolved := TauScatterStyle.new()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control, p_pane_index)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	# Layer 4: report what the resolved combination cannot draw.
	resolved.validate_resolved()
	return resolved


# Reports the resolved property combinations that cannot be drawn as
# configured. An enum-typed array holds plain integers at runtime, so a cycle
# assigned from code can carry a value no shape answers to. The entry is left as
# it is, resolve_marker_shape() supplies what draws.
func validate_resolved() -> void:
	for i in marker_shapes.size():
		var shape := marker_shapes[i]
		if not _is_marker_shape(shape):
			push_error("TauScatterStyle: marker_shapes[%d] is %d, not a MarkerShape value. Using CIRCLE." % [i, shape])


# Returns a copy of this resource carrying the property values and the
# override flags. The flags are copied explicitly because
# Resource.duplicate() only copies stored properties.
func make_snapshot() -> TauScatterStyle:
	var copy := duplicate() as TauScatterStyle
	copy._copy_overrides_from(self)
	return copy


func is_equal_to(p_other: TauStyle) -> bool:
	var other := p_other as TauScatterStyle
	if other == null:
		return false
	if not super.is_equal_to(other):
		return false
	if marker_sizes_px != other.marker_sizes_px:
		return false
	if outline_width_px != other.outline_width_px:
		return false
	if outline_color != other.outline_color:
		return false
	if hovered_marker_sizes_px != other.hovered_marker_sizes_px:
		return false
	if hovered_outline_width_px != other.hovered_outline_width_px:
		return false
	if hovered_outline_color != other.hovered_outline_color:
		return false
	if marker_shapes != other.marker_shapes:
		return false
	return true


# All TauScatterStyle properties are visual-only. They control how markers are
# drawn within a fixed domain but do not affect domain, ticks, or pane rect.
func has_layout_affecting_change(p_other: TauScatterStyle) -> bool:
	return false


# COUNT is the shape count, not a shape, which rules out a plain membership
# test over MarkerShape.values(). NONE must stay the last member for this to
# hold.
static func _is_marker_shape(p_value: int) -> bool:
	return (p_value >= 0 and p_value < MarkerShape.COUNT) or p_value == MarkerShape.NONE


# Returns p_value as a MarkerShape, falling back to CIRCLE when it answers to
# no member. An enum-typed array, a theme constant and a per-sample buffer all
# hold plain integers, so every path that reads a shape goes through here and
# every one of them draws the same shape for a value out of range.
static func resolve_marker_shape(p_value: int) -> MarkerShape:
	if _is_marker_shape(p_value):
		return p_value as MarkerShape
	return MarkerShape.CIRCLE


# Theme constants are free-form integers, so a shape key may hold anything.
#
# An invalid value falls back to CIRCLE rather than skipping the position, so
# the surrounding scan keeps the index run the theme declared.
static func _resolve_theme_marker_shape(p_key: StringName, p_value: int) -> MarkerShape:
	if not _is_marker_shape(p_value):
		push_error("TauScatterStyle.load_from_theme(): theme constant '%s' is %d, not a MarkerShape value. Using CIRCLE." % [p_key, p_value])
	return resolve_marker_shape(p_value)

#endregion
