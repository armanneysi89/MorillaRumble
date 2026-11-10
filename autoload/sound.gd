extends Node

## Zentrale Klangverwaltung: SFX-Stimmen und Musik mit Überblendung. M schaltet die Musik stumm.
##
## Klangbild: Die Effekte laufen nicht trocken auf dem Master, sondern über eine eigene SFX-Kette
## (Kompressor -> Hall). Der Kompressor hält laute Treffer zusammen, der Hall gibt ihnen einen Raum.
## Wichtige Effekte existieren in mehreren Aufnahmen (hit_1.wav, hit_2.wav ...); sfx() wählt zufällig
## eine davon. Dadurch klingt eine Schlagfolge nicht wie dieselbe Datei fünfmal hintereinander.
## Die Stimmen verteilen sich zusätzlich auf zwei leicht versetzte Bänke (links/rechts), damit das
## Klangbild Breite bekommt.

const SFX_PATH := "res://assets/audio/sfx/%s.wav"
const MUSIC_PATH := "res://assets/audio/music/%s.ogg"
const SFX_VOICES := 16
const MUSIC_DB := -11.0
const SFX_DB := -4.0
const SILENT := -60.0
## Anzahl der Aufnahmen pro Effekt (hit_1, hit_2 ...). Fehlt eine Variante, wird die Basisdatei genutzt.
const VARIANTS := 3
## Standard-Streuung der Tonhöhe, damit Wiederholungen nicht maschinell klingen.
const DEFAULT_JITTER := 0.06
## Seitlicher Versatz der beiden Stimmen-Bänke.
const PAN_LEFT := -0.28
const PAN_RIGHT := 0.28

var _sfx_cache := {}
## Basisname -> vorhandene Varianten (einmal ermittelt).
var _variants := {}
var _voices: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_name := ""
var _tween: Tween
var _duck_tween: Tween
var _next_voice := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX_L" if i % 2 == 0 else "SFX_R"
		add_child(p)
		_voices.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = SILENT
	add_child(_music)
	GameSettings.apply(GameSettings.load_all())


## Baut die Bus-Kette: Master (Limiter) <- Music, SFX_L/SFX_R (Kompressor -> Hall) <- SFX.
func _setup_buses() -> void:
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(0, limiter)
	_make_bus("Music", MUSIC_DB)
	_make_bus("SFX", SFX_DB)
	# Zwei Bänke für die seitliche Breite; beide laufen über denselben Effekt-Bus.
	_make_bus("SFX_L", 0.0, "SFX")
	_make_bus("SFX_R", 0.0, "SFX")
	_pan_bus("SFX_L", PAN_LEFT)
	_pan_bus("SFX_R", PAN_RIGHT)
	var sfx := AudioServer.get_bus_index("SFX")
	if sfx < 0:
		return
	# Kompressor: kurze Spitzen werden eingefangen, das Klangbild bleibt auch bei vielen Treffern sauber.
	var comp := AudioEffectCompressor.new()
	comp.threshold = -16.0
	comp.ratio = 3.0
	comp.attack_us = 4000.0
	comp.release_ms = 140.0
	comp.gain = 2.0
	AudioServer.add_bus_effect(sfx, comp)
	# Hall: ein kurzer Raum, damit Schläge nicht wie trockene Signale im Nichts stehen.
	var verb := AudioEffectReverb.new()
	verb.room_size = 0.42
	verb.damping = 0.55
	verb.wet = 0.16
	verb.dry = 1.0
	verb.spread = 0.6
	verb.predelay_msec = 18.0
	AudioServer.add_bus_effect(sfx, verb)


func _pan_bus(bus_name: String, pan: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var panner := AudioEffectPanner.new()
	panner.pan = pan
	AudioServer.add_bus_effect(idx, panner)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		var idx := AudioServer.get_bus_index("Music")
		AudioServer.set_bus_mute(idx, not AudioServer.is_bus_mute(idx))


## Spielt einen Effekt. `sound` ist der Basisname (z. B. "hit"); vorhandene Varianten werden zufällig gewählt.
func sfx(sound: String, volume_db := 0.0, pitch := 1.0, jitter := DEFAULT_JITTER) -> void:
	var stream := _sfx_stream(sound)
	if stream == null:
		return
	var voice := _free_voice()
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = maxf(pitch * randf_range(1.0 - jitter, 1.0 + jitter), 0.05)
	voice.play()


## Nächste freie Stimme; sind alle belegt, wird reihum die älteste wiederverwendet.
func _free_voice() -> AudioStreamPlayer:
	for v in _voices:
		if not v.playing:
			return v
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	return voice


func play_music(track: String, fade := 1.5) -> void:
	if track == _music_name:
		return
	_music_name = track
	var path := MUSIC_PATH % track
	if not ResourceLoader.exists(path):
		stop_music(fade)
		return
	var stream := load(path) as AudioStreamOggVorbis
	if stream:
		stream.loop = true
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	if _music.playing:
		_tween.tween_property(_music, "volume_db", SILENT, fade * 0.5)
	_tween.tween_callback(func() -> void:
		_music.stream = stream
		_music.play())
	_tween.tween_property(_music, "volume_db", 0.0, fade)


## Name des laufenden Musiktitels ("" wenn keine Musik läuft). Zwischensequenzen merken sich den Titel
## des Levels und stellen ihn nach der Szene wieder her.
func current_music() -> String:
	return _music_name


## Musik für Dialoge absenken, ohne den Titel zu wechseln. `amount` 0 = volle Lautstärke, 1 = stumm.
## Nutzt einen eigenen Tween, damit ein laufendes Ein-/Ausblenden (play_music) nicht abbricht.
func duck(amount: float, time := 0.4) -> void:
	if _music == null:
		return
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(_music, "volume_db", lerpf(0.0, SILENT, clampf(amount, 0.0, 1.0)), time)


func stop_music(fade := 1.0) -> void:
	_music_name = ""
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_music, "volume_db", SILENT, fade)
	_tween.tween_callback(_music.stop)


## Lädt eine Aufnahme; existieren Varianten (name_1 ... name_N), wird zufällig eine gewählt.
## Welche Varianten es gibt, wird einmal ermittelt und gemerkt – nicht bei jedem Aufruf geprüft.
func _sfx_stream(sound: String) -> AudioStream:
	if not _variants.has(sound):
		var found: Array[String] = []
		for i in range(1, VARIANTS + 1):
			var candidate := "%s_%d" % [sound, i]
			if ResourceLoader.exists(SFX_PATH % candidate):
				found.append(candidate)
		_variants[sound] = found
	var keys: Array = _variants[sound]
	var key: String = sound if keys.is_empty() else keys[randi() % keys.size()]
	if not _sfx_cache.has(key):
		var path := SFX_PATH % key
		_sfx_cache[key] = load(path) if ResourceLoader.exists(path) else null
	return _sfx_cache[key]


func _make_bus(bus_name: String, db: float, send := "Master") -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, send)
	AudioServer.set_bus_volume_db(idx, db)
