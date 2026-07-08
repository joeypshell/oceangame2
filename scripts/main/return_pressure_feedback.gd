extends RefCounted

const DEFAULT_CARGO_FULL_PROMPT := "Cargo full - return to extraction"
const RETURN_PRESSURE_ROUTE_ID := "return_pressure_decision"
const RETURN_PRESSURE_ROUTE_CHOICE_ID := "return_branch_bank_prompt"
const RETURN_PRESSURE_PROMPT := "Cargo full - bank at boat"


func cargo_full_prompt(nearby_salvage: Dictionary) -> String:
	if is_return_pressure_target(nearby_salvage):
		return RETURN_PRESSURE_PROMPT
	return DEFAULT_CARGO_FULL_PROMPT


func is_return_pressure_target(salvage: Dictionary) -> bool:
	if salvage.is_empty():
		return false
	if str(salvage.get("validation_route", "")) == RETURN_PRESSURE_ROUTE_ID:
		return true
	return str(salvage.get("route_choice_id", "")) == RETURN_PRESSURE_ROUTE_CHOICE_ID
