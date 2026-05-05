class_name JsonTelemetryService
extends AbstractTelemetryService

## Writes telemetry events to a local JSON file

## To do session processing (e.g. showcase floor demo analysis) 
## indicate your own events for "Session Start" and "Session End"
## and run a pre-processing step on your data to split sessions by event markers

## NOTE: Require a session end on program quit to avoid dangling session starts
## or treat a following session start as an implicit session end.
## Use a game-specific demo-style inactivity timeout for showcase scenarios.

const BASE_DIR := "user://"

var dest_file_name: String
var file_access: FileAccess

## Create with an opened target file
func _init(file_name: String) -> void:
	dest_file_name = file_name
	_open_file(_get_file_path())
	print("JSON TELEMETRY: Designated file ", _get_file_path())

## Opens the file and stores the FileAccess reference
func _open_file(dest_file_path: String) -> bool:
	if FileAccess.file_exists(dest_file_path):
		file_access = FileAccess.open(dest_file_path, FileAccess.READ_WRITE)
	else:
		file_access = FileAccess.open(dest_file_path, FileAccess.WRITE_READ)
	if not file_access:
		print("JSON TELEMETRY: Problem opening file, ", FileAccess.get_open_error())
		return false
	return true

## Append the events to the JSON file
func send(events: Array[TelemetryEvent]) -> void:
	if not file_access:
		print("JSON TELEMETRY: Problem! Can't write with null file_access")
		return
	
	# 1. Parse existing dictionaries
	var parsed_objects := _parse_file_content_to_dict_array(file_access.get_as_text())
	# 2. Append new events as dictionaries
	parsed_objects.append_array(events.map(func (event: TelemetryEvent) -> Dictionary:
		return event.to_dict(true)))
	# 3. Overwrite and flush
	var overwrite_success := _overwrite_json_in_file(parsed_objects)
	if overwrite_success:
		file_access.flush()

## Clear the JSON file
func request_data_deletion() -> bool:
	if not file_access:
		print("JSON TELEMETRY: Problem! Can't request data deletion with null file_access")
		return false
	
	_clear_file()
	file_access.seek(0)
	file_access.flush()
	return true

#region HELPERS

func _parse_file_content_to_dict_array(text_content: String) -> Array[Dictionary]:
	if text_content.is_empty():
		return []
	var parsed_variant: Variant = JSON.parse_string(text_content)
	var parsed_objects: Array[Dictionary] = []
	if parsed_variant and parsed_variant is Array:
		parsed_objects.assign(parsed_variant)
	return parsed_objects

func _overwrite_json_in_file(data: Variant) -> bool:
	var clear_success := _clear_file()
	if not clear_success:
		return false
	
	## Fix: Apparently pointer is not at start so we get a bunch of NULL padding
	file_access.seek(0)
	
	var store_res := file_access.store_string(JSON.stringify(data))
	if not store_res:
		print("JSON TELEMETRY: Problem writing to file!")
		return false
	
	return true

func _clear_file() -> bool:
	var resize_res := file_access.resize(0)
	if resize_res != OK:
		print("JSON TELEMETRY: Problem resizing file to clear, ", resize_res)
		return false
	return true

func _get_file_path() -> String:
	return BASE_DIR.path_join(dest_file_name)

#endregion
