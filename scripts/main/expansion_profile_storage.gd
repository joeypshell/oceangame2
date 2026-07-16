extends RefCounted


static func write_atomic(storage_path: String, payload: Dictionary) -> bool:
	var temp_path := "%s.tmp" % storage_path
	var backup_path := "%s.bak" % storage_path
	var target_absolute := ProjectSettings.globalize_path(storage_path)
	var temp_absolute := ProjectSettings.globalize_path(temp_path)
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	DirAccess.make_dir_recursive_absolute(target_absolute.get_base_dir())
	_remove_if_exists(temp_absolute)

	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()

	var had_original := FileAccess.file_exists(storage_path)
	if had_original:
		_remove_if_exists(backup_absolute)
		if DirAccess.rename_absolute(target_absolute, backup_absolute) != OK:
			_remove_if_exists(temp_absolute)
			return false
	if DirAccess.rename_absolute(temp_absolute, target_absolute) != OK:
		if had_original:
			DirAccess.rename_absolute(backup_absolute, target_absolute)
		_remove_if_exists(temp_absolute)
		return false
	_remove_if_exists(backup_absolute)
	return true


static func recover_interrupted_write(storage_path: String) -> void:
	var temp_path := "%s.tmp" % storage_path
	var backup_path := "%s.bak" % storage_path
	var target_absolute := ProjectSettings.globalize_path(storage_path)
	var temp_absolute := ProjectSettings.globalize_path(temp_path)
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(storage_path):
		_remove_if_exists(temp_absolute)
		_remove_if_exists(backup_absolute)
	elif FileAccess.file_exists(backup_path):
		DirAccess.rename_absolute(backup_absolute, target_absolute)
		_remove_if_exists(temp_absolute)
	elif FileAccess.file_exists(temp_path):
		DirAccess.rename_absolute(temp_absolute, target_absolute)


static func _remove_if_exists(absolute_path: String) -> void:
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)
