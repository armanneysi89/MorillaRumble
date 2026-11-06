class_name PlayerGrapple
extends Node

## Wiederverwendbarer Griff-Mechanismus: Ziel finden, prüfen, binden, positionieren und zuverlässig wieder lösen.
## Die zeitliche Abfolge (Phasen) liegt im Zustand "grapple".

const ABILITY_ID := "kimura"
const PIN_DISTANCE := 96.0
const DEFAULT_REACH := 150.0
## Der Sensor ist etwas größer als die Reichweite, damit Ziele am Rand nicht durchrutschen.
const SENSOR_PADDING := 80.0
## Höhe des Sensors: die Körperhöhe der Spielfigur.
const SENSOR_HEIGHT := 238.0
## Toleranz um die eigene Position, in der die Blickrichtung nicht geprüft wird.
const FACING_TOLERANCE := 40.0
## Ab dieser Größenklasse gilt ein Ziel als „groß" und ist nur per Suplex greifbar.
const LARGE_SIZE_CLASS := 2
## Abklingzeit, wenn keine Technik geladen ist (Sicherheitsnetz).
const FALLBACK_COOLDOWN := 0.8
## Anteil der Abklingzeit, den ein kompletter Fehlversuch kostet.
const WHIFF_COOLDOWN_SHARE := 0.35

var player: Morilla
var target: Node2D
var cooldown := 0.0
## Aktuell ausgeführte Technik (Kimura oder Suplex). Leer = Kimura.
var active: AbilityData


func setup(p: Morilla) -> void:
	player = p
	_sync_sensor()


func _physics_process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	_sync_sensor()


## Größe und Lage des Sensors folgen der aktiven Technik. Vorher wurde die Form einmalig mit der
## Kimura-Reichweite gebaut, während die Position pro Frame wanderte – der Suplex griff dadurch zu weit.
func _sync_sensor() -> void:
	var ab := ability()
	var reach := ab.reach if ab else DEFAULT_REACH
	var shape := (player.grab_sensor.get_node("Shape") as CollisionShape2D).shape as RectangleShape2D
	shape.size = Vector2(reach + SENSOR_PADDING, SENSOR_HEIGHT)
	player.grab_sensor.position = Vector2(player.facing * (reach * 0.5 + 10.0), -SENSOR_HEIGHT * 0.5)


func ability() -> AbilityData:
	return active if active != null else Progression.get_ability(ABILITY_ID)


func ability_for(id: String) -> AbilityData:
	return Progression.get_ability(id)


func is_unlocked(id := ABILITY_ID) -> bool:
	return Progression.has_ability(id) and ability_for(id) != null


func find_target(ab: AbilityData) -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for body in player.grab_sensor.get_overlapping_bodies():
		if not _is_valid_target(body, ab):
			continue
		var dx: float = body.global_position.x - player.global_position.x
		if absf(dx) < best_d:
			best_d = absf(dx)
			best = body
	return best


## Gibt es in Reichweite ein Ziel, das nur der Suplex greifen kann (große Gegner)?
## Die Blickrichtung zählt mit: Ein großer Gegner hinter der Figur darf die Technikwahl nicht bestimmen,
## sonst greift Morilla ins Leere, obwohl ein kleiner Gegner direkt vor ihm steht.
func has_large_target(ab: AbilityData) -> bool:
	for body in player.grab_sensor.get_overlapping_bodies():
		if _is_valid_target(body, ab) and int(body.get("size_class")) >= LARGE_SIZE_CLASS:
			return true
	return false


## Ein Ziel ist gültig, wenn es greifbar ist und vor der Figur steht.
func _is_valid_target(body: Node2D, ab: AbilityData) -> bool:
	if not is_instance_valid(body) or not body.has_method("can_be_grappled"):
		return false
	if not body.can_be_grappled(ab):
		return false
	var dx: float = body.global_position.x - player.global_position.x
	return absf(dx) <= FACING_TOLERANCE or signf(dx) == float(player.facing)


func bind(enemy: Node2D) -> void:
	target = enemy
	enemy.begin_grapple(player)


func pin(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var want := player.global_position + Vector2(player.facing * PIN_DISTANCE, 0.0)
	target.global_position = target.global_position.lerp(want, minf(delta * 18.0, 1.0))


func is_bound() -> bool:
	return is_instance_valid(target) and target.is_grappled()


## Löst das Ziel in jedem Fall wieder – auch wenn der Griff unterbrochen wurde.
## `started` unterscheidet einen echten Griff von einem kompletten Fehlversuch: Nur wer tatsächlich
## gebunden hat, zahlt die volle Abklingzeit. Ein danebengegangener Griff kostet nur einen Bruchteil.
func release(submitted := false, started := true) -> void:
	if is_instance_valid(target):
		target.end_grapple(submitted)
	target = null
	var ab := ability()
	var full := ab.cooldown if ab else FALLBACK_COOLDOWN
	cooldown = full if started else full * WHIFF_COOLDOWN_SHARE
