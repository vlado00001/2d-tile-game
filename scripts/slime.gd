extends CharacterBody2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_sfx: AudioStreamPlayer2D = $TakeDamage
@onready var die_sfx: AudioStreamPlayer2D = $Die
@onready var health_bar: Node2D = $HealthBar
@onready var attack_cooldown: Timer = $AttackCooldown


const SPEED: int = 175.0
const KNOCKBACK_FORCE: int = 100
const DROP_CHANCE: float = 0.5
var target = null
var target_in_range: bool = false
var health: int = 100
var strength: int = 5
var is_alive: bool = true

var health_pickup_scene = preload("res://scenes/health_pickup.tscn")

func _physics_process(delta: float) -> void:
	if is_alive and target:
		_attack(delta)
		update_z_index()

# functions beginning with _ are called only inside the same script where defined
func _attack(delta: float) -> void:
	var distance = position.distance_to(target.position)
	# smoothens enemy hitbox clipping with the player
	if distance > 15:
		var direction = (target.position - position).normalized()
		# position += direction * SPEED * delta
		velocity = direction * SPEED
		move_and_slide()
	animated_sprite.play("attack")
	
func update_z_index() -> void:
	if position.y < target.position.y:
		z_index = 4
	else:
		z_index = 5

func take_damage(dmg: int, attacker_position: Vector2) -> void:
	health -= dmg
	health_bar.update_health_bar(health)
	take_damage_sfx.play()
	# knockback enemy - smooth animation with a tween
	var knockback_direction = (position - attacker_position).normalized()
	var target_position = position + knockback_direction * KNOCKBACK_FORCE
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", target_position, 0.25)
	if health <= 0:
		_die()

func _die() -> void:
	is_alive = false
	die_sfx.play()
	animated_sprite.play("die")
	# disables collision
	$CollisionShape2D.set_deferred("disabled", true)
	$Sight/CollisionShape2D.set_deferred("disabled", true)
	$HealthBar.visible = false
	$Sight.queue_free()
	$Hitbox.queue_free()
	$CollisionShape2D.queue_free()
	self.z_index = 4
	# drop health pickup
	
	if randf() <= DROP_CHANCE:
		drop_item()
	
func _on_sight_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target = body

func _on_sight_body_exited(body: Node2D) -> void:
	if body.name == "Player" and is_alive:
		target = null
		animated_sprite.play("idle")

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name == "Player" and is_alive:
		target_in_range = true
		body.take_damage(strength)
		attack_cooldown.start()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		target_in_range = false
		attack_cooldown.stop()

func _on_attack_cooldown_timeout() -> void:
	if target and target_in_range and is_alive:
		target.take_damage(strength)
	
func drop_item():
	var drop = health_pickup_scene.instantiate()
	drop.position = position
	var level_root = get_parent().get_parent()
	var items_node = level_root.get_node("Items")
	items_node.call_deferred("add_child", drop)
