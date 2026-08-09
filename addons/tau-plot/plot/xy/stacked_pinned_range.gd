const StackedNormalization := preload("res://addons/tau-plot/plot/xy/stacked_normalization.gd").StackedNormalization
const StackedNegativePolicy := preload("res://addons/tau-plot/plot/xy/stacked_negative_policy.gd").StackedNegativePolicy


## Computes the pinned Y axis range that a stacked overlay imposes on its
## target axis, given the active normalization and negative policy.
##
## NONE normalization does not pin the range: the axis is computed from the
## stacked data itself by the domain scanner. Returns Vector2.ZERO and the
## caller is expected to ignore the result when normalization is NONE.
##
## FRACTION and PERCENT pin the range so that every per-X stack fits exactly:
## SKIP_NEGATIVES yields [0, 1] / [0, 100], the diverging and signed_sum
## policies need both half-axes and yield [-1, 1] / [-100, 100].
class StackedPinnedRange extends RefCounted:

	## Returns the (min, max) pinned range. Caller decides whether to apply it
	## based on normalization (NONE means no pinning).
	static func compute(p_normalization: StackedNormalization, p_policy: StackedNegativePolicy) -> Vector2:
		match p_normalization:
			StackedNormalization.FRACTION:
				if p_policy == StackedNegativePolicy.SKIP_NEGATIVES:
					return Vector2(0.0, 1.0)
				return Vector2(-1.0, 1.0)

			StackedNormalization.PERCENT:
				if p_policy == StackedNegativePolicy.SKIP_NEGATIVES:
					return Vector2(0.0, 100.0)
				return Vector2(-100.0, 100.0)

		return Vector2.ZERO
