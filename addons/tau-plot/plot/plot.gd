@tool

@icon("res://addons/tau-plot/tau-plot.svg")

class_name TauPlot extends PanelContainer

const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType

const VisualAttributes = preload("res://addons/tau-plot/plot/xy/visual_attributes.gd").VisualAttributes
const BarVisualAttributes := preload("res://addons/tau-plot/plot/xy/bar/bar_visual_attributes.gd").BarVisualAttributes
const ScatterVisualAttributes = preload("res://addons/tau-plot/plot/xy/scatter/scatter_visual_attributes.gd").ScatterVisualAttributes

const VisualCallbacks = preload("res://addons/tau-plot/plot/xy/visual_callbacks.gd").VisualCallbacks
const BarVisualCallbacks := preload("res://addons/tau-plot/plot/xy/bar/bar_visual_callbacks.gd").BarVisualCallbacks
const ScatterVisualCallbacks = preload("res://addons/tau-plot/plot/xy/scatter/scatter_visual_callbacks.gd").ScatterVisualCallbacks

const SampleHit = preload("res://addons/tau-plot/plot/xy/hover/sample_hit.gd").SampleHit

const ColorBuffer = preload("res://addons/tau-plot/model/color_buffer.gd").ColorBuffer
const Float32Buffer = preload("res://addons/tau-plot/model/float32_buffer.gd").Float32Buffer
const Float64Buffer := preload("res://addons/tau-plot/model/float64_buffer.gd").Float64Buffer
const Int32Buffer = preload("res://addons/tau-plot/model/int32_buffer.gd").Int32Buffer
const StringBuffer := preload("res://addons/tau-plot/model/string_buffer.gd").StringBuffer

const _XYPlotValidator := preload("res://addons/tau-plot/plot/xy/xy_plot_validator.gd").XYPlotValidator
const _ValidationResult := preload("res://addons/tau-plot/plot/validation_result.gd").ValidationResult
const _XYPlotScene := preload("res://addons/tau-plot/plot/xy/xy_plot.tscn")


## Plot title displayed above the chart (supports BBCode).
@export var title: String = "":
	set(value):
		if title == value:
			return
		title = value
		if _plot_title != null:
			_plot_title.text = title
			_plot_title.visible = not title.is_empty()



## Master switch for the legend. When false the legend is hidden.
## Default is true so that multi-series plots show their legend
## without extra setup.
@export var legend_enabled: bool = true:
	set(value):
		if legend_enabled == value:
			return
		legend_enabled = value
		if _xy_plot != null:
			_xy_plot.set_legend_enabled(legend_enabled)


## Configuration for the legend: position, flow direction, and visual
## style. When null, the legend uses built-in defaults (outside-top
## position, auto flow direction, default style).
@export var legend_config: TauLegendConfig = null:
	set(value):
		if legend_config == value:
			return
		legend_config = value
		if _xy_plot != null:
			_xy_plot.set_legend_config(legend_config)
			queue_refresh()


## Master switch. When false, no hit testing runs, no signals fire,
## no tooltip/crosshair/highlight is shown.
@export var hover_enabled: bool = true:
	set(value):
		if hover_enabled == value:
			return
		hover_enabled = value
		if _xy_plot != null:
			_xy_plot.set_hover_enabled(hover_enabled)


## Configuration for the hover system: mode, tooltip, crosshair,
## highlight, and formatting callbacks.
@export var hover_config: TauHoverConfig = null:
	set(value):
		if hover_config == value:
			return
		hover_config = value
		if _xy_plot != null:
			_xy_plot.set_hover_config(hover_config)


## Emitted when the mouse hovers over one or more samples.
## In NEAREST mode the array contains one entry.
## In X_ALIGNED mode it may contain one entry per series at that x position.
## When a series is bound to multiple overlays in the same pane, the array
## may contain multiple entries with the same (series_id, sample_index) but
## different overlay_type. Consumers are responsible for deduplication if
## they need it.
signal sample_hovered(hits: Array[SampleHit])

## Emitted when the mouse leaves all sample hit zones.
signal sample_hover_exited()

## Emitted on mouse click over one or more samples. Same content rules
## as sample_hovered.
signal sample_clicked(hits: Array[SampleHit])

## Emitted when a pinned tooltip is dismissed (click on empty space or Escape).
signal sample_click_dismissed()


var _pending_refresh := false

# Child nodes
var _plot_title: RichTextLabel
var _plot_vbox: VBoxContainer

# Active plot-type node (only one is non-null at a time).
var _xy_plot = null


func _init() -> void:
	theme_type_variation = &"TauPlot"

	# PlotVBox
	_plot_vbox = VBoxContainer.new()
	_plot_vbox.name = "PlotVBox"
	_plot_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_plot_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_plot_vbox.add_theme_constant_override("separation", 0)
	# INTERNAL_MODE_FRONT makes PlotVBox invisible to PanelContainer's layout
	# sorting. Without it, PanelContainer.queue_sort() would treat PlotVBox as
	# a regular child and force-fit it alongside any other non-internal children
	# (such as the legend overlay or the hover tooltip). Internal children are
	# excluded from Container._sort_children(), so PlotVBox keeps its own
	# size-flag-driven stretch behaviour and is not disrupted when other nodes
	# are added to or removed from the TauPlot PanelContainer at runtime.
	add_child(_plot_vbox, false, Node.INTERNAL_MODE_FRONT)

	# Title
	_plot_title = RichTextLabel.new()
	_plot_title.name = "Title"
	_plot_title.visible = false
	_plot_title.theme_type_variation = &"TauPlotTitle"
	_plot_title.bbcode_enabled = true
	_plot_title.fit_content = true
	_plot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plot_vbox.add_child(_plot_title)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_refresh()
		NOTIFICATION_THEME_CHANGED:
			if _xy_plot != null:
				_xy_plot.on_theme_changed()
			# Godot propagates NOTIFICATION_THEME_CHANGED to children after the
			# parent handler returns, so child renderers have not yet called
			# load_from_theme on their styles. Deferring ensures styles are
			# up to date before the refresh runs.
			queue_refresh()


func plot_xy(p_dataset: Dataset, p_xy_config: TauXYConfig, p_series_bindings: Array[TauXYSeriesBinding]) -> void:
	var validation_result := _ValidationResult.new()
	if not _XYPlotValidator.validate(p_dataset, p_xy_config, p_series_bindings, validation_result):
		push_error("plot_xy() validation failed:\n  " + validation_result.format_errors())
		return
	if validation_result.has_warnings():
		push_warning("plot_xy() validation warnings:\n  " + validation_result.format_warnings())

	_reset_active_plot()

	_xy_plot = _XYPlotScene.instantiate()
	_xy_plot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xy_plot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_plot_vbox.add_child(_xy_plot)

	_xy_plot.setup(
		self, queue_refresh,
		p_dataset, p_xy_config, p_series_bindings,
		legend_enabled, legend_config,
		hover_enabled, hover_config)

	# Title is driven by the exported property.
	_plot_title.text = title
	_plot_title.visible = not title.is_empty()


# TODO
func plot_pie():
	push_error("PIE plots are not implemented yet")


# TODO
func plot_radar():
	push_error("RADAR plots are not implemented yet")


func refresh_now():
	_refresh()


func queue_refresh():
	if _pending_refresh:
		return # Already scheduled
	_pending_refresh = true
	# Wait one frame to allow label visibility changes to propagate through layout system.
	await get_tree().process_frame
	_refresh()


func reset():
	_reset_active_plot()
	_plot_title.visible = false
	queue_redraw()


####################################################################################################
# Private
####################################################################################################

func _refresh() -> void:
	_pending_refresh = false
	if _xy_plot != null:
		var pos := legend_config.position if legend_config != null else TauLegendConfig.Position.OUTSIDE_TOP
		_xy_plot.refresh(global_position, pos)


func _reset_active_plot() -> void:
	if _xy_plot != null:
		_xy_plot.clear()
		_xy_plot.get_parent().remove_child(_xy_plot)
		_xy_plot.queue_free()
		_xy_plot = null
