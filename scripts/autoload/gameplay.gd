extends Node
## Luat choi: xem truoc hau qua, kiem tra dieu kien, roi thuc thi hoat dong.

const TRACKED_STATS: Array[String] = ["stamina", "health", "mood", "intelligence", "academic", "skill"]
const MINUTES_PER_DAY := 1440


## Xem truoc hau qua — KHONG tac dung phu (GDD 3.13.1).
## Day la thu bien "ca lam them hay buoi hoc" thanh quyet dinh co suy nghi.
func preview(activity_id: String) -> Dictionary:
	var activity := ActivityDB.get_activity(activity_id)
	if activity == null:
		return {}
	var next_class := Schedule.next_class()
	var to_class := int(next_class.get("minutes", -1))
	return {
		"id": activity.id,
		"name": activity.display_name,
		"minutes": activity.minutes,
		"energy_cost": activity.energy_cost,
		"money_cost": activity.money_cost,
		"money_gain": activity.money_gain,
		"stat_effects": activity.stat_effects.duplicate(),
		"can_afford": PlayerStats.can_afford(activity.money_cost),
		"has_stamina": PlayerStats.stamina >= activity.energy_cost,
		"minutes_left_today": MINUTES_PER_DAY - GameClock.minute_of_day,
		"minutes_to_next_class": to_class,
		"next_class_course": String(next_class.get("course_id", "")),
		# Hau qua that: lam xong hoat dong nay thi co tre tiet ke tiep khong?
		"misses_next_class": to_class >= 0 and activity.minutes > to_class,
	}


func can_perform(activity: Activity) -> bool:
	if activity.money_cost > 0 and not PlayerStats.can_afford(activity.money_cost):
		return false
	if activity.energy_cost > 0.0 and PlayerStats.stamina < activity.energy_cost:
		return false
	return true


## Tra ve true neu thuc hien duoc.
func perform_activity(activity_id: String) -> bool:
	var activity := ActivityDB.get_activity(activity_id)
	if activity == null:
		push_warning("Khong tim thay hoat dong '%s'" % activity_id)
		return false
	if not can_perform(activity):
		if activity.money_cost > 0 and not PlayerStats.can_afford(activity.money_cost):
			EventBus.toast.emit("Khong du tien cho: %s" % activity.display_name)
		else:
			EventBus.toast.emit("Het suc roi, di ngu thoi.")
		return false

	var before := _snapshot_stats()

	if activity.money_cost > 0:
		PlayerStats.add_money(-activity.money_cost)
	if activity.money_gain > 0:
		PlayerStats.add_money(activity.money_gain)
	if activity.energy_cost > 0.0:
		PlayerStats.add_stat("stamina", -activity.energy_cost)

	PlayerStats.apply_effects(activity.stat_effects)
	if activity.id == "eat":
		PlayerStats.eat_meal()
	if activity.study_minutes > 0 and not activity.course_id.is_empty():
		ExamSystem.add_study(activity.course_id, activity.study_minutes)

	DailyLog.record_activity(activity)
	_record_deltas(before)

	if activity.is_sleep:
		_finish_day()
	else:
		GameClock.advance_minutes(activity.minutes)

	EventBus.activity_performed.emit(activity.id)
	EventBus.toast.emit("%s (%d phut)" % [activity.display_name, activity.minutes])
	return true


## Ngu: phat an thieu bua, phat bang tong ket, roi sang ngay.
func _finish_day() -> void:
	# Phai chup lai TRUOC khi sleep_until() reset meals_today va tang day,
	# neu khong bang tong ket luon bao "0/3 bua" va sai ngay.
	var meals := PlayerStats.meals_today
	var finished_day := GameClock.day

	var penalty := PlayerStats.meal_penalty()
	if not penalty.is_empty():
		PlayerStats.apply_effects(penalty)
		DailyLog.record_effects(penalty)

	GameClock.sleep_until()
	# Ngu hoi suc luc. Muc hoi theo KTX (x1.0 / x0.8 / x0.6) — slice tam dung KTX A.
	PlayerStats.set_stat("stamina", 100.0)
	PlayerStats.add_stat("mood", 8.0)

	var summary := DailyLog.take_summary()
	summary["meals"] = meals
	summary["day"] = finished_day
	EventBus.day_summary.emit(summary)


func _snapshot_stats() -> Dictionary:
	var snapshot := {}
	for n in TRACKED_STATS:
		snapshot[n] = PlayerStats.get_stat(n)
	return snapshot


func _record_deltas(before: Dictionary) -> void:
	for n in TRACKED_STATS:
		DailyLog.record_stat_delta(n, PlayerStats.get_stat(n) - float(before[n]))
