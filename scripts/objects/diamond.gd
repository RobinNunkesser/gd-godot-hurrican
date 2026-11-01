class_name HurricanDiamond
extends Area2D

const HurricanPlayer = preload("res://scripts/player.gd")

signal collected

var sprite: Sprite2D
var anim_timer: float = 0.0
var current_frame: int = 0
const TOTAL_FRAMES: int = 9
const FRAME_DURATION: float = 0.08
const FRAME_WIDTH: int = 29
const FRAME_HEIGHT: int = 29

func _init() -> void:
	collision_layer = 8 # Pickups
	collision_mask = 4  # Player (collision layer 3 = bitmask 4)
	
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12.0
	col.shape = circle
	col.position = Vector2(14.5, 14.5)
	add_child(col)
	
	sprite = Sprite2D.new()
	sprite.centered = false
	var tex_path = "res://assets/textures/objects/diamant.png"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, FRAME_WIDTH, FRAME_HEIGHT)
	add_child(sprite)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	anim_timer += delta
	if anim_timer >= FRAME_DURATION:
		anim_timer -= FRAME_DURATION
		current_frame = (current_frame + 1) % TOTAL_FRAMES
		if sprite and sprite.texture:
			sprite.region_rect = Rect2(current_frame * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)

func _on_body_entered(body: Node2D) -> void:
	if body is HurricanPlayer or body.name.begins_with("Player"):
		_collect()

func _collect() -> void:
	collected.emit()
	var sfx_path = "res://assets/sfx/collect.wav"
	if ResourceLoader.exists(sfx_path) and is_inside_tree():
		var audio = AudioStreamPlayer2D.new()
		audio.stream = load(sfx_path)
		audio.position = position
		get_parent().add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)
	queue_free()
