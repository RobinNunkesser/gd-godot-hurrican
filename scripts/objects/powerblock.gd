class_name HurricanPowerBlock
extends StaticBody2D

const HurricanDiamond = preload("res://scripts/objects/diamond.gd")

signal hit

var sprite: Sprite2D
var hits_left: int = 3
var anim_timer: float = 0.0
var current_frame: int = 0
const TOTAL_FRAMES: int = 11
const FRAME_DURATION: float = 0.1
const FRAME_SIZE: int = 40

func _init() -> void:
	collision_layer = 1 # Solid world
	collision_mask = 0
	
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(FRAME_SIZE, FRAME_SIZE)
	col.shape = rect
	col.position = Vector2(FRAME_SIZE * 0.5, FRAME_SIZE * 0.5)
	add_child(col)
	
	sprite = Sprite2D.new()
	sprite.centered = false
	var tex_path = "res://assets/textures/objects/powerblock.png"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, FRAME_SIZE, FRAME_SIZE)
	add_child(sprite)

func _process(delta: float) -> void:
	anim_timer += delta
	if anim_timer >= FRAME_DURATION:
		anim_timer -= FRAME_DURATION
		current_frame = (current_frame + 1) % TOTAL_FRAMES
		if sprite and sprite.texture:
			sprite.region_rect = Rect2(current_frame * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)

func take_damage(_amount: float) -> void:
	trigger_hit()

func trigger_hit() -> void:
	if hits_left <= 0:
		return
	hits_left -= 1
	hit.emit()
	
	# Spawn a diamond above the powerblock
	var diamond = HurricanDiamond.new()
	diamond.position = position + Vector2(6, -34)
	if get_parent():
		get_parent().add_child(diamond)
	
	var sfx_path = "res://assets/sfx/click.wav"
	if ResourceLoader.exists(sfx_path) and is_inside_tree() and get_parent():
		var audio = AudioStreamPlayer2D.new()
		audio.stream = load(sfx_path)
		audio.position = position
		get_parent().add_child(audio)
		audio.play()
		audio.finished.connect(audio.queue_free)
