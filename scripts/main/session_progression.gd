extends RefCounted

const OXYGEN_TANK_UPGRADE_ID := "oxygen_tank_1"
const OXYGEN_TANK_UPGRADE_COST := 500
const OXYGEN_TANK_UPGRADE_SECONDS := 15.0

var _wallet := 0
var _total_payout_earned := 0


func record_banked_salvage(banked_score: int) -> int:
	var payout: int = max(0, banked_score)
	if payout <= 0:
		return 0
	_wallet += payout
	_total_payout_earned += payout
	return payout


func wallet() -> int:
	return _wallet


func total_payout_earned() -> int:
	return _total_payout_earned
