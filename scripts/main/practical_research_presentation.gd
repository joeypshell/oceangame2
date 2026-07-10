extends RefCounted


static func lead_text(pools: Array, researched_pool_ids: Array[String]) -> String:
	for value in pools:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var pool := value as Dictionary
		if not researched_pool_ids.has(str(pool.get("id", ""))):
			continue
		var label := str(pool.get("research_lead_label", "")).strip_edges()
		if not label.is_empty():
			return label
	return ""
