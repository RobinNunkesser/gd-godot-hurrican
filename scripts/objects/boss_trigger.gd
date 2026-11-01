class_name HurricanBossTrigger
extends Area2D

const HurricanConfig = preload("res://scripts/hurrican_config.gd")
const HurricanPlayer = preload("res://scripts/player.gd")

signal boss_triggered(trigger_node)

var is_triggered: bool = false

func _init() -> void:
	name = "BossTrigger"
	collision_layer = 0
	collision_mask = HurricanConfig.COLLISION_LAYER_PLAYER
	
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	# Vertikale Schranke über die gesamte Arena-Höhe
	rect.size = Vector2(80.0, 1200.0)
	col.shape = rect
	col.position = Vector2(40.0, 0.0)
	add_child(col)

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_triggered:
		return
	if body is HurricanPlayer or body.name.begins_with("Player"):
		is_triggered = true
		boss_triggered.emit(self)
