extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

var _smoke
var _hostile_id: String
var _guarded_cache_id: String
var _weapon_recipe: Dictionary


func _init(smoke, hostile_id: String, guarded_cache_id: String, weapon_recipe: Dictionary) -> void:
	_smoke = smoke
	_hostile_id = hostile_id
	_guarded_cache_id = guarded_cache_id
	_weapon_recipe = weapon_recipe


func verify_source_contract(encounter: Dictionary, project: Dictionary) -> bool:
	if not _smoke._require(str(encounter.get("id", "")) == _hostile_id and str(encounter.get("behavior", "")) == "territorial_lunge", "hostile source id or behavior drifted"):
		return false
	if not _smoke._require(encounter.get("territory_rect", Rect2()) == Rect2(Vector2(60, 71) * 32.0, Vector2(10, 8) * 32.0), "hostile territory drifted"):
		return false
	if not _smoke._require(int(_smoke._world.get_hostile_visual_report().get("rendered_count", 0)) == 1, "source encounter did not create one hostile visual"):
		return false
	var required_materials: Dictionary = project.get("required_materials", {})
	if not _smoke._require(
		str(project.get("target_hostile_id", "")) == _hostile_id
		and int(required_materials.get(ExpansionProfileState.TITANIUM_MATERIAL_ID, 0)) == 2
		and int(required_materials.get(ExpansionProfileState.COIL_MATERIAL_ID, 0)) == 1
		and required_materials.size() == 2,
		"shock prod project target or recipe drifted"
	):
		return false
	var source_materials: Dictionary = {}
	for candidate in _smoke._world.get_material_candidates():
		var material_id: String = str(candidate.get("material_id", ""))
		if _weapon_recipe.has(material_id) and str(candidate.get("type", "")) == "material_candidate":
			source_materials[material_id] = true
	var guarded_cache: Dictionary = _smoke._salvage_by_id(_guarded_cache_id)
	return _smoke._require(
		source_materials.size() == _weapon_recipe.size()
		and not project.has("drops")
		and not project.has("loot")
		and str(guarded_cache.get("guarded_by_hostile_id", "")) == _hostile_id
		and str(guarded_cache.get("required_capability_id", "")).is_empty()
		and str(guarded_cache.get("locked_label", "")).is_empty()
		and str(guarded_cache.get("guard_active_label", "")).is_empty()
		and not _smoke._main._primary_dive_objective.is_required_target(_guarded_cache_id),
		"project recipe, guarded cache link, or pre-weapon objective dependency drifted"
	)


func verify_behavioral_cache_guard() -> bool:
	var guarded_cache: Dictionary = _smoke._salvage_by_id(_guarded_cache_id)
	if not _smoke._require(not guarded_cache.is_empty(), "guarded cache source is missing"):
		return false
	_smoke._main._hostiles.reset_for_failure(_smoke._world)
	_smoke._main._player_health.reset()
	_smoke._main._timed_salvage.reset()
	_smoke._combat_interactions_enabled = true
	_smoke._player.global_position = guarded_cache["center"]
	_smoke._process(0.0)
	if not _smoke._require(_smoke._main._timed_salvage.is_active() and _smoke._status_text().find("Salvaging deep cache") != -1, "unarmed cache attempt did not start visible timed progress"):
		return false
	if not _smoke._require(_smoke._last_status_note.to_lower().find("locked") == -1 and _smoke._last_status_note.find("Shock prod required") == -1, "cache attempt still exposed a hard collection lock"):
		return false
	for _step in range(30):
		_smoke._process(0.1)
		if _smoke._main._player_health.current_health < 3:
			break
	var interruption_note: String = _smoke._last_status_note
	var interrupted: bool = (
		_smoke._main._player_health.current_health == 2
		and not _smoke._main._timed_salvage.is_active()
		and not _smoke._world.is_salvage_collected(_guarded_cache_id)
		and not _smoke._held_salvage_ids.has(_guarded_cache_id)
		and interruption_note.find("knocked back") != -1
	)
	_smoke._reset_run()
	_smoke._prepare_current_map()
	return _smoke._require(interrupted, "active eel did not behaviorally interrupt the attempt: %s" % interruption_note)
