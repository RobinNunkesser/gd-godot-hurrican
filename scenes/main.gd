class_name MainHurricanGame
extends Node2D

const HurricanConfig = preload("res://scripts/hurrican_config.gd")
const HurricanPlayer = preload("res://scripts/player.gd")
const HurricanHUD = preload("res://scripts/hud.gd")
const DummyTarget = preload("res://scripts/dummy_target.gd")
const HurricanLevelLoader = preload("res://scripts/hurrican_level_loader.gd")
const HurricanLevelData = preload("res://scripts/hurrican_level_data.gd")

@export var level_path: String = "res://assets/levels/jungle.map"

var player: HurricanPlayer
var hud: HurricanHUD
var camera: Camera2D
var active_level_node: Node2D
var active_level_data: HurricanLevelData

func _ready() -> void:
	if level_path != "" and FileAccess.file_exists(level_path):
		_load_hurrican_level(level_path)
	else:
		_build_fallback_stage()
	
	_setup_hud()

func _load_hurrican_level(path: String) -> void:
	active_level_data = HurricanLevelLoader.load_level_data(path)
	if not active_level_data:
		_build_fallback_stage()
		return
	
	active_level_node = HurricanLevelLoader.build_level_node(active_level_data)
	add_child(active_level_node)
	
	player = HurricanPlayer.new()
	var spawn_pos = active_level_data.player_spawn_p1
	if spawn_pos == Vector2.ZERO:
		spawn_pos = Vector2(200, 300)
	player.position = spawn_pos
	add_child(player)
	
	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(active_level_data.get_pixel_size().x)
	camera.limit_bottom = int(active_level_data.get_pixel_size().y)
	player.add_child(camera)
	camera.reset_smoothing()

func _build_fallback_stage() -> void:
	_build_background()
	_build_geometry()
	_spawn_fallback_player()
	_spawn_targets()

func _build_background() -> void:
	var canvas_bg = CanvasLayer.new()
	canvas_bg.layer = -5
	var bg_sprite = TextureRect.new()
	var bg_path = "res://assets/textures/environment/back_jungle.png"
	bg_sprite.texture = HurricanPlayer.load_texture_safe(bg_path)
	bg_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_sprite.modulate = Color(0.65, 0.75, 0.85)
	canvas_bg.add_child(bg_sprite)
	add_child(canvas_bg)

func _build_geometry() -> void:
	var world_body = StaticBody2D.new()
	world_body.name = "LevelGeometry"
	world_body.collision_layer = 1
	world_body.collision_mask = 0
	
	_add_box_obstacle(world_body, Vector2(1200, 420), Vector2(2400, 60), Color(0.2, 0.4, 0.25))
	_add_box_obstacle(world_body, Vector2(0, 100), Vector2(40, 700), Color(0.3, 0.35, 0.4))
	_add_box_obstacle(world_body, Vector2(2400, 100), Vector2(40, 700), Color(0.3, 0.35, 0.4))
	_add_box_obstacle(world_body, Vector2(350, 310), Vector2(180, 24), Color(0.4, 0.45, 0.3), true)
	_add_box_obstacle(world_body, Vector2(580, 240), Vector2(160, 24), Color(0.4, 0.45, 0.3), true)
	_add_box_obstacle(world_body, Vector2(800, 170), Vector2(200, 24), Color(0.4, 0.45, 0.3), true)
	_add_box_obstacle(world_body, Vector2(1100, 260), Vector2(220, 24), Color(0.4, 0.45, 0.3), true)
	
	var ramp_col = CollisionPolygon2D.new()
	ramp_col.polygon = PackedVector2Array([
		Vector2(1400, 390),
		Vector2(1650, 260),
		Vector2(1750, 260),
		Vector2(1750, 390)
	])
	world_body.add_child(ramp_col)
	
	var ramp_poly = Polygon2D.new()
	ramp_poly.polygon = ramp_col.polygon
	ramp_poly.color = Color(0.35, 0.4, 0.3)
	world_body.add_child(ramp_poly)
	
	add_child(world_body)

func _add_box_obstacle(parent: StaticBody2D, pos: Vector2, size: Vector2, color: Color, is_one_way: bool = false) -> void:
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	col.position = pos
	col.one_way_collision = is_one_way
	col.one_way_collision_margin = 6.0
	parent.add_child(col)
	
	var poly = Polygon2D.new()
	var half = size * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y)
	])
	poly.position = pos
	poly.color = color
	parent.add_child(poly)

func _spawn_fallback_player() -> void:
	player = HurricanPlayer.new()
	player.position = Vector2(160, 340)
	add_child(player)
	
	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_right = 2400
	camera.limit_top = -200
	camera.limit_bottom = 480
	player.add_child(camera)
	camera.reset_smoothing()

func _spawn_targets() -> void:
	var target_positions = [
		Vector2(380, 280),
		Vector2(620, 210),
		Vector2(850, 140),
		Vector2(1200, 350),
		Vector2(1700, 220)
	]
	for pos in target_positions:
		var target = DummyTarget.new()
		target.position = pos
		add_child(target)

func _setup_hud() -> void:
	hud = HurricanHUD.new()
	add_child(hud)
	
	if player:
		player.health_changed.connect(hud.set_health)
		player.wheel_energy_changed.connect(hud.set_wheel_energy)
		player.weapon_changed.connect(hud.set_weapon)
