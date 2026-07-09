extends Node

const DEFAULT_VOLUME_DB := -8.0
const HIGH_PRIORITY_VOLUME_DB := -6.0
const NORMAL_COOLDOWN_SECONDS := 0.08
const MEDIUM_COOLDOWN_SECONDS := 0.35
const HIGH_COOLDOWN_SECONDS := 0.12

const CUE_PATHS := {
	"salvage_pickup": "res://assets/audio/cues/salvage_pickup.wav",
	"salvage_bank": "res://assets/audio/cues/salvage_bank.wav",
	"oxygen_low": "res://assets/audio/cues/oxygen_low.wav",
	"oxygen_critical": "res://assets/audio/cues/oxygen_critical.wav",
	"oxygen_failure": "res://assets/audio/cues/oxygen_failure.wav",
	"hazard_warning": "res://assets/audio/cues/hazard_warning.wav",
	"hazard_contact": "res://assets/audio/cues/hazard_contact.wav",
	"upgrade_purchase": "res://assets/audio/cues/upgrade_purchase.wav",
}

const CUE_PRIORITIES := {
	"salvage_pickup": "normal",
	"salvage_bank": "normal",
	"oxygen_low": "medium",
	"oxygen_critical": "high",
	"oxygen_failure": "high",
	"hazard_warning": "medium",
	"hazard_contact": "high",
	"upgrade_purchase": "normal",
}

var _streams: Dictionary = {}
var _players: Dictionary = {}
var _last_played_at: Dictionary = {}
var _event_log: Array[Dictionary] = []
var _enabled := true
var _playback_available := true


func _ready() -> void:
	_playback_available = DisplayServer.get_name() != "headless"
	if not _playback_available:
		return
	_load_streams()
	_create_players()


func play_cue(cue_id: String, dedupe_key := "") -> bool:
	var priority := str(CUE_PRIORITIES.get(cue_id, "normal"))
	var event := {
		"cue_id": cue_id,
		"priority": priority,
		"dedupe_key": dedupe_key,
		"played": false,
		"reason": "",
	}
	_event_log.append(event)

	if not _enabled:
		event["reason"] = "disabled"
		return false
	if not CUE_PATHS.has(cue_id):
		event["reason"] = "unknown_cue"
		return false
	if not _playback_available:
		event["reason"] = "headless_audio"
		return false
	if not _streams.has(cue_id):
		event["reason"] = "missing_stream"
		return false
	if _is_in_cooldown(cue_id, dedupe_key, priority):
		event["reason"] = "cooldown"
		return false

	var player: AudioStreamPlayer = _players.get(priority, null)
	if player == null:
		event["reason"] = "missing_player"
		return false

	player.stop()
	player.stream = null
	player.stream = _streams[cue_id]
	player.volume_db = HIGH_PRIORITY_VOLUME_DB if priority == "high" else DEFAULT_VOLUME_DB
	player.play()
	_last_played_at[_cooldown_key(cue_id, dedupe_key)] = Time.get_ticks_msec() / 1000.0
	event["played"] = true
	event["reason"] = "played"
	return true


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if enabled:
		return
	for player in _players.values():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null


func shutdown() -> void:
	for player in _players.values():
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null
	_streams.clear()


func has_cue(cue_id: String) -> bool:
	if not CUE_PATHS.has(cue_id):
		return false
	return not _playback_available or _streams.has(cue_id)


func event_log() -> Array[Dictionary]:
	return _event_log.duplicate(true)


func clear_event_log() -> void:
	_event_log.clear()


func _load_streams() -> void:
	for cue_id in CUE_PATHS.keys():
		var path := str(CUE_PATHS[cue_id])
		if not FileAccess.file_exists(path):
			push_warning("Feedback cue asset missing: %s" % path)
			continue
		if not ResourceLoader.exists(path):
			continue
		var stream := load(path)
		if stream == null:
			push_warning("Feedback cue asset could not load: %s" % path)
			continue
		_streams[cue_id] = stream


func _create_players() -> void:
	for priority in ["normal", "medium", "high"]:
		var player := AudioStreamPlayer.new()
		player.name = "FeedbackCue%s" % priority.capitalize()
		player.volume_db = DEFAULT_VOLUME_DB
		add_child(player)
		_players[priority] = player


func _is_in_cooldown(cue_id: String, dedupe_key: String, priority: String) -> bool:
	var key := _cooldown_key(cue_id, dedupe_key)
	if not _last_played_at.has(key):
		return false
	var elapsed := (Time.get_ticks_msec() / 1000.0) - float(_last_played_at[key])
	return elapsed < _cooldown_seconds(priority)


func _cooldown_key(cue_id: String, dedupe_key: String) -> String:
	if dedupe_key.is_empty():
		return cue_id
	return "%s:%s" % [cue_id, dedupe_key]


func _cooldown_seconds(priority: String) -> float:
	if priority == "high":
		return HIGH_COOLDOWN_SECONDS
	if priority == "medium":
		return MEDIUM_COOLDOWN_SECONDS
	return NORMAL_COOLDOWN_SECONDS
