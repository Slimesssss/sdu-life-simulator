class_name CampusMap
extends RefCounted
## Ban do KHUON VIEN truong SDU (chi phan NGOAI TROI).
##
## QUY UOC QUAN TRONG — doc truoc khi sua:
##   1. Ngoai troi CHI ve mat tien cong trinh. Cong trinh la khoi dac.
##   2. Moi noi that (phong hoc, KTX, thu vien, cang tin, xuong...) la MOT SCENE RIENG.
##   3. Cua chi la diem danh dau tren tuong: dung truoc cua, bam E de vao scene.
##
## Nho quy uoc nay, noi that KHONG bi gioi han boi kich thuoc cong trinh ngoai troi.
## Phong KTX 4 nguoi can hanh lang + 4 cua phong thi cu ve no lon bao nhieu cung duoc.

const TILE := 16
const W := 64
const H := 36
const SPAWN := Vector2i(22, 6)

## FLOOR khong dung o ngoai troi, de danh cho scene noi that.
enum Tile { GRASS, FIELD, FLOOR, WALL, PATH, DOOR, WATER }

const NEIGHBOURS := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]

const BUILDINGS := [
	{"x": 1,  "y": 1,  "w": 8,  "h": 12},   # Nha B
	{"x": 17, "y": 1,  "w": 4,  "h": 4},    # Phong bao ve
	{"x": 32, "y": 3,  "w": 26, "h": 7},    # Nha de xe
	{"x": 2,  "y": 14, "w": 9,  "h": 5},    # Khu phong cac khoa
	{"x": 14, "y": 11, "w": 5,  "h": 11},   # Nha A canh trai
	{"x": 18, "y": 15, "w": 14, "h": 4},    # Nha A thanh giua (thu vien tang 1)
	{"x": 30, "y": 11, "w": 5,  "h": 11},   # Nha A canh phai
	{"x": 16, "y": 26, "w": 16, "h": 5},    # Hoi truong
	{"x": 16, "y": 32, "w": 16, "h": 4},    # Phong the thao
	{"x": 2,  "y": 22, "w": 7,  "h": 3},    # Xuong 1..4
	{"x": 2,  "y": 26, "w": 7,  "h": 3},
	{"x": 2,  "y": 29, "w": 7,  "h": 3},
	{"x": 2,  "y": 32, "w": 7,  "h": 3},
	{"x": 37, "y": 26, "w": 9,  "h": 4},    # Ki tuc xa A
	{"x": 48, "y": 27, "w": 9,  "h": 3},    # Ki tuc xa B
	{"x": 49, "y": 30, "w": 10, "h": 3},    # Ki tuc xa C
	{"x": 37, "y": 30, "w": 10, "h": 4},    # Can tin + phong CTSV
]

const FIELDS := [{"x": 38, "y": 11, "w": 17, "h": 15}]   # san bong
const BLOCKS := [{"x": 23, "y": 22, "w": 2, "h": 2}]      # dai phun nuoc

const ROADS := [
	{"x": 22, "y": 1,  "w": 2,  "h": 14},   # truc doc tu cong chinh
	{"x": 1,  "y": 19, "w": 13, "h": 2},    # truc ngang trai
	{"x": 11, "y": 19, "w": 2,  "h": 16},   # truc doc trai
	{"x": 20, "y": 21, "w": 2,  "h": 5},    # truc doc giua (xuong hoi truong)
	{"x": 35, "y": 19, "w": 2,  "h": 16},   # truc doc phai
	{"x": 35, "y": 34, "w": 24, "h": 1},    # truc ngang duoi
	{"x": 55, "y": 18, "w": 8,  "h": 2},    # truc ngang phai (cong phu 2)
	{"x": 56, "y": 20, "w": 2,  "h": 7},    # truc doc KTX B
]

## Cua vao cong trinh: id -> o nam TREN TUONG (cong trinh la khoi dac).
## O de bam E la o NGOAI ke ben — dung door_approach() tim, dung tu doan.
const DOORS := {
	"nha_b":      Vector2i(4, 12),
	"bao_ve":     Vector2i(18, 4),
	"nha_de_xe":  Vector2i(40, 9),
	"phong_khoa": Vector2i(10, 16),
	"nha_a":      Vector2i(22, 15),
	"xuong_1":    Vector2i(8, 23),
	"xuong_2":    Vector2i(8, 27),
	"xuong_3":    Vector2i(8, 30),
	"xuong_4":    Vector2i(8, 33),
	"hoi_truong": Vector2i(20, 26),
	"the_thao":   Vector2i(23, 32),
	"ktx_a":      Vector2i(38, 26),
	"ktx_b":      Vector2i(48, 28),
	"ktx_c":      Vector2i(50, 32),
	"cang_tin":   Vector2i(38, 33),
}

const GATES := [
	Vector2i(22, 0), Vector2i(23, 0),
	Vector2i(0, 19), Vector2i(0, 20),
	Vector2i(63, 18), Vector2i(63, 19),
]

## Vat the tuong tac NGOAI TROI. Do trong nha nam trong scene noi that.
const INTERACTABLES := {
	"football_field": Vector2i(45, 18),
	"fountain":       Vector2i(22, 23),   # o KE BEN dai phun nuoc (nuoc la o dac)
}


static func build() -> Array:
	var grid := []
	for y in H:
		var row := []
		for x in W:
			row.append(Tile.GRASS)
		grid.append(row)

	for f in FIELDS:
		_fill(grid, f, Tile.FIELD)
	for b in BUILDINGS:
		_fill(grid, b, Tile.WALL)
	for r in ROADS:
		_fill_if_grass(grid, r)
	for b in BLOCKS:
		_fill(grid, b, Tile.WATER)

	for x in W:
		grid[0][x] = Tile.WALL
		grid[H - 1][x] = Tile.WALL
	for y in H:
		grid[y][0] = Tile.WALL
		grid[y][W - 1] = Tile.WALL

	for d in DOORS.values():
		grid[d.y][d.x] = Tile.DOOR
	for g in GATES:
		grid[g.y][g.x] = Tile.PATH
	return grid


static func validate() -> Array[String]:
	var grid := build()
	var problems: Array[String] = []
	if is_solid(grid[SPAWN.y][SPAWN.x]):
		problems.append("SPAWN nam tren o dac: %s" % SPAWN)
		return problems
	var reachable := _flood_fill(grid, SPAWN)
	for id in DOORS:
		if not _has_reachable_neighbour(reachable, DOORS[id]):
			problems.append("Cua '%s' o %s khong co loi vao nao toi duoc." % [id, DOORS[id]])
	for id in INTERACTABLES:
		var cell: Vector2i = INTERACTABLES[id]
		if is_solid(grid[cell.y][cell.x]):
			problems.append("Vat the '%s' nam tren o dac: %s" % [id, cell])
		elif not reachable.has(cell):
			problems.append("Vat the '%s' khong toi duoc: %s" % [id, cell])
	
	# Kiem tra chong lan giua cac khoi cong trinh khong chu y
	for i in range(BUILDINGS.size()):
		var b1: Dictionary = BUILDINGS[i]
		for j in range(i + 1, BUILDINGS.size()):
			var b2: Dictionary = BUILDINGS[j]
			var x_overlap: bool = (b1.x < b2.x + b2.w) and (b1.x + b1.w > b2.x)
			var y_overlap: bool = (b1.y < b2.y + b2.h) and (b1.y + b1.h > b2.y)
			if x_overlap and y_overlap:
				# Chi bo qua chong lan thiet ke chu y giua cac khoi Nha A (chi so 4, 5, 6)
				var is_nha_a: bool = (i in [4, 5, 6]) and (j in [4, 5, 6])
				if not is_nha_a:
					problems.append("Chong lan cong trinh giua index %d va %d" % [i, j])
	return problems


static func door_approach(door_id: String) -> Vector2i:
	if not DOORS.has(door_id):
		return Vector2i.ZERO
	var cell: Vector2i = DOORS[door_id]
	var grid := build()
	for dir in NEIGHBOURS:
		var n: Vector2i = cell + dir
		if n.x < 0 or n.y < 0 or n.x >= W or n.y >= H:
			continue
		if not is_solid(grid[n.y][n.x]):
			return n
	return Vector2i.ZERO


static func _flood_fill(grid: Array, from: Vector2i) -> Dictionary:
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for dir in NEIGHBOURS:
			var n: Vector2i = c + dir
			if n.x < 0 or n.y < 0 or n.x >= W or n.y >= H:
				continue
			if seen.has(n) or is_solid(grid[n.y][n.x]):
				continue
			seen[n] = true
			queue.append(n)
	return seen


static func _has_reachable_neighbour(reachable: Dictionary, cell: Vector2i) -> bool:
	for dir in NEIGHBOURS:
		if reachable.has(cell + dir):
			return true
	return false


static func _fill(grid: Array, r: Dictionary, tile: int) -> void:
	for y in range(r["y"], r["y"] + r["h"]):
		for x in range(r["x"], r["x"] + r["w"]):
			grid[y][x] = tile


static func _fill_if_grass(grid: Array, r: Dictionary) -> void:
	for y in range(r["y"], r["y"] + r["h"]):
		for x in range(r["x"], r["x"] + r["w"]):
			if grid[y][x] == Tile.GRASS:
				grid[y][x] = Tile.PATH


static func is_solid(tile: int) -> bool:
	return tile == Tile.WALL or tile == Tile.WATER


static func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * float(TILE) + Vector2.ONE * (float(TILE) * 0.5)
