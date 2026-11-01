class_name HurricanBullet
extends Area2D

const HurricanConfig = preload("res://scripts/hurrican_config.gd")

signal hit_target(body: Node2D)

var weapon_type: HurricanConfig.WeaponType = HurricanConfig.WeaponType.SPREAD
var direction: Vector2 = Vector2.RIGHT
var speed: float = HurricanConfig.BULLET_SPEED
var damage: float = 10.0
var max_bounces: int = 4
var bounces_left: int = 0
var lifetime: float = HurricanConfig.BULLET_LIFETIME

var shooter: Node2D = null
var sprite: Sprite2D
var collision_shape: CollisionShape2D

func _init(type: HurricanConfig.WeaponType = HurricanConfig.WeaponType.SPREAD, dir: Vector2 = Vector2.RIGHT) -> void:
	weapon_type = type
	direction = dir.normalized()
	bounces_left = max_bounces if weapon_type == HurricanConfig.WeaponType.BOUNCE else 0

func _ready() -> void:
	name = "Bullet"
	collision_layer = HurricanConfig.COLLISION_LAYER_PROJECTILES # 8
	collision_mask = HurricanConfig.COLLISION_LAYER_WORLD | HurricanConfig.COLLISION_LAYER_ENEMIES # 1 | 4 (Only hits World & Enemies)
	
	collision_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 6.0
	collision_shape.shape = circle
	add_child(collision_shape)
	
	sprite = Sprite2D.new()
	var tex_path = "res://assets/textures/effects/spreadshot.png"
	match weapon_type:
		HurricanConfig.WeaponType.SPREAD:
			tex_path = "res://assets/textures/effects/spreadshot.png"
			damage = 10.0
		HurricanConfig.WeaponType.LASER:
			tex_path = "res://assets/textures/effects/laser.png"
			damage = 25.0
			speed = HurricanConfig.BULLET_SPEED * 1.3
		HurricanConfig.WeaponType.BOUNCE:
			tex_path = "res://assets/textures/effects/bounce1.png"
			damage = 14.0
	
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	sprite.rotation = direction.angle()
	add_child(sprite)
	
	_setup_dynamic_light()
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _setup_dynamic_light() -> void:
	var light = PointLight2D.new()
	light.name = "BulletLight"
	var light_tex = "res://assets/textures/effects/light_glow.png"
	if ResourceLoader.exists(light_tex):
		light.texture = load(light_tex)
		light.texture_scale = 0.8
		light.energy = 1.2
		match weapon_type:
			HurricanConfig.WeaponType.SPREAD:
				light.color = Color(1.0, 0.6, 0.25) # Warm amber
				light.texture_scale = 0.7
			HurricanConfig.WeaponType.LASER:
				light.color = Color(0.2, 0.8, 1.0) # Neon cyan
				light.texture_scale = 1.2
				light.energy = 1.5
			HurricanConfig.WeaponType.BOUNCE:
				light.color = Color(0.3, 1.0, 0.4) # Electric lime
				light.texture_scale = 0.9
		add_child(light)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Niemals die eigene Spielfigur treffen
	if body == shooter or body.name.begins_with("Player"):
		return
		
	if weapon_type == HurricanConfig.WeaponType.BOUNCE and bounces_left > 0:
		bounces_left -= 1
		# Einfache Reflexion (horizontal/vertikal je nach Überlappung)
		direction = -direction.rotated(randf_range(-0.4, 0.4))
		if sprite:
			sprite.rotation = direction.angle()
		return
	
	hit_target.emit(body)
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
