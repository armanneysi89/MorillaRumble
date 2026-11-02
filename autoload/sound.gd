extends Node

## Zentrale Klangverwaltung: SFX-Stimmen und Musik mit Überblendung. M schaltet die Musik stumm.

const SFX_PATH := "res://assets/audio/sfx/%s.wav"
const MUSIC_PATH := "res://assets/audio/music/%s.ogg"
const SFX_VOICES := 14
const MUSIC_DB := -6.0
const SFX_DB := -4.0
const SILENT := -60.0

var _sfx_cache := {}
var _voices: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_name := ""
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(0, limiter)
	_make_bus("Music", MUSIC_DB)
	_make_bus("SFX", SFX_DB)
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_voices.append(p)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = SILENT
	add_child(_music)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		var idx := AudioServer.get_bus_index("Music")
		AudioServer.set_bus_mute(idx, not AudioServer.is_bus_mute(idx))


func sfx(sound: String, volume_db := 0.0, pitch := 1.0, jitter := 0.05) -> void:
	var stream := _sfx_stream(sound)
	if stream == null:
		return
	var voice: AudioStreamPlayer = null
	for v in _voices:
		if not v.playing:
			voice = v
			break
	if voice == null:
		voice = _voices[0]
		_voices.push_back(_voices.pop_front())
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = pitch * randf_range(1.0 - jitter, 1.0 + jitter)
	voice.play()


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


func stop_music(fade := 1.0) -> void:
	_music_name = ""
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_music, "volume_db", SILENT, fade)
	_tween.tween_callback(_music.stop)


func _sfx_stream(sound: String) -> AudioStream:
	if not _sfx_cache.has(sound):
		var path := SFX_PATH % sound
		_sfx_cache[sound] = load(path) if ResourceLoader.exists(path) else null
	return _sfx_cache[sound]


func _make_bus(bus_name: String, db: float) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(idx, db)
