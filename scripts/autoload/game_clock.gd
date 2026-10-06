extends Node
## Dong ho game. 1 giay thuc = Balance.data.minutes_per_real_second phut game.
## Ngay bat dau tu 1, ngay 1 la Thu 2.

const MINUTES_PER_HOUR := 60
const MINUTES_PER_DAY := 1440
const DAYS_PER_WEEK := 7
const WEEKDAY_NAMES: Array[String] = [
	"Thu 2", "Thu 3", "Thu 4", "Thu 5", "Thu 6", "Thu 7", "Chu nhat",
]

var minute_of_day: int = 360
var day: int = 1
var paused: bool = false

var _accumulator: float = 0.0
var _silent: bool = false


func _ready() -> void:
	minute_of_day = Balance.data.day_start_minute
	EventBus.time_changed.emit(snapshot())


func _process(delta: float) -> void:
	if paused:
		return
	_accumulator += delta * Balance.data.minutes_per_real_second
	var steps := 0
	while _accumulator >= 1.0 and steps < 600:
		_accumulator -= 1.0
		_advance_minute()
		steps += 1


func _advance_minute() -> void:
	minute_of_day += 1
	var new_day := false
	if minute_of_day >= MINUTES_PER_DAY:
		minute_of_day = 0
		day += 1
		new_day = true
	if _silent:
		return
	if new_day:
		EventBus.day_started.emit(snapshot())
	EventBus.time_changed.emit(snapshot())


## Tua thoi gian. Chi phat signal mot lan cho ca lo.
func advance_minutes(amount: int) -> void:
	amount = maxi(amount, 0)
	if amount == 0:
		return
	var start_day := day
	_silent = true
	for _i in amount:
		_advance_minute()
	_silent = false
	if day != start_day:
		EventBus.day_started.emit(snapshot())
	EventBus.time_changed.emit(snapshot())


## Ngu sang hom sau, thuc day luc `target_minute`.
func sleep_until(target_minute: int = -1) -> void:
	if target_minute < 0:
		target_minute = Balance.data.day_start_minute
	advance_minutes(MINUTES_PER_DAY - minute_of_day + target_minute)


func hour() -> int:
	return floori(minute_of_day / 60.0)


func minute() -> int:
	return minute_of_day % MINUTES_PER_HOUR


func weekday_index() -> int:
	return (day - 1) % DAYS_PER_WEEK


func weekday_name() -> String:
	return WEEKDAY_NAMES[weekday_index()]


func week() -> int:
	return floori((day - 1) / float(DAYS_PER_WEEK)) + 1


func time_string() -> String:
	return "%02d:%02d" % [hour(), minute()]


func snapshot() -> Dictionary:
	return {
		"minute_of_day": minute_of_day, "hour": hour(), "minute": minute(),
		"day": day, "weekday_index": weekday_index(),
		"weekday_name": weekday_name(), "week": week(),
	}


func to_dict() -> Dictionary:
	return {"minute_of_day": minute_of_day, "day": day}


func from_dict(d: Dictionary) -> void:
	minute_of_day = clampi(int(d.get("minute_of_day", 360)), 0, MINUTES_PER_DAY - 1)
	day = maxi(int(d.get("day", 1)), 1)
	EventBus.time_changed.emit(snapshot())
