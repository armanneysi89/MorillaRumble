extends SceneTree

## Prüft, dass jede im Spiel benutzte Animation genug Frames hat, um Anlauf und Treffer zu trennen.
##   XDG_DATA_HOME=/tmp/x godot --path . --script tools/sprite_frames_test.gd
##
## Hintergrund: Der Attack-Zustand zeigt Frame 0 im Anlauf und Frame 1 in der aktiven Phase. Hat eine
## Animation nur einen Frame, clampt show_frame() auf 0 – Telegraph und Treffer sehen dann identisch aus
## und der Gegner kann den Schlag nicht lesen. Dieser Test verhindert, dass das unbemerkt zurückkommt.

## Animationen, bei denen zwei unterscheidbare Frames nötig sind.
const NEEDS_TWO := ["jab", "cross", "hook", "lowkick", "kick", "heavy_attack", "block", "hurt", "land"]
## Animationen, die nur einen Frame brauchen (statische Posen).
const NEEDS_ONE := ["dash", "grab"]

var _fails := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var frames := SpriteLibrary.build(CharacterSpecs.get_spec("morilla"))
	for anim in NEEDS_TWO:
		var count := frames.get_frame_count(anim)
		_check("Animation '%s' hat mindestens 2 Frames (hat %d)" % [anim, count], count >= 2)
	for anim in NEEDS_ONE:
		var count := frames.get_frame_count(anim)
		_check("Animation '%s' hat mindestens 1 Frame (hat %d)" % [anim, count], count >= 1)
	# Jede Animation, die ein Zustand anspricht, muss existieren.
	for anim in ["idle", "walk", "run", "jump", "fall", "land", "jab", "cross", "hook", "lowkick", "kick",
			"heavy_attack", "dash", "block", "grab", "kimura", "suplex", "summon", "hurt", "death"]:
		_check("Animation '%s' existiert" % anim, frames.has_animation(anim))
	print("RESULT sprite_frames fails=%d" % _fails)
	quit(_fails)


func _check(label: String, ok: bool) -> void:
	if not ok:
		_fails += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])
