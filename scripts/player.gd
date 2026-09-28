extends CharacterBody2D

signal died
signal health_changed(new_health: int)
const SPEED = 300.0
@onready var swing_sword: AudioStreamPlayer2D = $SwingSword
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var take_damage_sfx: AudioStreamPlayer2D = $TakeDamage
@onready var damage_cooldown: Timer = $DamageCooldown
# starting facing direction, which gets updated while moving
var last_facing_direction: Vector2 = Vector2.DOWN
# whether the player is attacking
var is_attacking: bool = false
# hitbox offset
var hitbox_offset: Vector2
# default player damage
var strength: int = 20
# health variables
var is_alive: bool = true
var max_health: int
var health: int

func _ready() -> void:
	# loads stats from singleton
	health = PlayerStats.health
	max_health = PlayerStats.max_health
	
	# initializes hitbox offset
	hitbox_offset = hitbox.position

# main function
func _physics_process(_delta: float) -> void:
	# disables hitbox until an attack is triggered
	hitbox.monitoring = false
	
	if not is_alive:
		return
	# processes attacking
	if Input.is_action_just_pressed("attack") and not is_attacking:
		_attack()
	
	if is_attacking:
		velocity = Vector2.ZERO
		return
	
	# updates variables to process animations
	process_movement()
	# selects the animation
	process_animation()
	# allows physics-based movement collisions
	move_and_slide()

#########################################
#	Movement & Animation				#
#########################################

func process_movement() -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		# while input from movement keys is received, there is velocity and the last facing direction gets updated
		velocity = direction * SPEED
		last_facing_direction = direction
		update_hitbox_offset()
	else:
		# no input from movement keys
		velocity = Vector2.ZERO

# passes a string according to the animation wanted
func process_animation() -> void:
	# attacking has its own function
	if is_attacking == true:
		return
	
	if velocity != Vector2.ZERO:
		play_animation("run", last_facing_direction)
	else:
		play_animation("idle", last_facing_direction)

# plays the correct animation
func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite.flip_h = dir.x < 0
		animated_sprite.play(prefix + "_right")
	elif dir.y > 0:
		animated_sprite.play(prefix + "_down")
	elif dir.y < 0:
		animated_sprite.play(prefix + "_up")

#########################################
#	Attacking							#
#########################################

func _attack() -> void:
	is_attacking = true
	hitbox.monitoring = true
	swing_sword.play()
	play_animation("attack", last_facing_direction)


func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking == true:
		is_attacking = false

#########################################
#	Hitbox								#
#########################################

func update_hitbox_offset() -> void:
	var x := hitbox_offset.x
	var y := hitbox_offset.y
	
	match last_facing_direction:
		Vector2.LEFT:
			hitbox.position = Vector2(-y, -x)
		Vector2.RIGHT:
			hitbox.position = Vector2(y, -x)
		Vector2.UP:
			hitbox.position = Vector2(-x, -y)
		Vector2.DOWN:
			hitbox.position = Vector2(x, y)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking and body.name.begins_with("Enemy"):
		body.take_damage(strength, position)

func heal(amount: int) -> void:
	health += amount
	if health > max_health:
		health = max_health
	PlayerStats.health = health
	emit_signal("health_changed", health)
	

func take_damage(amount: int) -> void:
	if not is_alive:
		return
	if damage_cooldown.time_left > 0:
		return
	take_damage_sfx.play()
	health -= amount
	PlayerStats.health = health
	emit_signal("health_changed", health)
	if health <= 0:
		_die()
	# gives player invincibility to avoid enemy spamming
	damage_cooldown.start()


func _die() -> void:
	animated_sprite.play("die")
	is_alive = false
	await animated_sprite.animation_finished
	died.emit()
