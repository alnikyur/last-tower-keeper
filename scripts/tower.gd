extends Node2D

signal damaged(amount: int)
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
@export var base_damage: float = 1.0
@export var damage_growth: float = 1.25
@export var shotgun_pellets: int = 7
@export var shotgun_spread_deg: float = 18.0
@export var shotgun_cooldown: float = 1.2
@export var shotgun_speed_mul: float = 0.95
@export var shotgun_damage_mul: float = 0.7

var _next_shotgun_time: float = 0.0

var projectile_scene: PackedScene
var projectiles_root: Node2D
var _next_shot_time: float = 0.0
var upgrade_level: int = 0
const MAX_LEVEL := 10

@onready var turret: Node2D = $Turret
@onready var muzzle: Marker2D = $Turret/Muzzle
@onready var hitbox: Area2D = $Hitbox
@onready var tower_fire: AudioStreamPlayer = $Turret/TowerFire
@onready var gun_sprite: AnimatedSprite2D = $Turret/GunSprite
@onready var shotgun_cd: TextureProgressBar = $ShotgunCooldown
@onready var fire_rate_buff_timer: Timer = $FireRateBuffTimer

var _fire_rate_buff_active := false
var _fire_rate_buff_mult: float = 1.0
var _base_fire_rate: float  # базовый fire_rate без активных баффов

func _ready() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)

	_base_fire_rate = fire_rate

	shotgun_cd.min_value = 0
	shotgun_cd.max_value = 100
	shotgun_cd.value = 100

	fire_rate_buff_timer.timeout.connect(_on_fire_rate_buff_timeout)

func _process(_dt: float) -> void:
	if is_dead:
		return

	var dir := get_global_mouse_position() - turret.global_position
	turret.rotation = dir.angle() + deg_to_rad(aim_offset_deg)

	var now := Time.get_ticks_msec() * 0.001

	# ЛКМ — обычный выстрел (как у тебя)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var cooldown := 1.0 / maxf(_effective_fire_rate(), 0.1)  # <-- было fire_rate
		if now >= _next_shot_time:
			_fire()
			_next_shot_time = now + cooldown

	# ПКМ — дробовик (по клику, не по удержанию)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if now >= _next_shotgun_time:
			_fire_shotgun()
			_next_shotgun_time = now + shotgun_cooldown

	_update_shotgun_cd()

func apply_fire_rate_buff(mult: float, duration: float) -> void:
	if mult <= 0.0:
		return
	_fire_rate_buff_active = true
	_fire_rate_buff_mult = mult
	# fire_rate НЕ меняем — используем через _effective_fire_rate()

	fire_rate_buff_timer.stop()
	fire_rate_buff_timer.wait_time = duration
	fire_rate_buff_timer.start()

func _on_fire_rate_buff_timeout() -> void:
	_fire_rate_buff_mult = 1.0
	_fire_rate_buff_active = false

func _update_shotgun_cd() -> void:
	var now: float = Time.get_ticks_msec() * 0.001
	var remain: float = maxf(0.0, _next_shotgun_time - now)

	# 1 = готово, 0 = только что выстрелил
	var ratio: float = 1.0 - (remain / maxf(shotgun_cooldown, 0.001))

	shotgun_cd.value = clampf(ratio * 100.0, 0.0, 100.0)

func _effective_fire_rate() -> float:
	return fire_rate * (_fire_rate_buff_mult if _fire_rate_buff_active else 1.0)

func _fire_shotgun() -> void:
	if is_dead:
		return
	if projectile_scene == null or projectiles_root == null:
		return

	tower_fire.play()
	gun_sprite.play("default")

	var base_rot: float = turret.global_rotation
	var spread: float = deg_to_rad(shotgun_spread_deg)
	var pellets: int = maxi(1, shotgun_pellets)

	for i: int in range(pellets):
		var t: float = 0.0 if pellets == 1 else float(i) / float(pellets - 1)  # 0..1
		var offset: float = lerpf(-spread * 0.5, spread * 0.5, t)

		var p: Area2D = projectile_scene.instantiate() as Area2D
		p.global_position = muzzle.global_position
		p.rotation = base_rot + offset

		var vdir: Vector2 = Vector2.UP.rotated(base_rot + offset)
		p.velocity = vdir * (bullet_speed * shotgun_speed_mul)

		p.damage = maxi(1, int(round(float(damage) * shotgun_damage_mul)))

		projectiles_root.add_child(p)



#func _process(_dt: float) -> void:
	#if is_dead:
		#return
#
	#var dir := get_global_mouse_position() - turret.global_position
	#turret.rotation = dir.angle() + deg_to_rad(aim_offset_deg)
#
	## единая логика: и для клика, и для удержания
	#if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#var now := Time.get_ticks_msec() * 0.001
		#var cooldown := 1.0 / maxf(fire_rate, 0.1)
		#if now >= _next_shot_time:
			#_fire()
			#_next_shot_time = now + cooldown

func apply_upgrade(type: String) -> void:
	if upgrade_level >= MAX_LEVEL:
		return

	match type:
		"hp":
			max_hp = int(max_hp * 1.2)
			hp = max_hp
			hp_changed.emit(hp, max_hp)

		"firerate":
			fire_rate *= 1.25
			_base_fire_rate = fire_rate

		"damage":
			upgrade_level += 1
			_recalc_damage()
			return

	upgrade_level += 1


func apply_damage(amount: int) -> void:
	if is_dead:
		return

	hp = max(hp - amount, 0)
	hp_changed.emit(hp, max_hp)

	damaged.emit(amount) # ✅ вот это добавь

	if hp <= 0:
		is_dead = true
		died.emit()


func get_upgrade_stats() -> Dictionary:
	return {
		"hp": max_hp,
		"firerate": fire_rate,
		"damage": damage,
		"level": upgrade_level
	}

func _recalc_damage() -> void:
	var raw := base_damage * pow(damage_growth, upgrade_level)
	damage = max(1, int(round(raw)))

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
