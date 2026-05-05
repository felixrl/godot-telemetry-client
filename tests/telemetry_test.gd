class_name TelemetryTest
extends Node2D

## Runs some basic logic using the JsonTelemetryService

func _ready() -> void:
	Telemetry.set_service(JsonTelemetryService.new("telemetry.json"))
	Telemetry.opt_in()
	
	Telemetry.log_event("SessionStart")
	Telemetry.log_event("LevelComplete", { "level": 1 })
	Telemetry.log_event("LevelComplete", { "level": 2 }, true)
	await get_tree().create_timer(1.0).timeout
	Telemetry.log_event("GameOver", { "score": 25 })
	await get_tree().create_timer(3.0).timeout
	Telemetry.log_event("SessionEnd")
	Telemetry.flush()
 
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept"):
		Telemetry.request_data_deletion()
