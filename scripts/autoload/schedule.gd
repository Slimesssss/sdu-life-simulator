extends Node
## Thoi khoa bieu. Tinh tiet ke tiep tu dong ho game.
const COURSE_DIR := "res://data/courses"
var _courses := {}


func _ready() -> void:
	reload()


func reload() -> void:
	_courses.clear()
	var dir := DirAccess.open(COURSE_DIR)
	if dir == null:
		push_warning("Khong mo duoc %s" % COURSE_DIR)
		return
	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var course := load(COURSE_DIR.path_join(file_name)) as Course
		if course != null:
			_courses[course.id] = course


func get_course(course_id: String) -> Course:
	return _courses.get(course_id) as Course


func all_courses() -> Array:
	return _courses.values()


## Tiet ke tiep: {"course_id", "minutes", "weekday", "minute"}. {} neu khong co tiet.
func next_class() -> Dictionary:
	var best := {}
	var best_minutes := -1
	var now_weekday := GameClock.weekday_index()
	var now_minute := GameClock.minute_of_day

	for course_id in _courses:
		var course: Course = _courses[course_id]
		for slot in course.class_slots:
			var weekday := int(slot.get("weekday", 0))
			var start := int(slot.get("minute", 450))
			var delta := ((weekday - now_weekday + 7) % 7) * 1440 + start - now_minute
			if delta < 0:
				delta += 7 * 1440
			if best_minutes < 0 or delta < best_minutes:
				best_minutes = delta
				best = {
					"course_id": course_id, "minutes": delta,
					"weekday": weekday, "minute": start,
				}
	return best


## So phut toi tiet ke tiep. -1 neu khong co tiet nao.
func minutes_to_next_class() -> int:
	var next := next_class()
	if next.is_empty():
		return -1
	return int(next["minutes"])
