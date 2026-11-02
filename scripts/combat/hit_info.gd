class_name HitInfo
extends RefCounted

## Beschreibt einen einzelnen Treffer, den eine Hitbox an eine Hurtbox übergibt.

var damage := 1
## Rückstoß in Pixel/s; x wird mit der Angriffsrichtung multipliziert.
var knockback := Vector2(300.0, -160.0)
var source: Node2D
## Blickrichtung des Angreifers (+1 rechts, -1 links).
var direction := 1
var stun := 0.25
var hit_stop := 0.05
var shake := 0.0
var heavy := false
var unblockable := false
