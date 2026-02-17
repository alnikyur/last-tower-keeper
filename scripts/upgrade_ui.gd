extends CanvasLayer

signal upgrade_selected(type: String)

@onready var card_hp: Button = $Cards/CardHP
@onready var card_rate: Button = $Cards/CardRate
@onready var card_dmg: Button = $Cards/CardDamage

var tower: Node = null

func _ready() -> void:
	hide()

	card_hp.pressed.connect(func(): _select("hp"))
	card_rate.pressed.connect(func(): _select("firerate"))
	card_dmg.pressed.connect(func(): _select("damage"))

func set_tower(t: Node) -> void:
	tower = t

func _update_texts() -> void:
	var stats = tower.get_upgrade_stats()

	_set_card_text(card_hp, "Health", stats.hp, "+20%")
	_set_card_text(card_rate, "Fire Rate", stats.firerate, "+25%")
	_set_card_text(card_dmg, "Damage", stats.damage, "+50%")

func _set_card_text(btn: Button, name: String, value, bonus: String) -> void:
	var lbl: Label = btn.get_node("BoxContainer/Label") as Label
	lbl.text = "%s\n%s\n(%s)" % [name, str(value), bonus]

func show_cards() -> void:
	if tower != null:
		_update_texts()
	get_tree().paused = true
	show()

func _select(type: String) -> void:
	hide()
	get_tree().paused = false
	upgrade_selected.emit(type)
