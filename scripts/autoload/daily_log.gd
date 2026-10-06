extends Node
## Ghi lai nhung gi xay ra trong ngay. THUAN DU LIEU — khong chua logic gameplay.
## Dung cho bang tong ket cuoi ngay (GDD 3.13.3).

var study_by_course := {}
var money_in := 0
var money_out := 0
var stat_delta := {}
var activities_done := {}


func record_activity(activity: Activity) -> void:
	if activity.study_minutes > 0 and not activity.course_id.is_empty():
		study_by_course[activity.course_id] = study_minutes(activity.course_id) + activity.study_minutes
	if activity.money_gain > 0:
		money_in += activity.money_gain
	if activity.money_cost > 0:
		money_out += activity.money_cost
	activities_done[activity.id] = int(activities_done.get(activity.id, 0)) + 1


func study_minutes(course_id: String) -> int:
	return int(study_by_course.get(course_id, 0))


func record_stat_delta(stat_name: String, delta: float) -> void:
	if is_zero_approx(delta):
		return
	stat_delta[stat_name] = float(stat_delta.get(stat_name, 0.0)) + delta


func record_effects(effects: Dictionary) -> void:
	for key in effects:
		record_stat_delta(String(key), float(effects[key]))


## Tra ve du lieu tong ket ROI RESET. Goi khi ngu.
func take_summary() -> Dictionary:
	var summary := {
		"study_minutes": study_by_course.duplicate(),
		"money_in": money_in,
		"money_out": money_out,
		"stat_delta": stat_delta.duplicate(),
		"activities_done": activities_done.duplicate(),
	}
	reset()
	return summary


func reset() -> void:
	study_by_course.clear()
	money_in = 0
	money_out = 0
	stat_delta.clear()
	activities_done.clear()


func to_dict() -> Dictionary:
	return {
		"study_minutes": study_by_course.duplicate(),
		"money_in": money_in, "money_out": money_out,
		"stat_delta": stat_delta.duplicate(),
		"activities_done": activities_done.duplicate(),
	}


func from_dict(d: Dictionary) -> void:
	study_by_course = d.get("study_minutes", {}).duplicate()
	money_in = int(d.get("money_in", 0))
	money_out = int(d.get("money_out", 0))
	stat_delta = d.get("stat_delta", {}).duplicate()
	activities_done = d.get("activities_done", {}).duplicate()
