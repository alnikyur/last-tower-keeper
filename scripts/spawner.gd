extends Node

@export var enemy_scene: PackedScene
@export var arena_radius: float = 256.0
@export var spawn_padding: float = 0

var enemies_root_path: NodePath
var target_path: NodePath

func spawn_enemy() -> Node2D:
	if enemy_scene == null:
		return null

	var enemies_root := get_node_or_null(enemies_root_path) as Node2D
	var target := get_node_or_null(target_path) as Node2D
	if enemies_root == null or target == null:
		return null

	# 1) случайный угол
	var angle := randf() * TAU
	# 2) точка на окружности вокруг башни
	var r := arena_radius + spawn_padding
	var spawn_pos := target.global_position + Vector2(cos(angle), sin(angle)) * r

	var e: Node2D = enemy_scene.instantiate()
	e.global_position = spawn_pos
	e.set("target_path", target.get_path())
	enemies_root.add_child(e)
	return e
