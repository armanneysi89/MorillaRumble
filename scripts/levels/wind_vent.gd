class_name WindVent
extends Area2D

## Aufwind: Ein senkrechter Luftstrom trägt Morilla nach oben. Er ersetzt eine Leiter und macht
## Schächte begehbar, die sonst nur mit der Feder erreichbar wären. Der Wind wirkt nur im Bereich
## des Feldes und lässt sich mit dem Dash verlassen.

const TEX_PATH := "res://assets/environments/quarry/props/wind_vent.png"
const WIDTH := 260.0
const HEIGHT := 900.0
const PLACEHOLDER := Color(0.55, 0.75, 0.95, 0.35)

## Höhe des Luftstroms (vom Fußpunkt nach oben). Vom Level gesetzt.
var height := HEIGHT
## Aufwärtsbeschleunigung im Feld (px/s²). Größer als die Schwerkraft, damit die Figur steigt.
const LIFT := 5200.0
## Höchstgeschwindigkeit nach oben.
const MAX_RISE := -900.0
## Seitliche Kontrolle im Wind (Anteil der normalen Beschleunigung).
const CONTROL := 0.55

var _particles: CPUParticles2D
var _streaks: Node2D
var _inside: Array[Morilla] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.PLAYER
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(WIDTH, height)
	cs.shape = shape
	cs.position = Vector2(0, -height * 0.5)
	add_child(cs)

	# Keine flächige Säule: Ein gefülltes Rechteck liest sich als grauer Balken, egal wie weich der
	# Verlauf ist. Der Wind besteht deshalb nur aus aufsteigenden Streifen und Partikeln.

	# Aufsteigende Streifen: Sie machen die Richtung des Luftstroms auch ohne Partikel lesbar.
	_streaks = Node2D.new()
	_streaks.z_index = -1
	add_child(_streaks)
	for i in 7:
		var streak := Line2D.new()
		var x := lerpf(-WIDTH * 0.34, WIDTH * 0.34, i / 6.0)
		var len_i := randf_range(90.0, 190.0)
		streak.points = PackedVector2Array([Vector2(x, 0), Vector2(x, -len_i)])
		streak.width = randf_range(3.0, 6.0)
		streak.default_color = Color(0.75, 0.92, 1.0, 0.5)
		streak.set_meta("speed", randf_range(320.0, 620.0))
		streak.set_meta("len", len_i)
		streak.position.y = randf_range(-height, 0.0)
		var smat := CanvasItemMaterial.new()
		smat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		streak.material = smat
		_streaks.add_child(streak)

	# Bodenmarkierung: ein Ring, der zeigt, wo der Wind austritt.
	var ring := Effects.glow(self, Vector2(0, -6), WIDTH * 0.62, Color(0.6, 0.85, 1.0, 0.5))
	ring.scale = Vector2(1.0, 0.22)
	ring.z_index = -1

	_particles = CPUParticles2D.new()
	_particles.amount = 40
	_particles.lifetime = 1.6
	_particles.preprocess = 1.6
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(WIDTH * 0.40, 12)
	_particles.position = Vector2(0, -20)
	_particles.direction = Vector2(0, -1)
	_particles.spread = 8.0
	_particles.initial_velocity_min = 320.0
	_particles.initial_velocity_max = 620.0
	_particles.gravity = Vector2.ZERO
	_particles.scale_amount_min = 4.0
	_particles.scale_amount_max = 9.0
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.8, 1.0])
	ramp.colors = PackedColorArray([Color(0.7, 0.9, 1.0, 0.0), Color(0.7, 0.9, 1.0, 0.7),
		Color(0.7, 0.9, 1.0, 0.5), Color(0.7, 0.9, 1.0, 0.0)])
	_particles.color_ramp = ramp
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_particles.material = mat
	add_child(_particles)

	body_entered.connect(func(b: Node2D) -> void:
		if b is Morilla:
			_inside.append(b as Morilla)
			Sound.sfx("wind", -10.0, 1.0, 0.1))
	body_exited.connect(func(b: Node2D) -> void:
		if b is Morilla:
			_inside.erase(b as Morilla))


func _process(delta: float) -> void:
	# Die Streifen wandern nach oben und beginnen am Boden neu: Das zeigt die Windrichtung.
	if _streaks == null:
		return
	for streak in _streaks.get_children():
		var line := streak as Line2D
		line.position.y -= float(line.get_meta("speed")) * delta
		if line.position.y < -height:
			line.position.y = 0.0


func _physics_process(delta: float) -> void:
	for player in _inside:
		if not is_instance_valid(player) or player.health.is_dead():
			continue
		# Der Wind hebt die Figur an, aber nie über die Feldhöhe hinaus.
		var top := global_position.y - height
		if player.global_position.y <= top + 10.0:
			continue
		player.velocity.y = maxf(player.velocity.y - LIFT * delta, MAX_RISE)
		# Seitliche Steuerung bleibt erhalten, damit man im Schacht korrigieren kann.
		player.velocity.x = move_toward(player.velocity.x, player.input_dir * Morilla.SPEED * CONTROL,
			Morilla.AIR_ACCEL * CONTROL * delta)
