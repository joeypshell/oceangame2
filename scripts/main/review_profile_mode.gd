extends RefCounted

const LOCAL_FLAG := "--fresh-review-profile"
const WEB_QUERY_SCRIPT := "window.location.search"


static func requested(user_args: PackedStringArray, engine_args: PackedStringArray) -> bool:
	if user_args.has(LOCAL_FLAG) or engine_args.has(LOCAL_FLAG):
		return true
	if not OS.has_feature("web"):
		return false
	return _web_query_requests_fresh(str(JavaScriptBridge.eval(WEB_QUERY_SCRIPT, true)))


static func persistence_enabled(automated_review: bool, fresh_review: bool) -> bool:
	return not automated_review and not fresh_review


static func overlay_line(has_propulsion_fins: bool) -> String:
	return "Review profile fresh/isolated | Fins %s" % ("owned" if has_propulsion_fins else "not owned")


static func startup_report(has_propulsion_fins: bool) -> String:
	return "Fresh review profile active: persistence=false propulsion_fins=%s." % str(has_propulsion_fins).to_lower()


static func _web_query_requests_fresh(query: String) -> bool:
	for field in query.trim_prefix("?").split("&", false):
		var parts := field.split("=", true, 1)
		var key := str(parts[0]).to_lower()
		if key == "review":
			return true
		if key == "fresh_profile" and parts.size() == 2 and str(parts[1]).to_lower() in ["1", "true", "yes"]:
			return true
	return false
