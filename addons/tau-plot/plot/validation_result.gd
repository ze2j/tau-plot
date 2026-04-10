## Accumulates validation errors and warnings raised by validators.
class ValidationResult extends RefCounted:

	var _errors: PackedStringArray = PackedStringArray()
	var _warnings: PackedStringArray = PackedStringArray()

	####################################################################################################
	# Errors
	####################################################################################################

	func add_error(p_message: String) -> void:
		_errors.append(p_message)


	func has_errors() -> bool:
		return not _errors.is_empty()


	func get_errors() -> PackedStringArray:
		return _errors


	func format_errors() -> String:
		return "\n - ".join(_errors)

	####################################################################################################
	# Warnings
	####################################################################################################

	func add_warning(p_message: String) -> void:
		_warnings.append(p_message)


	func has_warnings() -> bool:
		return not _warnings.is_empty()


	func get_warnings() -> PackedStringArray:
		return _warnings


	func format_warnings() -> String:
		return "\n - ".join(_warnings)
