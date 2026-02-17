extends Node

@export var enemy_scene: PackedScene
@export var arena_radius: float = 256.0
@export var spawn_padding: float = 0.0

@export var slime_green: SlimeData
@export var slime_red: SlimeData
@export var slime_blue: SlimeData

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

	var e := enemy_scene.instantiate()
	e.global_position = spawn_pos

	# ВАЖНО: у врага target_path — это NodePath до башни (как у тебя в enemy.gd)
	e.target_path = target.get_path()

	# Выбор типа (можешь поменять шансы)
	var roll := randf()
	var data: SlimeData = slime_green
	if roll < 0.15 and slime_red != null:
		data = slime_red
	elif roll < 0.50 and slime_blue != null:
		data = slime_blue
	elif slime_green != null:
		data = slime_green

	# ВАЖНО: назначить ДО add_child, чтобы enemy._ready() увидел data
	e.data = data

	enemies_root.add_child(e)
	return e
