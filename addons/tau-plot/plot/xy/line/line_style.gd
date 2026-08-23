@tool

## Contains theme-driven visual parameters for line overlays.
##
## Properties are resolved from the built-in defaults, the theme, and the values
## set here, in that order. The per-series arrays are read as cycles. See
## [TauStyle] for the details.
##
## [member fills] is the one exception to the array rule stated there. The other
## cycles on this class replace the themed one outright: assign
## [member line_widths_px] and every themed width is gone. A fill is merged
## instead, field by field, so it only has to carry what it changes.
##
## Say the theme fills every series with a gradient texture down to the baseline,
## and the only thing wrong is the opacity:
## [codeblock]
## var faded := TauLineFill.new()
## faded.alpha = 0.2
## line_style.fills = [faded]
## [/codeblock]
## The fill mode and the texture stay as the theme set them, because a
## [TauLineFill] tracks which of its own fields were assigned and leaves the rest
## to the theme. One entry is enough, since the cycle repeats it across every
## series.
##
## Theme type variation: TauLine
class_name TauLineStyle extends TauStyle

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()` and `validate_resolved()`.
################################################################################################

## Per-series cycle of line widths in pixels in the normal state. See
## [TauStyle] for how a cycle is indexed. An empty array is treated as all
## series rendered at [code]2.0[/code] pixels.
##
## An entry of [code]0[/code] draws no line for that series and leaves only
## its [TauLineFill], the way to get an area chart with no outline. Such a
## series still reports hover on its samples. A series with neither a line nor
## a fill paints nothing and answers no hover.
@export var line_widths_px: Array[float] = [2.0]:
	set(value):
		line_widths_px = _floored_floats(value, 0.0)
		_mark(&"line_widths_px")

## Per-series cycle of line widths in pixels for the two segments adjacent to
## the hovered sample. See [TauStyle] for how a cycle is indexed. An empty
## array means no hover emphasis: the segments adjacent to the hovered sample
## are drawn at the resolved [member line_widths_px] value for that series.
##
## At draw time, the resolved per-series hovered width is clamped to be at
## least the resolved per-series base width from [member line_widths_px], so
## a thicker series never becomes thinner on hover.
##
## A series whose base width is [code]0[/code] has no line to emphasize and
## ignores this property entirely: hovering it never makes a line appear.
@export var hovered_line_widths_px: Array[float] = [3.0]:
	set(value):
		hovered_line_widths_px = _floored_floats(value, 0.0)
		_mark(&"hovered_line_widths_px")

## Per-series dash length cycle, in pixels. See [TauStyle] for how a cycle is
## indexed. An entry of [code]0[/code] produces a solid line for that series.
## Any positive entry switches that series to dashed rendering with
## alternating on-off segments of that pixel length. An empty array is treated
## as all series solid.
@export var dash_lengths_px: Array[int] = [0]:
	set(value):
		dash_lengths_px = _floored_ints(value, 0)
		_mark(&"dash_lengths_px")

## Per-series cycle of [TauLineFill]. See [TauStyle] for how a cycle is
## indexed.
##
## Merges with the themed cycle rather than replacing it. The resolved
## cycle is as long as the longer of the two cycles, both are read cyclically,
## and each resolved entry keeps every themed field the matching
## [TauLineFill] leaves unset. Leave the array empty to take the themed cycle
## as is, or use a null entry to leave one position to the theme.
@export var fills: Array[TauLineFill] = []:
	set(value):
		_unrelay_fills()
		# The copy is of the cycle, not of the entries: a TauLineFill assigned
		# here stays the caller's until _merge_fills() rebuilds it.
		fills = value.duplicate()
		_relay_fills()
		# Not read by the cascade: _merge_fills() runs unconditionally. The flag
		# only feeds is_equal_to(), so a user first assigning fills registers as
		# a change.
		_mark(&"fills")


#region Internal, not public API, may change without notice.

# Shared instance returned by get_series_fill() when fills is empty or the
# series entry is null, so the renderer does not allocate one per series per
# frame. Read-only: callers must not mutate it.
#
# Built on first access rather than here. A static initializer runs while
# line_style.gd is being loaded, at which point TauLineFill is not
# guaranteed to be resolvable yet, and a static is initialized once and
# never retried.
static var _SHARED_DEFAULT_FILL: TauLineFill = null


# Returns the resolved line width in pixels for the given series index.
#
# An empty line_widths_px returns 2.0.
func get_series_width_px(p_series_index: int) -> float:
	if line_widths_px.is_empty():
		return 2.0
	return line_widths_px[p_series_index % line_widths_px.size()]


# Returns the resolved hovered line width in pixels for the given series
# index. An empty hovered_line_widths_px returns 0.0 as a "no hover emphasis"
# sentinel. The result is later clamped against the per-series base width from
# line_widths_px at draw time, so the empty-array case falls back to the base
# width and never produces a thinner line on hover.
func get_series_hovered_width_px(p_series_index: int) -> float:
	if hovered_line_widths_px.is_empty():
		return 0.0
	return hovered_line_widths_px[p_series_index % hovered_line_widths_px.size()]


# Returns the resolved dash length in pixels for the given series index.
func get_series_dash_length_px(p_series_index: int) -> int:
	if dash_lengths_px.is_empty():
		return 0
	return dash_lengths_px[p_series_index % dash_lengths_px.size()]


# Returns the resolved TauLineFill for the given series index.
#
# An empty fills returns a shared instance at TauLineFill's built-in defaults.
# The returned resource must be treated as read-only.
func get_series_fill(p_series_index: int) -> TauLineFill:
	if not fills.is_empty():
		var fill: TauLineFill = fills[p_series_index % fills.size()]
		if fill != null:
			return fill

	# An empty list or a null entry both mean this series takes the built-in
	# defaults.
	if _SHARED_DEFAULT_FILL == null:
		_SHARED_DEFAULT_FILL = TauLineFill.new()
	return _SHARED_DEFAULT_FILL


# Loads properties from the Godot theme attached to p_control.
#
# The per-series arrays use the two-level cycle keys described in TauStyle.
#
# Theme key prefixes for the per-series arrays:
#   - line_widths_px:         line_width_px
#   - hovered_line_widths_px: line_hovered_width_px
#   - dash_lengths_px:        line_dash_px
#
# fills uses the same two-level keys, applied independently per TauLineFill
# field, so a theme may define more entries for one field than another:
#   - fill_mode:        line_fill_mode (theme constant, an integer
#     TauLineFill.FillMode value)
#   - color:            line_fill_color (theme color)
#   - alpha:            line_fill_alpha_percent (theme constant, percent
#     integer, 100 means 1.0)
#   - texture:           line_fill_texture (theme icon)
#   - texture_mode:      line_fill_texture_mode (theme constant, an integer
#     TauLineFill.FillTextureMode value)
#   - stretch_span:      line_fill_texture_stretch_span (theme constant, an
#     integer TauLineFill.FillStretchSpan value)
#   - tile_scale:        line_fill_texture_scale_percent (theme constant,
#     percent integer, 100 means 1.0)
#   - tile_rotation_deg: line_fill_texture_rotation_deg (theme constant,
#     integer degrees)
#   - tile_offset_px:    line_fill_texture_offset_px_x and
#     line_fill_texture_offset_px_y (theme constants)
#
# Values are written without consulting the override marks, because this runs
# on the resolved instance, not on the user-provided resource. A property with
# no matching theme entry keeps the value it already holds.
#
# A constant holding a value outside the enum it feeds is reported and
# replaced by that enum's default, keeping the cycle the length the theme
# declared.
func load_from_theme(p_control: Control, p_pane_index: int) -> void:
	if p_control == null:
		push_error("TauLineStyle.load_from_theme(): control is null")
		return

	# line_widths_px: two-level indexed lookup. Level 1 sets values across all
	# panes. Level 2 overrides per pane.
	var global_widths: Array[float] = []
	var width_index := 0
	while true:
		var key := "line_width_px_%d" % width_index
		if not p_control.has_theme_constant(key):
			break
		global_widths.append(float(p_control.get_theme_constant(key)))
		width_index += 1

	if not global_widths.is_empty():
		line_widths_px = global_widths

	# Built aside and assigned whole, so the entries pass through the setter.
	var pane_widths := line_widths_px.duplicate()
	var pane_width_index := 0
	while true:
		var key := "line_width_px_%d_%d" % [pane_width_index, p_pane_index]
		if not p_control.has_theme_constant(key):
			break
		# Grow the array if the per-pane theme defines more width entries than
		# the global theme (or the default).
		if pane_width_index >= pane_widths.size():
			pane_widths.resize(pane_width_index + 1)
		pane_widths[pane_width_index] = float(p_control.get_theme_constant(key))
		pane_width_index += 1

	if pane_width_index > 0:
		line_widths_px = pane_widths

	# hovered_line_widths_px: two-level indexed lookup, same pattern as
	# line_widths_px.
	var global_hovered: Array[float] = []
	var hovered_index := 0
	while true:
		var key := "line_hovered_width_px_%d" % hovered_index
		if not p_control.has_theme_constant(key):
			break
		global_hovered.append(float(p_control.get_theme_constant(key)))
		hovered_index += 1

	if not global_hovered.is_empty():
		hovered_line_widths_px = global_hovered

	var pane_hovered_widths := hovered_line_widths_px.duplicate()
	var pane_hovered_index := 0
	while true:
		var key := "line_hovered_width_px_%d_%d" % [pane_hovered_index, p_pane_index]
		if not p_control.has_theme_constant(key):
			break
		if pane_hovered_index >= pane_hovered_widths.size():
			pane_hovered_widths.resize(pane_hovered_index + 1)
		pane_hovered_widths[pane_hovered_index] = float(p_control.get_theme_constant(key))
		pane_hovered_index += 1

	if pane_hovered_index > 0:
		hovered_line_widths_px = pane_hovered_widths

	# dash_lengths_px: two-level indexed lookup, same pattern as
	# line_widths_px.
	var global_dashes: Array[int] = []
	var dash_index := 0
	while true:
		var key := "line_dash_px_%d" % dash_index
		if not p_control.has_theme_constant(key):
			break
		global_dashes.append(int(p_control.get_theme_constant(key)))
		dash_index += 1

	if not global_dashes.is_empty():
		dash_lengths_px = global_dashes

	var pane_dashes := dash_lengths_px.duplicate()
	var pane_dash_index := 0
	while true:
		var key := "line_dash_px_%d_%d" % [pane_dash_index, p_pane_index]
		if not p_control.has_theme_constant(key):
			break
		if pane_dash_index >= pane_dashes.size():
			pane_dashes.resize(pane_dash_index + 1)
		pane_dashes[pane_dash_index] = int(p_control.get_theme_constant(key))
		pane_dash_index += 1

	if pane_dash_index > 0:
		dash_lengths_px = pane_dashes

	# fills: every field uses the same two-level indexed lookup as
	# line_widths_px, applied per series entry of `fills` instead of a
	# single scalar or array. Each field scans its series index
	# independently, growing `fills` as needed, so a theme may define more
	# entries for one field than another.

	# fill_mode
	var fill_mode_index := 0
	while true:
		var key := StringName("line_fill_mode_%d" % fill_mode_index)
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(fill_mode_index + 1)
		fills[fill_mode_index].fill_mode = _resolve_theme_fill_mode(key, p_control.get_theme_constant(key))
		fill_mode_index += 1

	var pane_fill_mode_index := 0
	while true:
		var key := StringName("line_fill_mode_%d_%d" % [pane_fill_mode_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(pane_fill_mode_index + 1)
		fills[pane_fill_mode_index].fill_mode = _resolve_theme_fill_mode(key, p_control.get_theme_constant(key))
		pane_fill_mode_index += 1

	# color
	var color_index := 0
	while true:
		var key := StringName("line_fill_color_%d" % color_index)
		if not p_control.has_theme_color(key):
			break
		_ensure_fills_min_size(color_index + 1)
		fills[color_index].color = p_control.get_theme_color(key)
		color_index += 1

	var pane_color_index := 0
	while true:
		var key := StringName("line_fill_color_%d_%d" % [pane_color_index, p_pane_index])
		if not p_control.has_theme_color(key):
			break
		_ensure_fills_min_size(pane_color_index + 1)
		fills[pane_color_index].color = p_control.get_theme_color(key)
		pane_color_index += 1

	# alpha: theme constants are integers, so the value is stored as a
	# percent (100 means 1.0).
	var alpha_index := 0
	while true:
		var key := StringName("line_fill_alpha_percent_%d" % alpha_index)
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(alpha_index + 1)
		fills[alpha_index].alpha = float(p_control.get_theme_constant(key)) / 100.0
		alpha_index += 1

	var pane_alpha_index := 0
	while true:
		var key := StringName("line_fill_alpha_percent_%d_%d" % [pane_alpha_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(pane_alpha_index + 1)
		fills[pane_alpha_index].alpha = float(p_control.get_theme_constant(key)) / 100.0
		pane_alpha_index += 1

	# texture
	var texture_index := 0
	while true:
		var key := StringName("line_fill_texture_%d" % texture_index)
		if not p_control.has_theme_icon(key):
			break
		_ensure_fills_min_size(texture_index + 1)
		fills[texture_index].texture = p_control.get_theme_icon(key)
		texture_index += 1

	var pane_texture_index := 0
	while true:
		var key := StringName("line_fill_texture_%d_%d" % [pane_texture_index, p_pane_index])
		if not p_control.has_theme_icon(key):
			break
		_ensure_fills_min_size(pane_texture_index + 1)
		fills[pane_texture_index].texture = p_control.get_theme_icon(key)
		pane_texture_index += 1

	# texture_mode
	var mode_index := 0
	while true:
		var key := StringName("line_fill_texture_mode_%d" % mode_index)
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(mode_index + 1)
		fills[mode_index].texture_mode = _resolve_theme_fill_texture_mode(key, p_control.get_theme_constant(key))
		mode_index += 1

	var pane_mode_index := 0
	while true:
		var key := StringName("line_fill_texture_mode_%d_%d" % [pane_mode_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(pane_mode_index + 1)
		fills[pane_mode_index].texture_mode = _resolve_theme_fill_texture_mode(key, p_control.get_theme_constant(key))
		pane_mode_index += 1

	# stretch_span
	var span_index := 0
	while true:
		var key := StringName("line_fill_texture_stretch_span_%d" % span_index)
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(span_index + 1)
		fills[span_index].stretch_span = _resolve_theme_fill_stretch_span(key, p_control.get_theme_constant(key))
		span_index += 1

	var pane_span_index := 0
	while true:
		var key := StringName("line_fill_texture_stretch_span_%d_%d" % [pane_span_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(pane_span_index + 1)
		fills[pane_span_index].stretch_span = _resolve_theme_fill_stretch_span(key, p_control.get_theme_constant(key))
		pane_span_index += 1

	# tile_scale: stored as a percent (100 means 1.0).
	var scale_index := 0
	while true:
		var key := StringName("line_fill_texture_scale_percent_%d" % scale_index)
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(scale_index + 1)
		fills[scale_index].tile_scale = float(p_control.get_theme_constant(key)) / 100.0
		scale_index += 1

	var pane_scale_index := 0
	while true:
		var key := StringName("line_fill_texture_scale_percent_%d_%d" % [pane_scale_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(pane_scale_index + 1)
		fills[pane_scale_index].tile_scale = float(p_control.get_theme_constant(key)) / 100.0
		pane_scale_index += 1

	# tile_rotation_deg
	var rotation_index := 0
	while true:
		var key := StringName("line_fill_texture_rotation_deg_%d" % rotation_index)
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(rotation_index + 1)
		fills[rotation_index].tile_rotation_deg = float(p_control.get_theme_constant(key))
		rotation_index += 1

	var pane_rotation_index := 0
	while true:
		var key := StringName("line_fill_texture_rotation_deg_%d_%d" % [pane_rotation_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(pane_rotation_index + 1)
		fills[pane_rotation_index].tile_rotation_deg = float(p_control.get_theme_constant(key))
		pane_rotation_index += 1

	# tile_offset_px: x and y are separate theme keys.
	var offset_x_index := 0
	while true:
		var key := StringName("line_fill_texture_offset_px_x_%d" % offset_x_index)
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(offset_x_index + 1)
		var offset := fills[offset_x_index].tile_offset_px
		offset.x = float(p_control.get_theme_constant(key))
		fills[offset_x_index].tile_offset_px = offset
		offset_x_index += 1

	var pane_offset_x_index := 0
	while true:
		var key := StringName("line_fill_texture_offset_px_x_%d_%d" % [pane_offset_x_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(pane_offset_x_index + 1)
		var offset := fills[pane_offset_x_index].tile_offset_px
		offset.x = float(p_control.get_theme_constant(key))
		fills[pane_offset_x_index].tile_offset_px = offset
		pane_offset_x_index += 1

	var offset_y_index := 0
	while true:
		var key := StringName("line_fill_texture_offset_px_y_%d" % offset_y_index)
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(offset_y_index + 1)
		var offset := fills[offset_y_index].tile_offset_px
		offset.y = float(p_control.get_theme_constant(key))
		fills[offset_y_index].tile_offset_px = offset
		offset_y_index += 1

	var pane_offset_y_index := 0
	while true:
		var key := StringName("line_fill_texture_offset_px_y_%d_%d" % [pane_offset_y_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(pane_offset_y_index + 1)
		var offset := fills[pane_offset_y_index].tile_offset_px
		offset.y = float(p_control.get_theme_constant(key))
		fills[pane_offset_y_index].tile_offset_px = offset
		pane_offset_y_index += 1


# Applies overridden properties from p_user_style onto this resolved
# instance. fills merges per entry and per field, every other property
# replaces.
func apply_overrides_from(p_user_style: TauLineStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.is_overridden(&"line_widths_px"):
		line_widths_px = p_user_style.line_widths_px
	if p_user_style.is_overridden(&"hovered_line_widths_px"):
		hovered_line_widths_px = p_user_style.hovered_line_widths_px
	if p_user_style.is_overridden(&"dash_lengths_px"):
		dash_lengths_px = p_user_style.dash_lengths_px
	fills = _merge_fills(p_user_style.fills)


# Produces a fully resolved TauLineStyle by applying all three cascade layers:
#   1. Start from defaults (a fresh TauLineStyle instance).
#   2. Load theme values (non-indexed, then indexed for this pane).
#   3. Apply user overrides from p_user_style (may be null).
#   4. Report what the resolved combination cannot draw.
#
# The returned instance is a new TauLineStyle owned by the caller.
# p_user_style is never mutated.
static func resolve(p_control: Control, p_pane_index: int, p_user_style: TauLineStyle) -> TauLineStyle:
	# Layer 1: defaults.
	var resolved := TauLineStyle.new()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control, p_pane_index)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	# Layer 4: report what the resolved combination cannot draw.
	resolved.validate_resolved()
	return resolved


# Reports the resolved property combinations that cannot be drawn as
# configured, and carries the pass into the fill cycle, which has no resolve()
# of its own. A resolved cycle holds a fill at every position, since
# _merge_fills() rebuilds them all, so the null entries the user may write are
# already gone.
func validate_resolved() -> void:
	for fill in fills:
		fill.validate_resolved()

	if _paints_nothing():
		push_warning("TauLineStyle: every line width is 0 and no series is filled, the overlay paints nothing")


# True when no series has a line to stroke nor an area to fill. An empty
# line_widths_px falls back to a non-zero width, and an empty fills falls back
# to a NONE fill, so neither empty cycle can blank the overlay on its own.
func _paints_nothing() -> bool:
	if line_widths_px.is_empty():
		return false
	for width_px in line_widths_px:
		if width_px > 0.0:
			return false
	for fill in fills:
		if fill.fill_mode != TauLineFill.FillMode.NONE:
			return false
	return true


# Returns a copy of this resource carrying the property values and the
# override flags. The flags are copied explicitly because
# Resource.duplicate() only copies stored properties.
func make_snapshot() -> TauLineStyle:
	var copy := duplicate() as TauLineStyle
	copy._copy_overrides_from(self)
	copy._copy_fills_from(self)
	return copy


# duplicate() gives the copy its own array but keeps the source's TauLineFill
# instances in it, so a fill mutated in place would be compared against itself.
# The entries are rebuilt one by one. Null entries are part of the contract and
# stay null. The texture stays shared, since it is a user asset compared by
# identity.
#
# Built aside and assigned whole: duplicate() ran the setter with the source's
# entries, so the copy relays them until the assignment swaps the relays over to
# its own.
func _copy_fills_from(p_source: TauLineStyle) -> void:
	var copies: Array[TauLineFill] = []
	copies.resize(p_source.fills.size())
	for i in range(copies.size()):
		var source_fill: TauLineFill = p_source.fills[i]
		copies[i] = null if source_fill == null else source_fill.make_snapshot()
	fills = copies


# Deep equality between this instance and p_other. Compares every public
# property value-for-value, including the per-series arrays, plus the set of
# overridden property names.
func is_equal_to(p_other: TauStyle) -> bool:
	var other := p_other as TauLineStyle
	if other == null:
		return false
	if not super.is_equal_to(other):
		return false
	if line_widths_px != other.line_widths_px:
		return false
	if hovered_line_widths_px != other.hovered_line_widths_px:
		return false
	if dash_lengths_px != other.dash_lengths_px:
		return false
	# Array equality compares object entries by identity, so the fill cycle is
	# compared entry by entry to reach the field values and the override flags.
	if fills.size() != other.fills.size():
		return false
	for i in range(fills.size()):
		var fill: TauLineFill = fills[i]
		var other_fill: TauLineFill = other.fills[i]
		if fill == null:
			if other_fill != null:
				return false
			continue
		if not fill.is_equal_to(other_fill):
			return false
	return true


# Returns true if a change from p_other to this instance would require the
# surrounding layout (domain, ticks, pane rect) to be recomputed. Always
# false: TauLineStyle properties only affect how lines are drawn within a
# fixed domain.
func has_layout_affecting_change(p_other: TauLineStyle) -> bool:
	return false


# Theme constants are free-form integers, so a key feeding a TauLineFill enum
# may hold anything. None of the three enums carries a sentinel member, so
# membership is tested directly.
#
# An invalid value falls back to the enum's default rather than skipping the
# position, so the surrounding scan keeps the index run the theme declared.
static func _resolve_theme_fill_mode(p_key: StringName, p_value: int) -> TauLineFill.FillMode:
	if TauLineFill.FillMode.values().has(p_value):
		return p_value as TauLineFill.FillMode

	push_error("TauLineStyle.load_from_theme(): theme constant '%s' is %d, not a TauLineFill.FillMode value. Using NONE." % [p_key, p_value])
	return TauLineFill.FillMode.NONE


static func _resolve_theme_fill_texture_mode(p_key: StringName, p_value: int) -> TauLineFill.FillTextureMode:
	if TauLineFill.FillTextureMode.values().has(p_value):
		return p_value as TauLineFill.FillTextureMode

	push_error("TauLineStyle.load_from_theme(): theme constant '%s' is %d, not a TauLineFill.FillTextureMode value. Using STRETCH." % [p_key, p_value])
	return TauLineFill.FillTextureMode.STRETCH


static func _resolve_theme_fill_stretch_span(p_key: StringName, p_value: int) -> TauLineFill.FillStretchSpan:
	if TauLineFill.FillStretchSpan.values().has(p_value):
		return p_value as TauLineFill.FillStretchSpan

	push_error("TauLineStyle.load_from_theme(): theme constant '%s' is %d, not a TauLineFill.FillStretchSpan value. Using LINE." % [p_key, p_value])
	return TauLineFill.FillStretchSpan.LINE


# A fill has no listener of its own, so its changed signal is forwarded as a
# change of the style holding it. The same TauLineFill may sit at several
# positions of the cycle, hence the connection test.
func _relay_fills() -> void:
	for fill in fills:
		if fill != null and not fill.changed.is_connected(emit_changed):
			fill.changed.connect(emit_changed)


# Drops the relays of the cycle being replaced. Called before `fills` is
# reassigned, never on the incoming array.
func _unrelay_fills() -> void:
	for fill in fills:
		if fill != null and fill.changed.is_connected(emit_changed):
			fill.changed.disconnect(emit_changed)


# Grows `fills` to at least p_min_size entries, filling any new slots with
# default-constructed TauLineFill instances.
#
# The theme loads fills field by field at both levels, so the plot-wide level
# patches where the other cycles replace. That only coincides with a replace
# because the built-in default of `fills` is empty. Keep it empty.
func _ensure_fills_min_size(p_min_size: int) -> void:
	while fills.size() < p_min_size:
		fills.append(TauLineFill.new())
	_relay_fills()


# Merges the themed cycle already in `fills` with p_user_fills into the
# resolved cycle. Both sides are read modulo their own size over a resolved
# length of max(sizes), so neither is a sparse patch table and the shorter one
# repeats.
#
# Every entry is built fresh. A themed entry lands at several resolved
# positions when the cycles differ in length, and each of them may merge a
# different user entry on top, so they cannot share one instance. Building
# fresh also keeps the resolved style from sharing a TauLineFill with the
# user's resource.
func _merge_fills(p_user_fills: Array[TauLineFill]) -> Array[TauLineFill]:
	var themed_count := fills.size()
	var user_count := p_user_fills.size()
	var merged: Array[TauLineFill] = []
	merged.resize(maxi(themed_count, user_count))
	for i in range(merged.size()):
		var entry: TauLineFill
		if themed_count == 0:
			entry = TauLineFill.new()
		else:
			entry = fills[i % themed_count].duplicate() as TauLineFill
		if user_count > 0:
			entry.apply_overrides_from(p_user_fills[i % user_count])
		merged[i] = entry
	return merged

#endregion
