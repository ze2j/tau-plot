## Maps a dataset series to a visual representation in the plot.
class_name TauXYSeriesBinding extends Resource

const PaneOverlayType = preload("res://addons/tau-plot/plot/xy/pane_overlay_type.gd").PaneOverlayType
const VisualAttributes = preload("res://addons/tau-plot/plot/xy/visual_attributes.gd").VisualAttributes
const AxisId = preload("res://addons/tau-plot/plot/xy/xy_axes.gd").AxisId


## The series ID from the dataset that this mapping applies to.
@export var series_id: int = 0

## Which pane this series belongs to. This is an index into [member TauXYConfig.panes].
@export var pane_index: int = 0

## The type of overlay to use for rendering this series.
@export var overlay_type: PaneOverlayType = PaneOverlayType.BAR

## Which y-axis this series is assigned to.
## Must be orthogonal to the x-axis.
@export var y_axis_id: AxisId = AxisId.LEFT

var visual_attributes: VisualAttributes = null
