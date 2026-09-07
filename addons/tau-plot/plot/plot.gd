@tool

@icon("res://addons/tau-plot/tau-plot.svg")

class_name TauPlot extends PanelContainer

const Dataset := preload("res://addons/tau-plot/model/dataset.gd").Dataset
const DatasetChange := preload("res://addons/tau-plot/model/dataset_change.gd").DatasetChange

const AxisId := preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId
const PaneOverlayType := preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const StackedNormalization := preload("res://addons/tau-plot/plot/xy/stacked_normalization.gd").StackedNormalization
const StackedNegativePolicy := preload("res://addons/tau-plot/plot/xy/stacked_negative_policy.gd").StackedNegativePolicy

const VisualAttributes := preload("res://addons/tau-plot/plot/xy/visual_attributes.gd").VisualAttributes
const BarVisualAttributes := preload("res://addons/tau-plot/plot/xy/bar/bar_visual_attributes.gd").BarVisualAttributes
const ScatterVisualAttributes := preload("res://addons/tau-plot/plot/xy/scatter/scatter_visual_attributes.gd").ScatterVisualAttributes
const LineVisualAttributes := preload("res://addons/tau-plot/plot/xy/line/line_visual_attributes.gd").LineVisualAttributes

const VisualCallbacks := preload("res://addons/tau-plot/plot/xy/visual_callbacks.gd").VisualCallbacks
const BarVisualCallbacks := preload("res://addons/tau-plot/plot/xy/bar/bar_visual_callbacks.gd").BarVisualCallbacks
const ScatterVisualCallbacks := preload("res://addons/tau-plot/plot/xy/scatter/scatter_visual_callbacks.gd").ScatterVisualCallbacks
const LineVisualCallbacks := preload("res://addons/tau-plot/plot/xy/line/line_visual_callbacks.gd").LineVisualCallbacks

const SampleHit := preload("res://addons/tau-plot/plot/xy/hover/sample_hit.gd").SampleHit

const ColorBuffer := preload("res://addons/tau-plot/model/color_buffer.gd").ColorBuffer
const Float32Buffer := preload("res://addons/tau-plot/model/float32_buffer.gd").Float32Buffer
const Float64Buffer := preload("res://addons/tau-plot/model/float64_buffer.gd").Float64Buffer
const Int32Buffer := preload("res://addons/tau-plot/model/int32_buffer.gd").Int32Buffer
const StringBuffer := preload("res://addons/tau-plot/model/string_buffer.gd").StringBuffer

const _PlotArea := preload("res://addons/tau-plot/plot/plot_area.gd").PlotArea
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
			queue_refresh()


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
			queue_refresh()


## Configuration for the legend: position, flow direction, and visual
## style. When null, the legend uses built-in defaults (outside-top
## position, auto flow direction, default style).
@export var legend_config: TauLegendConfig = null:
	set(value):
		if legend_config == value:
			return
		legend_config = value
		if _xy_plot != null:
			_xy_plot.set_legend_config(_effective_legend_config())
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


# A request stands until it renders.
var _refresh_requested := false
# Only covers the frame being awaited.
var _refresh_scheduled := false

# Stands in for legend_config when the user leaves it unset, so the plot
# internals always read a config. Its defaults are the documented ones.
var _default_legend_config := TauLegendConfig.new()

# Child nodes
var _plot_title: RichTextLabel
var _plot_area: _PlotArea

# Active plot-type node (only one is non-null at a time).
var _xy_plot = null


func _init() -> void:
	theme_type_variation = &"TauPlot"

	# Nothing inside the plot may paint outside it. A node that is top_level
	# leaves this canvas item and escapes the clip, so it has to clip itself.
	# The hover tooltip is the one part allowed to leave, which is what a
	# tooltip is for.
	clip_contents = true

	_plot_area = _PlotArea.new()
	_plot_area.name = "PlotArea"
	_plot_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_plot_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# INTERNAL_MODE_FRONT keeps the area out of a get_children() walk of the plot
	# and pins it ahead of everything added later. It does not keep it out of
	# PanelContainer's layout: both the sort and get_minimum_size() count the
	# internal children in, and skip only a top_level or hidden child. The inside
	# legend overlay is top_level for that reason, which is the trick that works.
	add_child(_plot_area, false, Node.INTERNAL_MODE_FRONT)

	# Title
	_plot_title = RichTextLabel.new()
	_plot_title.name = "Title"
	_plot_title.visible = false
	_plot_title.theme_type_variation = &"TauPlotTitle"
	_plot_title.bbcode_enabled = true
	# The title is the one part of the plot that may size it, and it does so the
	# way an autowrapped Label does. The wrap is what keeps the minimum width at
	# a pixel while fit_content turns the wrapped text into a minimum height, so
	# a long title takes more lines instead of more width. A title too tall for
	# the plot is shortened by whoever typed it.
	_plot_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_plot_title.fit_content = true
	_plot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plot_area.set_title(_plot_title)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			# Entering at the size it already had raises no
			# NOTIFICATION_RESIZED, so a request made outside the tree is run
			# here.
			if _refresh_requested:
				_schedule_refresh()
		NOTIFICATION_RESIZED:
			# Godot resizes the descendants one deferred step at a time, so
			# nothing below this node has its new size yet.
			queue_refresh()
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
	_plot_area.set_content(_xy_plot)

	_xy_plot.setup(
		self, queue_refresh,
		p_dataset, p_xy_config, p_series_bindings,
		legend_enabled, _effective_legend_config(),
		hover_enabled, hover_config)

	# Title is driven by the exported property.
	_plot_title.text = title
	_plot_title.visible = not title.is_empty()


# TODO
func plot_pie() -> void:
	push_error("PIE plots are not implemented yet")


# TODO
func plot_radar() -> void:
	push_error("RADAR plots are not implemented yet")


func refresh_now() -> void:
	_refresh()


func queue_refresh() -> void:
	_refresh_requested = true
	_schedule_refresh()


func reset() -> void:
	_reset_active_plot()
	queue_redraw()


####################################################################################################
# Private
####################################################################################################

func _refresh() -> void:
	if _xy_plot != null:
		_xy_plot.refresh()


# Defers to the next frame so repeated requests coalesce into one refresh.
# Outside the tree there is nothing to lay out, so the request waits for NOTIFICATION_ENTER_TREE.
func _schedule_refresh() -> void:
	if _refresh_scheduled or not is_inside_tree():
		return
	_refresh_scheduled = true
	await get_tree().process_frame
	_refresh_scheduled = false
	if not is_inside_tree():
		return
	# Cleared first so an internal request made during the refresh schedules the next one.
	_refresh_requested = false
	_refresh()


func _effective_legend_config() -> TauLegendConfig:
	return legend_config if legend_config != null else _default_legend_config


func _reset_active_plot() -> void:
	if _xy_plot != null:
		_xy_plot.clear()
		_plot_area.clear_content()
		_xy_plot.queue_free()
		_xy_plot = null
