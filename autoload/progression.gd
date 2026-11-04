extends Node

## Persistenter Spielfortschritt: Gürtel, Techniken, Upgrades, Bosse, Checkpoints, Weltzustand und Quests.
## Alles wird über Save (versioniertes JSON) gespeichert.

signal belt_changed(belt_id: String)
signal ability_unlocked(ability_id: String)
signal task_changed

const BELTS: PackedStringArray = ["white", "blue", "purple", "brown", "black"]
const BELT_PATH := "res://resources/belts/%s.tres"
const ABILITY_PATH := "res://resources/abilities/%s.tres"
const BASE_HP := 5
const MAIN_GOAL := "Suche alle Coaches auf und verfolge die Spur des Schattenmeisters."
const TASKS := {"find_arman": "Finde Coach Arman im Mondbambus-Hain."}

var belt := "white"
var abilities: Array[String] = []
var upgrades: Dictionary = {}
var bosses: Array[String] = []
var checkpoints: Dictionary = {}
var last_checkpoint: Dictionary = {}
var world: Dictionary = {}
var quests: Dictionary = {}

var _belt_cache := {}
var _ability_cache := {}


func _ready() -> void:
	load_progress()


func load_progress() -> void:
	_apply(Save.load_data())


func save_progress() -> void:
	Save.write({
		"belt": belt,
		"abilities": abilities,
		"upgrades": upgrades,
		"bosses": bosses,
		"checkpoints": checkpoints,
		"last_checkpoint": last_checkpoint,
		"world": world,
		"quests": quests,
	})


func new_game() -> void:
	_apply(Save.default_data())
	save_progress()


func _apply(data: Dictionary) -> void:
	belt = data["belt"] if BELTS.has(data["belt"]) else "white"
	abilities = _to_strings(data["abilities"])
	upgrades = data["upgrades"]
	bosses = _to_strings(data["bosses"])
	checkpoints = data["checkpoints"]
	last_checkpoint = data["last_checkpoint"]
	world = data["world"]
	quests = data["quests"]
	belt_changed.emit(belt)


func _to_strings(src: Variant) -> Array[String]:
	var out: Array[String] = []
	if src is Array:
		for v: Variant in src:
			out.append(str(v))
	return out


func belt_data(belt_id := "") -> BeltData:
	var id := belt if belt_id == "" else belt_id
	if not _belt_cache.has(id):
		_belt_cache[id] = load(BELT_PATH % id)
	return _belt_cache[id]


func set_belt(belt_id: String) -> void:
	if not BELTS.has(belt_id) or belt_id == belt:
		return
	belt = belt_id
	for ability_id in belt_data().granted_abilities:
		unlock_ability(ability_id, false)
	belt_changed.emit(belt)
	save_progress()


func belt_index() -> int:
	return BELTS.find(belt)


func is_belt_at_least(belt_id: String) -> bool:
	return belt_index() >= BELTS.find(belt_id)


func max_hp() -> int:
	return BASE_HP + belt_data().max_hp_bonus + int(upgrades.get("max_hp", 0))


func damage_multiplier() -> float:
	return belt_data().damage_multiplier


func has_ability(ability_id: String) -> bool:
	return abilities.has(ability_id)


func unlock_ability(ability_id: String, announce := true) -> void:
	if abilities.has(ability_id):
		return
	abilities.append(ability_id)
	save_progress()
	if announce:
		ability_unlocked.emit(ability_id)


func get_ability(ability_id: String) -> AbilityData:
	if not _ability_cache.has(ability_id):
		var path := ABILITY_PATH % ability_id
		_ability_cache[ability_id] = load(path) if ResourceLoader.exists(path) else null
	return _ability_cache[ability_id]


func add_upgrade(key: String, amount := 1) -> void:
	upgrades[key] = int(upgrades.get(key, 0)) + amount
	save_progress()


func complete_boss(boss_id: String) -> void:
	if not bosses.has(boss_id):
		bosses.append(boss_id)
		save_progress()


func discover_checkpoint(level_id: String, checkpoint_id: String) -> void:
	var list: Array = checkpoints.get(level_id, [])
	if not list.has(checkpoint_id):
		list.append(checkpoint_id)
	checkpoints[level_id] = list
	last_checkpoint = {"level": level_id, "id": checkpoint_id}
	save_progress()


func checkpoint_for(level_id: String) -> String:
	return str(last_checkpoint.get("id", "")) if last_checkpoint.get("level", "") == level_id else ""


func set_flag(key: String, value: Variant = true) -> void:
	world[key] = value
	save_progress()


func get_flag(key: String, default: Variant = false) -> Variant:
	return world.get(key, default)


func set_quest(quest_id: String, state: String) -> void:
	quests[quest_id] = state
	save_progress()


func quest_state(quest_id: String) -> String:
	return str(quests.get(quest_id, ""))


## Aktuelle Aufgabe (id aus TASKS, leer = keine). Gibt auch das übergeordnete Ziel frei.
func set_task(task_id: String) -> void:
	quests["main_goal"] = "active"
	quests["task"] = task_id
	save_progress()
	task_changed.emit()


func task_text() -> String:
	return TASKS.get(quest_state("task"), "")


func main_goal_text() -> String:
	return MAIN_GOAL if quest_state("main_goal") == "active" else ""
