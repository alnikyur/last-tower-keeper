extends Area2D

@export var lifetime: float = 2.0

var velocity: Vector2 = Vector2.ZERO
var damage: int = 1

@onready var projectile: AnimatedSprite2D = $Projectile
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	projectile.play("default")

	screen_notifier.screen_exited.connect(queue_free)

	if has_node("LifeTimer"):
		$LifeTimer.timeout.connect(queue_free)
		$LifeTimer.start(lifetime)

func _physics_process(dt: float) -> void:
	global_position += velocity * dt

func _hit(node: Node) -> void:
	if node and node.has_method("take_damage"):
		var hit_dir: Vector2 = velocity
		if hit_dir.length() > 0.001:
			hit_dir = hit_dir.normalized()
		else:
			hit_dir = Vector2.ZERO

		# ВАЖНО: enemy.gd должен принимать второй аргумент hit_dir
		node.call("take_damage", damage, hit_dir)

	queue_free()

func _on_area_entered(a: Area2D) -> void:
	_hit(a)

func _on_body_entered(b: Node) -> void:
	_hit(b)
