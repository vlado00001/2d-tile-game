extends Node2D
@onready var hud: CanvasLayer = $HUD

var level: int = 1
var current_level_root: Node = null
const MAX_LEVEL = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# removes the base node from the scene
	current_level_root = get_node_or_null("LevelRoot")
	if current_level_root:
		remove_child(current_level_root)
		current_level_root.queue_free()
	# loads the first level
	current_level_root = null
	_load_level(level)
	await hud.fade(0.0)

#########################################
#	Level Management					#
#########################################

func _load_level(level_number: int) -> void:
	if current_level_root:
		remove_child(current_level_root)
		current_level_root.queue_free()
		current_level_root = null

	# changes level
	var level_path = "res://scenes/levels/level_%s.tscn" % level_number
	var level_scene = load(level_path)
	if level_scene == null:
		push_error("Level scene not found: %s" % level_path)
		return
	
	current_level_root = level_scene.instantiate()
	current_level_root.name = "LevelRoot"
	add_child(current_level_root)
	_setup_level(current_level_root)

func _setup_level(level_root: Node) -> void:
	# connects the player
	var player = level_root.get_node("Player")
	player.died.connect(_on_player_died)
	$HUD.set_player(player)
	# connects the exit
	var exit = level_root.get_node_or_null("Exit")
	if exit:
		exit.body_entered.connect(_on_exit_body_entered)

#########################################
#	Signal Handlers						#
#########################################
func _on_exit_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return

	level += 1
	if level > MAX_LEVEL:
		_on_game_complete()
		return
	call_deferred("_load_level", level)

func _on_player_died() -> void:
	await get_tree().create_timer(1.5).timeout
	await hud.fade(1.0)
	level = 1
	PlayerStats.reset()
	_load_level(level)
	await hud.fade(0.0)

func _on_game_complete() -> void:
	pass
