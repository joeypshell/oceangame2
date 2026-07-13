extends RefCounted

const EXPECTED_MAP_ID := "production_level_01"
const EXPECTED_TILE_SIZE_PX := 32
const EXPECTED_WIDTH_TILES := 158
const EXPECTED_HEIGHT_TILES := 161
const EXPECTED_TERRAIN_CELLS := 14898
const EXPECTED_COLLISION_RECTS := 376
const SAMPLE_FRAMES := 30
const PRACTICAL_STARTUP_LIMIT_MS := 15000.0
const PRACTICAL_FRAME_LIMIT_MS := 100.0
const SUPPORTED_VIEWPORTS := [
	{"id": "desktop_1280x720", "browser_width": 1280, "browser_height": 720},
	{"id": "mobile_844x390", "browser_width": 844, "browser_height": 390},
]


static func measure_and_quit(tree: SceneTree, world: Node, player: Node, startup_ms: float) -> void:
	var frame_sample_started := Time.get_ticks_usec()
	for _frame in range(SAMPLE_FRAMES):
		await tree.process_frame
	var average_frame_ms := float(Time.get_ticks_usec() - frame_sample_started) / 1000.0 / float(SAMPLE_FRAMES)
	var report := build_report(world, player, startup_ms, average_frame_ms)
	var failures := validate_report(report)
	print("Full-level runtime measurement: %s" % JSON.stringify(report))
	if not failures.is_empty():
		for failure in failures:
			push_error("Full-level runtime measurement failed: %s" % failure)
		tree.quit(1)
		return
	print("Promoted full-level measurement passed: map=%s startup_ms=%.2f terrain_cells=%d collision_rects=%d average_frame_ms=%.2f camera_bounds=true desktop_mobile_fit=true." % [
		report["map_id"],
		float(report["startup_ms"]),
		int(report["terrain_cells"]),
		int(report["collision_rects"]),
		float(report["average_frame_ms"]),
	])
	tree.quit()


static func build_report(world: Node, player: Node, startup_ms: float, average_frame_ms: float) -> Dictionary:
	var parity: Dictionary = world.get_runtime_parity_report()
	var width_tiles := int(parity.get("width_tiles", 0))
	var height_tiles := int(parity.get("height_tiles", 0))
	var tile_size_px := int(parity.get("tile_size_px", 0))
	var map_size_px := Vector2(float(width_tiles * tile_size_px), float(height_tiles * tile_size_px))
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	var camera_zoom := camera.zoom if camera != null else Vector2.ZERO
	var logical_game_size := player.get_viewport().get_visible_rect().size
	var camera_limits := {
		"left": camera.limit_left if camera != null else 0,
		"top": camera.limit_top if camera != null else 0,
		"right": camera.limit_right if camera != null else 0,
		"bottom": camera.limit_bottom if camera != null else 0,
	}
	var viewport_reports := []
	for viewport in SUPPORTED_VIEWPORTS:
		var visible_world_size := Vector2.ZERO
		if camera_zoom.x > 0.0 and camera_zoom.y > 0.0:
			visible_world_size = Vector2(logical_game_size.x / camera_zoom.x, logical_game_size.y / camera_zoom.y)
		viewport_reports.append({
			"id": viewport["id"],
			"browser_px": [viewport["browser_width"], viewport["browser_height"]],
			"logical_game_px": [int(logical_game_size.x), int(logical_game_size.y)],
			"visible_world_px": [snappedf(visible_world_size.x, 0.01), snappedf(visible_world_size.y, 0.01)],
			"fits_inside_map": visible_world_size.x <= map_size_px.x and visible_world_size.y <= map_size_px.y,
		})
	var terrain_cells: Array = parity.get("terrain_cells", [])
	var collision_rects: Array = parity.get("collision_rects", [])
	return {
		"map_id": str(parity.get("map_id", "")),
		"map_path": str(parity.get("map_path", "")),
		"tile_size_px": tile_size_px,
		"width_tiles": width_tiles,
		"height_tiles": height_tiles,
		"map_size_px": [int(map_size_px.x), int(map_size_px.y)],
		"terrain_cells": terrain_cells.size(),
		"collision_rects": collision_rects.size(),
		"startup_ms": snappedf(startup_ms, 0.01),
		"average_frame_ms": snappedf(average_frame_ms, 0.01),
		"camera_zoom": [camera_zoom.x, camera_zoom.y],
		"camera_limits": camera_limits,
		"runtime_game_viewport_px": [int(logical_game_size.x), int(logical_game_size.y)],
		"supported_viewports": viewport_reports,
		"observation": "practical_no_blocker" if startup_ms <= PRACTICAL_STARTUP_LIMIT_MS and average_frame_ms <= PRACTICAL_FRAME_LIMIT_MS else "blocking_measurement",
	}


static func validate_report(report: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	if str(report.get("map_id", "")) != EXPECTED_MAP_ID:
		failures.append("expected map %s, got %s" % [EXPECTED_MAP_ID, report.get("map_id", "")])
	if int(report.get("tile_size_px", 0)) != EXPECTED_TILE_SIZE_PX:
		failures.append("expected tile size %d" % EXPECTED_TILE_SIZE_PX)
	if int(report.get("width_tiles", 0)) != EXPECTED_WIDTH_TILES or int(report.get("height_tiles", 0)) != EXPECTED_HEIGHT_TILES:
		failures.append("expected dimensions %dx%d" % [EXPECTED_WIDTH_TILES, EXPECTED_HEIGHT_TILES])
	if int(report.get("terrain_cells", 0)) != EXPECTED_TERRAIN_CELLS:
		failures.append("expected %d terrain cells" % EXPECTED_TERRAIN_CELLS)
	if int(report.get("collision_rects", 0)) != EXPECTED_COLLISION_RECTS:
		failures.append("expected %d collision rectangles" % EXPECTED_COLLISION_RECTS)
	var limits: Dictionary = report.get("camera_limits", {})
	if limits != {"left": 0, "top": 0, "right": EXPECTED_WIDTH_TILES * EXPECTED_TILE_SIZE_PX, "bottom": EXPECTED_HEIGHT_TILES * EXPECTED_TILE_SIZE_PX}:
		failures.append("camera limits do not match the full map bounds: %s" % limits)
	for viewport in report.get("supported_viewports", []):
		if not bool(viewport.get("fits_inside_map", false)):
			failures.append("camera frame exceeds map bounds at %s" % viewport.get("id", "unknown"))
	if float(report.get("startup_ms", PRACTICAL_STARTUP_LIMIT_MS + 1.0)) > PRACTICAL_STARTUP_LIMIT_MS:
		failures.append("startup exceeded %.0f ms practical limit" % PRACTICAL_STARTUP_LIMIT_MS)
	if float(report.get("average_frame_ms", PRACTICAL_FRAME_LIMIT_MS + 1.0)) > PRACTICAL_FRAME_LIMIT_MS:
		failures.append("frame sample exceeded %.0f ms practical limit" % PRACTICAL_FRAME_LIMIT_MS)
	return failures
