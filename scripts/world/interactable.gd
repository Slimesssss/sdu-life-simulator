class_name Interactable
extends StaticBody2D
## Vat the tuong tac. Dung gan va bam E.

@export var activity_id := ""
@export var label := ""
@export var color := Color("d8b45a")

signal interacted


func _ready() -> void:
	add_to_group("interactable")


func prompt() -> String:
	var shown := label if not label.is_empty() else activity_id
	return "[E] %s" % shown


func preview() -> Dictionary:
	return Gameplay.preview(activity_id)


func interact() -> void:
	if Gameplay.perform_activity(activity_id):
		interacted.emit()


func _draw() -> void:
	draw_rect(Rect2(-6, -6, 12, 12), color)
	draw_rect(Rect2(-7, -7, 14, 14), color.darkened(0.45), false, 1.0)
