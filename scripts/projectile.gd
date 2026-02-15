extends Area2D

@export var lifetime: float = 2.0
var velocity: Vector2 = Vector2.ZERO
var damage: int = 1

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	if has_node("LifeTimer"):
		$LifeTimer.timeout.connect(queue_free)
		$LifeTimer.start(lifetime)

func _physics_process(dt: float) -> void:
	global_position += velocity * dt

func _hit(node: Node) -> void:
	if node and node.has_method("take_damage"):
		node.call("take_damage", damage)
	queue_free()

func _on_area_entered(a: Area2D) -> void:
	_hit(a)

func _on_body_entered(b: Node) -> void:
	_hit(b)
