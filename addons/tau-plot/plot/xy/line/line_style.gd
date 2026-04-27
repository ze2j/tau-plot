## Contains theme-driven visual parameters for line overlays.
##
## Properties set on this resource take the highest priority, always winning
## over the theme and the built-in defaults.
##
## Properties left untouched fall back to the Godot theme. If the theme does
## not define them either, the built-in defaults apply.
##
## [b]Limitation:[/b] because "untouched" means "still equal to the built-in
## default", setting a property to exactly its default value has no visible
## effect. To force the default value to win over a theme, use an imperceptibly
## different value (e.g. 2.001 instead of 2.0).
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
@export var line_widths_px: Array[float] = [2.0]

## Per-series dash length cycle, in pixels. Each entry sets the dash length
## for one series, with the array indexed cyclically by series index using
## modulo: series [code]i[/code] reads entry
## [code]i % dash_lengths_px.size()[/code]. An entry of [code]0[/code]
## produces a solid line for that series. Any positive entry switches that
## series to dashed rendering with alternating on-off segments of that pixel
## length. An empty array is treated as all series solid.
const DEFAULT_DASH_LENGTHS_PX: Array[int] = [0]
@export var dash_lengths_px: Array[int] = [0]


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


## Returns the resolved dash length in pixels for the given series index.
func get_series_dash_px(p_series_index: int) -> int:
	if dash_lengths_px.is_empty():
		return 0
	var entry: int = dash_lengths_px[p_series_index % dash_lengths_px.size()]
	return max(entry, 0)


####################################################################################################
# Cascade: theme loading (layer 2)
####################################################################################################

## Loads properties from the Godot theme attached to [param p_control].
##
## All properties on this resource are per-series arrays. For each, a
## two-level indexed lookup applies at series granularity:
##   1. [code]<key>_N[/code] sets the value for series N across all panes.
##   2. [code]<key>_N_P[/code] overrides series N in pane P only.
##
## For [code]line_widths_px[/code] the keys are [code]line_width_px_N[/code]
## and [code]line_width_px_N_P[/code]. For [code]dash_lengths_px[/code] they
## are [code]line_dash_px_N[/code] and [code]line_dash_px_N_P[/code].
##
## This method writes every property unconditionally because it is called on
## the resolved instance, not on the user-provided resource.
func load_from_theme(p_control: Control, p_pane_index: int) -> void:
	if p_control == null:
		push_error("TauLineStyle.load_from_theme(): control is null")
		return

	# line_widths_px: two-level indexed lookup.
	# Level 1 (global): line_width_px_N
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

	# Level 2 (per-pane): line_width_px_N_P overrides series N in pane P.
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

	# dash_lengths_px: two-level indexed lookup.
	# Level 1 (global): line_dash_px_N
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

	# Level 2 (per-pane): line_dash_px_N_P overrides series N in pane P.
	var pane_dash_index := 0
	while true:
		var key := "line_dash_px_%d_%d" % [pane_dash_index, p_pane_index]
		if not p_control.has_theme_constant(key):
			break
		# Grow the array if the per-pane theme defines more dash entries than
		# the global theme (or the default).
		if pane_dash_index >= dash_lengths_px.size():
			dash_lengths_px.resize(pane_dash_index + 1)
		dash_lengths_px[pane_dash_index] = max(int(p_control.get_theme_constant(key)), 0)
		pane_dash_index += 1


####################################################################################################
# Cascade: user overrides (layer 3)
####################################################################################################

## Applies overridden properties from [param p_user_style] onto this resolved
## instance. A property is considered overridden when its value on the user
## resource differs from the matching DEFAULT_* constant.
func apply_overrides_from(p_user_style: TauLineStyle) -> void:
	if p_user_style == null:
		return

	# line_widths_px: element-wise comparison against the default array.
	if _is_line_widths_overridden(p_user_style.line_widths_px):
		line_widths_px = p_user_style.line_widths_px.duplicate()

	# dash_lengths_px: element-wise comparison against the default array.
	if _is_dash_lengths_overridden(p_user_style.dash_lengths_px):
		dash_lengths_px = p_user_style.dash_lengths_px.duplicate()


####################################################################################################
# Full cascade resolution
####################################################################################################

## Produces a fully resolved TauLineStyle by applying all three cascade layers:
##   1. Start from defaults (a fresh TauLineStyle instance).
##   2. Load theme values (non-indexed, then indexed for this pane).
##   3. Apply user overrides from [param p_user_style] (may be null).
##
## The returned instance is a new TauLineStyle owned by the caller. It is
## separate from [param p_user_style] which is never mutated.
static func resolve(
	p_control: Control,
	p_pane_index: int,
	p_user_style: TauLineStyle
) -> TauLineStyle:
	# Layer 1: defaults.
	var resolved := TauLineStyle.new()
	# Layer 2: theme values.
	resolved.load_from_theme(p_control, p_pane_index)
	# Layer 3: user overrides.
	resolved.apply_overrides_from(p_user_style)
	return resolved


####################################################################################################
# Change detection
####################################################################################################

func is_equal_to(p_other: TauLineStyle) -> bool:
	if p_other == null:
		return false
	if line_widths_px.size() != p_other.line_widths_px.size():
		return false
	for i in range(line_widths_px.size()):
		if line_widths_px[i] != p_other.line_widths_px[i]:
			return false
	if dash_lengths_px.size() != p_other.dash_lengths_px.size():
		return false
	for i in range(dash_lengths_px.size()):
		if dash_lengths_px[i] != p_other.dash_lengths_px[i]:
			return false
	return true


# All TauLineStyle properties are visual-only. They control how lines are
# drawn within a fixed domain but do not affect domain, ticks, or pane rect.
func has_layout_affecting_change(p_other: TauLineStyle) -> bool:
	return false


####################################################################################################
# Private
####################################################################################################

## Returns true if [param p_widths] differs from DEFAULT_LINE_WIDTHS_PX using
## a size + element loop (safest approach for typed arrays in GDScript).
static func _is_line_widths_overridden(p_widths: Array[float]) -> bool:
	if p_widths.size() != DEFAULT_LINE_WIDTHS_PX.size():
		return true
	for i in range(p_widths.size()):
		if p_widths[i] != DEFAULT_LINE_WIDTHS_PX[i]:
			return true
	return false


## Returns true if [param p_dashes] differs from DEFAULT_DASH_LENGTHS_PX using
## a size + element loop (safest approach for typed arrays in GDScript).
static func _is_dash_lengths_overridden(p_dashes: Array[int]) -> bool:
	if p_dashes.size() != DEFAULT_DASH_LENGTHS_PX.size():
		return true
	for i in range(p_dashes.size()):
		if p_dashes[i] != DEFAULT_DASH_LENGTHS_PX[i]:
			return true
	return false
