## Configuration for the legend system.
class_name TauLegendConfig extends Resource

enum Position
{
	# Outside positions (part of layout flow, consume space from the plot area)
	OUTSIDE_TOP,
	OUTSIDE_BOTTOM,
	OUTSIDE_LEFT,
	OUTSIDE_RIGHT,

	# Inside positions, anchored to an edge (centered along that edge)
	INSIDE_TOP,
	INSIDE_BOTTOM,
	INSIDE_LEFT,
	INSIDE_RIGHT,

	# Inside positions, anchored to a corner
	INSIDE_TOP_LEFT,
	INSIDE_TOP_RIGHT,
	INSIDE_BOTTOM_LEFT,
	INSIDE_BOTTOM_RIGHT,
}

enum FlowDirection
{
	AUTO,        # Derived from position
	HORIZONTAL,
	VERTICAL,
}


## Where the legend is placed relative to the plot area.
@export var position: Position = Position.OUTSIDE_TOP

## Item flow direction inside the legend container.
## AUTO derives the direction from the position.
@export var flow_direction: FlowDirection = FlowDirection.AUTO

## Visual styling for the legend.
## Resolved through the standard defaults > theme > user-override cascade.
## Never null.
@export var style: TauLegendStyle = TauLegendStyle.new()
