extends Node2D

signal died
signal hp_changed(current: int, max: int)

@export var max_hp: int = 20
var hp: int
var is_dead := false

# твои поля стрельбы оставляем как есть:
@export var fire_rate: float = 1.5
@export var bullet_speed: float = 520.0
@export var damage: int = 1
@export var aim_offset_deg: float = 0.0

var projectile_scene: PackedScene
var projectiles_root: Node2D
var _next_shot_time: float = 0.0

@onready var turret: Node2D = $Turret
@onready var muzzle: Marker2D = $Turret/Muzzle
@onready var hitbox: Area2D = $Hitbox
@onready var tower_fire: AudioStreamPlayer = $Turret/TowerFire
@onready var gun_sprite: AnimatedSprite2D = $Turret/GunSprite

func _ready() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)

func _process(_dt: float) -> void:
	if is_dead:
		return

	var dir := get_global_mouse_position() - turret.global_position
	turret.rotation = dir.angle() + deg_to_rad(aim_offset_deg)

	# единая логика: и для клика, и для удержания
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var now := Time.get_ticks_msec() * 0.001
		var cooldown := 1.0 / maxf(fire_rate, 0.1)
		if now >= _next_shot_time:
			_fire()
			_next_shot_time = now + cooldown


func apply_damage(amount: int) -> void:
	if is_dead:
		return

	hp = max(hp - amount, 0)
	hp_changed.emit(hp, max_hp)

	if hp <= 0:
		is_dead = true
		died.emit()

func _fire() -> void:
	if is_dead:
		return
	if projectile_scene == null or projectiles_root == null:
		return
	
	tower_fire.play()
	gun_sprite.play("default")
	var p: Area2D = projectile_scene.instantiate()
	p.global_position = muzzle.global_position
	p.rotation = turret.global_rotation
	p.velocity = Vector2.UP.rotated(turret.global_rotation) * bullet_speed
	p.damage = damage
	projectiles_root.add_child(p)
