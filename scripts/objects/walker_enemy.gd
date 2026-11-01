class_name HurricanWalkerEnemy
extends CharacterBody2D

signal destroyed

var health: float = 20.0
var max_health: float = 20.0
var speed: float = 70.0
var direction: float = -1.0
var gravity: float = 980.0

var sprite: Sprite2D
var anim_timer: float = 0.0
var current_frame: int = 0
const TOTAL_FRAMES: int = 8
const FRAME_DURATION: float = 0.1
const FRAME_WIDTH: int = 45
const FRAME_HEIGHT: int = 45

func _init() -> void:
	collision_layer = 2 # Enemies
	collision_mask = 1  # World
	
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(32, 40)
	col.shape = rect
	col.position = Vector2(0, -20)
	add_child(col)
	
	sprite = Sprite2D.new()
	sprite.centered = true
	sprite.position = Vector2(0, -22)
	var tex_path = "res://assets/textures/objects/enemy-walker.png"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, FRAME_WIDTH, FRAME_HEIGHT)
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	
	velocity.x = direction * speed
	move_and_slide()
	
	if is_on_wall():
		direction *= -1.0
		if sprite:
			sprite.flip_h = (direction > 0)
	
	# Walking animation
	anim_timer += delta
	if anim_timer >= FRAME_DURATION:
		anim_timer -= FRAME_DURATION
		current_frame = (current_frame + 1) % TOTAL_FRAMES
		if sprite and sprite.texture:
			sprite.region_rect = Rect2(current_frame * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		destroyed.emit()
		_spawn_explosion()
		queue_free()
		return
	
	# Damage flash
	if sprite and is_inside_tree():
		sprite.modulate = Color(2.5, 2.5, 2.5)
		var tween = get_tree().create_tween() if get_tree() else null
		if tween:
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _spawn_explosion() -> void:
	var sfx_path = "res://assets/sfx/explosion1.wav"
	if ResourceLoader.exists(sfx_path) and is_inside_tree() and get_parent():
		var audio = AudioStreamPlayer2D.new()
		audio.stream = load(sfx_path)
		audio.position = position
		get_parent().add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)
