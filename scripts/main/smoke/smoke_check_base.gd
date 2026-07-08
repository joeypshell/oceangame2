extends RefCounted

const SMOKE_TIMED_SALVAGE_MARGIN_SECONDS := 0.1

var _main

var _world: Node:
	get:
		return _main._world
	set(value):
		_main._world = value

var _player: Node:
	get:
		return _main._player
	set(value):
		_main._player = value

var _status_label: Label:
	get:
		return _main._status_label

var _result_panel: PanelContainer:
	get:
		return _main._result_panel

var _result_label: Label:
	get:
		return _main._result_label

var _total_salvage: int:
	get:
		return _main._total_salvage

var _held_salvage: int:
	get:
		return _main._held_salvage
	set(value):
		_main._held_salvage = value

var _banked_salvage: int:
	get:
		return _main._banked_salvage
	set(value):
		_main._banked_salvage = value

var _held_salvage_ids: Array[String]:
	get:
		return _main._held_salvage_ids
	set(value):
		_main._held_salvage_ids = value

var _held_salvage_score: int:
	get:
		return _main._held_salvage_score
	set(value):
		_main._held_salvage_score = value

var _banked_score: int:
	get:
		return _main._banked_score
	set(value):
		_main._banked_score = value

var _completion_oxygen_bonus: int:
	get:
		return _main._completion_oxygen_bonus

var _session_best_scores_by_map: Dictionary:
	get:
		return _main._session_best_scores_by_map

var _hazard_cooldown_seconds: float:
	get:
		return _main._hazard_cooldown_seconds
	set(value):
		_main._hazard_cooldown_seconds = value

var _hazard_interactions_enabled: bool:
	get:
		return _main._hazard_interactions_enabled
	set(value):
		_main._hazard_interactions_enabled = value

var _hazard_warning_id: String:
	get:
		return _main._hazard_warning_id
	set(value):
		_main._hazard_warning_id = value

var _oxygen_seconds: float:
	get:
		return _main._oxygen_seconds
	set(value):
		_main._oxygen_seconds = value

var _run_complete: bool:
	get:
		return _main._run_complete

var _run_failed: bool:
	get:
		return _main._run_failed

var _last_status_note: String:
	get:
		return _main._last_status_note
	set(value):
		_main._last_status_note = value

var HELD_SALVAGE_CAPACITY: int:
	get:
		return _main.HELD_SALVAGE_CAPACITY

var SALVAGE_COLLECTION_RADIUS: float:
	get:
		return _main.SALVAGE_COLLECTION_RADIUS

var HAZARD_CONTACT_RADIUS: float:
	get:
		return _main.HAZARD_CONTACT_RADIUS

var HAZARD_WARNING_RADIUS: float:
	get:
		return _main.HAZARD_WARNING_RADIUS

var HAZARD_OXYGEN_PENALTY_SECONDS: float:
	get:
		return _main.HAZARD_OXYGEN_PENALTY_SECONDS

var OXYGEN_MAX_SECONDS: float:
	get:
		return _main.OXYGEN_MAX_SECONDS

var OXYGEN_BONUS_POINTS_PER_SECOND: int:
	get:
		return _main.OXYGEN_BONUS_POINTS_PER_SECOND

var SAFE_ROUTE_CHOICE_ID: String:
	get:
		return _main.SAFE_ROUTE_CHOICE_ID

var EXPANDED_ROUTE_CHOICE_ID: String:
	get:
		return _main.EXPANDED_ROUTE_CHOICE_ID

var MOVEMENT_FEEL_PROBE_CENTER_TILES: Vector2:
	get:
		return _main.MOVEMENT_FEEL_PROBE_CENTER_TILES

var PRODUCTION_SLICE_MAP_PATH: String:
	get:
		return _main.PRODUCTION_SLICE_MAP_PATH

var PRODUCTION_SLICE_02_MAP_PATH: String:
	get:
		return _main.PRODUCTION_SLICE_02_MAP_PATH

var PRODUCTION_SLICE_03_MAP_PATH: String:
	get:
		return _main.PRODUCTION_SLICE_03_MAP_PATH


func _init(main_node) -> void:
	_main = main_node


func get_tree() -> SceneTree:
	return _main.get_tree()


func _process(delta: float) -> void:
	_main._process(delta)


func _collect_salvage_for_smoke(salvage: Dictionary) -> bool:
	var salvage_id := str(salvage.get("id", "salvage"))
	_process(0.0)
	if _world.is_salvage_collected(salvage_id):
		return true
	if str(salvage.get("interaction", "instant")) != "timed_salvage":
		return false

	var interaction_seconds := maxf(0.01, float(salvage.get("interaction_seconds", 0.0)))
	_process(interaction_seconds + SMOKE_TIMED_SALVAGE_MARGIN_SECONDS)
	return _world.is_salvage_collected(salvage_id)


func _reset_run() -> void:
	_main._reset_run()


func _load_playable_map(map_path: String, show_debug_overlay: bool) -> void:
	_main._load_playable_map(map_path, show_debug_overlay)


func _update_status_label() -> void:
	_main._update_status_label()


func _handle_oxygen_depleted() -> void:
	_main._handle_oxygen_depleted()


func _session_best_score() -> int:
	return _main._session_best_score()


func _current_expedition_score() -> int:
	return _main._current_expedition_score()


func _complete_route_outcome_review_state() -> bool:
	return _main._complete_route_outcome_review_state()


func _oxygen_feedback_label() -> String:
	return _main._oxygen_feedback_label()


func _salvage_collection_feedback(tier: String, score: int) -> String:
	return _main._salvage_collection_feedback(tier, score)
