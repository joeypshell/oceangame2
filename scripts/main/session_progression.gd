extends RefCounted

const OXYGEN_TANK_UPGRADE_ID := "oxygen_tank_1"
const OXYGEN_TANK_UPGRADE_COST := 500
const OXYGEN_TANK_UPGRADE_SECONDS := 15.0
const CARGO_CAPACITY_UPGRADE_ID := "cargo_pouch_1"
const CARGO_CAPACITY_UPGRADE_COST := 700
const CARGO_CAPACITY_UPGRADE_BONUS := 1
const LIGHT_UPGRADE_ID := "dive_light_1"
const LIGHT_UPGRADE_COST := 900
const LIGHT_UPGRADE_RANGE_SCALE := 1.25
const LIGHT_UPGRADE_ALPHA := 0.48
const PROPULSION_UPGRADE_ID := "propulsion_fins"
const PROPULSION_UPGRADE_COST := 1000

var _wallet := 0
var _total_payout_earned := 0
var _purchased_upgrades: Dictionary = {}


func record_banked_salvage(banked_score: int) -> int:
	var payout: int = maxi(0, banked_score)
	if payout <= 0:
		return 0
	_wallet += payout
	_total_payout_earned += payout
	return payout


func grant_wallet_reward(amount: int) -> int:
	var reward: int = maxi(0, amount)
	_wallet += reward
	return _wallet


func spend_wallet(amount: int) -> Dictionary:
	if amount <= 0:
		return {"spent": false, "reason": "invalid_amount", "wallet": _wallet}
	if _wallet < amount:
		return {
			"spent": false,
			"reason": "insufficient_funds",
			"wallet": _wallet,
			"needed": amount - _wallet,
		}
	_wallet -= amount
	return {"spent": true, "wallet": _wallet, "amount": amount}


func purchase_oxygen_tank_upgrade() -> Dictionary:
	if has_oxygen_tank_upgrade():
		return {"purchased": false, "reason": "already_purchased", "wallet": _wallet}
	if _wallet < OXYGEN_TANK_UPGRADE_COST:
		return {
			"purchased": false,
			"reason": "insufficient_funds",
			"wallet": _wallet,
			"needed": OXYGEN_TANK_UPGRADE_COST - _wallet,
		}
	_wallet -= OXYGEN_TANK_UPGRADE_COST
	_purchased_upgrades[OXYGEN_TANK_UPGRADE_ID] = true
	return {"purchased": true, "wallet": _wallet, "upgrade_id": OXYGEN_TANK_UPGRADE_ID}


func purchase_cargo_capacity_upgrade() -> Dictionary:
	if has_cargo_capacity_upgrade():
		return {"purchased": false, "reason": "already_purchased", "wallet": _wallet}
	if _wallet < CARGO_CAPACITY_UPGRADE_COST:
		return {
			"purchased": false,
			"reason": "insufficient_funds",
			"wallet": _wallet,
			"needed": CARGO_CAPACITY_UPGRADE_COST - _wallet,
		}
	_wallet -= CARGO_CAPACITY_UPGRADE_COST
	_purchased_upgrades[CARGO_CAPACITY_UPGRADE_ID] = true
	return {"purchased": true, "wallet": _wallet, "upgrade_id": CARGO_CAPACITY_UPGRADE_ID}


func purchase_light_upgrade() -> Dictionary:
	if has_light_upgrade():
		return {"purchased": false, "reason": "already_purchased", "wallet": _wallet}
	if _wallet < LIGHT_UPGRADE_COST:
		return {
			"purchased": false,
			"reason": "insufficient_funds",
			"wallet": _wallet,
			"needed": LIGHT_UPGRADE_COST - _wallet,
		}
	_wallet -= LIGHT_UPGRADE_COST
	_purchased_upgrades[LIGHT_UPGRADE_ID] = true
	return {"purchased": true, "wallet": _wallet, "upgrade_id": LIGHT_UPGRADE_ID}


func purchase_propulsion_upgrade() -> Dictionary:
	if has_propulsion_upgrade():
		return {"purchased": false, "reason": "already_purchased", "wallet": _wallet}
	if _wallet < PROPULSION_UPGRADE_COST:
		return {
			"purchased": false,
			"reason": "insufficient_funds",
			"wallet": _wallet,
			"needed": PROPULSION_UPGRADE_COST - _wallet,
		}
	_wallet -= PROPULSION_UPGRADE_COST
	_purchased_upgrades[PROPULSION_UPGRADE_ID] = true
	return {"purchased": true, "wallet": _wallet, "upgrade_id": PROPULSION_UPGRADE_ID}


func has_oxygen_tank_upgrade() -> bool:
	return bool(_purchased_upgrades.get(OXYGEN_TANK_UPGRADE_ID, false))


func has_cargo_capacity_upgrade() -> bool:
	return bool(_purchased_upgrades.get(CARGO_CAPACITY_UPGRADE_ID, false))


func has_light_upgrade() -> bool:
	return bool(_purchased_upgrades.get(LIGHT_UPGRADE_ID, false))


func has_propulsion_upgrade() -> bool:
	return bool(_purchased_upgrades.get(PROPULSION_UPGRADE_ID, false))


func oxygen_bonus_seconds() -> float:
	return OXYGEN_TANK_UPGRADE_SECONDS if has_oxygen_tank_upgrade() else 0.0


func cargo_capacity_bonus() -> int:
	return CARGO_CAPACITY_UPGRADE_BONUS if has_cargo_capacity_upgrade() else 0


func light_range_scale() -> float:
	return LIGHT_UPGRADE_RANGE_SCALE if has_light_upgrade() else 1.0


func light_alpha() -> float:
	return LIGHT_UPGRADE_ALPHA if has_light_upgrade() else 0.38


func cargo_capacity_upgrade_cost() -> int:
	return CARGO_CAPACITY_UPGRADE_COST


func light_upgrade_cost() -> int:
	return LIGHT_UPGRADE_COST


func wallet() -> int:
	return _wallet


func total_payout_earned() -> int:
	return _total_payout_earned
