extends RefCounted


static func select_for_day(map_id: String, pools: Array, day_number: int, completed_discovery_ids := []) -> Array[String]:
	var selected: Array[String] = []
	for value in pools:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var pool := value as Dictionary
		if not str(pool.get("daily_condition_id", "")).is_empty():
			continue
		var candidate_ids: Array = _effective_candidate_ids(pool, completed_discovery_ids)
		var select_count := clampi(int(pool.get("select_count", 0)), 0, candidate_ids.size())
		if candidate_ids.is_empty() or select_count <= 0:
			continue
		var pool_id := str(pool.get("id", "material_pool"))
		var offset := (_stable_hash("%s:%s" % [map_id, pool_id]) + maxi(1, day_number) - 1) % candidate_ids.size()
		for index in range(select_count):
			var candidate_id := str(candidate_ids[(offset + index) % candidate_ids.size()])
			if not candidate_id.is_empty() and not selected.has(candidate_id):
				selected.append(candidate_id)
	return selected


static func researched_pool_ids(pools: Array, completed_discovery_ids := []) -> Array[String]:
	var active: Array[String] = []
	for value in pools:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var pool := value as Dictionary
		var discovery_id := str(pool.get("research_discovery_id", ""))
		if not discovery_id.is_empty() and completed_discovery_ids.has(discovery_id):
			active.append(str(pool.get("id", "")))
	return active


static func _effective_candidate_ids(pool: Dictionary, completed_discovery_ids) -> Array:
	var discovery_id := str(pool.get("research_discovery_id", ""))
	if not discovery_id.is_empty() and completed_discovery_ids.has(discovery_id):
		var researched: Array = pool.get("researched_candidate_ids", [])
		if not researched.is_empty():
			return researched
	return pool.get("candidate_ids", [])


static func _stable_hash(value: String) -> int:
	var result := 2166136261
	for byte in value.to_utf8_buffer():
		result = ((result ^ int(byte)) * 16777619) & 0x7fffffff
	return result
