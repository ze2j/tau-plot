## What each stack of a stacking overlay is scaled to.
enum StackedNormalization
{
	## Stack the raw values. The top of each stack is their sum.
	NONE,

	## Scale each stack so it reaches [code]1.0[/code], turning every series
	## into its share of that stack.
	FRACTION,

	## Scale each stack so it reaches [code]100.0[/code], the same share
	## expressed as a percentage.
	PERCENT
}
