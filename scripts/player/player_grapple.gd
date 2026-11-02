class_name PlayerGrapple
extends Node

## Wiederverwendbarer Griff-Mechanismus: Ziel finden, prüfen, binden, positionieren und zuverlässig wieder lösen.
## Die zeitliche Abfolge (Phasen) liegt im Zustand "grapple".

const ABILITY_ID := "kimura"
const PIN_DISTANCE := 96.0
const DEFAULT_REACH := 150.0

var player: Morilla
var target: Enemy
var cooldown := 0.0


func setup(p: Morilla) -> void:
	player = p
	var ab := ability()
	var reach := ab.reach if ab else DEFAULT_REACH
	var shape := (player.grab_sensor.get_node("Shape") as CollisionShape2D).shape as RectangleShape2D
	shape.size = Vector2(reach + 80.0, 238.0)


func _physics_process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	var reach := ability().reach if ability() else DEFAULT_REACH
	player.grab_sensor.position = Vector2(player.facing * (reach * 0.5 + 10.0), -119.0)


func ability() -> AbilityData:
	return Progression.get_ability(ABILITY_ID)


func is_unlocked() -> bool:
	return Progression.has_ability(ABILITY_ID) and ability() != null


func find_target(ab: AbilityData) -> Enemy:
	var best: Enemy = null
	var best_d := INF
	for body in player.grab_sensor.get_overlapping_bodies():
		if not body is Enemy or not (body as Enemy).can_be_grappled(ab):
			continue
		var dx: float = body.global_position.x - player.global_position.x
		if signf(dx) != float(player.facing) and absf(dx) > 40.0:
			continue
		if absf(dx) < best_d:
			best_d = absf(dx)
			best = body
	return best


func bind(enemy: Enemy) -> void:
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
func release(submitted := false) -> void:
	if is_instance_valid(target):
		target.end_grapple(submitted)
	target = null
	var ab := ability()
	cooldown = ab.cooldown if ab else 0.8
