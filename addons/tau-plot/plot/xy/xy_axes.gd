enum AxisId
{
	BOTTOM,
	TOP,
	LEFT,
	RIGHT
}

class Axis extends Object:
	static func as_string(p_id: AxisId) -> String:
		match p_id:
			AxisId.BOTTOM:
				return "BOTTOM"
			AxisId.TOP:
				return "TOP"
			AxisId.LEFT:
				return "LEFT"
			AxisId.RIGHT:
				return "RIGHT"
			_:
				return "???"


	## Returns true if both axes are orthogonal.
	static func are_orthogonal(p_axis_id_1: AxisId, p_axis_id_2: AxisId) -> bool:
		match p_axis_id_1:
			AxisId.BOTTOM, AxisId.TOP:
				return p_axis_id_2 == AxisId.LEFT or p_axis_id_2 == AxisId.RIGHT
			AxisId.LEFT, AxisId.RIGHT:
				return p_axis_id_2 == AxisId.BOTTOM or p_axis_id_2 == AxisId.TOP
			_:
				return false


	## Returns the AxisId on the opposite edge.
	static func get_opposite(p_id: AxisId) -> AxisId:
		match p_id:
			AxisId.BOTTOM:
				return AxisId.TOP
			AxisId.TOP:
				return AxisId.BOTTOM
			AxisId.LEFT:
				return AxisId.RIGHT
			AxisId.RIGHT:
				return AxisId.LEFT
			_:
				return p_id


	## Returns the two axes orthogonal to the given axis.
	## BOTTOM or TOP -> [LEFT, RIGHT]
	## LEFT or RIGHT -> [BOTTOM, TOP]
	static func get_orthogonal_axes(p_axis_id: AxisId) -> Array[AxisId]:
		match p_axis_id:
			AxisId.BOTTOM, AxisId.TOP:
				return [AxisId.LEFT, AxisId.RIGHT]
			AxisId.LEFT, AxisId.RIGHT:
				return [AxisId.BOTTOM, AxisId.TOP]
			_:
				return []


	## Returns true if the axis is horizontal (BOTTOM or TOP).
	static func is_horizontal(p_axis_id: AxisId) -> bool:
		return p_axis_id == AxisId.BOTTOM or p_axis_id == AxisId.TOP
