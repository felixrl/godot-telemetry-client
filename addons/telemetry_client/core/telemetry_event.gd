class_name TelemetryEvent
extends RefCounted

## Dumb data object for a game event to be tracked by telemetry

const NAME_KEY := "name"
const SYSTEM_TIMESTAMP_KEY := "sys_unix_time"
const DATA_KEY := "data"
const EVENT_UUID_KEY := "event_uuid"

var name: String
var system_unix_timestamp: float
var key_values: Dictionary = {}
## Uniquely identify the event in the case of network API idempotency
var event_uuid: String

func _init(_name: String, _key_values: Dictionary = {}) -> void:
	name = _name
	key_values.assign(_key_values)
	system_unix_timestamp = Time.get_unix_time_from_system()
	event_uuid = TelemetryUUID.v4()

func to_dict(include_event_uuid := false) -> Dictionary:
	var dict := {
			NAME_KEY: name,
			SYSTEM_TIMESTAMP_KEY: system_unix_timestamp,
			DATA_KEY: key_values,
		}
	
	if include_event_uuid:
		dict.set(EVENT_UUID_KEY, event_uuid)
	
	return dict
