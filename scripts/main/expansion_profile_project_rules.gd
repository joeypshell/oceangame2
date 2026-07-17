extends RefCounted

const RULES := {
	"propulsion_fins_project": {
		"capability_id": "propulsion_fins",
		"required_discovery_id": "propulsion_fins_blueprint",
		"required_project_id": "",
		"target_field": "target_gate_id",
		"target_id": "upper_right_current_pocket_gate",
		"required_materials": {"titanium_scrap": 2, "rubber_sheet": 1},
	},
	"survey_scanner_project": {
		"capability_id": "survey_scanner_1",
		"required_discovery_id": "survey_scanner_blueprint",
		"required_project_id": "",
		"target_field": "target_id",
		"target_id": "lower_right_anomaly_survey",
		"required_materials": {"titanium_scrap": 1, "conductive_coil": 1},
	},
	"salvage_cutter_project": {
		"capability_id": "salvage_cutter",
		"required_discovery_id": "salvage_cutter_blueprint",
		"legacy_required_discovery_id": "lower_right_anomaly_discovery",
		"required_project_id": "",
		"target_field": "target_id",
		"target_id": "salvage_sealed_wreck_cache",
		"required_materials": {"titanium_scrap": 2, "conductive_coil": 1},
	},
	"current_stabilizer_project": {
		"capability_id": "current_stabilizer",
		"required_discovery_id": "lower_right_anomaly_discovery",
		"required_project_id": "salvage_cutter_project",
		"target_field": "target_gate_id",
		"target_id": "lower_left_loop_current",
		"required_materials": {"titanium_scrap": 2, "conductive_coil": 1},
	},
	"shock_prod_project": {
		"capability_id": "shock_prod",
		"required_discovery_id": "lower_right_anomaly_discovery",
		"required_project_id": "salvage_cutter_project",
		"target_field": "target_hostile_id",
		"target_id": "deep_cache_territorial_eel",
		"required_materials": {"titanium_scrap": 2, "conductive_coil": 1},
		"capability_effect": "",
	},
	"shock_prod_capacitor_project": {
		"capability_id": "shock_prod_capacitor",
		"required_discovery_id": "lower_right_anomaly_discovery",
		"required_project_id": "shock_prod_project",
		"target_field": "target_hostile_id",
		"target_id": "deep_cache_territorial_eel",
		"required_materials": {"conductive_coil": 1, "insulating_gel": 1, "eel_electrocyte": 1},
		"capability_effect": "interrupt_warning_lunge",
	},
	"dive_light_1_project": {
		"capability_id": "dive_light_1",
		"required_discovery_id": "lower_right_signal_reef_discovery",
		"required_project_id": "",
		"target_field": "target_id",
		"target_id": "signal_reef_deep_harmonic_survey",
		"required_materials": {"titanium_scrap": 1, "conductive_coil": 1, "insulating_gel": 1},
	},
	"pressure_suit_1_project": {
		"capability_id": "pressure_suit_1",
		"required_discovery_id": "signal_reef_deep_harmonic_discovery",
		"required_project_id": "",
		"target_field": "target_id",
		"target_id": "abyssal_basin_harmonic_source_survey",
		"required_materials": {"titanium_scrap": 2, "rubber_sheet": 1, "insulating_gel": 1},
	},
}


static func validate_definition(project_definition: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	var rules: Dictionary = RULES.get(str(project_definition.get("id", "")), {})
	if rules.is_empty():
		return ["unsupported project id"]
	var authored_discovery := str(project_definition.get("required_discovery_id", ""))
	var supported_discoveries: Array[String] = [str(rules.get("required_discovery_id", ""))]
	var legacy_discovery := str(rules.get("legacy_required_discovery_id", ""))
	if not legacy_discovery.is_empty():
		supported_discoveries.append(legacy_discovery)
	if authored_discovery not in supported_discoveries:
		failures.append("unsupported project discovery")
	if str(project_definition.get("unlocks_capability_id", "")) != str(rules["capability_id"]):
		failures.append("unsupported project capability")
	if str(project_definition.get("required_project_id", "")) != str(rules["required_project_id"]):
		failures.append("unsupported project prerequisite")
	var authored_target_fields := []
	for target_field in ["target_id", "target_gate_id", "target_hostile_id"]:
		if project_definition.has(target_field):
			authored_target_fields.append(target_field)
	if authored_target_fields.size() != 1 or str(project_definition.get(str(rules["target_field"]), "")) != str(rules["target_id"]):
		failures.append("unsupported project target")
	if str(project_definition.get("build_phase", "")) != "night_debrief":
		failures.append("unsupported project build phase")
	if str(project_definition.get("capability_effect", "")) != str(rules.get("capability_effect", "")):
		failures.append("unsupported project capability effect")
	var required = project_definition.get("required_materials")
	if typeof(required) != TYPE_DICTIONARY:
		failures.append("project required_materials must be an object")
		return failures
	var expected: Dictionary = rules["required_materials"]
	if required.size() != expected.size():
		failures.append("project recipe has unsupported materials")
	for material_id in expected:
		var quantity = required.get(material_id)
		if not _is_nonnegative_integer_value(quantity) or int(quantity) != int(expected[material_id]):
			failures.append("project recipe %s must equal %d" % [material_id, expected[material_id]])
	return failures


static func _is_nonnegative_integer_value(value) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var number := float(value)
	return is_finite(number) and number >= 0.0 and is_equal_approx(number, floor(number))
