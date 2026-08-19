# Single place holding the emphasis policy of the highlight pass.
class HoverHighlight extends RefCounted:

	# Fraction of its own alpha a sample keeps when it is not the emphasized one.
	const DIM_ALPHA_FACTOR: float = 0.7

	# Amount the emphasized sample is lightened by.
	const HOVERED_LIGHTEN: float = 0.15


	## Returns the color to draw for a sample from its emphasis state.
	static func resolve(p_color: Color, p_hovered: bool, p_callback: Callable) -> Color:
		if p_callback.is_valid():
			return p_callback.call(p_color, p_hovered)

		if p_hovered:
			return p_color.lightened(HOVERED_LIGHTEN)
		else:
			return Color(p_color, p_color.a * DIM_ALPHA_FACTOR)
