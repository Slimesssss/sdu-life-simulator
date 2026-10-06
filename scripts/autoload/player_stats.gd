extends Node
## 7 chi so nguoi choi. Xem GDD 3.2 / 3.2d.
var stamina := 100.0
var health := 80.0
var mood := 80.0
var intelligence := 20.0
var academic := 30.0
var skill := 10.0
var money := 3_000_000
var highest_milestone := {}
var perk_choices := {}

## So bua da an hom nay, 0..3. Reset khi sang ngay.
var meals_today := 0

const STAT_NAMES: Array[String] = ["stamina", "health", "mood", "intelligence", "academic", "skill"]
## SAN chi ap cho 3 chi so ky nang. stamina/health/mood phai tut tu do duoc.
const FLOOR_STATS: Array[String] = ["intelligence", "academic", "skill"]


func _ready() -> void:
	stamina = Balance.data.start_stamina
	health = Balance.data.start_health
	mood = Balance.data.start_mood
	intelligence = Balance.data.start_intelligence
	academic = Balance.data.start_academic
	skill = Balance.data.start_skill
	money = Balance.data.start_money
	EventBus.day_started.connect(_on_day_started)


## Phat khi ngu ma an thieu bua. Xem GDD 3.13.4.
## Khong co luat nay thi "nhin an tiet kiem" la lua chon MIEN PHI — ai cung nhin,
## va ap luc tien bien mat.
func meal_penalty() -> Dictionary:
	match mini(meals_today, 3):
		3: return {}
		2: return {"health": -3.0}
		1: return {"health": -8.0, "mood": -4.0}
		_: return {"health": -15.0, "mood": -10.0}


func eat_meal() -> void:
	meals_today = mini(meals_today + 1, 3)
	EventBus.stat_changed.emit("meals_today", float(meals_today))


func _on_day_started(_clock: Dictionary) -> void:
	meals_today = 0


func has_floor(n: String) -> bool:
	return FLOOR_STATS.has(n)


func floor_for(n: String) -> float:
	return float(highest_milestone.get(n, 0)) if has_floor(n) else 0.0


func get_stat(n: String) -> float:
	match n:
		"stamina": return stamina
		"health": return health
		"mood": return mood
		"intelligence": return intelligence
		"academic": return academic
		"skill": return skill
	return 0.0


## Kep theo SAN DONG, khong phai clampf(value, 0, 100).
func set_stat(n: String, v: float) -> void:
	v = clampf(v, floor_for(n), 100.0)
	match n:
		"stamina": stamina = v
		"health": health = v
		"mood": mood = v
		"intelligence": intelligence = v
		"academic": academic = v
		"skill": skill = v
	_update_milestone(n, v)
	EventBus.stat_changed.emit(n, v)


func add_stat(n: String, d: float) -> void:
	set_stat(n, get_stat(n) + d)


func _update_milestone(n: String, v: float) -> void:
	if not has_floor(n):
		return
	var step: int = Balance.data.milestone_step
	var reached := int(floor(v / float(step))) * step
	if reached > int(highest_milestone.get(n, 0)):
		highest_milestone[n] = reached


func add_money(a: int) -> void:
	money = maxi(money + a, 0)
	EventBus.stat_changed.emit("money", float(money))


func can_afford(a: int) -> bool:
	return money >= a


## {"mood": 5, "skill": 2, "money": -25000}
func apply_effects(e: Dictionary) -> void:
	for k in e:
		var n := String(k)
		if n == "money":
			add_money(int(e[k]))
		elif STAT_NAMES.has(n):
			add_stat(n, float(e[k]))
		else:
			push_warning("Hieu ung chua ho tro: %s" % n)


func to_dict() -> Dictionary:
	var d := {
		"money": money,
		"meals_today": meals_today,
		"highest_milestone": highest_milestone.duplicate(),
		"perk_choices": perk_choices.duplicate(),
	}
	for n in STAT_NAMES:
		d[n] = get_stat(n)
	return d


func from_dict(d: Dictionary) -> void:
	# Nap SAN truoc khi set chi so, neu khong set_stat se kep sai.
	highest_milestone = d.get("highest_milestone", {}).duplicate()
	perk_choices = d.get("perk_choices", {}).duplicate()
	for n in STAT_NAMES:
		set_stat(n, float(d.get(n, get_stat(n))))
	money = int(d.get("money", Balance.data.start_money))
	meals_today = int(d.get("meals_today", 0))
	EventBus.stat_changed.emit("all", 0.0)
