extends RefCounted


static func active_line(state) -> String:
	if state == null or not state.has_method("active_label"):
		return ""
	return str(state.active_label())


static func forecast_line(state) -> String:
	if state == null or not state.has_method("forecast_label"):
		return ""
	return str(state.forecast_label())
