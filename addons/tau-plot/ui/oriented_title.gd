@tool
extends Control

const TitleAlignment = TauAxisConfig.TitleAlignment
const TitleOrientation = TauAxisConfig.TitleOrientation
const TextAlignment = TauAxisConfig.TextAlignment

@export var text: String = "":
	get:
		return _label_text
	set(value):
		if value == _label_text:
			return
		_label_text = value
		if _label != null:
			_label.text = _label_text
			_recompute_layout()


@export var title_orientation: TitleOrientation = TitleOrientation.HORIZONTAL:
	set(value):
		if title_orientation == value:
			return
		title_orientation = value
		if _label != null:
			_apply_orientation()
			_recompute_layout()


@export var title_alignment: TitleAlignment = TitleAlignment.CENTER:
	set(value):
		if title_alignment == value:
			return
		title_alignment = value
		_update_alignment()


## Horizontal alignment of a horizontal title inside the control. A vertical
## title is rotated and the control is only as wide as the text height, so
## there is nothing to align.
@export var text_alignment: TextAlignment = TextAlignment.CENTER:
	set(value):
		if text_alignment == value:
			return
		text_alignment = value
		_update_alignment()


## True when the title aligns along the X direction, false when it aligns
## along the Y direction. Names which pair of data area edges below applies.
var aligns_horizontally: bool = false:
	set(value):
		if aligns_horizontally == value:
			return
		aligns_horizontally = value
		_update_alignment()

## Near edge of the pane data area along the alignment direction, in global
## coordinates: the left edge when aligning horizontally, the top edge
## otherwise. The title aligns with the data area rather than with the whole
## control, which also covers the space the tick labels take.
##
## The data area is stored rather than the insets derived from it, so a resize
## recomputes a correct offset instead of reusing a stale one.
var data_begin_global: float = 0.0:
	set(value):
		if data_begin_global == value:
			return
		data_begin_global = value
		_update_alignment()

## Far edge of the pane data area along the alignment direction, in global
## coordinates: the right edge when aligning horizontally, the bottom edge
## otherwise.
var data_end_global: float = 0.0:
	set(value):
		if data_end_global == value:
			return
		data_end_global = value
		_update_alignment()


var _label: RichTextLabel = null
var _label_text: String = ""
var _in_recompute: bool = false

# Position of the label inside the control before alignment, and the size of
# the label once rotated. Both come out of the measurement below.
var _base_position := Vector2.ZERO
var _rotated_extent := Vector2.ZERO


func _ready() -> void:
	_label = $RichTextLabel
	_label.anchor_left = 0.0
	_label.anchor_top = 0.0
	_label.anchor_right = 0.0
	_label.anchor_bottom = 0.0
	_label.offset_left = 0.0
	_label.offset_top = 0.0
	_label.text = _label_text
	_label.minimum_size_changed.connect(_recompute_layout)
	_label.resized.connect(_recompute_layout)
	theme_changed.connect(_recompute_layout)
	resized.connect(_update_alignment)

	_apply_orientation()
	_recompute_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_recompute_layout()


func _apply_orientation() -> void:
	if _label == null:
		return

	match title_orientation:
		TitleOrientation.HORIZONTAL:
			_label.rotation_degrees = 0.0
		TitleOrientation.VERTICAL:
			_label.rotation_degrees = -90.0
		TitleOrientation.AUTO:
			push_error("TitleOrientation.AUTO has not been resolved")


# Measures the text, applies the rotation, and sizes the control to what the
# rotated text needs.
func _recompute_layout() -> void:
	if _label == null:
		return
	if _in_recompute:
		return
	_in_recompute = true

	# A RichTextLabel with fit_content derives its height from its width, so it
	# is given more width than any title needs. The text then stays on one line
	# and the measurement below is the extent of that line.
	_label.custom_minimum_size = Vector2.ZERO
	_label.size = Vector2(4096.0, 0.0)
	_label.pivot_offset = Vector2.ZERO
	_label.fit_content = true

	var content_w := _label.get_content_width()
	var content_h := _label.get_content_height()
	var unrotated_size := Vector2(maxf(content_w, 1.0), maxf(content_h, 1.0))

	_label.custom_minimum_size = unrotated_size
	_label.size = unrotated_size

	match title_orientation:
		TitleOrientation.HORIZONTAL:
			_label.rotation_degrees = 0.0
			custom_minimum_size = unrotated_size
			_base_position = Vector2.ZERO
			_rotated_extent = unrotated_size
			_in_recompute = false
			_update_alignment()
			return

		TitleOrientation.VERTICAL:
			_label.rotation_degrees = -90.0

		TitleOrientation.AUTO:
			push_error("TitleOrientation.AUTO has not been resolved")

	# The rotation turns the text box around its origin, so the bounding box of
	# the four rotated corners gives the size to ask for, and its negated
	# minimum brings the text back inside.
	var t := Transform2D(_label.rotation, Vector2.ZERO)

	var corners := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(unrotated_size.x, 0.0),
		Vector2(0.0, unrotated_size.y),
		Vector2(unrotated_size.x, unrotated_size.y),
	])

	var min_p := t * corners[0]
	var max_p := min_p
	for i in range(1, corners.size()):
		var p := t * corners[i]
		min_p = min_p.min(p)
		max_p = max_p.max(p)

	_rotated_extent = max_p - min_p
	custom_minimum_size = _rotated_extent
	_base_position = -min_p

	_in_recompute = false
	_update_alignment()


# Positions the label from the current control rect and the data area.
#
# The insets narrow the control down to the data area. title_alignment then
# places the label inside it, along the alignment direction: BEGIN at the axis
# origin, which is the bottom or the left, END at the opposite end.
func _update_alignment() -> void:
	if _label == null:
		return

	# Derived here rather than stored, so the rect read below is always the
	# current one and the two cannot disagree.
	var inset_left := 0.0
	var inset_right := 0.0
	var inset_top := 0.0
	var inset_bottom := 0.0
	if aligns_horizontally:
		inset_left = data_begin_global - global_position.x
		inset_right = (global_position.x + size.x) - data_end_global
	else:
		inset_top = data_begin_global - global_position.y
		inset_bottom = (global_position.y + size.y) - data_end_global

	match title_orientation:
		TitleOrientation.HORIZONTAL:
			var v_offset := 0.0
			var h_offset := 0.0

			if aligns_horizontally:
				# BEGIN is the left of the data area, END its right.
				var effective_width := size.x - inset_left - inset_right
				var h_slack := effective_width - _rotated_extent.x
				match title_alignment:
					TitleAlignment.BEGIN:
						h_offset = inset_left
					TitleAlignment.CENTER:
						h_offset = inset_left + h_slack * 0.5
					TitleAlignment.END:
						h_offset = inset_left + h_slack

				# Nothing to align vertically, so the label sits in the middle.
				var v_slack := size.y - _rotated_extent.y
				v_offset = v_slack * 0.5
			else:
				# BEGIN is the bottom of the data area, where the Y axis starts,
				# END its top.
				var effective_height := size.y - inset_top - inset_bottom
				var v_slack := effective_height - _rotated_extent.y
				match title_alignment:
					TitleAlignment.BEGIN:
						v_offset = inset_top + v_slack
					TitleAlignment.CENTER:
						v_offset = inset_top + v_slack * 0.5
					TitleAlignment.END:
						v_offset = inset_top

				# Across the alignment direction, text_alignment decides.
				var h_slack := size.x - _rotated_extent.x
				match text_alignment:
					TextAlignment.LEFT:
						h_offset = 0.0
					TextAlignment.CENTER:
						h_offset = h_slack * 0.5
					TextAlignment.RIGHT:
						h_offset = h_slack

			_label.position = _base_position + Vector2(h_offset, v_offset)

		TitleOrientation.VERTICAL:
			if aligns_horizontally:
				# BEGIN is the left of the data area, END its right.
				var effective_width := size.x - inset_left - inset_right
				var slack := effective_width - _rotated_extent.x
				var h_offset := 0.0
				match title_alignment:
					TitleAlignment.BEGIN:
						h_offset = inset_left
					TitleAlignment.CENTER:
						h_offset = inset_left + slack * 0.5
					TitleAlignment.END:
						h_offset = inset_left + slack
				# Nothing to align vertically, so the label sits in the middle.
				var v_slack := size.y - _rotated_extent.y
				_label.position = _base_position + Vector2(h_offset, v_slack * 0.5)
			else:
				# BEGIN is the bottom of the data area, where the Y axis starts,
				# END its top.
				var effective_height := size.y - inset_top - inset_bottom
				var slack := effective_height - _rotated_extent.y
				match title_alignment:
					TitleAlignment.BEGIN:
						_label.position = _base_position + Vector2(0.0, inset_top + slack)
					TitleAlignment.CENTER:
						_label.position = _base_position + Vector2(0.0, inset_top + slack * 0.5)
					TitleAlignment.END:
						_label.position = _base_position + Vector2(0.0, inset_top)

		TitleOrientation.AUTO:
			push_error("TitleOrientation.AUTO has not been resolved")
