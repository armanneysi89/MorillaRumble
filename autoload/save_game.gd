extends Node

## Speichert den Spielstand versioniert als JSON in user:// (auf dem Web im IndexedDB-Speicher des Browsers).

const SAVE_PATH := "user://morilla_save.json"
const SAVE_VERSION := 1


func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"belt": "white",
		"abilities": [],
		"upgrades": {},
		"bosses": [],
		"checkpoints": {},
		"last_checkpoint": {},
		"world": {},
		"quests": {},
	}


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_data() -> Dictionary:
	var data := default_data()
	if not has_save():
		return data
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return data
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		var loaded: Dictionary = _migrate(parsed)
		for key: String in data:
			if loaded.has(key):
				data[key] = loaded[key]
	return data


func write(data: Dictionary) -> void:
	data["version"] = SAVE_VERSION
	var tmp := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("Spielstand konnte nicht geschrieben werden: %s" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	DirAccess.rename_absolute(tmp, SAVE_PATH)


func delete() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)


## Hebt ältere Spielstände schrittweise auf die aktuelle Version. Neue Versionen hier als weiteren Schritt ergänzen.
func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	if version < 1:
		version = 1
	data["version"] = version
	return data
