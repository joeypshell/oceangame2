extends RefCounted

const LOCAL_FLAG := "--fresh-review-profile"
const LOCAL_CHECKPOINT_FLAG := "--review-checkpoint"
const WEB_QUERY_SCRIPT := "window.location.search"


static func requested(user_args: PackedStringArray, engine_args: PackedStringArray) -> bool:
	if user_args.has(LOCAL_FLAG) or engine_args.has(LOCAL_FLAG) or not checkpoint_id(user_args, engine_args).is_empty():
		return true
	if not OS.has_feature("web"):
		return false
	return _web_query_requests_fresh(str(JavaScriptBridge.eval(WEB_QUERY_SCRIPT, true)))


static func checkpoint_id(user_args: PackedStringArray, engine_args: PackedStringArray) -> String:
	for args in [user_args, engine_args]:
		for index in range(args.size()):
			var argument := str(args[index])
			if argument == LOCAL_CHECKPOINT_FLAG and index + 1 < args.size():
				return _normalize_checkpoint_id(str(args[index + 1]))
			var prefix := "%s=" % LOCAL_CHECKPOINT_FLAG
			if argument.begins_with(prefix):
				return _normalize_checkpoint_id(argument.substr(prefix.length()))
	if not OS.has_feature("web"):
		return ""
	return checkpoint_from_web_query(str(JavaScriptBridge.eval(WEB_QUERY_SCRIPT, true)))


static func persistence_enabled(automated_review: bool, fresh_review: bool) -> bool:
	return not automated_review and not fresh_review


static func overlay_line(has_propulsion_fins: bool, checkpoint := "", checkpoint_ready := false) -> String:
	if not str(checkpoint).is_empty():
		if checkpoint_ready:
			return "Review checkpoint %s | isolated | Fins %s" % [checkpoint, "owned" if has_propulsion_fins else "not owned"]
		return "Review checkpoint rejected: %s | fresh/isolated" % checkpoint
	return "Review profile fresh/isolated | Fins %s" % ("owned" if has_propulsion_fins else "not owned")


static func startup_report(has_propulsion_fins: bool, checkpoint := "", checkpoint_ready := false) -> String:
	if not str(checkpoint).is_empty():
		if checkpoint_ready:
			return "Review checkpoint active: id=%s persistence=false propulsion_fins=%s." % [checkpoint, str(has_propulsion_fins).to_lower()]
		return "Review checkpoint rejected: id=%s persistence=false fallback=fresh." % checkpoint
	return "Fresh review profile active: persistence=false propulsion_fins=%s." % str(has_propulsion_fins).to_lower()


static func checkpoint_from_web_query(query: String) -> String:
	for field in query.trim_prefix("?").split("&", false):
		var parts := field.split("=", true, 1)
		if str(parts[0]).to_lower() == "checkpoint" and parts.size() == 2:
			return _normalize_checkpoint_id(str(parts[1]))
	return ""


static func _web_query_requests_fresh(query: String) -> bool:
	for field in query.trim_prefix("?").split("&", false):
		var parts := field.split("=", true, 1)
		var key := str(parts[0]).to_lower()
		if key == "review":
			return true
		if key == "checkpoint" and parts.size() == 2 and not str(parts[1]).strip_edges().is_empty():
			return true
		if key == "fresh_profile" and parts.size() == 2 and str(parts[1]).to_lower() in ["1", "true", "yes"]:
			return true
	return false


static func _normalize_checkpoint_id(value: String) -> String:
	return value.strip_edges().to_lower()
