extends Node2D

@export var enemy_scene: PackedScene
@export var projectile_scene: PackedScene

@export var arena_radius: float = 512.0
@export var base_enemies_wave1: int = 10
@export var time_between_waves: float = 3.0
@export var spawn_interval: float = 0.9

var wave: int = 0
var to_spawn: int = 0
var alive: int = 0

# Fibonacci multiplier: 1,2,3,5,8...
var fib_prev: int = 1
var fib_curr: int = 2

@onready var tower: Node2D = $Tower
@onready var enemies_root: Node2D = $Enemies
@onready var projectiles_root: Node2D = $Projectiles
@onready var wave_timer: Timer = $WaveTimer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawner: Node = $Spawner

@onready var wave_label: Label = $UI/WaveLabel
@onready var remaining_label: Label = $UI/RemainingLabel
@onready var hp_label: Label = $UI/HpLabel
@onready var line_aim: Node2D = $LineAim
@onready var upgrade_ui: CanvasLayer = $UpgradeUI

var _waiting_next_wave := false

func _ready() -> void:
	randomize()

	assert(enemy_scene != null)
	assert(projectile_scene != null)

	# Страховка от настроек сцены
	wave_timer.one_shot = true
	wave_timer.autostart = false
	wave_timer.stop()

	spawn_timer.one_shot = false
	spawn_timer.autostart = false
	spawn_timer.stop()

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

	line_aim.call("set_muzzle", tower.get_node("Turret/Muzzle"))

	upgrade_ui.connect("upgrade_selected", _on_upgrade_selected)

	upgrade_ui.call("set_tower", tower)

	upgrade_ui.show_cards()

func _process(_dt: float) -> void:
	# Следующая волна только когда:
	# 1) больше не нужно спавнить
	# 2) живых врагов реально 0
	if not _waiting_next_wave and to_spawn <= 0 and alive <= 0:
		_waiting_next_wave = true
		upgrade_ui.show_cards()

func _start_wave() -> void:
	_waiting_next_wave = false
	wave += 1

	var mult := _next_fib_mult()
	var total := base_enemies_wave1 * mult

	to_spawn = total
	alive = 0

	_update_wave_ui()
	_update_remaining_ui()

	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()

func _on_upgrade_selected(type: String) -> void:
	tower.apply_upgrade(type)

	if tower.upgrade_level >= tower.MAX_LEVEL:
		_show_victory()
		return

	_start_wave()


func _show_victory() -> void:
	spawn_timer.stop()
	wave_timer.stop()
	set_process(false)

	if hp_label:
		hp_label.text = "VICTORY"


func _on_spawn_timer_timeout() -> void:
	if to_spawn <= 0:
		spawn_timer.stop()
		return

	var enemy = spawner.call("spawn_enemy")
	if enemy == null:
		# Если спавн иногда фейлится — не “съедаем” счётчик
		return

	alive += 1
	# tree_exited сработает при queue_free (после анимации смерти тоже)
	enemy.tree_exited.connect(_on_enemy_tree_exited)

	to_spawn -= 1
	_update_remaining_ui()

	if to_spawn <= 0:
		spawn_timer.stop()

func _on_enemy_tree_exited() -> void:
	alive = max(alive - 1, 0)
	_update_remaining_ui()

func _remaining() -> int:
	return max(to_spawn + alive, 0)

func _update_remaining_ui() -> void:
	if remaining_label:
		remaining_label.text = "Remaining: %d" % _remaining()

func _update_wave_ui() -> void:
	if wave_label:
		wave_label.text = "Wave: %d" % wave

func _next_fib_mult() -> int:
	# 1,2,3,5,8...
	if wave == 1:
		return 1
	var ret := fib_curr
	var next := fib_prev + fib_curr
	fib_prev = fib_curr
	fib_curr = next
	return ret

func _on_tower_hp_changed(current: int, max_hp: int) -> void:
	if hp_label:
		hp_label.text = "HP: %d / %d" % [current, max_hp]

func _on_tower_died() -> void:
	spawn_timer.stop()
	wave_timer.stop()
	set_process(false)
	if hp_label:
		hp_label.text = "HP: 0 (GAME OVER)"
