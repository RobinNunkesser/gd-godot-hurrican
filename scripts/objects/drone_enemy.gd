class_name HurricanDroneEnemy
extends CharacterBody2D

signal destroyed

var health: float = 30.0
var max_health: float = 30.0
var hover_time: float = 0.0
var base_y: float = 0.0

var sprite: Sprite2D
var flame_sprite: Sprite2D
var anim_timer: float = 0.0
var current_frame: int = 0
const TOTAL_FRAMES: int = 4
const FRAME_DURATION: float = 0.12
const FRAME_WIDTH: int = 70
const FRAME_HEIGHT: int = 80

func _init() -> void:
	collision_layer = 2 # Enemies
	collision_mask = 1  # World
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 24.0
	col.shape = circle
	col.position = Vector2(0, 0)
	add_child(col)
	
	sprite = Sprite2D.new()
	sprite.centered = true
	var tex_path = "res://assets/textures/objects/drone.png"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, FRAME_WIDTH, FRAME_HEIGHT)
	add_child(sprite)
	
	flame_sprite = Sprite2D.new()
	flame_sprite.position = Vector2(0, 32)
	var flame_path = "res://assets/textures/objects/droneflame.png"
	if ResourceLoader.exists(flame_path):
		flame_sprite.texture = load(flame_path)
		flame_sprite.region_enabled = true
		flame_sprite.region_rect = Rect2(0, 0, 82, 46)
	add_child(flame_sprite)

func _ready() -> void:
	base_y = position.y

func _physics_process(delta: float) -> void:
	hover_time += delta * 2.5
	position.y = base_y + sin(hover_time) * 16.0
	
	anim_timer += delta
	if anim_timer >= FRAME_DURATION:
		anim_timer -= FRAME_DURATION
		current_frame = (current_frame + 1) % TOTAL_FRAMES
		if sprite and sprite.texture:
			sprite.region_rect = Rect2(current_frame * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
		if flame_sprite and flame_sprite.texture:
			var f_idx = (current_frame % 2)
			flame_sprite.region_rect = Rect2(f_idx * 82, 0, 82, 46)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		destroyed.emit()
		_spawn_explosion()
		queue_free()
		return
	
	if sprite and is_inside_tree():
		sprite.modulate = Color(2.5, 2.5, 2.5)
		var tween = get_tree().create_tween() if get_tree() else null
		if tween:
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _spawn_explosion() -> void:
	var sfx_path = "res://assets/sfx/explosion2.wav"
	if ResourceLoader.exists(sfx_path) and is_inside_tree() and get_parent():
		var audio = AudioStreamPlayer2D.new()
		audio.stream = load(sfx_path)
		audio.position = position
		get_parent().add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)
