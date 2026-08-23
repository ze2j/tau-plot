@tool

## Base class of the style resources, holding the rules every one of them follows.
##
## A style resource carries the visual parameters of one part of the plot. The
## plot never reads those parameters straight off the resource. It resolves them
## first, through three layers:
##
## 1. The built-in defaults, the values a fresh instance of the style starts with.
## 2. The Godot theme attached to the plot.
## 3. The properties set on the style resource handed to the plot.
##
## A later layer wins over the ones before it. Leave a property alone and the
## theme decides. Leave it out of the theme too and the built-in default stands.
##
## [b]What counts as set[/b]
##
## A property counts as set as soon as it is assigned, whatever the value.
## Assigning a built-in default from code still beats the theme:
## [codeblock]
## var style := TauXYStyle.new()
## style.pane_gap_px = 4
## [/codeblock]
## [code]4[/code] is also the built-in default, and the theme has now lost that
## property anyway.
##
## What marks an array property is the assignment, not the contents. Assign a
## new array to mark it. Changing an entry of the array already in place leaves
## the property unmarked and the theme overwrites it, so it is not a way to set
## a cycle:
## [codeblock]
## style.series_colors = [Color.GREEN]      # Marked, this wins.
## style.series_colors[0] = Color.GREEN     # Avoid, not marked, the theme wins.
## [/codeblock]
##
## A cycle is stored as a copy of the array assigned to it, so changing that
## array afterwards leaves the style alone. Reading the property back gives the
## stored array, which the second line above changes in place.
##
## A property holding another resource, such as a [StyleBox], a [Font] or a
## [Texture2D], follows the same rule. Assign a new one to change it. One
## changed in place is not marked and not picked up:
## [codeblock]
## style.style_box = new_box                # Marked, this wins.
## style.style_box.bg_color = Color.GREEN   # Avoid, not marked, no repaint.
## [/codeblock]
##
## [b]Empty values[/b]
##
## [code]null[/code] and the empty array are values, not a way to defer to the
## theme. Assigning one marks the property like any other assignment, and what
## it draws is stated on the property: a named default for the properties that
## carry a mark of their own, or the value they fall back on for the ones that
## sit on top of another. Neither is ever an error, and neither removes the mark.
##
## [b]Valid ranges[/b]
##
## A property with a valid range clamps into it on assignment, so a value out of
## range is never observed, whichever layer it comes from. A cycle is clamped
## entry by entry as it is stored. An entry changed in place goes around the
## setter and keeps what it was given, which is a second reason to assign a new
## array instead.
##
## [b]Reported problems[/b]
##
## A range covers one property. A combination of resolved values that cannot be
## drawn, such as a fill left with nothing to paint, is reported as a warning or
## an error once the three layers have been applied, so it is raised once per
## plot build rather than once per frame.
##
## [b]Cycles[/b]
##
## Some properties are arrays holding one entry per series, such as
## [member TauXYStyle.series_colors] or [member TauLineStyle.line_widths_px].
## The array does not have to match the number of series in the dataset. It is
## read as a cycle: series [code]i[/code] uses entry [code]i % size[/code].
##
## A shorter array repeats from the start, a longer one leaves its extra entries
## unused, and an empty array means every series falls back to the property's
## built-in default. Nothing has to be kept in sync with the dataset.
## [codeblock]
## style.series_colors = [Color.RED, Color.BLUE, Color.GREEN]
## [/codeblock]
## Six series drawn with that cycle come out red, blue, green, red, blue, green.
##
## [b]Theme keys[/b]
##
## The theme layer reads one key per property. A scalar property has a plain key,
## and adding a pane index aims that key at a single pane:
## [codeblock lang=text]
## bar_width_px      the bar width, everywhere
## bar_width_px_2    the bar width in the third pane
## [/codeblock]
##
## A cycle is an array, and a theme cannot hold an array, so its entries are
## written one key at a time. The number at the end of the key is the cycle
## index:
## [codeblock lang=text]
## line_width_px_0   first width
## line_width_px_1   second width
## line_width_px_2   third width
## [/codeblock]
## Those three keys build a cycle of three widths, used everywhere. Series 0
## takes the first width, series 1 the second, series 2 the third, series 3 the
## first again.
##
## A second number aims one of those entries at a single pane, the same way it
## does for a scalar:
## [codeblock lang=text]
## line_width_px_1_2   second width, in the third pane
## [/codeblock]
## The other two widths, and every other pane, keep what they had.
##
## [b]Notes[/b]
##
## [b]A cycle key always carries an index.[/b] There is no
## [code]line_width_px[/code] on its own. [code]line_width_px_0[/code] already
## covers every pane, so a cycle has no un-indexed key.
##
## [b]Cycle indices must be contiguous.[/b] The theme is read index by index and
## stops at the first one it does not define, so the indices have to run from
## [code]0[/code] with no gap. A theme defining [code]series_color_0[/code] and
## [code]series_color_2[/code] but not [code]series_color_1[/code] yields a cycle
## of one color.
##
## [b]A themed cycle replaces the default cycle.[/b] Three cycle keys give a
## cycle of exactly three entries, however many the built-in default held. A
## per-pane key does the opposite: it changes the one index it names and leaves
## the rest of the cycle alone.
##
## [b]Plot-wide styles take no pane index.[/b] A style covering the whole plot
## rather than one pane, such as [TauXYStyle], has no pane to name. Its keys stop
## at the property, or at the cycle index.
##
## [b]The inspector cannot mark a default.[/b] A property set from the inspector
## to exactly its built-in default is not written to the saved resource, so it
## reads as untouched on load and the theme wins. Assign it from code instead.
@abstract class_name TauStyle extends Resource

#region Internal, not public API, may change without notice.

# Exported property names assigned at least once, whatever the value. Member
# initializers bypass the setters, so a fresh instance starts empty.
var _overridden: Dictionary[StringName, bool] = {}


# Returns a copy of p_values with every entry clamped into [p_min, p_max]. A
# cycle setter with a range on both ends assigns the result, which also gives it
# the copy every cycle setter stores.
static func _clamped_floats(p_values: Array[float], p_min: float, p_max: float) -> Array[float]:
	var result: Array[float] = []
	result.resize(p_values.size())
	for i in p_values.size():
		result[i] = clampf(p_values[i], p_min, p_max)
	return result


# Returns a copy of p_values with every entry raised to p_min. Companion to
# _clamped_floats() for the cycles bounded on the low end only.
static func _floored_floats(p_values: Array[float], p_min: float) -> Array[float]:
	var result: Array[float] = []
	result.resize(p_values.size())
	for i in p_values.size():
		result[i] = maxf(p_values[i], p_min)
	return result


# Returns a copy of p_values with every entry raised to p_min.
static func _floored_ints(p_values: Array[int], p_min: int) -> Array[int]:
	var result: Array[int] = []
	result.resize(p_values.size())
	for i in p_values.size():
		result[i] = maxi(p_values[i], p_min)
	return result


# Reports the resolved property combinations that cannot be drawn as
# configured. Ranges are enforced on assignment, so what is left here spans
# several properties. Called on the resolved instance at the end of resolve(),
# never on the user resource, whose properties are still half unset.
@abstract func validate_resolved() -> void


# Records p_property as assigned and notifies the listeners.
func _mark(p_property: StringName) -> void:
	_overridden[p_property] = true
	emit_changed()


# Returns true when p_property has been assigned on this resource, whatever the
# assigned value.
func is_overridden(p_property: StringName) -> bool:
	return _overridden.has(p_property)


# Deep equality between this instance and p_other. Subclasses chain into this to
# compare the set of overridden property names, then compare their own property
# values.
func is_equal_to(p_other: TauStyle) -> bool:
	if p_other == null:
		return false
	return _overridden == p_other._overridden


# Writing a typed collection into another instance through a property is
# rejected at runtime, so the copy is made from inside the target.
func _copy_overrides_from(p_source: TauStyle) -> void:
	_overridden = p_source._overridden.duplicate()

#endregion
