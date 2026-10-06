extends SceneTree
## Chay kiem tra ban do bang dong lenh:
##   godot --headless --path <thu muc project> --script res://tools/check_map.gd

const MapScript = preload("res://scripts/world/campus_map.gd")


func _init() -> void:
	print("=== KIEM TRA BAN DO CAMPUS ===")
	var problems: Array = MapScript.validate()
	if problems.is_empty():
		print("OK: khong co loi. Moi cua va vat the deu toi duoc tu SPAWN, khong chong lan cong trinh bat thuong.")
	else:
		print("CO LOI (%d):" % problems.size())
		for p in problems:
			print("  - ", p)

	print("")
	print("--- O dung de bam E cho tung cua ---")
	for id in MapScript.DOORS:
		var approach: Vector2i = MapScript.door_approach(id)
		print("  %-12s cua %s  ->  dung tai %s" % [id, MapScript.DOORS[id], approach])

	print("")
	print("--- Thong ke o ---")
	var grid: Array = MapScript.build()
	var counts := {}
	for y in MapScript.H:
		for x in MapScript.W:
			var t: int = grid[y][x]
			counts[t] = counts.get(t, 0) + 1
	var names := ["GRASS", "FIELD", "FLOOR", "WALL", "PATH", "DOOR", "WATER"]
	for t in counts:
		print("  %-6s %d o" % [names[t], counts[t]])

	# Negative test: xac nhan validator THAT SU bat duoc loi da bao.
	# (38,30) va (50,30) la 2 cua cu bi tuong bit — phai bao la KHONG toi duoc.
	print("")
	print("--- Negative test: 2 cua CU (da sua) phai bi bat loi ---")
	var reachable: Dictionary = MapScript._flood_fill(grid, MapScript.SPAWN)
	for cell in [Vector2i(38, 30), Vector2i(50, 30)]:
		var ok: bool = MapScript._has_reachable_neighbour(reachable, cell)
		print("  cua cu %s co loi vao khong? %s  (mong doi: false)" % [cell, ok])
	for cell in [Vector2i(38, 33), Vector2i(50, 32)]:
		var ok: bool = MapScript._has_reachable_neighbour(reachable, cell)
		print("  cua moi %s co loi vao khong? %s  (mong doi: true)" % [cell, ok])

	quit()
