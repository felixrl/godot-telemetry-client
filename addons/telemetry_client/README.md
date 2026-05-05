# Godot Telemetry Client

**v0.0.1**

A simple Godot plugin that provides a Telemetry autoload for logging telemetry events and requests, with various swappable telemetry services based on an AbstractTelemetryService "interface".

# Getting Started

1. Install the `addons/telemetry_client` folder to your Godot project and enable it in `Project Settings > Plugins`.
2. In your game's "main" startup logic, call `Telemetry.set_service(...)` with your choice of service.
3. After receiving user consent, call `Telemetry.opt_in()`.

Then, whenever you want to log an event, call `Telemetry.log_event(...)`. This can be marked with an argument to flush (send) immediately, or you can flush in bulk later by calling `Telemetry.flush()`.

### Opting Out & Deletion Requests

If the user opts out, call `Telemetry.opt_out()`. This will stop all data tracking and transmission but will not delete data. 

To delete the user's data, call `Telemetry.request_data_deletion()`. This will return a boolean based on the success of the deletion.

# Supported Services

### Local JSON

```
Telemetry.set_service(JsonTelemetryService.new("telemetry_data.json"))
```

Writes all events to the named file in Godot's `user://` path when flushed. Data deletion will keep the file but clear all contents.

### Unity Services Analytics

```
Telemetry.set_service(UnityTelemetryService.new("<PROJECT-ID>", "<ENVIRONMENT-NAME>"))
```

Calls the Unity Analytics REST API with your event list in bulk upon flushing. 

NOTE: Make sure to use the Project ID and not Project Name! The Project ID can be found in the Settings part of the Unity Services project dashboard.

# Custom Services

You can connect your own telemetry service by creating a class that extends `AbstractTelemetryService` and implementing:

### `func send(events: Array[TelemetryEvent]) -> void`
 - Flushes and tracks the given list of events. 
 - E.g. writes to file, sends a network request, etc.

### `func request_data_deletion() -> bool`
- Sends a request to delete all collected data about the current user. Returns true if the data was successfully deleted and false if a problem occurred. 
- E.g. clears file, deletes file, sends network data deletion request, etc.
