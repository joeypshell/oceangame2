extends RefCounted

const SPARK_RAY := "spark_ray"
const VEIL_CUTTLE := "veil_cuttle"
const SILT_HOUND := "silt_hound"
const SPARK_RAY_SCENE := preload("res://scenes/companion/SparkRayCompanion.tscn")
const VEIL_CUTTLE_SCENE := preload("res://scenes/companion/VeilCuttleCompanion.tscn")
const SILT_HOUND_SCENE := preload("res://scenes/companion/SiltHoundCompanion.tscn")
const CompanionControlRuntime := preload("res://scripts/companion/companion_control_runtime.gd")
const VeilCuttleControlRuntime := preload("res://scripts/companion/veil_cuttle_control_runtime.gd")
const SiltHoundControlRuntime := preload("res://scripts/companion/silt_hound_control_runtime.gd")


func create_companion(species_id: String):
	match species_id:
		SPARK_RAY:
			return SPARK_RAY_SCENE.instantiate()
		VEIL_CUTTLE:
			return VEIL_CUTTLE_SCENE.instantiate()
		SILT_HOUND:
			return SILT_HOUND_SCENE.instantiate()
	return null


func create_control(species_id: String):
	match species_id:
		SPARK_RAY:
			return CompanionControlRuntime.new()
		VEIL_CUTTLE:
			return VeilCuttleControlRuntime.new()
		SILT_HOUND:
			return SiltHoundControlRuntime.new()
	return null


func default_callsign(species_id: String) -> String:
	match species_id:
		VEIL_CUTTLE:
			return "Mica"
		SILT_HOUND:
			return "Marl"
	return "Kite"


func display_name(species_id: String) -> String:
	match species_id:
		VEIL_CUTTLE:
			return "Veil Cuttle"
		SILT_HOUND:
			return "Silt Hound"
	return "Spark Ray"


func is_supported(species_id: String) -> bool:
	return species_id in [SPARK_RAY, VEIL_CUTTLE, SILT_HOUND]
