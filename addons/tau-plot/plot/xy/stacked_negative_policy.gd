enum StackedNegativePolicy
{
	DIVERGING,        ## Positive values stack upward from zero, negative values stack
					  ## downward from zero. Two independent cumulatives per X.

	SIGNED_SUM,       ## Negative values are summed signed into the cumulative.
					  ## A negative contribution causes the cumulative to dip below
					  ## the previous layer.

	SKIP_NEGATIVES    ## Negative values are dropped from the cumulative. The sample
					  ## is treated as if its value were zero for stacking purposes.
}
