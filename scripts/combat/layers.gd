class_name Layers
extends RefCounted

## Physik-Ebenen als Bitmasken (müssen mit [layer_names] in project.godot übereinstimmen).
## Gameplay-Kollision und Hitboxen sind bewusst von der Sprite-Grafik getrennt.

const WORLD := 1
const PLAYER := 2
const ENEMY := 4
const PLAYER_HURT := 8
const ENEMY_HURT := 16
const PLAYER_HIT := 32
const ENEMY_HIT := 64
const INTERACT := 128
