@tool

## Contains theme-driven visual parameters for line overlays.
##
## Properties set on this resource take the highest priority, always winning
## over the theme and the built-in defaults. A property counts as set as soon
## as it is assigned, whatever the value, so assigning a built-in default from
## code still beats the theme.
##
## Properties left untouched fall back to the Godot theme. If the theme does
## not define them either, the built-in defaults apply.
##
## For the per-series arrays other than [member fills], assign a new array to
## mark the property as set. Mutating the existing array in place does not.
## [member fills] needs no marking: it merges with the theme entry by entry.
##
## [b]Limitation:[/b] a property set from the inspector to exactly its built-in
## default is not written to the saved resource, so it reads as untouched on
## load and the theme still wins. Assign it from code instead.
class_name TauLineStyle extends Resource

################################################################################################
# WARNING: Any new member added to this class must be reflected in `is_equal_to()`,
#          `apply_overrides_from()`, and, if applicable, in
#          `has_layout_affecting_change()`.
################################################################################################

## Per-series cycle of line widths in pixels in the normal state. Each entry
## sets the line width for one series, with the array indexed cyclically by
## series index using modulo: series [code]i[/code] reads entry
## [code]i % line_widths_px.size()[/code]. An empty array is treated as all
## series rendered at [code]2.0[/code] pixels.
const DEFAULT_LINE_WIDTHS_PX: Array[float] = [2.0]
@export var line_widths_px: Array[float] = [2.0]:
	set(value):
		line_widths_px = value
		_overridden[&"line_widths_px"] = true

## Per-series cycle of line widths in pixels for the two segments adjacent to
## the hovered sample. Each entry sets the hovered width for one series, with
## the array indexed cyclically by series index using modulo: series
## [code]i[/code] reads entry [code]i % hovered_line_widths_px.size()[/code].
## An empty array means no hover emphasis: the segments adjacent to the
## hovered sample are drawn at the resolved [member line_widths_px] value for
## that series.
##
## At draw time, the resolved per-series hovered width is clamped to be at
## least the resolved per-series base width from [member line_widths_px], so
## a thicker series never becomes thinner on hover.
const DEFAULT_HOVERED_LINE_WIDTHS_PX: Array[float] = [3.0]
@export var hovered_line_widths_px: Array[float] = [3.0]:
	set(value):
		hovered_line_widths_px = value
		_overridden[&"hovered_line_widths_px"] = true

## Per-series dash length cycle, in pixels. Each entry sets the dash length
## for one series, with the array indexed cyclically by series index using
## modulo: series [code]i[/code] reads entry
## [code]i % dash_lengths_px.size()[/code]. An entry of [code]0[/code]
## produces a solid line for that series. Any positive entry switches that
## series to dashed rendering with alternating on-off segments of that pixel
## length. An empty array is treated as all series solid.
const DEFAULT_DASH_LENGTHS_PX: Array[int] = [0]
@export var dash_lengths_px: Array[int] = [0]:
	set(value):
		dash_lengths_px = value
		_overridden[&"dash_lengths_px"] = true

## Per-series cycle of [TauLineFill], indexed cyclically by series index
## using modulo.
##
## This property merges with the theme instead of replacing it. The resolved
## cycle is as long as the longer of the two cycles, both are read cyclically,
## and each resolved entry keeps every themed field the matching
## [TauLineFill] leaves unset. Leave the array empty to take the themed cycle
## as is, or use a null entry to leave one position to the theme.
const DEFAULT_FILLS: Array[TauLineFill] = []
@export var fills: Array[TauLineFill] = []:
	set(value):
		fills = value
		_overridden[&"fills"] = true


# Exported property names assigned at least once, whatever the value. Member
# initializers bypass the setters, so a fresh instance starts empty.
var _overridden: Dictionary[StringName, bool] = {}


# Shared instance returned by get_series_fill() when fills is empty or the
# series entry is null, so the renderer does not allocate one per series per
# frame. Read-only: callers must not mutate it.
#
# Built on first access rather than here. A static initializer runs while
# line_style.gd is being loaded, at which point TauLineFill is not
# guaranteed to be resolvable yet, and a static is initialized once and
# never retried.
static var _SHARED_DEFAULT_FILL: TauLineFill = null


####################################################################################################
# Helpers
####################################################################################################

## Returns the resolved line width in pixels for the given series index.
##
## An empty [member line_widths_px] returns the default
## [constant DEFAULT_LINE_WIDTHS_PX] entry. The result is clamped to be
## non-negative.
func get_series_width_px(p_series_index: int) -> float:
	if line_widths_px.is_empty():
		return DEFAULT_LINE_WIDTHS_PX[0]
	var entry: float = line_widths_px[p_series_index % line_widths_px.size()]
	return max(entry, 0.0)


## Returns the resolved hovered line width in pixels for the given series
## index. An empty [member hovered_line_widths_px] returns [code]0.0[/code]
## as a "no hover emphasis" sentinel. The result is later clamped against
## the per-series base width from [member line_widths_px] at draw time, so
## the empty-array case falls back to the base width and never produces a
## thinner line on hover.
func get_series_hovered_width_px(p_series_index: int) -> float:
	if hovered_line_widths_px.is_empty():
		return 0.0
	var entry: float = hovered_line_widths_px[p_series_index % hovered_line_widths_px.size()]
	return max(entry, 0.0)


## Returns the resolved dash length in pixels for the given series index.
func get_series_dash_px(p_series_index: int) -> int:
	if dash_lengths_px.is_empty():
		return 0
	var entry: int = dash_lengths_px[p_series_index % dash_lengths_px.size()]
	return max(entry, 0)


## Returns the resolved [TauLineFill] for the given series index.
##
## An empty [member fills] returns a shared instance at [TauLineFill]'s
## built-in defaults. The returned resource must be treated as read-only.
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


####################################################################################################
# Cascade: theme loading (layer 2)
####################################################################################################

## Loads properties from the Godot theme attached to [param p_control].
##
## The per-series array properties use a two-level indexed lookup at series
## granularity:
##   1. [code]<key>_N[/code] sets the value for series N across all panes.
##   2. [code]<key>_N_P[/code] overrides series N in pane P only.
##
## Theme key prefixes for the per-series arrays:
##   - [member line_widths_px]:         [code]line_width_px[/code]
##   - [member hovered_line_widths_px]: [code]line_hovered_width_px[/code]
##   - [member dash_lengths_px]:        [code]line_dash_px[/code]
##
## [member fills] uses the same two-level indexing, applied independently
## per [TauLineFill] field, so a theme may define more entries for one
## field than another:
##   - fill_mode:        [code]line_fill_mode[/code] (theme constant, an
##     integer [enum TauLineFill.FillMode] value)
##   - color:            [code]line_fill_color[/code] (theme color)
##   - alpha:            [code]line_fill_alpha_percent[/code] (theme
##     constant, percent integer, [code]100[/code] means [code]1.0[/code])
##   - texture:           [code]line_fill_texture[/code] (theme icon)
##   - texture_mode:      [code]line_fill_texture_mode[/code] (theme
##     constant, an integer [enum TauLineFill.FillTextureMode] value)
##   - stretch_span:      [code]line_fill_texture_stretch_span[/code] (theme
##     constant, an integer [enum TauLineFill.FillStretchSpan] value)
##   - tile_scale:        [code]line_fill_texture_scale_percent[/code]
##     (theme constant, percent integer, [code]100[/code] means
##     [code]1.0[/code])
##   - tile_rotation_deg: [code]line_fill_texture_rotation_deg[/code]
##     (theme constant, integer degrees)
##   - tile_offset_px:    [code]line_fill_texture_offset_px_x[/code] and
##     [code]line_fill_texture_offset_px_y[/code] (theme constants)
##
## Every property is written unconditionally. Properties without a matching
## theme entry keep their current value, so this method is safe to call on
## an instance already populated with defaults.
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
		global_widths.append(max(float(p_control.get_theme_constant(key)), 0.0))
		width_index += 1

	if not global_widths.is_empty():
		line_widths_px = global_widths

	var pane_width_index := 0
	while true:
		var key := "line_width_px_%d_%d" % [pane_width_index, p_pane_index]
		if not p_control.has_theme_constant(key):
			break
		# Grow the array if the per-pane theme defines more width entries than
		# the global theme (or the default).
		if pane_width_index >= line_widths_px.size():
			line_widths_px.resize(pane_width_index + 1)
		line_widths_px[pane_width_index] = max(float(p_control.get_theme_constant(key)), 0.0)
		pane_width_index += 1

	# hovered_line_widths_px: two-level indexed lookup, same pattern as
	# line_widths_px.
	var global_hovered: Array[float] = []
	var hovered_index := 0
	while true:
		var key := "line_hovered_width_px_%d" % hovered_index
		if not p_control.has_theme_constant(key):
			break
		global_hovered.append(max(float(p_control.get_theme_constant(key)), 0.0))
		hovered_index += 1

	if not global_hovered.is_empty():
		hovered_line_widths_px = global_hovered

	var pane_hovered_index := 0
	while true:
		var key := "line_hovered_width_px_%d_%d" % [pane_hovered_index, p_pane_index]
		if not p_control.has_theme_constant(key):
			break
		if pane_hovered_index >= hovered_line_widths_px.size():
			hovered_line_widths_px.resize(pane_hovered_index + 1)
		hovered_line_widths_px[pane_hovered_index] = max(float(p_control.get_theme_constant(key)), 0.0)
		pane_hovered_index += 1

	# dash_lengths_px: two-level indexed lookup, same pattern as
	# line_widths_px.
	var global_dashes: Array[int] = []
	var dash_index := 0
	while true:
		var key := "line_dash_px_%d" % dash_index
		if not p_control.has_theme_constant(key):
			break
		global_dashes.append(max(int(p_control.get_theme_constant(key)), 0))
		dash_index += 1

	if not global_dashes.is_empty():
		dash_lengths_px = global_dashes

	var pane_dash_index := 0
	while true:
		var key := "line_dash_px_%d_%d" % [pane_dash_index, p_pane_index]
		if not p_control.has_theme_constant(key):
			break
		if pane_dash_index >= dash_lengths_px.size():
			dash_lengths_px.resize(pane_dash_index + 1)
		dash_lengths_px[pane_dash_index] = max(int(p_control.get_theme_constant(key)), 0)
		pane_dash_index += 1

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
		fills[fill_mode_index].fill_mode = p_control.get_theme_constant(key) as TauLineFill.FillMode
		fill_mode_index += 1

	var pane_fill_mode_index := 0
	while true:
		var key := StringName("line_fill_mode_%d_%d" % [pane_fill_mode_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(pane_fill_mode_index + 1)
		fills[pane_fill_mode_index].fill_mode = p_control.get_theme_constant(key) as TauLineFill.FillMode
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
		fills[alpha_index].alpha = clampf(float(p_control.get_theme_constant(key)) / 100.0, 0.0, 1.0)
		alpha_index += 1

	var pane_alpha_index := 0
	while true:
		var key := StringName("line_fill_alpha_percent_%d_%d" % [pane_alpha_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(pane_alpha_index + 1)
		fills[pane_alpha_index].alpha = clampf(float(p_control.get_theme_constant(key)) / 100.0, 0.0, 1.0)
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
		fills[mode_index].texture_mode = p_control.get_theme_constant(key) as TauLineFill.FillTextureMode
		mode_index += 1

	var pane_mode_index := 0
	while true:
		var key := StringName("line_fill_texture_mode_%d_%d" % [pane_mode_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(pane_mode_index + 1)
		fills[pane_mode_index].texture_mode = p_control.get_theme_constant(key) as TauLineFill.FillTextureMode
		pane_mode_index += 1

	# stretch_span
	var span_index := 0
	while true:
		var key := StringName("line_fill_texture_stretch_span_%d" % span_index)
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(span_index + 1)
		fills[span_index].stretch_span = p_control.get_theme_constant(key) as TauLineFill.FillStretchSpan
		span_index += 1

	var pane_span_index := 0
	while true:
		var key := StringName("line_fill_texture_stretch_span_%d_%d" % [pane_span_index, p_pane_index])
		if not p_control.has_theme_constant(key):
			break
		_ensure_fills_min_size(pane_span_index + 1)
		fills[pane_span_index].stretch_span = p_control.get_theme_constant(key) as TauLineFill.FillStretchSpan
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


####################################################################################################
# Cascade: user overrides (layer 3)
####################################################################################################

## Returns [code]true[/code] when [param p_property] has been assigned on this
## resource, whatever the assigned value.
func is_overridden(p_property: StringName) -> bool:
	return _overridden.has(p_property)


## Applies overridden properties from [param p_user_style] onto this resolved
## instance. [member fills] merges per entry and per field, every other
## property replaces.
func apply_overrides_from(p_user_style: TauLineStyle) -> void:
	if p_user_style == null:
		return

	if p_user_style.is_overridden(&"line_widths_px"):
		line_widths_px = p_user_style.line_widths_px.duplicate()
	if p_user_style.is_overridden(&"hovered_line_widths_px"):
		hovered_line_widths_px = p_user_style.hovered_line_widths_px.duplicate()
	if p_user_style.is_overridden(&"dash_lengths_px"):
		dash_lengths_px = p_user_style.dash_lengths_px.duplicate()
	fills = _merge_fills(p_user_style.fills)


####################################################################################################
# Full cascade resolution
####################################################################################################

## Produces a fully resolved TauLineStyle by applying all three cascade layers:
##   1. Start from defaults (a fresh TauLineStyle instance).
##   2. Load theme values (non-indexed, then indexed for this pane).
##   3. Apply user overrides from [param p_user_style] (may be null).
##
## The returned instance is a new TauLineStyle owned by the caller.
## [param p_user_style] is never mutated.
static func resolve(
	p_control: Control,
	p_pane_index: int,
	p_user_style: TauLineStyle
) -> TauLineStyle:
	var resolved := TauLineStyle.new()
	resolved.load_from_theme(p_control, p_pane_index)
	resolved.apply_overrides_from(p_user_style)
	return resolved


####################################################################################################
# Change detection
####################################################################################################

## Returns a copy of this resource carrying the property values and the
## override flags. The flags are copied explicitly because
## [method Resource.duplicate] only copies stored properties.
func make_snapshot() -> TauLineStyle:
	var copy := duplicate() as TauLineStyle
	copy._copy_overrides_from(self)
	copy._copy_fills_from(self)
	return copy


# Writing a typed collection into another instance through a property is
# rejected at runtime, so the copy is made from inside the target.
func _copy_overrides_from(p_source: TauLineStyle) -> void:
	_overridden = p_source._overridden.duplicate()


# duplicate() gives the copy its own array but keeps the source's TauLineFill
# instances in it, so a fill mutated in place would be compared against itself.
# The entries are rebuilt one by one. Null entries are part of the contract and
# stay null. The texture stays shared, since it is a user asset compared by
# identity.
func _copy_fills_from(p_source: TauLineStyle) -> void:
	fills.resize(p_source.fills.size())
	for i in range(fills.size()):
		var source_fill: TauLineFill = p_source.fills[i]
		fills[i] = null if source_fill == null else source_fill.make_snapshot()


## Deep equality between this instance and [param p_other]. Compares every
## public property value-for-value, including the per-series arrays, plus the
## set of overridden property names.
func is_equal_to(p_other: TauLineStyle) -> bool:
	if p_other == null:
		return false
	if _overridden != p_other._overridden:
		return false
	if line_widths_px.size() != p_other.line_widths_px.size():
		return false
	for i in range(line_widths_px.size()):
		if line_widths_px[i] != p_other.line_widths_px[i]:
			return false
	if hovered_line_widths_px.size() != p_other.hovered_line_widths_px.size():
		return false
	for i in range(hovered_line_widths_px.size()):
		if hovered_line_widths_px[i] != p_other.hovered_line_widths_px[i]:
			return false
	if dash_lengths_px.size() != p_other.dash_lengths_px.size():
		return false
	for i in range(dash_lengths_px.size()):
		if dash_lengths_px[i] != p_other.dash_lengths_px[i]:
			return false
	if fills.size() != p_other.fills.size():
		return false
	for i in range(fills.size()):
		var fill: TauLineFill = fills[i]
		var other_fill: TauLineFill = p_other.fills[i]
		if fill == null:
			if other_fill != null:
				return false
			continue
		if not fill.is_equal_to(other_fill):
			return false
	return true


## Returns true if a change from [param p_other] to this instance would
## require the surrounding layout (domain, ticks, pane rect) to be
## recomputed. Always false: TauLineStyle properties only affect how lines
## are drawn within a fixed domain.
func has_layout_affecting_change(p_other: TauLineStyle) -> bool:
	return false


####################################################################################################
# Private
####################################################################################################

# Grows `fills` to at least p_min_size entries, filling any new slots with
# default-constructed TauLineFill instances.
func _ensure_fills_min_size(p_min_size: int) -> void:
	while fills.size() < p_min_size:
		fills.append(TauLineFill.new())


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
