extends RefCounted

const SPARK_RAY := "spark_ray"
const VEIL_CUTTLE := "veil_cuttle"
const SPARK_RAY_SCENE := preload("res://scenes/companion/SparkRayCompanion.tscn")
const VEIL_CUTTLE_SCENE := preload("res://scenes/companion/VeilCuttleCompanion.tscn")
const CompanionControlRuntime := preload("res://scripts/companion/companion_control_runtime.gd")
const VeilCuttleControlRuntime := preload("res://scripts/companion/veil_cuttle_control_runtime.gd")


func create_companion(species_id: String):
	match species_id:
		SPARK_RAY:
			return SPARK_RAY_SCENE.instantiate()
		VEIL_CUTTLE:
			return VEIL_CUTTLE_SCENE.instantiate()
	return null


func create_control(species_id: String):
	match species_id:
		SPARK_RAY:
			return CompanionControlRuntime.new()
		VEIL_CUTTLE:
			return VeilCuttleControlRuntime.new()
	return null


func default_callsign(species_id: String) -> String:
	return "Mica" if species_id == VEIL_CUTTLE else "Kite"


func display_name(species_id: String) -> String:
	return "Veil Cuttle" if species_id == VEIL_CUTTLE else "Spark Ray"


func is_supported(species_id: String) -> bool:
	return species_id in [SPARK_RAY, VEIL_CUTTLE]
