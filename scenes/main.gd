class_name MainHurricanGame
extends Node2D

const HurricanConfig = preload("res://scripts/hurrican_config.gd")
const HurricanPlayer = preload("res://scripts/player.gd")
const HurricanHUD = preload("res://scripts/hud.gd")
const DummyTarget = preload("res://scripts/dummy_target.gd")
const HurricanLevelLoader = preload("res://scripts/hurrican_level_loader.gd")
const HurricanLevelData = preload("res://scripts/hurrican_level_data.gd")

const HurricanBossTrigger = preload("res://scripts/objects/boss_trigger.gd")
const HurricanSpiderBoss = preload("res://scripts/objects/spider_boss.gd")

@export var level_path: String = "res://assets/levels/jungle.map"

var player: HurricanPlayer
var hud: HurricanHUD
var camera: Camera2D
var active_level_node: Node2D
var active_level_data: HurricanLevelData

var stage_music_player: AudioStreamPlayer
var boss_music_player: AudioStreamPlayer
var spider_boss: HurricanSpiderBoss
var world_env: WorldEnvironment
var is_hd_mode: bool = false

func _ready() -> void:
	if level_path != "" and FileAccess.file_exists(level_path):
		_load_hurrican_level(level_path)
	else:
		_build_fallback_stage()
	
	_setup_hud()
	_setup_environment()
	_setup_music()
	_bind_boss_events()

func _setup_environment() -> void:
	world_env = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env = Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.0 # Standardmäßig Retro (kein Glow)
	env.glow_bloom = 0.25
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	world_env.environment = env
	add_child(world_env)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			toggle_graphics_mode()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index in [JOY_BUTTON_BACK, JOY_BUTTON_MISC1]:
			toggle_graphics_mode()

func toggle_graphics_mode() -> void:
	is_hd_mode = not is_hd_mode
	if active_level_node and active_level_data:
		HurricanLevelLoader.set_hd_mode(active_level_node, active_level_data, is_hd_mode)
	if hud:
		hud.set_graphics_mode(is_hd_mode)
		hud.show_mode_notification("★ MODUS: HD TEXTUREN + 2D LIGHTING (2026) ★" if is_hd_mode else "★ MODUS: RETRO PIXEL (2007) ★")
	if world_env and world_env.environment:
		world_env.environment.glow_intensity = 0.85 if is_hd_mode else 0.0

func _setup_music() -> void:
	stage_music_player = AudioStreamPlayer.new()
	stage_music_player.name = "StageMusic"
	var stage_song = "res://assets/music/jungle.mp3"
	if ResourceLoader.exists(stage_song):
		stage_music_player.stream = load(stage_song)
	add_child(stage_music_player)
	
	boss_music_player = AudioStreamPlayer.new()
	boss_music_player.name = "BossMusic"
	var boss_song = "res://assets/music/boss.mp3"
	if ResourceLoader.exists(boss_song):
		boss_music_player.stream = load(boss_song)
	add_child(boss_music_player)
	
	if stage_music_player.stream and is_inside_tree():
		stage_music_player.play()

func _bind_boss_events() -> void:
	if not active_level_node:
		return
	var objects = active_level_node.get_node_or_null("LevelObjects")
	if not objects:
		return
		
	for child in objects.get_children():
		if child is HurricanBossTrigger:
			child.boss_triggered.connect(_on_boss_triggered)
		elif child is HurricanSpiderBoss:
			spider_boss = child
			spider_boss.health_changed.connect(_on_boss_health_changed)
			spider_boss.defeated.connect(_on_boss_defeated)

func _on_boss_triggered(_trigger_node: HurricanBossTrigger) -> void:
	if hud:
		hud.trigger_warning()
		hud.show_boss_health(true)
		
	# Musik-Übergang von Stage zu Boss
	if stage_music_player and stage_music_player.playing:
		stage_music_player.stop()
	if boss_music_player and boss_music_player.stream and not boss_music_player.playing:
		boss_music_player.play()
		
	# Kamera auf die Arena beschränken
	if camera:
		camera.limit_left = 11400
		
	# Boss aktivieren
	if spider_boss:
		spider_boss.activate_boss()

func _on_boss_health_changed(hp: float, max_hp: float) -> void:
	if hud:
		hud.update_boss_health(hp, max_hp)

func _on_boss_defeated() -> void:
	if hud:
		hud.show_boss_health(false)
	if boss_music_player and boss_music_player.playing:
		boss_music_player.stop()

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
