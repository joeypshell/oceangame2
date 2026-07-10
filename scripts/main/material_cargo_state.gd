extends RefCounted

var _held_entries: Array[Dictionary] = []


func collect(candidate: Dictionary, map_id: String) -> bool:
	var candidate_id := str(candidate.get("id", ""))
	var material_id := str(candidate.get("material_id", ""))
	var quantity := int(candidate.get("material_quantity", 0))
	if candidate_id.is_empty() or material_id.is_empty() or quantity <= 0 or has_candidate(candidate_id):
		return false
	_held_entries.append({
		"candidate_id": candidate_id,
		"map_id": map_id,
		"material_id": material_id,
		"quantity": quantity,
	})
	return true


func has_candidate(candidate_id: String) -> bool:
	for entry in _held_entries:
		if str(entry.get("candidate_id", "")) == candidate_id:
			return true
	return false


func held_count() -> int:
	var total := 0
	for entry in _held_entries:
		total += maxi(0, int(entry.get("quantity", 0)))
	return total


func quantities() -> Dictionary:
	var values := {}
	for entry in _held_entries:
		var material_id := str(entry.get("material_id", ""))
		values[material_id] = int(values.get(material_id, 0)) + maxi(0, int(entry.get("quantity", 0)))
	return values


func clear() -> Array[Dictionary]:
	var cleared: Array[Dictionary] = []
	for entry in _held_entries:
		cleared.append(entry.duplicate(true))
	_held_entries = []
	return cleared


func report() -> Dictionary:
	var entries: Array[Dictionary] = []
	for entry in _held_entries:
		entries.append(entry.duplicate(true))
	return {
		"held_count": held_count(),
		"held_quantities": quantities(),
		"held_entries": entries,
	}
