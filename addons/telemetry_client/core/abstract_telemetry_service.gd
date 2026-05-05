@abstract
class_name AbstractTelemetryService
extends RefCounted

## Abstract (interface) class for services that deal with game events

@abstract
func send(events: Array[TelemetryEvent]) -> void

@abstract
func request_data_deletion() -> bool
