extends CharacterBody2D

signal died

@export var data: SlimeData
@export var speed: float = 30.0
@export var max_hp: int = 2
@export var touch_damage: int = 1
@export var touch_radius: float = 18.0
@onready var enemy_impact: AudioStreamPlayer = $EnemyImpact
@onready var slime: AnimatedSprite2D = $Slime
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var knockback_distance: float = 28.0
@export var knockback_time: float = 0.08
@export var turn_speed: float = 10.0
@export var wander_strength: float = 0.22
@export var wander_freq: float = 1.6

var _wander_phase: float = 0.0

var knockback_dir: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0


var hp: int
var target_path: NodePath
var _did_touch := false
var is_dead := false

func _ready() -> void:
	if data != null:
		max_hp = data.max_hp
		touch_damage = data.touch_damage
		speed = data.speed
		slime.modulate = data.tint

	hp = max_hp
	slime.play("walk")

func _physics_process(dt: float) -> void:
	if is_dead:
		return

	var target := get_node_or_null(target_path) as Node2D
	if target == null:
		return

	var dir := (target.global_position - global_position)
	var dist := dir.length()

	if dist <= touch_radius and not _did_touch:
		_did_touch = true
		if target.has_method("apply_damage"):
			target.call("apply_damage", touch_damage)
		queue_free()
		return

	# ===== НОВОЕ ДВИЖЕНИЕ (steering + wobble) =====
	var desired_dir := dir.normalized()

	_wander_phase += dt * wander_freq
	var side := Vector2(-desired_dir.y, desired_dir.x)
	var wobble := sin(_wander_phase + float(get_instance_id()) * 0.01)
	desired_dir = (desired_dir + side * wobble * wander_strength).normalized()

	var desired_velocity := desired_dir * speed
	velocity = velocity.lerp(desired_velocity, clampf(turn_speed * dt, 0.0, 1.0))
	# ==============================================

	# knockback
	if knockback_timer > 0.0:
		var kb_speed := knockback_distance / maxf(knockback_time, 0.001)
		velocity += knockback_dir * kb_speed
		knockback_timer -= dt
		if knockback_timer <= 0.0:
			knockback_timer = 0.0
			knockback_dir = Vector2.ZERO

	move_and_slide()


func take_damage(amount: int, hit_dir: Vector2 = Vector2.ZERO) -> bool:
	if is_dead:
		return false

	hp -= amount

	if hit_dir.length() > 0.001:
		knockback_dir = hit_dir.normalized()
		knockback_timer = knockback_time

	if hp <= 0:
		is_dead = true
		velocity = Vector2.ZERO

		# ВАЖНО: отключаем физику, а не прячем
		if is_instance_valid(collision_shape_2d):
			collision_shape_2d.set_deferred("disabled", true)

		_play_death_sound_global()
		slime.play("die")
		await slime.animation_finished
		died.emit()
		queue_free()

	return true



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
