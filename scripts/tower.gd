extends Node2D

@export var fire_rate: float = 6.0 # выстр/сек
@export var bullet_speed: float = 520.0
@export var damage: int = 1

var projectile_scene: PackedScene
var projectiles_root_path: NodePath

@onready var muzzle: Marker2D = $Muzzle
@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
	fire_timer.wait_time = 1.0 / maxf(fire_rate, 0.1)
	fire_timer.timeout.connect(_fire)

func _process(_dt: float) -> void:
	look_at(get_global_mouse_position())

	# зажми ЛКМ чтобы стрелять постоянно
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if fire_timer.is_stopped():
			fire_timer.start()
	else:
		if not fire_timer.is_stopped():
			fire_timer.stop()

func _fire() -> void:
	if projectile_scene == null:
		return

	var root := get_node_or_null(projectiles_root_path)
	if root == null:
		return

	var p: Area2D = projectile_scene.instantiate()
	p.global_position = muzzle.global_position
	p.rotation = global_rotation
	p.set("velocity", Vector2.RIGHT.rotated(global_rotation) * bullet_speed)
	p.set("damage", damage)
	root.add_child(p)
