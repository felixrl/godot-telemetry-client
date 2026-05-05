@tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("Telemetry", get_plugin_path() + "/telemetry_client_global.gd")

func _exit_tree():
	remove_autoload_singleton("Telemetry")

func get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir()
