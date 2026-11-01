class_name DummyTarget
extends CharacterBody2D

signal destroyed

var health: float = 40.0
var max_health: float = 40.0
var sprite: Sprite2D
var sfx_explode: AudioStreamPlayer2D

func _ready() -> void:
	collision_layer = HurricanConfig.COLLISION_LAYER_ENEMIES # Layer 3 (Mask 4)
	collision_mask = HurricanConfig.COLLISION_LAYER_WORLD    # Layer 1 (Mask 1)
	
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(28, 28)
	col.shape = rect
	add_child(col)
	
	sprite = Sprite2D.new()
	# Optional Gegner-Sprite laden
	var drone_path = "res://assets/textures/effects/spreadshot_big.png"
	if ResourceLoader.exists(drone_path):
		sprite.texture = load(drone_path)
	sprite.modulate = Color(1.0, 0.4, 0.4)
	add_child(sprite)
	
	sfx_explode = AudioStreamPlayer2D.new()
	var ex_path = "res://assets/sfx/explosion1.wav"
	if ResourceLoader.exists(ex_path):
		sfx_explode.stream = load(ex_path)
	add_child(sfx_explode)

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		destroyed.emit()
		queue_free()
		return
	
	# Kurzer weißer Trefferblitz (nur wenn noch am Leben)
	if sprite and is_inside_tree():
		sprite.modulate = Color(2.0, 2.0, 2.0)
		var tween = get_tree().create_tween() if get_tree() else null
		if tween:
			tween.tween_property(sprite, "modulate", Color(1.0, 0.4, 0.4), 0.1)
