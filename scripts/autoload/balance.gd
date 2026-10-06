extends Node
## Nap data/balance.tres. Neu thieu file thi dung gia tri mac dinh trong BalanceConfig.

const DATA_PATH := "res://data/balance.tres"

var data: BalanceConfig


func _ready() -> void:
	if ResourceLoader.exists(DATA_PATH):
		var loaded := load(DATA_PATH)
		if loaded is BalanceConfig:
			data = loaded
	if data == null:
		push_warning("Khong nap duoc %s — dung gia tri mac dinh." % DATA_PATH)
		data = BalanceConfig.new()
