extends RefCounted


static func select_for_day(map_id: String, pools: Array, day_number: int, completed_discovery_ids := [], active_condition_ids := []) -> Array[String]:
	var selected: Array[String] = []
	for value in pools:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var pool := value as Dictionary
		var condition_id := str(pool.get("daily_condition_id", ""))
		if not condition_id.is_empty() and not active_condition_ids.has(condition_id):
			continue
		var candidate_ids: Array = _effective_candidate_ids(pool, completed_discovery_ids)
		var select_count := clampi(int(pool.get("select_count", 0)), 0, candidate_ids.size())
		if candidate_ids.is_empty() or select_count <= 0:
			continue
		var guaranteed_ids := _guaranteed_candidate_ids(pool, candidate_ids)
		for candidate_id in guaranteed_ids:
			if not selected.has(candidate_id):
				selected.append(candidate_id)
		var rotating_ids: Array = candidate_ids.filter(func(candidate_id): return not guaranteed_ids.has(candidate_id))
		var rotating_count := select_count - guaranteed_ids.size()
		if rotating_count <= 0 or rotating_ids.is_empty():
			continue
		var pool_id := str(pool.get("id", "material_pool"))
		var offset := (_stable_hash("%s:%s" % [map_id, pool_id]) + maxi(1, day_number) - 1) % rotating_ids.size()
		for index in range(rotating_count):
			var candidate_id := str(rotating_ids[(offset + index) % rotating_ids.size()])
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


static func _guaranteed_candidate_ids(pool: Dictionary, effective_ids: Array) -> Array[String]:
	var guaranteed: Array[String] = []
	for candidate_id in pool.get("guaranteed_candidate_ids", []):
		var normalized := str(candidate_id)
		if effective_ids.has(normalized) and not guaranteed.has(normalized):
			guaranteed.append(normalized)
	return guaranteed


static func _stable_hash(value: String) -> int:
	var result := 2166136261
	for byte in value.to_utf8_buffer():
		result = ((result ^ int(byte)) * 16777619) & 0x7fffffff
	return result
