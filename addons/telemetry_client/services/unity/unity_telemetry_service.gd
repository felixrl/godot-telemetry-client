class_name UnityTelemetryService
extends AbstractTelemetryService

## Sends telemetry events over the network using Unity Services REST API

## WARNING: This class is UNFINISHED AND UNTESTED. Use at your own risk!

## NOTE: Make sure to configure the relevant Event Schemas on the Unity Services side
##       and ensure that said Event Schemas are perfectly matched by game events!

## TODO: Store events locally to send on next connection when network is unavailable

## TODO: Compliance with Chinese privacy headers
##       See https://services.docs.unity.com/analytics/v1/#tag/Analytics/operation/submitEvent with PIPL_CONSENT and PIPL_EXPORT

const FORGET_EVENT_NAME := "ddnaForgetMe"

const TIMEOUT_MAX_RETRIES := 3

var project_id: String
var env_name: String

var player_id: String
var session_id: String

## Create service for Project ID and Environment
## with a new/existing player UUID and a new session UUID
func _init(_project_id: String, _env_name: String) -> void:
	project_id = _project_id
	env_name = _env_name
	print("UNITY TELEMETRY: Unity telemetry setup on project " + project_id + " in environment " + env_name)
	
	_load_or_create_unity_player_id()
	session_id = TelemetryUUID.v4()
	print("UNITY TELEMETRY: Unity telemetry started with Player ID " + player_id + " and Session ID " + session_id)

## Send telemetry events to Unity in a batch API call
## https://docs.unity.com/en-us/analytics/rest-api/record-event-rest-api
func send(events: Array[TelemetryEvent]) -> void:
	# Create a list that maps each event
	var list: Array[Dictionary] = [] 
	list.assign(events.map(func (event: TelemetryEvent) -> Dictionary:
			var event_data: Dictionary = {
				"eventName": event.name,
				#"eventTimestamp": TODO: Convert system UNIX time to timestamp form
				"eventUUID": event.event_uuid,
				"eventVersion": 1,
				"sessionID": session_id,
				"userID": player_id,
				"eventParams": event.key_values
			}
			
			return event_data))
	
	var req: Dictionary = {
		"eventList": list
	}
	
	## TODO: Wait for success, then return bool value?
	_post_to_events_endpoint(JSON.stringify(req))

## Send a ddnaForgetMe request for data deletion
## https://docs.unity.com/en-us/analytics/rest-api/request-data-deletion-rest-api
func request_data_deletion() -> bool:
	var req: Dictionary = {
		"eventName": FORGET_EVENT_NAME,
		#"eventTimestamp": TODO: Convert system UNIX time to timestamp form
		"eventUUID": TelemetryUUID.v4(),
		"eventVersion": 1,
		"sessionID": session_id,
		"userID": player_id,
		"eventParams": {
			## TODO: Fill in these values because apparently they are required???
			#"clientVersion": ""
			#"sdkMethod": ""
		}
	}
	
	_post_to_events_endpoint(JSON.stringify(req))
	## TODO: Wait for success, then return bool value?
	
	return true

#region HELPERS

func _load_or_create_unity_player_id() -> void:
	## TODO: Store somewhere on create, read first on init
	player_id = TelemetryUUID.v4()

#endregion

#region NETWORK REQUESTS

func _post_to_events_endpoint(json_body: String) -> void:
	var http_req := HTTPRequest.new()
	# TODO: Switch to HTTPClient instead, to avoid this awkward process_frame stuff?
	Telemetry.call_deferred("add_child", http_req)
	await Telemetry.get_tree().process_frame
	
	print("UNITY TELEMETRY: Sending HTTP request...")
	var req_err := http_req.request(_get_events_endpoint_url(), ["Content-Type: application/json"], HTTPClient.METHOD_POST, json_body)
	http_req.request_completed.connect(_on_request_completed)
	if req_err != OK:
		print("UNITY TELEMETRY: Error while sending HTTP request!")

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("UNITY TELEMETRY: Request completed...")
	if result != HTTPRequest.RESULT_SUCCESS:
		print("UNITY TELEMETRY: Request failed!")
		if result == HTTPRequest.RESULT_TIMEOUT:
			## TODO: Implement a retry system that uses TIMEOUT_MAX_RETRIES
			pass

func _get_events_endpoint_url() -> String:
	return "https://collect.analytics.unity3d.com/api/analytics/collect/v1/projects/" + project_id + "/environments/" + env_name

#endregion
