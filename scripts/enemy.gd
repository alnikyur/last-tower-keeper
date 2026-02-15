extends CharacterBody2D

@export var speed: float = 30.0
@export var max_hp: int = 2
@export var touch_damage: int = 1
@export var touch_radius: float = 18.0
@onready var enemy_impact: AudioStreamPlayer = $EnemyImpact
@onready var tower_fire: AudioStreamPlayer = $Turret/TowerFire

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
		_play_death_sound_global()
		queue_free()

func _play_death_sound_global() -> void:
	if enemy_impact == null or enemy_impact.stream == null:
		return

	var p := AudioStreamPlayer2D.new()
	p.stream = enemy_impact.stream
	p.global_position = global_position
	p.volume_db = 3
	p.pitch_scale = randf_range(0.95, 1.05)
	get_tree().current_scene.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
