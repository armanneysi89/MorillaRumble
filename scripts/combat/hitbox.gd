class_name Hitbox
extends Area2D

## Angriffsfläche. Wird nur für die aktive Phase eines Angriffs eingeschaltet und trifft jede Hurtbox höchstens einmal pro Aktivierung.

signal hit_landed(hurtbox: Hurtbox, info: HitInfo)

var info: HitInfo
var _already_hit: Array[Hurtbox] = []


func _ready() -> void:
	monitorable = false
	monitoring = false
	area_entered.connect(_on_area_entered)


func activate(new_info: HitInfo) -> void:
	info = new_info
	_already_hit.clear()
	set_deferred("monitoring", true)


func deactivate() -> void:
	info = null
	set_deferred("monitoring", false)


func _on_area_entered(area: Area2D) -> void:
	if info == null or not area is Hurtbox:
		return
	var hurtbox := area as Hurtbox
	if _already_hit.has(hurtbox):
		return
	_already_hit.append(hurtbox)
	if hurtbox.receive_hit(info):
		hit_landed.emit(hurtbox, info)
