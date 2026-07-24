extends SceneTree

const ActiveToolHud := preload("res://scripts/main/active_tool_hud.gd")
const HeldCargoHud := preload("res://scripts/main/held_cargo_hud.gd")
const MaterialCargoState := preload("res://scripts/main/material_cargo_state.gd")
const SortieState := preload("res://scripts/main/sortie_state.gd")
const OWNED_CAPABILITIES := [
	"survey_scanner_1",
	"salvage_cutter",
	"shock_prod",
	"propulsion_fins",
	"dive_light_1",
	"pressure_suit_1",
	"current_stabilizer",
	"shock_prod_capacitor",
]
const PASSIVE_CAPABILITIES := [
	"propulsion_fins",
	"dive_light_1",
	"pressure_suit_1",
	"current_stabilizer",
	"shock_prod_capacitor",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cargo := HeldCargoHud.new()
	var active_tool := ActiveToolHud.new()
	get_root().add_child(cargo)
	get_root().add_child(active_tool)
	await process_frame

	active_tool.refresh({
		"selected_tool_id": "survey_scanner_1",
		"owned_tool_ids": ["survey_scanner_1", "salvage_cutter", "shock_prod"],
	})
	cargo.layout_for_size(Vector2(1280, 720))
	active_tool.layout_for_size(Vector2(1280, 720))
	cargo.refresh({}, {}, 2, OWNED_CAPABILITIES)
	var report: Dictionary = cargo.get_test_report()
	var desktop_rect: Rect2 = report.get("rect", Rect2())
	_expect(report.get("used") == 0 and report.get("available") == 2, "empty cargo capacity was wrong")
	_expect(report.get("items", []).is_empty(), "empty cargo rendered an item")
	_expect(not desktop_rect.intersects(active_tool.get_test_report().get("rect", Rect2())), "desktop cargo overlapped active tool")
	_expect(desktop_rect.position.x >= 312.0 and desktop_rect.end.x <= 976.0, "desktop cargo overlapped an edge HUD owner")
	_expect(active_tool.get_test_report().get("bottom_gap") == 18.0, "desktop active-tool hotbar left the bottom band")
	var equipment: Dictionary = report.get("equipment", {})
	_expect(equipment.get("title") == "EQUIPPED", "desktop passive strip title drifted")
	_expect(_equipment_ids(equipment) == PASSIVE_CAPABILITIES, "desktop passive equipment order/filter drifted: %s" % str(equipment.get("owned_items", [])))
	_expect(equipment.get("displayed_items", []).size() == 5 and equipment.get("slots", []).size() == 5, "desktop passive strip did not show five stable slots")
	for slot in equipment.get("slots", []):
		_expect(bool(slot.get("has_texture", false)), "desktop passive equipment slot lacked a named icon: %s" % slot)
		_expect(not str(slot.get("tooltip", "")).is_empty(), "desktop passive equipment slot lacked a tooltip")
	for active_tool_id in ["survey_scanner_1", "salvage_cutter", "shock_prod"]:
		_expect(not _equipment_ids(equipment).has(active_tool_id), "active tool leaked into passive equipment: %s" % active_tool_id)

	var materials := MaterialCargoState.new()
	materials.collect(_candidate("titanium_a", "titanium_scrap"), "production_level_01")
	var material_report: Dictionary = materials.report()
	material_report["banked_materials"] = {"rubber_sheet": 99}
	cargo.refresh(material_report, {}, 2, OWNED_CAPABILITIES)
	report = cargo.get_test_report()
	_expect(_item_ids(report) == ["titanium_scrap"], "banked profile materials leaked into held cargo: %s" % report.get("items", []))
	_expect(bool(report.get("items", [])[0].get("has_texture", false)), "named titanium asset was not used")

	var sortie := SortieState.new(90.0)
	sortie.collect_salvage("upper_left_wreck_relay_core", 300)
	cargo.refresh(material_report, sortie.report(), 2, OWNED_CAPABILITIES)
	report = cargo.get_test_report()
	_expect(report.get("used") == 2 and report.get("available") == 0, "mixed full cargo capacity was wrong")
	_expect(_item_ids(report) == ["titanium_scrap", "held_salvage"], "mixed material/salvage order drifted")
	_expect(str(report.get("capacity_text", "")).find("0 free") != -1, "full cargo did not show available capacity")

	materials.clear()
	sortie.clear_held()
	cargo.refresh(materials.report(), sortie.report(), 2, OWNED_CAPABILITIES)
	report = cargo.get_test_report()
	_expect(report.get("used") == 0 and report.get("items", []).is_empty(), "bank/restoration clear left stale cargo")

	var biological := MaterialCargoState.new()
	for entry in [
		_candidate("titanium_b", "titanium_scrap"),
		_candidate("rubber_b", "rubber_sheet"),
		_candidate("coil_b", "conductive_coil"),
		_candidate("gel_b", "insulating_gel"),
		_candidate("electro_b", "eel_electrocyte"),
	]:
		biological.collect(entry, "production_level_01")
	cargo.refresh(biological.report(), {}, 6, OWNED_CAPABILITIES)
	cargo.layout_for_size(Vector2(844, 390))
	active_tool.layout_for_size(Vector2(844, 390))
	report = cargo.get_test_report()
	var cargo_rect: Rect2 = report.get("rect", Rect2())
	var tool_rect: Rect2 = active_tool.get_test_report().get("rect", Rect2())
	_expect(bool(report.get("compact", false)) and cargo_rect == Rect2(313, 12, 96, 72), "landscape cargo left its stable safe column: %s" % cargo_rect)
	_expect(cargo_rect.end.x <= 410.0 and cargo_rect.position.x >= 312.0, "landscape cargo overlapped edge HUD or touch buttons")
	_expect(not cargo_rect.intersects(tool_rect) and tool_rect.position.y >= 286.0 and tool_rect.end.y <= 390.0, "landscape hotbar left its reserved bottom band: %s" % tool_rect)
	_expect(report.get("displayed_items", []).size() == 2 and report.get("displayed_items", [])[1].get("id") == "overflow", "compact cargo did not bound overflow types")
	_expect(not bool(_item_by_id(report, "insulating_gel").get("has_texture", true)), "gel fallback unexpectedly claimed an asset")
	equipment = report.get("equipment", {})
	_expect(equipment.get("title") == "EQ" and bool(equipment.get("compact", false)), "compact passive equipment mode drifted")
	_expect(equipment.get("displayed_items", []).size() == 1 and equipment.get("slots", []).size() == 1, "compact equipment did not collapse to one summary")
	if not equipment.get("slots", []).is_empty():
		var compact_slot: Dictionary = equipment.get("slots", [])[0]
		_expect(compact_slot.get("badge") == "5", "compact equipment summary count was wrong")
		_expect(str(compact_slot.get("tooltip", "")).find("Current Stabilizer") != -1, "compact equipment tooltip omitted owned passives")
	cargo.layout_for_size(Vector2(932, 430))
	active_tool.layout_for_size(Vector2(932, 430))
	cargo_rect = cargo.get_test_report().get("rect", Rect2())
	tool_rect = active_tool.get_test_report().get("rect", Rect2())
	_expect(cargo_rect.end.x <= 498.0 and not cargo_rect.intersects(tool_rect), "wide-mobile HUDs entered the touch-button region")
	_expect(bool(active_tool.get_test_report().get("compact", false)), "wide-mobile active tool did not share the cargo breakpoint")

	cargo.queue_free()
	active_tool.queue_free()
	await process_frame
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Held cargo HUD smoke failed: %s" % failure)
		quit(1)
		return
	print("Held cargo HUD smoke passed: owner=read_only cargo_slots=6 compact_cargo_slots=2 passive_equipment=5 compact_equipment=summary named_assets=Ti+Rubber+Coil+Relic fallbacks=Gel+Electro capacity=used+free banked_excluded=true active_tools_excluded=true layouts=1280x720+844x390 active_tool_bottom_separate=true.")
	quit(0)


func _candidate(candidate_id: String, material_id: String) -> Dictionary:
	return {"id": candidate_id, "material_id": material_id, "material_quantity": 1}


func _item_ids(report: Dictionary) -> Array:
	return report.get("items", []).map(func(item): return str(item.get("id", "")))


func _item_by_id(report: Dictionary, item_id: String) -> Dictionary:
	for item in report.get("items", []):
		if str(item.get("id", "")) == item_id:
			return item
	return {}


func _equipment_ids(report: Dictionary) -> Array:
	return report.get("owned_items", []).map(func(item): return str(item.get("id", "")))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
