extends Resource
class_name SlimeData

@export var max_hp: int = 2
@export var touch_damage: int = 1
@export var speed: float = 30.0
@export var tint: Color = Color.WHITE

@export var frames: SpriteFrames # ✅ разные визуалы (walk/die)
@export var walk_anim: StringName = &"walk"
@export var die_anim: StringName = &"die"
