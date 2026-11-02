class_name EnemyData
extends Resource

## Konfiguration eines Gegnertyps. Verhalten und Werte stehen hier, nicht im Szenenbaum.

@export var id := "white_belt_recruit"
@export var display_name := "Weißgurt-Rekrut"
## Schlüssel in CharacterSpecs für die Sprites.
@export var spec_key := "recruit"
@export var max_hp := 3
@export var move_speed := 150.0
@export var detect_range := 620.0
@export var attack_range := 120.0
@export var attack_damage := 1
@export var attack_knockback := Vector2(380, -220)
## Ankündigung des Angriffs (Telegraph) – Zeitfenster zum Blocken oder Ausweichen.
@export var windup_time := 0.55
@export var attack_time := 0.16
@export var recover_time := 0.75
@export var attack_cooldown := 0.6
@export var lunge_speed := 420.0
## 0 klein, 1 mittel, 2 groß – entscheidet, welche Griffe wirken.
@export var size_class := 0
@export var grapple_vulnerable := true
## Schwere Treffer werfen den Gegner aus dem Angriff, leichte nicht, wenn true.
@export var super_armor_windup := false
