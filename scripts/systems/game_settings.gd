class_name GameSettings
extends RefCounted

## Persistente Einstellungen (Lautstärke, Vollbild) in user://settings.cfg.

const PATH := "user://settings.cfg"
const SECTION := "game"


static func load_all() -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	return {
		"music": float(cfg.get_value(SECTION, "music", 1.0)),
		"sfx": float(cfg.get_value(SECTION, "sfx", 1.0)),
		"fullscreen": bool(cfg.get_value(SECTION, "fullscreen", false)),
	}


static func save_all(values: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for key: String in values:
		cfg.set_value(SECTION, key, values[key])
	cfg.save(PATH)


## Wirkt auf die Audio-Busse (Basispegel + Reglerstand) und den Fenstermodus.
static func apply(values: Dictionary) -> void:
	_set_bus("Music", Sound.MUSIC_DB, float(values["music"]))
	_set_bus("SFX", Sound.SFX_DB, float(values["sfx"]))
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if values["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)


static func _set_bus(bus_name: String, base_db: float, volume: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, base_db + linear_to_db(maxf(volume, 0.0001)))
