extends RefCounted

const FINAL_DIVE_COMPLETION_CUE := "Final dive signal locked"


static func build_text(context: Dictionary) -> String:
	if not bool(context.get("run_complete", false)) and not bool(context.get("run_failed", false)):
		return ""

	var result_lines := PackedStringArray()
	result_lines.append(_title(context))
	_append_if_present(result_lines, str(context.get("objective_text", "")))
	_append_if_present(result_lines, str(context.get("next_dive_text", "")))
	_append_if_present(result_lines, str(context.get("relay_follow_through_text", "")))
	var final_dive_text := str(context.get("final_dive_text", ""))
	_append_if_present(result_lines, final_dive_text)
	if not final_dive_text.strip_edges().is_empty():
		_append_if_present(result_lines, FINAL_DIVE_COMPLETION_CUE)
	_append_if_present(result_lines, str(context.get("route_text", "")))
	result_lines.append("Score %d" % int(context.get("score", 0)))
	result_lines.append("Salvage score %d" % int(context.get("salvage_score", 0)))
	result_lines.append("Oxygen bonus +%d" % int(context.get("oxygen_bonus", 0)))
	result_lines.append("Best %d" % int(context.get("best_score", 0)))
	result_lines.append("Salvage %d/%d" % [
		int(context.get("banked_salvage", 0)),
		int(context.get("total_salvage", 0)),
	])
	_append_if_present(result_lines, str(context.get("progression_text", "")))
	_append_if_present(result_lines, str(context.get("progression_status_note", "")))
	result_lines.append(str(context.get("oxygen_text", "")))
	result_lines.append("Press R to retry")
	return "\n".join(result_lines)


static func _title(context: Dictionary) -> String:
	return "Expedition complete" if bool(context.get("run_complete", false)) else "Expedition failed"


static func _append_if_present(lines: PackedStringArray, value: String) -> void:
	var text := value.strip_edges()
	if text.is_empty():
		return
	lines.append(text)
