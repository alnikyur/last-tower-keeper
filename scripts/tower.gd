extends Node2D

@export var fire_rate: float = 6.0
@export var bullet_speed: float = 520.0
@export var damage: int = 1

var projectile_scene: PackedScene
var projectiles_root: Node2D

@onready var turret: Node2D = $Turret
@onready var muzzle: Marker2D = $Turret/Muzzle
@onready var fire_timer: Timer = $FireTimer
@onready var tower_fire: AudioStreamPlayer = $Turret/TowerFire

var _was_pressed := false

func _ready() -> void:
	fire_timer.wait_time = 1.0 / maxf(fire_rate, 0.1)
	fire_timer.timeout.connect(_fire)

func _process(_dt: float) -> void:
	# вращаем только турель
	var dir = get_global_mouse_position() - turret.global_position
	turret.rotation = dir.angle()

	var pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if pressed and not _was_pressed:
		_fire()

	if pressed:
		if fire_timer.is_stopped():
			fire_timer.start()
	else:
		if not fire_timer.is_stopped():
			fire_timer.stop()

	_was_pressed = pressed

func _fire() -> void:
	if projectile_scene == null or projectiles_root == null:
		return

	tower_fire.play()
	var p: Area2D = projectile_scene.instantiate()
	p.global_position = muzzle.global_position
	p.rotation = turret.global_rotation
	p.velocity = Vector2.RIGHT.rotated(turret.global_rotation) * bullet_speed
	projectiles_root.add_child(p)
