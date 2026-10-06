extends Node
## Nap toan bo hoat dong tu data/activities/*.tres.

const ACTIVITY_DIR := "res://data/activities"

var _activities := {}


func _ready() -> void:
	reload()


func reload() -> void:
	_activities.clear()
	var dir := DirAccess.open(ACTIVITY_DIR)
	if dir == null:
		push_warning("Khong mo duoc %s" % ACTIVITY_DIR)
		return
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var res := load(ACTIVITY_DIR.path_join(file_name))
		var activity := res as Activity
		if activity != null:
			_activities[activity.id] = activity
	print("[ActivityDB] nap %d hoat dong" % _activities.size())


func get_activity(id: String) -> Activity:
	return _activities.get(id) as Activity


func all_ids() -> Array:
	return _activities.keys()
