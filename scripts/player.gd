extends CharacterBody2D
## Nguoi choi. Di 4 huong, bam E de tuong tac voi vat gan nhat.

const SPEED := 78.0
const REACH := 34.0

var nearest: Interactable = null
var locked := false


func _ready() -> void:
	add_to_group("player")


func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	if not locked:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()
	_update_nearest()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if locked:
		return
	if event.is_action_pressed("interact") and nearest != null:
		nearest.interact()
		get_viewport().set_input_as_handled()


func _update_nearest() -> void:
	var best: Interactable = null
	var best_distance := REACH * REACH
	for node in get_tree().get_nodes_in_group("interactable"):
		var other := node as Interactable
		if other == null:
			continue
		var distance := global_position.distance_squared_to(other.global_position)
		if distance < best_distance:
			best_distance = distance
			best = other
	if best != nearest:
		nearest = best
		EventBus.prompt_changed.emit(nearest.prompt() if nearest != null else "")


func _draw() -> void:
	draw_circle(Vector2(0, 7), 4.0, Color(0, 0, 0, 0.22))
	draw_rect(Rect2(-4, 3, 3, 5), Color("303a50"))
	draw_rect(Rect2(1, 3, 3, 5), Color("303a50"))
	draw_rect(Rect2(-5, -5, 10, 9), Color("4876c6"))
	draw_rect(Rect2(-4, -14, 8, 9), Color("e8be98"))
	draw_rect(Rect2(-4, -14, 8, 3), Color("3a2820"))
