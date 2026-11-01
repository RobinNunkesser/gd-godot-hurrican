class_name HurricanSpiderBoss
extends CharacterBody2D

const HurricanConfig = preload("res://scripts/hurrican_config.gd")
const HurricanBullet = preload("res://scripts/bullet.gd")

signal activated
signal health_changed(current_hp: float, max_hp: float)
signal defeated

const MAX_HP: float = 650.0

var health: float = MAX_HP
var is_active: bool = false
var is_defeated: bool = false

var facing_direction: float = -1.0
var walk_speed: float = 85.0
var stomping_timer: float = 0.0
var attack_timer: float = 0.0

var body_sprite: Sprite2D
var head_sprite: Sprite2D
var damage_flash_timer: float = 0.0
var death_timer: float = 0.0

var scream_audio: AudioStreamPlayer2D

func _init() -> void:
	name = "SpiderBoss"
	collision_layer = HurricanConfig.COLLISION_LAYER_ENEMIES
	collision_mask = HurricanConfig.COLLISION_LAYER_WORLD
	
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(260.0, 140.0)
	col.shape = rect
	col.position = Vector2(0.0, -70.0)
	add_child(col)
	
	# Body / Rumpf Sprite (415 x 160)
	body_sprite = Sprite2D.new()
	var rumpf_tex = "res://assets/textures/objects/spiderboss_rumpf.png"
	if ResourceLoader.exists(rumpf_tex):
		body_sprite.texture = load(rumpf_tex)
		body_sprite.position = Vector2(0.0, -80.0)
		body_sprite.scale = Vector2(0.85, 0.85)
	add_child(body_sprite)
	
	# Head / Kopf Sprite (127 x 92)
	head_sprite = Sprite2D.new()
	var kopf_tex = "res://assets/textures/objects/spiderboss_kopf.png"
	if ResourceLoader.exists(kopf_tex):
		head_sprite.texture = load(kopf_tex)
		head_sprite.position = Vector2(-70.0, -50.0)
		head_sprite.scale = Vector2(0.9, 0.9)
	add_child(head_sprite)
	
	# Scream Audio
	scream_audio = AudioStreamPlayer2D.new()
	var scream_path = "res://assets/sfx/spiderscream.wav"
	if ResourceLoader.exists(scream_path):
		scream_audio.stream = load(scream_path)
	add_child(scream_audio)

func activate_boss() -> void:
	if is_active or is_defeated:
		return
	is_active = true
	if is_inside_tree() and scream_audio and scream_audio.stream:
		scream_audio.play()
	activated.emit()
	health_changed.emit(health, MAX_HP)

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
		
	if is_defeated:
		_process_death(delta)
		return
		
	if not is_active:
		return
		
	# Damage Flash Rückstellung
	if damage_flash_timer > 0.0:
		damage_flash_timer -= delta
		if damage_flash_timer <= 0.0:
			modulate = Color.WHITE
			
	# Schwerkraft
	if not is_on_floor():
		velocity.y += HurricanConfig.GRAVITY * delta
	else:
		velocity.y = 0.0
		
	# Patrouillen-Bewegung mit rhythmischem Stampfen
	stomping_timer += delta * 4.0
	var bob_offset = sin(stomping_timer) * 12.0
	if body_sprite:
		body_sprite.position.y = -80.0 + bob_offset
	if head_sprite:
		head_sprite.position.y = -50.0 + (bob_offset * 0.6)
		
	velocity.x = facing_direction * walk_speed
	move_and_slide()
	
	# Wand-Reflexion
	if is_on_wall():
		facing_direction *= -1.0
		if head_sprite:
			head_sprite.position.x = 70.0 * facing_direction
			head_sprite.flip_h = (facing_direction > 0.0)
		if body_sprite:
			body_sprite.flip_h = (facing_direction > 0.0)
			
	# Angriffs-Timer (Gift-Projektile)
	attack_timer += delta
	if attack_timer >= 2.6:
		attack_timer = 0.0
		_spit_venom()

func _spit_venom() -> void:
	if not get_parent():
		return
	var shoot_pos = global_position + Vector2(facing_direction * 90.0, -50.0)
	var angles = [-0.25, 0.0, 0.25]
	for a in angles:
		var dir = Vector2(facing_direction, -0.3).normalized().rotated(a)
		var bullet = HurricanBullet.new(HurricanConfig.WeaponType.SPREAD, dir)
		bullet.damage = 15.0
		bullet.global_position = shoot_pos
		bullet.shooter = self
		# Venom Kugeln treffen den Spieler
		bullet.collision_mask = HurricanConfig.COLLISION_LAYER_WORLD | HurricanConfig.COLLISION_LAYER_PLAYER
		bullet.modulate = Color(0.4, 0.95, 0.2, 1.0) # Gift-Grün
		get_parent().add_child(bullet)

func take_damage(amount: float) -> void:
	if not is_active or is_defeated:
		return
		
	health -= amount
	damage_flash_timer = 0.12
	modulate = Color(1.8, 0.4, 0.4, 1.0) # Roter Trefferblitz
	health_changed.emit(max(0.0, health), MAX_HP)
	
	if health <= 0.0:
		_start_defeat()

func _start_defeat() -> void:
	is_defeated = true
	is_active = false
	velocity = Vector2.ZERO
	defeated.emit()
	
	# Todes-Schrei
	if is_inside_tree() and scream_audio and scream_audio.stream:
		scream_audio.pitch_scale = 0.7
		scream_audio.play()

func _process_death(delta: float) -> void:
	death_timer += delta
	# Flackern und Absinken
	modulate.a = max(0.0, 1.0 - (death_timer / 2.0))
	position.y += 20.0 * delta
	
	if death_timer >= 2.5:
		queue_free()
