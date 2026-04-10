## Lightweight tooltip node that draws a styled background with either BBCode
## text (via RichTextLabel) or a user-provided Control. Uses standard Godot
## nodes for all rendering: a Panel for the background StyleBox, a
## MarginContainer for padding, and a RichTextLabel for text content.
class TooltipPanel extends Control:
	var _background: Panel = null
	var _margin: MarginContainer = null
	var _rich_label: RichTextLabel = null
	var _custom_control: Control = null

	var _font: Font = null
	var _font_size: int = 14
	var _padding: int = 8
	var _max_width: int = 300


	func _init() -> void:
		theme_type_variation = &"TauTooltip"

		_background = Panel.new()
		_background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		_background.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_background)

		_margin = MarginContainer.new()
		_margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		_margin.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_margin)

		_rich_label = RichTextLabel.new()
		_rich_label.bbcode_enabled = true
		_rich_label.fit_content = true
		_rich_label.scroll_active = false
		_rich_label.mouse_filter = MOUSE_FILTER_IGNORE
		_rich_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_rich_label.add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
		_margin.add_child(_rich_label)


	## Applies the resolved visual style. Called before setting content
	## each time the tooltip is shown, so style changes are picked up
	## immediately.
	func apply_style(
			p_style_box: StyleBox,
			p_font: Font,
			p_font_size: int,
			p_font_color: Color,
			p_padding: int,
			p_max_width: int) -> void:
		_font = p_font
		_font_size = p_font_size
		_padding = p_padding
		_max_width = p_max_width

		# Background.
		if p_style_box != null:
			_background.add_theme_stylebox_override(&"panel", p_style_box)

		# Padding.
		_margin.add_theme_constant_override(&"margin_left", p_padding)
		_margin.add_theme_constant_override(&"margin_top", p_padding)
		_margin.add_theme_constant_override(&"margin_right", p_padding)
		_margin.add_theme_constant_override(&"margin_bottom", p_padding)

		# Font overrides on the RichTextLabel.
		if p_font != null:
			_rich_label.add_theme_font_override(&"normal_font", p_font)
		_rich_label.add_theme_font_size_override(&"normal_font_size", p_font_size)
		_rich_label.add_theme_font_size_override(&"bold_font_size", p_font_size)
		_rich_label.add_theme_font_size_override(&"italics_font_size", p_font_size)
		_rich_label.add_theme_font_size_override(&"bold_italics_font_size", p_font_size)
		_rich_label.add_theme_color_override(&"default_color", p_font_color)


	## Replaces the current content with BBCode text. Removes any custom
	## control previously set via set_custom_control.
	func set_text_content(p_text: String) -> void:
		_free_custom_control()
		_rich_label.visible = true
		_rich_label.text = p_text
		_recompute_size()


	## Replaces the current content with a user-provided Control. Hides the
	## RichTextLabel and inserts the control as a child of the margin
	## container (padded on all sides).
	func set_custom_control(p_control: Control) -> void:
		_rich_label.visible = false
		_rich_label.text = ""
		_free_custom_control()
		_custom_control = p_control
		if _custom_control != null:
			_margin.add_child(_custom_control)
		_recompute_size()


	## Hides the tooltip and frees any custom control. This honors the
	## documented contract that custom controls are freed when the tooltip
	## hides.
	func dismiss() -> void:
		visible = false
		_free_custom_control()
		_rich_label.text = ""
		_rich_label.visible = false


	####################################################################
	# Private
	####################################################################

	func _free_custom_control() -> void:
		if _custom_control != null and is_instance_valid(_custom_control):
			_margin.remove_child(_custom_control)
			_custom_control.queue_free()
			_custom_control = null


	func _recompute_size() -> void:
		if _custom_control != null:
			var content_min := _custom_control.get_combined_minimum_size()
			var pad2 := Vector2(_padding * 2, _padding * 2)
			size = content_min + pad2
			return

		if _font == null or _rich_label.text.is_empty():
			size = Vector2.ZERO
			return

		# Use get_parsed_text() to obtain the visible text with all BBCode
		# tags resolved by the engine's own parser.
		var plain_text := _rich_label.get_parsed_text()
		var lines := plain_text.split("\n")
		var line_height := _font.get_height(_font_size)
		var max_line_width: float = 0.0

		for line in lines:
			var w := ceilf(_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size).x)
			max_line_width = maxf(max_line_width, w)

		var pad2 := float(_padding) * 2.0
		var content_width := max_line_width

		if _max_width > 0:
			content_width = minf(content_width, float(_max_width) - pad2)

		# Fix the RichTextLabel width so it knows its layout constraint.
		# With fit_content = true it will report the correct content height at this width.
		_rich_label.custom_minimum_size.x = content_width

		var content_height := float(lines.size()) * line_height

		size = Vector2(content_width + pad2, content_height + pad2)
