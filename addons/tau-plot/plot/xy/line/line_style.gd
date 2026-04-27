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

const DEFAULT_LINE_WIDTH_PX: float = 2.0
@export var line_width_px: float = DEFAULT_LINE_WIDTH_PX

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
## For scalar properties, the non-indexed theme key is fetched first (shared
## base for all panes), then the indexed key for [param p_pane_index]
## overwrites it if present.
##
## For [code]dash_lengths_px[/code], the same convention applies at series
## granularity:
##   1. [code]line_dash_px_N[/code] sets the dash length for series N across
##      all panes.
##   2. [code]line_dash_px_N_P[/code] overrides series N in pane P only.
##
## This method writes every property unconditionally because it is called on
## the resolved instance, not on the user-provided resource.
func load_from_theme(p_control: Control, p_pane_index: int) -> void:
	if p_control == null:
		push_error("TauLineStyle.load_from_theme(): control is null")
		return

	# line_width_px
	if p_control.has_theme_constant(&"line_width_px"):
		line_width_px = max(float(p_control.get_theme_constant(&"line_width_px")), 0.0)
	var indexed_width_key := StringName("line_width_px_%d" % p_pane_index)
	if p_control.has_theme_constant(indexed_width_key):
		line_width_px = max(float(p_control.get_theme_constant(indexed_width_key)), 0.0)

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

	if p_user_style.line_width_px != DEFAULT_LINE_WIDTH_PX:
		line_width_px = p_user_style.line_width_px

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
	if line_width_px != p_other.line_width_px:
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

## Returns true if [param p_dashes] differs from DEFAULT_DASH_LENGTHS_PX using
## a size + element loop (safest approach for typed arrays in GDScript).
static func _is_dash_lengths_overridden(p_dashes: Array[int]) -> bool:
	if p_dashes.size() != DEFAULT_DASH_LENGTHS_PX.size():
		return true
	for i in range(p_dashes.size()):
		if p_dashes[i] != DEFAULT_DASH_LENGTHS_PX[i]:
			return true
	return false
