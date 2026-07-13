extends RefCounted

const DEFAULT_MAP_PATH := "res://maps/production_slice_01.greybox.json"
const ORIGINAL_MAP_PATH := "res://maps/cave_salvage_test_01.greybox.json"
const TILESET_TEST_MAP_PATH := "res://maps/cave_tileset_test_01.greybox.json"
const ORGANIC_MAP_PATH := "res://maps/cave_salvage_organic_01.greybox.json"
const FULL_SKETCH_MAP_PATH := "res://maps/full_cave_sketch_01.greybox.json"
const PRODUCTION_LEVEL_MAP_PATH := "res://maps/production_level_01.greybox.json"
const PRODUCTION_SLICE_MAP_PATH := "res://maps/production_slice_01.greybox.json"
const PRODUCTION_SLICE_02_MAP_PATH := "res://maps/production_slice_02.greybox.json"
const PRODUCTION_SLICE_03_MAP_PATH := "res://maps/production_slice_03.greybox.json"
const PRODUCTION_SLICE_04_MAP_PATH := "res://maps/production_slice_04.greybox.json"
const PRODUCTION_LEVEL_FLAG := "--production-level-map"
const WEB_QUERY_SCRIPT := "window.location.search"

const REVIEW_OPTIONS := [
	{"label": "Full Level Candidate", "path": PRODUCTION_LEVEL_MAP_PATH},
	{"label": "Production 01", "path": PRODUCTION_SLICE_MAP_PATH},
	{"label": "Production 02", "path": PRODUCTION_SLICE_02_MAP_PATH},
	{"label": "Production 03", "path": PRODUCTION_SLICE_03_MAP_PATH},
	{"label": "Production 04", "path": PRODUCTION_SLICE_04_MAP_PATH},
	{"label": "Original", "path": ORIGINAL_MAP_PATH},
	{"label": "Organic", "path": ORGANIC_MAP_PATH},
	{"label": "Full Sketch", "path": FULL_SKETCH_MAP_PATH},
]


static func requested_map_path(user_args: PackedStringArray, engine_args: PackedStringArray) -> String:
	if user_args.has(PRODUCTION_LEVEL_FLAG) or engine_args.has(PRODUCTION_LEVEL_FLAG):
		return PRODUCTION_LEVEL_MAP_PATH
	var explicit_path := _arg_value(user_args, engine_args, "--map-path")
	if not explicit_path.is_empty():
		return explicit_path
	if not OS.has_feature("web"):
		return ""
	return web_review_map_path_for_query(str(JavaScriptBridge.eval(WEB_QUERY_SCRIPT, true)))


static func web_review_map_path_for_query(query: String) -> String:
	var review_requested := false
	var map_id := ""
	for field in query.trim_prefix("?").split("&", false):
		var parts := field.split("=", true, 1)
		var key := str(parts[0]).to_lower()
		if key == "review":
			review_requested = true
		elif key == "map" and parts.size() == 2:
			map_id = str(parts[1]).to_lower()
	if review_requested and map_id == "production_level_01":
		return PRODUCTION_LEVEL_MAP_PATH
	return ""


static func review_options() -> Array:
	return REVIEW_OPTIONS.duplicate(true)


static func _arg_value(user_args: PackedStringArray, engine_args: PackedStringArray, name: String) -> String:
	for args in [user_args, engine_args]:
		for index in range(args.size()):
			var arg := str(args[index])
			if arg == name and index + 1 < args.size():
				return str(args[index + 1])
			var prefix := "%s=" % name
			if arg.begins_with(prefix):
				return arg.substr(prefix.length())
	return ""
