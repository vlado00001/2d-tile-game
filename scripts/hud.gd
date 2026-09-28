extends CanvasLayer

var player
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var hearts_container: Node = $Hearts
const HEART_SIZE: int = 10
const HEART_FULL = preload("res://assets/images/player/FullHeart.png")
const HEART_HALF = preload("res://assets/images/player/HalfHeart.png")
const HEART_EMPTY = preload("res://assets/images/player/EmptyHeart.png")

func set_player(p) -> void:
	player = p
	if player:
		player.health_changed.connect(_update_health)
		_update_health(player.health)

func _update_health(new_health: int) -> void:
	var hearts = hearts_container.get_children()
	var max_hearts = len(hearts)
	var full_hearts = int(new_health / HEART_SIZE)
	var half_hearts = 1 if (new_health % HEART_SIZE) > 0 else 0
	var empty_hearts = max_hearts - (full_hearts + half_hearts)
	# updates full hearts
	for i in full_hearts:
		hearts[i].texture = HEART_FULL
	if half_hearts:
		hearts[full_hearts].texture = HEART_HALF
	for i in empty_hearts:
		hearts[len(hearts) - i - 1].texture = HEART_EMPTY

func fade(to_alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", to_alpha, 1.5)
	await tween.finished
