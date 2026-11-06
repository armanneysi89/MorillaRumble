extends SceneTree

## Prüft, ob die Vitali-Cutscene-Videos von Godot geladen werden können.

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var dir := "res://assets/cutscenes/vitali/"
	var names: Array[String] = ["1_vorhof", "2_baby_mo", "3_thron_zeigen", "4_thron_enthuellung", "5_vitali_hut", "6_vor_dem_thron"]
	var fails := 0
	for n in names:
		var vp: String = dir + n + ".ogv"
		var sp: String = dir + n + ".jpg"
		var vok := ResourceLoader.exists(vp)
		var sok := ResourceLoader.exists(sp)
		var stream: VideoStream = load(vp) as VideoStream if vok else null
		var tex: Texture2D = load(sp) as Texture2D if sok else null
		print("PASS  %s video=%s still=%s" % [n, "ja" if stream != null else "NEIN", "ja" if tex != null else "NEIN"])
		if stream == null or tex == null:
			fails += 1
	print("RESULT video_check fails=%d" % fails)
	quit(1 if fails > 0 else 0)
