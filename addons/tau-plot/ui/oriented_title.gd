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


## Horizontal text alignment for horizontal labels. Has no effect on vertical
## labels (where the text is rotated and the holder is as wide as the text
## height).
@export var text_alignment: TextAlignment = TextAlignment.CENTER:
	set(value):
		if text_alignment == value:
			return
		text_alignment = value
		_update_alignment()


## Top inset in pixels. The effective area for alignment starts this many
## pixels below the holder's top edge. Set by the plot after computing the
## layout so the label aligns with the pane data area, not the full
## container (which includes tick label overhead).
var inset_top: float = 0.0:
	set(value):
		if inset_top == value:
			return
		inset_top = value
		_update_alignment()

## Bottom inset in pixels. The effective area for alignment ends this many
## pixels above the holder's bottom edge.
var inset_bottom: float = 0.0:
	set(value):
		if inset_bottom == value:
			return
		inset_bottom = value
		_update_alignment()


## Left inset in pixels. For horizontal title containers, the effective area
## starts this many pixels from the holder's left edge.
var inset_left: float = 0.0:
	set(value):
		if inset_left == value:
			return
		inset_left = value
		_update_alignment()

## Right inset in pixels. For horizontal title containers, the effective area
## ends this many pixels from the holder's right edge.
var inset_right: float = 0.0:
	set(value):
		if inset_right == value:
			return
		inset_right = value
		_update_alignment()


var _label: RichTextLabel = null
var _label_text: String = ""
var _in_recompute: bool = false

# Cached from _recompute_layout so _update_alignment can use them.
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


# Measures the label content, sets the rotation, and computes the holder's
# minimum size. Caches _base_position and _rotated_extent for _update_alignment.
func _recompute_layout() -> void:
	if _label == null:
		return
	if _in_recompute:
		return
	_in_recompute = true

	# RichTextLabel with fit_content computes its height based on its current
	# width. To get the true single-line text extent we must give it enough
	# room so it does not word-wrap, then read back the content dimensions.
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

	# Compute rotated AABB and reposition so it fits in the holder.
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


# Positions the label based on the current alignment, the actual allocated size,
# and the inset values that define the effective data area.
#
# Insets narrow the effective area within the holder to match the pane data rect.
# Left/right edge containers (VBoxContainer) set inset_top and inset_bottom.
# Top/bottom edge containers (HBoxContainer) set inset_left and inset_right.
#
# title_alignment positions the label along the axis direction (the stacking
# direction of the parent container). When vertical insets are active, alignment
# runs vertically. When horizontal insets are active, alignment runs horizontally.
# BEGIN maps to the axis origin (bottom or left of the data area), END to the
# opposite end (top or right).
func _update_alignment() -> void:
	if _label == null:
		return

	# Determine which axis direction the parent container stacks along.
	# When the plot sets inset_left or inset_right, the container is horizontal
	# (top/bottom HBoxContainer). Otherwise it is vertical (left/right VBoxContainer).
	var stacks_horizontally := (inset_left != 0.0 or inset_right != 0.0)

	match title_orientation:
		TitleOrientation.HORIZONTAL:
			var v_offset := 0.0
			var h_offset := 0.0

			if stacks_horizontally:
				# In an HBoxContainer: title_alignment positions horizontally
				# within the effective width defined by inset_left/inset_right.
				# BEGIN = left of pane, END = right of pane.
				var effective_width := size.x - inset_left - inset_right
				var h_slack := effective_width - _rotated_extent.x
				match title_alignment:
					TitleAlignment.BEGIN:
						h_offset = inset_left
					TitleAlignment.CENTER:
						h_offset = inset_left + h_slack * 0.5
					TitleAlignment.END:
						h_offset = inset_left + h_slack

				# Vertical centering in the holder height.
				var v_slack := size.y - _rotated_extent.y
				v_offset = v_slack * 0.5
			else:
				# In a VBoxContainer: title_alignment positions vertically
				# within the effective height defined by inset_top/inset_bottom.
				# BEGIN = bottom of pane (axis origin), END = top of pane.
				var effective_height := size.y - inset_top - inset_bottom
				var v_slack := effective_height - _rotated_extent.y
				match title_alignment:
					TitleAlignment.BEGIN:
						v_offset = inset_top + v_slack
					TitleAlignment.CENTER:
						v_offset = inset_top + v_slack * 0.5
					TitleAlignment.END:
						v_offset = inset_top

				# Horizontal text alignment within the holder width.
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
			if stacks_horizontally:
				# Rotated label in an HBoxContainer: title_alignment positions
				# horizontally within the effective width.
				# BEGIN = left of pane, END = right of pane.
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
				# Center vertically in holder height.
				var v_slack := size.y - _rotated_extent.y
				_label.position = _base_position + Vector2(h_offset, v_slack * 0.5)
			else:
				# Rotated label in a VBoxContainer: title_alignment positions
				# vertically within the effective height.
				# BEGIN = bottom of pane (axis origin), END = top of pane.
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
