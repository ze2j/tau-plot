## Configures a single axis in the plot.
##
## The [member type] determines whether the axis shows categories (labels like
## "Jan", "Feb") or continuous numeric values. When [code]type[/code] is
## [code]CONTINUOUS[/code], the [member scale] property controls whether values
## are mapped linearly or logarithmically.
class_name TauAxisConfig extends Resource

enum Type
{
	CATEGORICAL,
	CONTINUOUS
}

## Whether the axis shows category labels or continuous numeric values.
@export var type: Type = Type.CONTINUOUS

enum Scale
{
	LINEAR,
	LOGARITHMIC
}

## The scale used to map data values to screen space. Only used when [member type]
## is [code]CONTINUOUS[/code].
@export var scale: Scale = Scale.LINEAR

## If [code]true[/code], the visual direction of the axis is reversed.
## For a vertical axis the minimum value is drawn at the top and the maximum
## at the bottom (the opposite of the default bottom-to-top direction).
## For a horizontal axis the minimum value is drawn on the right and the
## maximum on the left (the opposite of the default left-to-right direction).
## Works with both continuous and categorical axes.
@export var inverted: bool = false

## If [code]true[/code], the axis domain is expanded so that zero is always visible.
## Useful for bar charts where bars should start from zero. Disable this when the data
## range does not include zero and showing it would waste space (e.g. temperature readings).
## Only used when [member type] is [code]CONTINUOUS[/code].
@export var include_zero_in_domain: bool = true

################################################################################################
# Axis title
################################################################################################

@export_group("Title")

## Descriptive title displayed next to the axis (supports BBCode).
## The axis title is visible when this string is not empty.
@export var title: String = ""

## Orientation of the title text.
enum TitleOrientation
{
	AUTO,           ## HORIZONTAL for bottom/top axes, VERTICAL for left/right axes.
	HORIZONTAL,
	VERTICAL,
}

## Orientation of the axis title.
@export var title_orientation: TitleOrientation = TitleOrientation.AUTO

## Alignment of the title along the axis direction.
## For horizontal axes this maps to horizontal alignment (BEGIN = left, END = right).
## For vertical axes this maps to vertical alignment along the axis direction
## (BEGIN = bottom of the pane, END = top of the pane).
enum TitleAlignment
{
	BEGIN,
	CENTER,
	END,
}

## Alignment of the title along the axis direction.
@export var title_alignment: TitleAlignment = TitleAlignment.CENTER

## Horizontal text alignment when the title is rendered horizontally.
enum TextAlignment
{
	LEFT,
	CENTER,
	RIGHT,
}

## Horizontal text alignment for the title when rendered horizontally.
## Has no effect on vertically oriented titles.
@export var title_text_alignment: TextAlignment = TextAlignment.CENTER

################################################################################################
# Tick label formatting
################################################################################################

@export_group("Tick Labels")

## Optional callback to format tick labels. Receives the default label string
## and returns the formatted string to display.
## Signature: [code]func(p_label: String) -> String[/code]
var format_tick_label: Callable = Callable()

################################################################################################
# Tick count preferences (Linear scales only - logarithmic scales ignore these)
################################################################################################

@export_group("Tick Count (Linear Scale)")

## Preferred number of ticks (at least 2). The resolver will try to stay close to this count
## while choosing round step values and avoiding label overlap.
@export var tick_count_preferred: int = 5

################################################################################################
# Tick label overlap prevention
################################################################################################

@export_group("Label Overlap")

enum OverlapStrategy
{
	## No overlap prevention (user's responsibility).
	NONE,
	## Reduce the number of ticks until labels no longer overlap.
	## Not valid for CATEGORICAL type: falls back to SKIP_LABELS.
	REDUCE_COUNT,
	## Keep all ticks but skip rendering labels that would overlap.
	SKIP_LABELS,

	# Future strategies (not yet implemented):
	# ROTATE,       # Rotate labels to reduce horizontal footprint
	# ABBREVIATE,   # Shorten labels using K/M/B suffixes or custom abbreviation rules
	# STAGGER,      # Alternate label heights (above/below axis for X, left/right offset for Y)
	# TRUNCATE      # Cut labels with ellipsis (...) when too long
}

## Strategy for preventing tick labels from overlapping each other.
## [b]Note:[/b] REDUCE_COUNT is not valid for CATEGORICAL type and will fall back to SKIP_LABELS.
@export var overlap_strategy: OverlapStrategy = OverlapStrategy.SKIP_LABELS

## Minimum spacing in pixels between adjacent tick labels.
@export var min_label_spacing_px: int = 8

################################################################################################
# Numeric range overrides
################################################################################################

@export_group("Range Override")

## If [code]true[/code], the axis uses [member min_override] and [member max_override]
## instead of computing the range from data. Only used when [member type]
## is [code]CONTINUOUS[/code].
@export var range_override_enabled: bool = false

## Minimum value of the axis when [member range_override_enabled] is [code]true[/code].
@export var min_override: float = 0.0

## Maximum value of the axis when [member range_override_enabled] is [code]true[/code].
@export var max_override: float = 1.0

################################################################################################
# Domain padding
################################################################################################

@export_group("Domain Padding")

enum DomainPaddingMode
{
	## Automatically chooses padding based on axis configuration.
	## For linear scales with [member include_zero_in_domain] enabled:
	## pad_min = 0, pad_max = 5% (FRACTION).
	## Otherwise: symmetric 5% (FRACTION) on both sides.
	AUTO,
	## No padding. Data min/max are the domain boundaries.
	NONE,
	## Padding = fraction * data_span.
	FRACTION,
	## Padding = fixed value in data units.
	DATA_UNITS,
}

## How the domain is padded beyond the data min/max.
## Only used when [member type] is [code]CONTINUOUS[/code] and
## [member range_override_enabled] is [code]false[/code].
@export var domain_padding_mode: DomainPaddingMode = DomainPaddingMode.AUTO

## Padding applied to the min side of the domain.
## Ignored when [member domain_padding_mode] is [code]AUTO[/code] or [code]NONE[/code].
## For FRACTION mode: fraction of the data span (0.05 = 5%).
## For DATA_UNITS mode: fixed value in data units.
## For LOGARITHMIC scales with FRACTION mode: fraction of the log-span.
@export var domain_padding_min: float = 0.05

## Padding applied to the max side of the domain.
## Ignored when [member domain_padding_mode] is [code]AUTO[/code] or [code]NONE[/code].
## For FRACTION mode: fraction of the data span (0.05 = 5%).
## For DATA_UNITS mode: fixed value in data units.
## For LOGARITHMIC scales with FRACTION mode: fraction of the log-span.
@export var domain_padding_max: float = 0.05
