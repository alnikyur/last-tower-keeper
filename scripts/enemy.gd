extends CharacterBody2D

@export var speed: float = 80.0
@export var max_hp: int = 3
@export var touch_damage: int = 1
@export var touch_radius: float = 18.0

var hp: int
var target_path: NodePath

func _ready() -> void:
	hp = max_hp

func _physics_process(_dt: float) -> void:
	var target := get_node_or_null(target_path) as Node2D
	if target == null:
		return

	var dir := (target.global_position - global_position)
	var dist := dir.length()

	if dist <= touch_radius:
		# Пока просто: при касании - умираем, позже сделаешь урон башне/хп
		queue_free()
		return

	velocity = dir.normalized() * speed
	move_and_slide()

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		queue_free()
