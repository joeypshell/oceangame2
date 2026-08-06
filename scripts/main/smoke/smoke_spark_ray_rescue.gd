extends SceneTree

const WORLD_SCENE := preload("res://scenes/world/GreyboxWorld.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const ActiveToolController := preload("res://scripts/main/active_tool_controller.gd")
const ActiveToolRuntime := preload("res://scripts/main/active_tool_runtime.gd")
const CompanionRescueRuntime := preload("res://scripts/companion/companion_rescue_runtime.gd")
const CompanionSortieRuntime := preload("res://scripts/companion/companion_sortie_runtime.gd")
const CutterSalvageController := preload("res://scripts/main/cutter_salvage_controller.gd")
const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const SortieState := preload("res://scripts/main/sortie_state.gd")

const MAP_PATH := "res://maps/production_level_01.greybox.json"
const PROFILE_PATH := "user://smoke_spark_ray_rescue_profile.json"
const RESCUE_ID := "spark_ray_rescue_01"
const INDIVIDUAL_ID := "spark_ray_juvenile_01"
const SPECIES_ID := "spark_ray"
const CUTTER_ID := "salvage_cutter"
const BOAT_ENTRY_ID := "surface_boat_entry"

var _failures: Array[String] = []


class ProfileFacade:
	extends RefCounted

	var _profile

	func _init(profile) -> void:
		_profile = profile

	func profile_state():
		return _profile


class ActiveToolMainFixture:
	extends RefCounted

	const SALVAGE_COLLECTION_RADIUS := 34.0

	var _companion_rescue
	var _world
	var _player
	var _cutter_salvage
	var _anomaly_survey
	var _last_status_note := ""

	func _init(runtime, world, player, profile) -> void:
		_companion_rescue = runtime
		_world = world
		_player = player
		_cutter_salvage = CutterSalvageController.new(profile)
		_anomaly_survey = ProfileFacade.new(profile)

	func _held_cargo_count() -> int:
		return 2

	func _held_salvage_capacity() -> int:
		return 2

	func _update_status_label() -> void:
		pass


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_profile()
	var world := WORLD_SCENE.instantiate()
	world.map_path = MAP_PATH
	get_root().add_child(world)
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	get_root().add_child(player)
	player.set_physics_process(false)
	await physics_frame

	var rescues: Array = world.get_creature_rescues()
	_expect(rescues.size() == 2, "full-level source did not expose the bounded two-rescue set")
	var rescue := {}
	for candidate in rescues:
		if str(candidate.get("id", "")) == RESCUE_ID:
			rescue = candidate
			break
	_expect(not rescue.is_empty(), "full-level source omitted the Spark Ray rescue")
	if rescue.is_empty():
		_finish(world, player, null, null)
		return
	_expect(str(rescue.get("id", "")) == RESCUE_ID, "source rescue id drifted")
	_expect(str(rescue.get("rescue_kind", "")) == "physical_aid", "source rescue stopped being physical aid")
	_expect(str(rescue.get("required_capability_id", "")) == CUTTER_ID, "source rescue lost its Cutter requirement")
	_expect(str(rescue.get("commit_entry_id", "")) == BOAT_ENTRY_ID, "source rescue lost its canonical boat entry")
	var marker := world.get_node_or_null("Markers/%s" % RESCUE_ID)
	_expect(marker != null and marker.get_node_or_null("MaintenanceCable") != null, "rescue marker did not render a distinct maintenance cable")

	var profile := ExpansionProfileState.new(PROFILE_PATH, true)
	profile.load_profile()
	var runtime := CompanionRescueRuntime.new()
	get_root().add_child(runtime)
	player.global_position = rescue.get("center", Vector2.ZERO)
	runtime.bind_map(
		world,
		player,
		profile,
		Callable(self, "_has_no_upgrade"),
		Callable(profile, "has_capability"),
		34.0
	)
	_expect(str(world.get_creature_rescue_report().get("states", {}).get(RESCUE_ID, "")) == "available", "fresh rescue marker was not available")
	_expect(str(runtime.activate().get("reason", "")) == "missing_capability", "rescue allowed physical aid without the Cutter")

	_seed_cutter_profile(profile, world)
	var full_cargo := SortieState.new(90.0)
	full_cargo.collect_salvage("cargo_a", 100)
	full_cargo.collect_salvage("cargo_b", 100)
	_expect(full_cargo.held_salvage == 2, "full-cargo fixture was not full")
	var selection := ActiveToolController.new()
	var tool_main := ActiveToolMainFixture.new(runtime, world, player, profile)
	var tool_runtime := ActiveToolRuntime.new(tool_main, selection)
	selection.refresh_ownership(Callable(profile, "has_capability"))
	_expect(selection.selected_tool_id() == CUTTER_ID, "full-cargo tool fixture did not select Cutter")
	var activated: Dictionary = tool_runtime.use()
	_expect(str(activated.get("status", "")) == "used", "full cargo blocked Cutter dispatch to the non-cargo rescue")
	var partial: Dictionary = runtime.update(CompanionRescueRuntime.RELEASE_SECONDS * 0.5)
	_expect(str(partial.get("state", "")) == "releasing", "held Cutter did not advance rescue progress")
	_expect(float(runtime.report().get("release_progress", 0.0)) >= 0.49, "partial rescue progress was not reported")
	_expect(not profile.has_committed_companion(), "partial rescue wrote durable companion state")
	var canceled: Dictionary = tool_runtime.release_use()
	_expect(str(canceled.get("state", "")) == "canceled", "releasing USE did not cancel partial rescue")
	_expect(is_zero_approx(float(runtime.report().get("release_progress", -1.0))), "canceled rescue retained progress")
	_expect(str(world.get_creature_rescue_report().get("states", {}).get(RESCUE_ID, "")) == "available", "canceled rescue did not restore its source marker")

	_expect(bool(runtime.activate().get("changed", false)), "second Cutter hold did not activate")
	var completed: Dictionary = runtime.update(CompanionRescueRuntime.RELEASE_SECONDS + 0.1)
	_expect(str(completed.get("state", "")) == "complete", "complete Cutter hold did not free the juvenile")
	var pending_ray = runtime.pending_companion()
	_expect(pending_ray != null, "completed rescue did not create a sortie-local juvenile")
	_expect(not profile.has_committed_companion(), "release committed the bond before the boat")
	_expect(str(world.get_creature_rescue_report().get("states", {}).get(RESCUE_ID, "")) == "pending", "released rescue marker did not enter pending state")
	var transient_reload := ExpansionProfileState.new(PROFILE_PATH, true)
	transient_reload.load_profile()
	_expect(not transient_reload.has_committed_companion(), "profile reload persisted pending rescue state")
	if pending_ray != null:
		pending_ray.set_physics_process(false)
		player.global_position += Vector2(110.0, 0.0)
		pending_ray.advance(0.0)
		_expect(str(pending_ray.report().get("state", "")) in ["follow", "catch_up"], "freed juvenile did not enter a readable return-follow state")

	var wrong_destination: Dictionary = runtime.commit_at_boat()
	_expect(str(wrong_destination.get("reason", "")) == "not_at_commit_destination", "rescue committed away from the source-authored boat")
	var restored: Dictionary = runtime.reset_for_failure("oxygen_failure")
	_expect(bool(restored.get("changed", false)), "failure did not clear pending rescue")
	_expect(runtime.pending_companion() == null and not profile.has_committed_companion(), "failure retained transient juvenile or profile state")
	_expect(str(world.get_creature_rescue_report().get("states", {}).get(RESCUE_ID, "")) == "available", "failure did not restore source opportunity")

	player.global_position = rescue.get("center", Vector2.ZERO)
	runtime.activate()
	runtime.update(CompanionRescueRuntime.RELEASE_SECONDS + 0.1)
	runtime.clear_map("scene_exit")
	_expect(runtime.pending_companion() == null and not profile.has_committed_companion(), "scene exit retained transient rescue state")
	_expect(str(world.get_creature_rescue_report().get("states", {}).get(RESCUE_ID, "")) == "available", "scene exit did not restore source opportunity")
	runtime.bind_map(
		world,
		player,
		profile,
		Callable(self, "_has_no_upgrade"),
		Callable(profile, "has_capability"),
		34.0
	)
	runtime.activate()
	runtime.update(CompanionRescueRuntime.RELEASE_SECONDS + 0.1)
	var sortie_runtime := CompanionSortieRuntime.new()
	get_root().add_child(sortie_runtime)
	sortie_runtime.bind_map(world, player, profile, Callable(self, "_has_no_upgrade"), false)
	_expect(sortie_runtime.companion() == null, "pending rescue spawned a rideable companion")
	player.global_position = world.get_entry_position(BOAT_ENTRY_ID)
	_expect(world.is_inside_boat(player.global_position), "canonical entry fixture was outside the boat")
	var committed: Dictionary = runtime.commit_at_boat()
	_expect(bool(committed.get("changed", false)), "canonical boat did not commit the rescued individual")
	_expect(profile.has_committed_companion(), "boat commit omitted durable companion state")
	_expect(runtime.pending_companion() == null, "boat commit retained duplicate transient juvenile")
	_expect(sortie_runtime.companion() == null, "boat commit spawned riding before the next sortie")
	var committed_snapshot := profile.companion_report()
	var duplicate: Dictionary = runtime.commit_at_boat()
	_expect(not bool(duplicate.get("changed", false)), "boat commit duplicated the bond")
	_expect(profile.companion_report() == committed_snapshot, "duplicate commit changed persistent state")

	var reloaded := ExpansionProfileState.new(PROFILE_PATH, true)
	var reload_report: Dictionary = reloaded.load_profile()
	_expect(str(reload_report.get("status", "")) == "loaded", "committed profile did not reload")
	_expect(reloaded.has_committed_companion(), "profile reload lost committed bond")
	var next_sortie: Dictionary = sortie_runtime.sync_spawn()
	_expect(bool(next_sortie.get("spawned", false)) and sortie_runtime.companion() != null, "following sortie did not unlock the committed Spark Ray")
	_finish(world, player, runtime, sortie_runtime)


func _seed_cutter_profile(profile, world) -> void:
	var blueprint: Dictionary = profile.complete_discovery(
		ExpansionProfileState.SALVAGE_CUTTER_BLUEPRINT_ID,
		false
	)
	_expect(bool(blueprint.get("changed", false)), "Cutter blueprint fixture failed")
	var cutter_project := {}
	for project in world.get_material_projects():
		if str(project.get("id", "")) == ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID:
			cutter_project = project
			break
	_expect(not cutter_project.is_empty(), "map source omitted Cutter project")
	if cutter_project.is_empty():
		return
	var required_materials := {}
	for material_id in cutter_project.get("required_materials", {}):
		required_materials[str(material_id)] = int(cutter_project["required_materials"][material_id])
	var deposit: Dictionary = profile.deposit_materials(required_materials, false)
	_expect(bool(deposit.get("changed", false)), "Cutter material fixture failed: %s" % [deposit])
	var built: Dictionary = profile.complete_material_project(cutter_project, false)
	_expect(bool(built.get("changed", false)), "Cutter project fixture failed: %s" % [built])


func _has_no_upgrade(_upgrade_id: String) -> bool:
	return false


func _cleanup_profile() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var path := "%s%s" % [PROFILE_PATH, suffix]
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _finish(world, player, runtime, sortie_runtime) -> void:
	if sortie_runtime != null:
		sortie_runtime.clear_map()
		sortie_runtime.queue_free()
	if runtime != null:
		runtime.clear_map("smoke_complete")
		runtime.queue_free()
	player.queue_free()
	world.queue_free()
	_cleanup_profile()
	if not _failures.is_empty():
		for failure in _failures:
			push_error("Spark Ray rescue smoke failed: %s" % failure)
		quit(1)
		return
	print("PASS: Spark Ray rescue source=true cutter_hold=true cargo_independent=true cancel_restore=true pending_follow=true failure_restore=true boat_commit=true exact_once=true next_sortie=true persistence=true.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
