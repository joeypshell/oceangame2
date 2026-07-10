extends RefCounted


static func select_for_day(map_id: String, pools: Array, day_number: int) -> Array[String]:
	var selected: Array[String] = []
	for value in pools:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var pool := value as Dictionary
		var candidate_ids: Array = pool.get("candidate_ids", [])
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


static func _stable_hash(value: String) -> int:
	var result := 2166136261
	for byte in value.to_utf8_buffer():
		result = ((result ^ int(byte)) * 16777619) & 0x7fffffff
	return result
