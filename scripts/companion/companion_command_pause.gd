extends RefCounted

const POLICY_ID := "tactical_pause"

var _tree: SceneTree
var _prior_paused := false
var _owns_pause := false


func begin(tree: SceneTree) -> void:
	if _owns_pause or tree == null:
		return
	_tree = tree
	_prior_paused = tree.paused
	_owns_pause = true
	tree.paused = true


func end() -> void:
	if not _owns_pause:
		return
	var tree := _tree
	var restore_paused := _prior_paused
	_tree = null
	_prior_paused = false
	_owns_pause = false
	if tree != null:
		tree.paused = restore_paused


func is_active() -> bool:
	return _owns_pause and _tree != null and _tree.paused


func report() -> Dictionary:
	return {
		"timing_policy": POLICY_ID,
		"simulation_paused": is_active(),
		"owns_pause": _owns_pause,
		"prior_paused": _prior_paused,
	}
