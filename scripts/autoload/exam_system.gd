extends Node
## Tinh diem thi. Cong thuc o GDD 3.4.
var study_minutes_by_course := {}
var attendance_by_course := {}
var locked_scores := {}


func add_study(course_id: String, minutes: int) -> void:
	study_minutes_by_course[course_id] = study_minutes(course_id) + minutes


func study_minutes(course_id: String) -> int:
	return int(study_minutes_by_course.get(course_id, 0))


func attendance(course_id: String) -> float:
	return float(attendance_by_course.get(course_id, 1.0))


## Ti le chuan bi thi, 0..1. HUD va cong thuc diem dung CHUNG ham nay —
## neu tinh o hai noi thi hai con so se lech nhau, nguoi choi mat tin vao HUD.
func prep_ratio(course: Course) -> float:
	var effective: float = float(study_minutes(course.id)) \
		* (1.0 + Balance.data.int_bonus * PlayerStats.intelligence / 100.0)
	return clampf(effective / float(course.required_minutes), 0.0, 1.0)


## So phut tu hoc con thieu de dat prep = 1.0. Dung de hien "con thieu X gio".
func minutes_missing(course: Course) -> int:
	var per_minute := 1.0 + Balance.data.int_bonus * PlayerStats.intelligence / 100.0
	var needed: float = float(course.required_minutes) * (1.0 - prep_ratio(course))
	return maxi(int(ceil(needed / per_minute)), 0)


## prep = gio hoc hieu qua / gio can thiet. Tri tue quyet dinh hieu qua gio hoc.
func compute_score(course: Course, minigame_score: float) -> float:
	var cfg: BalanceConfig = Balance.data
	var prep := prep_ratio(course)

	var raw := cfg.prep_weight * prep \
		+ cfg.minigame_weight * clampf(minigame_score, 0.0, 1.0) \
		+ cfg.knowledge_weight * (PlayerStats.academic / 100.0) \
		+ cfg.attendance_weight * attendance(course.id)

	# Phong do: lay chi so THAP HON giua suc khoe va tinh than.
	var form := cfg.form_min \
		+ (cfg.form_max - cfg.form_min) * (minf(PlayerStats.health, PlayerStats.mood) / 100.0)

	return snappedf(10.0 * clampf(raw, 0.0, 1.0) * form, cfg.score_step)


## Chot diem mon. Khoa vinh vien — goi lai cung khong doi.
func lock_score(course: Course, minigame_score: float) -> Dictionary:
	if locked_scores.has(course.id):
		return locked_scores[course.id]
	var result := {"score": compute_score(course, minigame_score), "is_retake": false}
	locked_scores[course.id] = result
	EventBus.exam_finished.emit(course.id, float(result["score"]))
	return result


func is_passed(course_id: String) -> bool:
	if not locked_scores.has(course_id):
		return false
	return float(locked_scores[course_id]["score"]) >= Balance.data.pass_score


## Hoc lai he: cai thien duoc, nhung KHONG BAO GIO qua 8.
func retake(course: Course, minigame_score: float) -> float:
	var score := minf(compute_score(course, minigame_score), Balance.data.retake_cap)
	locked_scores[course.id] = {"score": score, "is_retake": true}
	EventBus.exam_finished.emit(course.id, score)
	return score


func to_dict() -> Dictionary:
	return {
		"study_minutes_by_course": study_minutes_by_course.duplicate(),
		"attendance_by_course": attendance_by_course.duplicate(),
		"locked_scores": locked_scores.duplicate(true),
	}


func from_dict(d: Dictionary) -> void:
	study_minutes_by_course = d.get("study_minutes_by_course", {}).duplicate()
	attendance_by_course = d.get("attendance_by_course", {}).duplicate()
	locked_scores = d.get("locked_scores", {}).duplicate(true)
