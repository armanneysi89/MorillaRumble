class_name AbilityData
extends Resource

## Eine freischaltbare Jiu-Jitsu-Technik. Alle Werte sind Daten, damit weitere Techniken ohne neuen Code entstehen.

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var damage := 2
## Betäubungsdauer des Gegners nach der Technik (Sekunden).
@export var stun_time := 1.5
## Maximale Entfernung zum Gegner beim Greifen (Pixel).
@export var reach := 150.0
## Größte Gegnerklasse, die sich greifen lässt (0 klein, 1 mittel, 2 groß).
@export var max_size_class := 1
@export var cooldown := 0.8
## Dauer der einzelnen Phasen: Greifen, Kontrolle, Ausführung, Erholung (Sekunden).
@export var lunge_time := 0.16
@export var control_time := 0.22
@export var execute_time := 0.5
@export var recover_time := 0.3
@export var hit_stop := 0.12
## Anzeige im HUD: Taste, mit der die Technik ausgelöst wird.
@export var input_hint := "F"
## Beschwörungen: höchstens so viele Gegner pro Einsatz (0 = keine Beschwörung).
@export var max_targets := 0
## Beschwörungen: Dauer der Konzentration vor dem Erscheinen (Sekunden).
@export var charge_time := 0.5
