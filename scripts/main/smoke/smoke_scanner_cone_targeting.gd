extends SceneTree

const ScannerTargetingContract := preload("res://scripts/main/smoke/scanner_targeting_contract.gd")


func _init() -> void:
	var report: Dictionary = ScannerTargetingContract.new().run()
	if not bool(report.get("passed", false)):
		for failure in report.get("failures", []):
			push_error("Scanner cone targeting smoke failed: %s" % str(failure))
		quit(1)
		return
	print("Scanner cone targeting smoke passed: range_tiles=%d half_angle=%d ahead=true behind=false off_axis=false out_of_range=false occluded=false rank=%s cancel=%s progress_reset=true." % [
		int(report.get("range_tiles", 0)),
		int(report.get("half_angle_degrees", 0)),
		str(report.get("ranking", "")),
		str(report.get("cancellation", "")),
	])
	quit(0)
