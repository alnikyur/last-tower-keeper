extends Node2D

@export var thickness: float = 2.0
@export var alpha: float = 0.35
@export var min_len: float = 6.0

var muzzle: Node2D = null

func set_muzzle(node: Node2D) -> void:
	muzzle = node

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	if muzzle == null:
		return

	var start := to_local(muzzle.global_position)
	var end := to_local(get_global_mouse_position())

	var dist := start.distance_to(end)
	if dist < min_len:
		return

	draw_line(start, end, Color(1.0, 0.2, 0.5, alpha), thickness)
