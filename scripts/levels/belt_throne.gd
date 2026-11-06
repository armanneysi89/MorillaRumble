class_name BeltThrone
extends Node2D

## Vitalis Gürtelthron: ein gewaltiger Thron aus Tausenden Jiu-Jitsu-Gürteln seiner besiegten Gegner.
## Bewusst als wenige getrennte Grafikebenen gebaut (Sockel, Sitz/Rückenlehne, zwei versetzte Gürtelkaskaden) –
## keine Tausende Physikobjekte und keine prozeduralen Rechtecke, die wie bunte Stäbe wirken.
## Vitali bleibt ein eigener Knoten und sitzt auf der Sitzfläche (SEAT_HEIGHT).

const TEX_PATH := "res://assets/environments/quarry/props/belt_throne.png"
const BASE_TEX_PATH := "res://assets/environments/quarry/props/belt_throne_base.png"
const CASCADE_TEX_PATH := "res://assets/environments/quarry/props/belt_throne_cascade.png"
const HEIGHT := 620.0
## Höhe der Sitzfläche über dem Fußpunkt des Throns. Im Thronbild liegt die Sitzfläche bei y=655 von 1167 px,
## also 512 px über dem Fuß; bei HEIGHT = 620 sind das 272 px.
const SEAT_HEIGHT := 272.0
## Fußpunkt der sitzenden Figur über dem Thronfuß: Vitalis Füße stehen auf der vorderen Gürtelkaskade.
## Die Sitzpose ist 442 px hoch, bei Skalierung 0,64 also 283 px; die Hüfte liegt 128 px über den Füßen.
const SIT_FOOT_HEIGHT := 144.0


func _ready() -> void:
	z_index = -1
	_add_layer(BASE_TEX_PATH, HEIGHT * 0.42, 0.0, -3)
	_add_layer(TEX_PATH, HEIGHT, 0.0, -2)
	# Zwei versetzte Kaskaden-Ebenen statt prozeduraler Streifen: die generierte Gürteltextur liest sich als
	# Stoff, gerade Rechtecke wirken dagegen wie bunte Stäbe. Beide hängen über dem Sockel und enden am
	# Thronfuß, damit sie die Sitzfläche (SEAT_HEIGHT) nicht verdecken.
	_add_layer(CASCADE_TEX_PATH, HEIGHT * 0.46, 0.0, 1, 1.04)
	_add_layer(CASCADE_TEX_PATH, HEIGHT * 0.38, 0.0, 2, 0.88, 0.0, true)


func _add_layer(path: String, height: float, y: float, z: int, width_scale := 1.0, x := 0.0,
		flip := false) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	var sp := Sprite2D.new()
	sp.texture = tex
	sp.centered = false
	var s := height / tex.get_height()
	sp.scale = Vector2(s * width_scale * (-1.0 if flip else 1.0), s)
	sp.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	sp.position = Vector2(x, y)
	sp.z_index = z
	add_child(sp)
