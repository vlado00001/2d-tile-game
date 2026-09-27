extends CharacterBody2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_sfx: AudioStreamPlayer2D = $TakeDamage
@onready var die_sfx: AudioStreamPlayer2D = $Die
@onready var health_bar: Node2D = $HealthBar


const SPEED: int = 175.0
const KNOCKBACK_FORCE: int = 100
var target = null
var health: int = 100
var is_alive: bool = true


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
	print(health)
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
	self.z_index = 4
	
func _on_sight_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target = body

func _on_sight_body_exited(body: Node2D) -> void:
	if body.name == "Player" and is_alive:
		target = null
		animated_sprite.play("idle")
