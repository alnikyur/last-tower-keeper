extends Node2D

@export var enemy_scene: PackedScene
@export var projectile_scene: PackedScene

@export var arena_radius: float = 512.0
@export var enemies_per_wave_base: int = 10
@export var enemies_per_wave_growth: int = 3
@export var time_between_waves: float = 3.0
@export var spawn_interval: float = 0.9

var wave: int = 0
var to_spawn: int = 0
var alive: int = 0
var kills: int = 0

@onready var tower: Node2D = $Tower
@onready var enemies_root: Node2D = $Enemies
@onready var projectiles_root: Node2D = $Projectiles
@onready var wave_timer: Timer = $WaveTimer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawner: Node = $Spawner
@onready var kills_label: Label = $UI/KillsLabel
@onready var hp_label: Label = $UI/HpLabel

func _ready() -> void:
	# Проверь, что сцены назначены в инспекторе
	assert(enemy_scene != null)
	assert(projectile_scene != null)

	tower.set("projectile_scene", projectile_scene)
	tower.set("projectiles_root", projectiles_root)

	spawner.set("arena_radius", arena_radius)
	spawner.set("enemies_root_path", enemies_root.get_path())
	spawner.set("enemy_scene", enemy_scene)
	spawner.set("target_path", tower.get_path())

	tower.connect("hp_changed", _on_tower_hp_changed)
	tower.connect("died", _on_tower_died)

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	wave_timer.timeout.connect(_start_wave)
	_update_kills_ui()
	_start_wave()

func _on_tower_hp_changed(current: int, max_hp: int) -> void:
	if hp_label:
		hp_label.text = "HP: %d / %d" % [current, max_hp]

func _on_tower_died() -> void:
	# остановить спавн и всё остальное
	spawn_timer.stop()
	wave_timer.stop()

	# можно вывести текст
	if hp_label:
		hp_label.text = "HP: 0 (GAME OVER)"

func _start_wave() -> void:
	wave += 1
	to_spawn = enemies_per_wave_base + (wave - 1) * enemies_per_wave_growth
	alive = 0

	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if to_spawn <= 0:
		spawn_timer.stop()
		return

	var enemy = spawner.call("spawn_enemy")
	if enemy:
		alive += 1
		enemy.tree_exited.connect(_on_enemy_removed)
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)
	enemy  # just to silence “unused” in some editors

	to_spawn -= 1

func _on_enemy_died() -> void:
	kills += 1
	_update_kills_ui()

func _update_kills_ui() -> void:
	if kills_label:
		kills_label.text = "Kills: %d" % kills


func _on_enemy_removed() -> void:
	alive -= 1
	if to_spawn <= 0 and alive <= 0:
		wave_timer.start(time_between_waves)
