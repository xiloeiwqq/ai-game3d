class_name GameRules
extends RefCounted

const REQUIRED := 3
var collected: Dictionary = {}

func reset() -> void:
	collected.clear()

func collect_once(id: String) -> bool:
	if id.is_empty() or collected.has(id):
		return false
	collected[id] = true
	return true

func count() -> int:
	return collected.size()

func exit_allowed() -> bool:
	return count() >= REQUIRED
