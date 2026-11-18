extends Node
## English source catalog; UI uses keys so future translations do not touch logic.
var catalog: Dictionary = {}

func _ready() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/locales/en.json"))
    if parsed is Dictionary:
        catalog = parsed
    else:
        push_error("Invalid English locale catalog")

func text(key: String) -> String:
    return str(catalog.get(key, key))
