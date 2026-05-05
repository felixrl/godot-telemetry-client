class_name TelemetryClientGlobal
extends Node

## Autoload access for the rest of the game to access the telemetry client

## Objectives:
## - Low priority, threaded work to avoid gameplay blocking.
## - Always fail silently to avoid crashes.

## TODO: Store consent to local config/settings file

var service: AbstractTelemetryService = null

var telemetry_thread: Thread
var queue_lock: Mutex
var service_lock: Mutex
var flush_requested: Semaphore

var event_queue: Array[TelemetryEvent] = []

## If telemetry as a whole is enabled
var is_telemetry_enabled: bool = true
## If the user has consented to data collection
var is_opted_in: bool = false

func _ready() -> void:
	_spin_up_worker_thread()

## Run all expensive telemetry logic (file or network IO) on a thread
## to avoid blocking gameplay.
func _spin_up_worker_thread() -> void:
	telemetry_thread = Thread.new()
	queue_lock = Mutex.new()
	service_lock = Mutex.new()
	flush_requested = Semaphore.new()
	telemetry_thread.start(_thread_telemetry_worker, Thread.PRIORITY_LOW)

## Inject chosen telemetry provider
func set_service(_service: AbstractTelemetryService) -> void:
	service_lock.lock()
	service = _service
	service_lock.unlock()

## Tries to add an event with name and (key, value) pairs dictionary
## Can indicate flush_immediately to flush this and all queued events through the service
func log_event(event_name: String, event_key_values: Dictionary = {}, flush_immediately: bool = false) -> void:
	if not _is_active():
		return
	
	queue_lock.lock()
	event_queue.push_back(TelemetryEvent.new(event_name, event_key_values))
	queue_lock.unlock()
	
	if flush_immediately:
		flush_requested.post()

## Request a flush for all queued events
func flush() -> void:
	flush_requested.post()

## Compliance with privacy regulations to allow user to request data deletion
func request_data_deletion() -> bool:
	service_lock.lock()
	var res := service.request_data_deletion()
	service_lock.unlock()
	return res

#region ACTIVE STATUS

func set_telemetry_enabled(status: bool) -> void:
	is_telemetry_enabled = status

func opt_in() -> void:
	is_opted_in = true

func opt_out() -> void:
	is_opted_in = false

## Active when enabled 
func _is_active() -> bool:
	return is_telemetry_enabled and is_opted_in and service != null

#endregion

#region THREADED LOGIC

func _thread_telemetry_worker() -> void:
	while true:
		# TODO: Replace this polling with a wait on a semaphore signal or something
		if not _is_active():
			continue
		
		flush_requested.wait()
		if not event_queue.is_empty():
			var start_time := Time.get_ticks_msec()
			print("TELEMETRY: Logging events...")
			
			# Pull from queue and clear the original queue
			queue_lock.lock()
			var local_queue: Array[TelemetryEvent] = []
			local_queue.assign(event_queue)
			event_queue.clear()
			queue_lock.unlock()
			
			_process_events_on_thread(local_queue)
			
			print("TELEMETRY: Events logged with duration: ", Time.get_ticks_msec() - start_time, "ms")
		else:
			print("TELEMETRY: Flush requested, but no events in queue!")

func _process_events_on_thread(events: Array[TelemetryEvent]) -> void:
	service_lock.lock()
	service.send(events)
	service_lock.unlock()

#endregion
