extends Node2D
## Diem vao cua game.
##
## Che do tu kiem tra (khong can nguoi choi):
##   godot --headless --path <project> -- --selftest

const TILE := 16
const COURSE_PATH := "res://data/courses/it101.tres"
const PLAYER_SCRIPT := preload("res://scripts/player.gd")
const HUD_SCRIPT := preload("res://scripts/ui/hud.gd")
const INTERACTABLE_SCRIPT := preload("res://scripts/world/interactable.gd")

## Cua nao cho hoat dong nao.
const DOOR_ACTIVITIES := {
	"ktx_a": "sleep",
	"cang_tin": "eat",
	"nha_a": "study",
	"nha_de_xe": "part_time",
}

const DOOR_LABELS := {
	"ktx_a": "Ngu (KTX A)",
	"cang_tin": "An o can tin",
	"nha_a": "Tu hoc o thu vien",
	"nha_de_xe": "Lam them trong xe",
}

const TILE_COLORS := {
	CampusMap.Tile.GRASS: Color("4f8f45"),
	CampusMap.Tile.FIELD: Color("3f7a3a"),
	CampusMap.Tile.WALL: Color("7d6354"),
	CampusMap.Tile.PATH: Color("9e9a96"),
	CampusMap.Tile.DOOR: Color("a87c4f"),
	CampusMap.Tile.WATER: Color("3a6ea5"),
}

var grid: Array
var player: Node2D


func _ready() -> void:
	grid = CampusMap.build()
	if "--selftest" in OS.get_cmdline_user_args():
		_run_selftest()
		return
	if "--looptest" in OS.get_cmdline_user_args():
		_run_looptest()
		return
	if "--hudtest" in OS.get_cmdline_user_args():
		_run_hudtest()
		return
	if "--econtest" in OS.get_cmdline_user_args():
		_run_econtest()
		return
	_start_game()


# ------------------------------------------------------------- econtest

## Bang kinh te CO TINH HOC PHI. Bang cu trong GDD bo sot hoc phi nen lac quan qua.
func _run_econtest() -> void:
	var b: BalanceConfig = Balance.data
	var semester_weeks := 15.0
	var days_per_month := 28.0
	var months_per_semester := semester_weeks * 7.0 / days_per_month
	var tuition_month := float(b.tuition_per_term) / months_per_semester
	var meals_month := float(b.meal_cost) * 3.0 * days_per_month
	var scholarship := 3_000_000

	print("=== KINH TE: 1 THANG = 28 NGAY ===")
	print("1 hoc ky = %.0f tuan = %.2f thang" % [semester_weeks, months_per_semester])
	print("Hoc phi %s/ky  ->  %s/thang" % [_fmt(b.tuition_per_term), _fmt(int(tuition_month))])
	print("An 3 bua/ngay    ->  %s/thang" % _fmt(int(meals_month)))
	print("Gia dinh         ->  %s/thang" % _fmt(b.family_monthly))
	print("1 ca lam them    ->  %s" % _fmt(b.part_time_pay))
	print("")

	var header := "%-6s %12s %12s %12s %14s %8s"
	print(header % ["KTX", "Thu", "Thue+an", "Hoc phi", "Con/thang", "Ca/thang"])
	print("-".repeat(74))
	for row in [["A", b.rent_a], ["B", b.rent_b], ["C", b.rent_c]]:
		var cost := float(row[1]) + meals_month
		var left := float(b.family_monthly) - cost - tuition_month
		var shifts := 0
		if left < 0.0:
			shifts = int(ceil(-left / float(b.part_time_pay)))
		print(header % [row[0], _fmt(b.family_monthly), _fmt(int(cost)),
			_fmt(int(tuition_month)), _fmt(int(left)), shifts])

	print("")
	print("Ca lam them cho CA HOC KY (%.2f thang):" % months_per_semester)
	for row in [["A", b.rent_a], ["B", b.rent_b], ["C", b.rent_c]]:
		var left := float(b.family_monthly) - float(row[1]) - meals_month - tuition_month
		var total := 0
		if left < 0.0:
			total = int(ceil(-left * months_per_semester / float(b.part_time_pay)))
		print("  KTX %s: %2d ca/ky (~%.1f ca/tuan) | no ca ky neu khong lam: %s" % [
			row[0], total, float(total) / semester_weeks, _fmt(int(left * months_per_semester))])
	print("")
	print("Hoc bong %s/ky (GPA >= 8.0) = %.1f ca lam them." % [
		_fmt(scholarship), float(scholarship) / float(b.part_time_pay)])
	get_tree().quit()


func _fmt(amount: int) -> String:
	var text := str(absi(amount))
	var out := ""
	while text.length() > 3:
		out = "." + text.right(3) + out
		text = text.left(text.length() - 3)
	return ("-" if amount < 0 else "") + text + out + "d"


# ------------------------------------------------------------- looptest

## Mo phong tron 1 tuan voi 2 loi choi, de tra loi tieu chi M0:
## "hoc hay di lam" co phai quyet dinh that khong?
func _run_looptest() -> void:
	print("=== LOOPTEST: 1 TUAN, 2 LOI CHOI ===")
	var course := load(COURSE_PATH) as Course
	_play_week(course, "A. Cham chi hoc (0 ca lam them)", 6, 0)
	_play_week(course, "B. Di lam nhieu (1 ca/ngay)", 2, 1)
	_play_week(course, "C. Chi di lam (3 ca)", 0, 3)
	get_tree().quit()


func _play_week(course: Course, label: String, study_per_day: int, work_per_day: int) -> void:
	PlayerStats.from_dict({})
	ExamSystem.from_dict({})
	DailyLog.reset()
	GameClock.from_dict({"day": 1, "minute_of_day": 390})
	GameClock.paused = true

	var money_start := PlayerStats.money
	var failed := 0
	for _day in 7:
		for _meal in 3:
			if not Gameplay.perform_activity("eat"):
				failed += 1
		for _i in study_per_day:
			if not Gameplay.perform_activity("study"):
				failed += 1
		for _i in work_per_day:
			if not Gameplay.perform_activity("part_time"):
				failed += 1
		Gameplay.perform_activity("sleep")

	var prep := ExamSystem.prep_ratio(course)
	var score := ExamSystem.compute_score(course, 0.8)
	print("%-32s tien %+9s | prep %3d%% | diem %.1f | suc khoe %d | tinh than %d | %d luot bi chan"
		% [label, _vnd(PlayerStats.money - money_start), int(prep * 100.0), score,
		int(PlayerStats.health), int(PlayerStats.mood), failed])


func _vnd(amount: int) -> String:
	return "%s%d" % ["-" if amount < 0 else "+", absi(amount)]


# -------------------------------------------------------------- hudtest

## Kiem tra HUD THAT SU chay duoc: khung xem truoc (3.13.1) va bang tong ket (3.13.3).
## Headless khong ve duoc pixel, nhung Label va ham dinh dang van chay that —
## day la cho duy nhat bat duoc loi runtime cua HUD ma khong can ngoi choi.
func _run_hudtest() -> void:
	_start_game()
	var hud := get_node_or_null("HUD")
	if hud == null:
		printerr("Khong tao duoc HUD")
		get_tree().quit(1)
		return

	print("=== HUDTEST ===")
	var interactables := get_tree().get_nodes_in_group("interactable")
	print("Interactable tao duoc: %d" % interactables.size())
	for node in interactables:
		print("  %-16s -> %-10s tai %s" % [node.name, node.activity_id, node.position])

	# Di chuyen nguoi choi toi cua Nha A roi de _update_nearest tu tim.
	var cell := CampusMap.door_approach("nha_a")
	player.position = CampusMap.cell_to_world(cell)
	player.call("_update_nearest")
	var found = player.get("nearest")
	print("")
	print("Player dung o %s -> tim thay: %s" % [cell, found.name if found != null else "KHONG CO"])
	if found == null:
		printerr("LOI: khong tim thay vat tuong tac nao")
		get_tree().quit(1)
		return

	print("Dong goi y: %s" % found.prompt())
	print("")
	print("--- Khung xem truoc hau qua (GDD 3.13.1) ---")
	print(hud.get("_preview").text)

	# Xem truoc TAT CA hoat dong cung luc: cai nao lam tre tiet?
	print("")
	print("--- Hoat dong nao lam tre tiet ke tiep? ---")
	for node in interactables:
		var p: Dictionary = node.preview()
		print("%-22s %3d phut | toi tiet %3d phut | tre tiet? %s" % [
			p["name"], int(p["minutes"]), int(p["minutes_to_next_class"]), p["misses_next_class"],
		])

	print("")
	print("--- Bang tong ket cuoi ngay (GDD 3.13.3) ---")
	Gameplay.perform_activity("study")
	Gameplay.perform_activity("eat")
	Gameplay.perform_activity("part_time")
	Gameplay.perform_activity("sleep")
	print(hud.get("_summary").text)

	print("")
	print("--- Thanh chi so (GDD 3.13.2) ---")
	print(hud.get("_info").text)

	print("")
	print("--- Toast ---")
	print(hud.get("_toast").text)
	get_tree().quit()


func _start_game() -> void:
	_build_collision()
	var hud: CanvasLayer = HUD_SCRIPT.new()
	hud.name = "HUD"
	add_child(hud)
	_spawn_player()
	_spawn_interactables()
	hud.set("player", player)
	queue_redraw()
	EventBus.toast.emit("WASD de di, E de tuong tac.")


func _draw() -> void:
	for y in CampusMap.H:
		for x in CampusMap.W:
			var tile: int = grid[y][x]
			var color: Color = TILE_COLORS.get(tile, Color.MAGENTA)
			if tile == CampusMap.Tile.GRASS and (x + y) % 2 == 0:
				color = color.lightened(0.03)
			draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), color)
	for door_id in DOOR_ACTIVITIES:
		var cell := CampusMap.door_approach(door_id)
		draw_rect(Rect2(cell.x * TILE - 2, cell.y * TILE - 2, TILE + 4, TILE + 4), Color(1, 1, 1, 0.5), false, 2.0)


## Gop cac o dac lien nhau theo hang thanh mot hinh chu nhat — dung tao 1 collider moi o.
func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "Walls"
	add_child(body)
	for y in CampusMap.H:
		var x := 0
		while x < CampusMap.W:
			if not CampusMap.is_solid(grid[y][x]):
				x += 1
				continue
			var start := x
			while x < CampusMap.W and CampusMap.is_solid(grid[y][x]):
				x += 1
			var width := x - start
			var shape := RectangleShape2D.new()
			shape.size = Vector2(width * TILE, TILE)
			var collider := CollisionShape2D.new()
			collider.shape = shape
			collider.position = Vector2((start + width * 0.5) * TILE, (y + 0.5) * TILE)
			body.add_child(collider)


func _spawn_player() -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 9)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(0, 2)
	player.add_child(collider)

	var camera := Camera2D.new()
	camera.zoom = Vector2(2, 2)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = CampusMap.W * TILE
	camera.limit_bottom = CampusMap.H * TILE
	camera.position_smoothing_enabled = true
	player.add_child(camera)

	player.position = CampusMap.cell_to_world(CampusMap.SPAWN)
	add_child(player)


func _spawn_interactables() -> void:
	var root := Node2D.new()
	root.name = "Interactables"
	add_child(root)
	for door_id in DOOR_ACTIVITIES:
		var activity_id: String = DOOR_ACTIVITIES[door_id]
		var node: StaticBody2D = INTERACTABLE_SCRIPT.new()
		node.name = "Door_" + String(door_id)
		node.set("activity_id", activity_id)
		node.set("label", DOOR_LABELS.get(door_id, activity_id))
		node.position = CampusMap.cell_to_world(CampusMap.door_approach(door_id))
		root.add_child(node)


# ------------------------------------------------------------------ selftest

func _run_selftest() -> void:
	print("=== SELFTEST: CONG THUC DIEM THI (GDD 3.4) ===")
	var course := load(COURSE_PATH) as Course
	if course == null:
		printerr("Khong nap duoc %s" % COURSE_PATH)
		get_tree().quit(1)
		return
	print("Mon: %s | required_minutes = %d | truot khi < %.1f"
		% [course.display_name, course.required_minutes, Balance.data.pass_score])
	print("")

	_case(course, "A. Bo hoc hoan toan", 0, 0.8, 1.0, 30.0, 100.0, 100.0, 4.0, 4.5)
	_case(course, "B. Hoc du gio, thi tot", course.required_minutes, 0.8, 1.0, 30.0, 100.0, 100.0, 8.0, 9.0)
	_case(course, "C. Hoc du gio nhung om", course.required_minutes, 0.8, 1.0, 30.0, 20.0, 40.0, 6.5, 8.0)

	# Hoc lai he: cai thien duoc nhung KHONG BAO GIO qua 8.
	ExamSystem.study_minutes_by_course.clear()
	ExamSystem.study_minutes_by_course[course.id] = course.required_minutes * 3
	PlayerStats.set_stat("health", 100.0)
	PlayerStats.set_stat("mood", 100.0)
	PlayerStats.set_stat("academic", 100.0)
	PlayerStats.set_stat("intelligence", 100.0)
	var retake := ExamSystem.retake(course, 1.0)
	print("D. Hoc lai he, thi 10/10        -> %.1f   (tran %.1f)"
		% [retake, Balance.data.retake_cap])
	print("   Dat? %s | is_retake = %s"
		% [ExamSystem.is_passed(course.id), ExamSystem.locked_scores[course.id]["is_retake"]])

	print("")
	print("=== Ban do ===")
	var problems := CampusMap.validate()
	if problems.is_empty():
		print("OK: 15/15 cua toi duoc tu SPAWN.")
	else:
		for p in problems:
			print("  LOI: ", p)

	print("")
	print("=== ActivityDB ===")
	print("Nap duoc: %s" % [ActivityDB.all_ids()])

	print("")
	print("=== Xem truoc hau qua khi bam E (GDD 3.13.1) ===")
	print(JSON.stringify(Gameplay.preview("part_time")))

	print("")
	print("=== Phat an thieu bua (GDD 3.13.4) ===")
	for meals in [3, 2, 1, 0]:
		PlayerStats.meals_today = meals
		print("  %d bua -> %s" % [meals, PlayerStats.meal_penalty()])

	get_tree().quit()


func _case(course: Course, label: String, study: int, minigame: float, attend: float,
		academic: float, health: float, mood: float, lo: float, hi: float) -> void:
	ExamSystem.study_minutes_by_course[course.id] = study
	ExamSystem.attendance_by_course[course.id] = attend
	PlayerStats.set_stat("intelligence", 0.0)
	PlayerStats.set_stat("academic", academic)
	PlayerStats.set_stat("health", health)
	PlayerStats.set_stat("mood", mood)
	var score := ExamSystem.compute_score(course, minigame)
	var prep := ExamSystem.prep_ratio(course)
	var verdict := "OK" if (score >= lo and score <= hi) else "LECH"
	print("%-29s prep=%3d%%  diem=%.1f  [%s]  mong doi %.1f..%.1f"
		% [label, int(prep * 100.0), score, verdict, lo, hi])
