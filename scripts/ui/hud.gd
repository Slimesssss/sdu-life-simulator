extends CanvasLayer
## HUD + bon thu "vong phan hoi" o GDD 3.13.

const EXAM_DAY := 7

var player: Node = null
var _course: Course
var _info: Label
var _prompt: Label
var _preview: Label
var _toast: Label
var _summary: Label
var _toast_timer := 0.0
var _summary_timer := 0.0


func _ready() -> void:
	layer = 10
	_course = load("res://data/courses/it101.tres") as Course
	_info = _label(Vector2(12, 8), Vector2(430, 120), 17)
	_prompt = _label(Vector2(0, 632), Vector2(1280, 28), 20)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview = _label(Vector2(12, 496), Vector2(620, 130), 15)
	_toast = _label(Vector2(0, 456), Vector2(1280, 26), 18)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary = _label(Vector2(380, 150), Vector2(520, 220), 16)
	_summary.visible = false
	EventBus.time_changed.connect(func(_c): _refresh())
	EventBus.stat_changed.connect(func(_n, _v): _refresh())
	EventBus.toast.connect(_show_toast)
	EventBus.prompt_changed.connect(_on_prompt)
	EventBus.day_summary.connect(_show_summary)
	_refresh()


func _label(pos: Vector2, size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	return label


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast.modulate.a = clampf(_toast_timer, 0.0, 1.0)
	if _summary_timer > 0.0:
		_summary_timer -= delta
		if _summary_timer <= 0.0:
			_summary.visible = false


func _refresh() -> void:
	var clock := GameClock.snapshot()
	_info.text = "%s · %s · ngay %d\nSuc luc %s\nSuc khoe %s\nTinh than %s\nTien %s · an %d/3 bua" % [
		clock["weekday_name"], GameClock.time_string(), clock["day"],
		_bar(PlayerStats.stamina), _bar(PlayerStats.health), _bar(PlayerStats.mood),
		_money(PlayerStats.money), PlayerStats.meals_today,
	]
	if _course != null:
		var prep := ExamSystem.prep_ratio(_course)
		_info.text += "\nChuan bi thi %s: %d%% (thieu %d phut)" % [
			_course.id, int(prep * 100.0), ExamSystem.minutes_missing(_course),
		]
		_info.text += "\nTri tue %d · Hoc luc %d · Ki nang %d" % [
			int(PlayerStats.intelligence), int(PlayerStats.academic), int(PlayerStats.skill),
		]


func _bar(value: float) -> String:
	var filled := clampi(int(round(value / 10.0)), 0, 10)
	return "[%s%s] %d%%" % ["#".repeat(filled), "-".repeat(10 - filled), int(value)]


func _money(amount: int) -> String:
	var text := str(absi(amount))
	var out := ""
	while text.length() > 3:
		out = "." + text.right(3) + out
		text = text.left(text.length() - 3)
	return ("-" if amount < 0 else "") + text + out + "d"


func _on_prompt(text: String) -> void:
	_prompt.text = text
	var target: Interactable = null
	if player != null:
		target = player.get("nearest") as Interactable
	if target == null:
		_preview.text = ""
		return
	_preview.text = _preview_text(target.preview())


## GDD 3.13.1 — day la thu bien "di lam hay di hoc" thanh quyet dinh co suy nghi.
func _preview_text(p: Dictionary) -> String:
	if p.is_empty():
		return ""
	var lines: Array[String] = ["--- %s ---" % p["name"]]
	var cost := "Ton: %d phut · %d suc luc" % [p["minutes"], int(p["energy_cost"])]
	if int(p["money_cost"]) > 0:
		cost += " · %s" % _money(int(p["money_cost"]))
	lines.append(cost)
	if int(p["money_gain"]) > 0:
		lines.append("Nhan: +%s" % _money(int(p["money_gain"])))
	var effects: Array[String] = []
	for stat_name in p["stat_effects"]:
		effects.append("%s %+.0f" % [stat_name, float(p["stat_effects"][stat_name])])
	if not effects.is_empty():
		lines.append("Chi so: " + ", ".join(effects))
	var to_class := int(p.get("minutes_to_next_class", -1))
	if to_class < 0:
		lines.append("Tuan nay khong con tiet nao.")
	else:
		lines.append("Con %d gio %d phut toi tiet %s" % [
			to_class / 60, to_class % 60, String(p.get("next_class_course", "")),
		])
	# Hau qua that neu lam hoat dong nay: co mat tiet khong?
	if bool(p.get("misses_next_class", false)):
		lines.append("!! Lam xong la TRE TIET / mat tiet")
	if not p["can_afford"]:
		lines.append("!! Khong du tien")
	if not p["has_stamina"]:
		lines.append("!! Khong du suc luc")
	return "\n".join(lines)


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.modulate.a = 1.0
	_toast_timer = 3.0


## GDD 3.13.3 — vong phan hoi re nhat ma hieu qua nhat.
func _show_summary(summary: Dictionary) -> void:
	var lines: Array[String] = ["== HET NGAY %d ==" % int(summary.get("day", GameClock.day))]
	var studied: Dictionary = summary["study_minutes"]
	if studied.is_empty():
		lines.append("Hom nay khong hoc phut nao.")
	for course_id in studied:
		lines.append("Hoc %d phut mon %s" % [int(studied[course_id]), course_id])
	lines.append("Tien: +%s · -%s" % [
		_money(int(summary["money_in"])), _money(int(summary["money_out"])),
	])
	var deltas: Array[String] = []
	for stat_name in summary["stat_delta"]:
		deltas.append("%s %+.0f" % [stat_name, float(summary["stat_delta"][stat_name])])
	if not deltas.is_empty():
		lines.append("Chi so: " + ", ".join(deltas))
	var meals := int(summary.get("meals", PlayerStats.meals_today))
	if meals < 3:
		lines.append("Chi an %d/3 bua — suc khoe bi tru." % meals)
	if _course != null:
		var prep := int(ExamSystem.prep_ratio(_course) * 100.0)
		var days_left := maxi(EXAM_DAY - int(summary.get("day", GameClock.day)), 0)
		if days_left <= 0:
			lines.append("!! Ngay mai thi %s, ban dang o %d%%" % [_course.id, prep])
		else:
			lines.append("Con %d ngay thi %s, ban moi dat %d%%" % [days_left, _course.id, prep])
	_summary.text = "\n".join(lines)
	_summary.visible = true
	_summary_timer = 8.0
