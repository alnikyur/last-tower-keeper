extends Button

@export var duration: float = 0.6
@export var squash_y: float = 0.06   # лёгкое "дыхание" по Y (опционально)

var _tween: Tween
var _playing := false
var _base_scale: Vector2

func _ready() -> void:
	pivot_offset = size * 0.5
	_base_scale = scale

	mouse_entered.connect(_play_flip)

func _play_flip() -> void:
	if _playing:
		return
	_playing = true

	if _tween and _tween.is_valid():
		_tween.kill()

	scale = _base_scale
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.set_ease(Tween.EASE_IN_OUT)

	# 1 -> 0 (ребро)
	_tween.tween_property(self, "scale:x", 0.0, duration * 0.25)

	# 0 -> -1 (перевернули)
	_tween.tween_property(self, "scale:x", -_base_scale.x, duration * 0.25)

	# -1 -> 0
	_tween.tween_property(self, "scale:x", 0.0, duration * 0.25)

	# 0 -> 1 (вернулись)
	_tween.tween_property(self, "scale:x", _base_scale.x, duration * 0.25)

	# лёгкий "памп" по Y (чтобы было живее) — можно убрать
	if squash_y > 0.0:
		_tween.parallel().tween_property(self, "scale:y", _base_scale.y * (1.0 + squash_y), duration * 0.5)
		_tween.parallel().tween_property(self, "scale:y", _base_scale.y, duration * 0.5).set_delay(duration * 0.5)

	_tween.finished.connect(func():
		scale = _base_scale
		_playing = false
	)
