extends SceneTree

const HurricanConfig = preload("res://scripts/hurrican_config.gd")
const HurricanBullet = preload("res://scripts/bullet.gd")
const LightningBeam = preload("res://scripts/lightning_beam.gd")
const HurricanPlayer = preload("res://scripts/player.gd")
const HurricanHUD = preload("res://scripts/hud.gd")
const DummyTarget = preload("res://scripts/dummy_target.gd")
const HurricanLevelLoader = preload("res://scripts/hurrican_level_loader.gd")
const HurricanLevelData = preload("res://scripts/hurrican_level_data.gd")
const MainHurricanGame = preload("res://scenes/main.gd")

func _init() -> void:
	print("\n--- Running Headless Godot 4 Unit & Gameplay Tests for Hurrican Godot ---")
	var success = true
	success = success and _test_config()
	success = success and _test_bullet()
	success = success and _test_lightning_beam()
	success = success and _test_player_states_and_wheel()
	success = success and _test_player_weapons()
	success = success and _test_gamepad_mappings()
	success = success and _test_dummy_target()
	success = success and _test_level_loader()
	success = success and _test_main_scene()
	success = success and _test_boss_and_music()
	success = success and _test_hd_mode_and_lighting()
	
	if success:
		print("=== ALL TESTS FOR HURRICAN GODOT PASSED SUCCESSFULLY! ===")
		quit(0)
	else:
		printerr("=== TESTS FAILED ===")
		quit(1)

func _test_config() -> bool:
	print("[1/9] Testing HurricanConfig parameters...")
	assert(HurricanConfig.MOVE_SPEED > 0.0, "Move speed must be positive")
	assert(HurricanConfig.JUMP_VELOCITY < 0.0, "Jump velocity must be negative (upwards)")
	assert(HurricanConfig.GRAVITY > 0.0, "Gravity must be positive")
	assert(HurricanConfig.WHEEL_ENERGY_MAX == 100.0, "Wheel energy max should be 100")
	assert(HurricanConfig.LIGHTNING_MAX_DISTANCE > 100.0, "Lightning beam distance should be > 100")
	print("  -> HurricanConfig OK.")
	return true

func _test_bullet() -> bool:
	print("[2/9] Testing HurricanBullet weapon types & behaviors...")
	var spread_bullet = HurricanBullet.new(HurricanConfig.WeaponType.SPREAD, Vector2.RIGHT)
	root.add_child(spread_bullet)
	spread_bullet._ready()
	assert(spread_bullet.weapon_type == HurricanConfig.WeaponType.SPREAD, "Spread bullet type mismatch")
	assert(spread_bullet.bounces_left == 0, "Spread bullet should not bounce")
	
	var bounce_bullet = HurricanBullet.new(HurricanConfig.WeaponType.BOUNCE, Vector2.LEFT)
	root.add_child(bounce_bullet)
	bounce_bullet._ready()
	assert(bounce_bullet.weapon_type == HurricanConfig.WeaponType.BOUNCE, "Bounce bullet type mismatch")
	assert(bounce_bullet.bounces_left > 0, "Bounce bullet should have bounces")
	
	# Friendly fire test
	var player = HurricanPlayer.new()
	root.add_child(player)
	player._ready()
	var initial_hp = player.health
	bounce_bullet.shooter = player
	bounce_bullet._on_body_entered(player)
	assert(player.health == initial_hp, "Bullet should NEVER damage the player (friendly fire protection)")
	
	player.queue_free()
	spread_bullet.queue_free()
	bounce_bullet.queue_free()
	print("  -> HurricanBullet OK.")
	return true

func _test_lightning_beam() -> bool:
	print("[3/9] Testing LightningBeam 360° raycast & procedural jitter...")
	var beam = LightningBeam.new()
	root.add_child(beam)
	beam._ready()
	
	assert(not beam.is_active, "Beam should start inactive")
	beam.set_beam_active(true)
	assert(beam.is_active, "Beam should be active")
	assert(beam.line_outer.visible, "Outer line should be visible when active")
	assert(beam.line_core.visible, "Core line should be visible when active")
	
	# Test aim angle
	beam.update_aim(Vector2.UP)
	assert(beam.aim_angle == Vector2.UP.angle(), "Aim angle should match UP direction")
	assert(beam.raycast.target_position.y < -100.0, "Raycast target y should be negative for UP")
	
	beam.set_beam_active(false)
	assert(not beam.is_active, "Beam should be inactive after toggle")
	
	beam.queue_free()
	print("  -> LightningBeam OK.")
	return true

func _test_player_states_and_wheel() -> bool:
	print("[4/9] Testing HurricanPlayer state machine & Gyro-Wheel transformation...")
	var player = HurricanPlayer.new()
	root.add_child(player)
	player._ready()
	
	assert(player.current_state == HurricanPlayer.PlayerState.IDLE, "Player should start in IDLE")
	assert(player.health == 100.0, "Player should start with 100 HP")
	assert(player.wheel_energy == HurricanConfig.WHEEL_ENERGY_MAX, "Player should start with full wheel energy")
	
	# Test Wheel Mode
	player._enter_wheel_mode()
	assert(player.current_state == HurricanPlayer.PlayerState.WHEEL, "Player should transition to WHEEL")
	assert(player.collision_shape.shape is CircleShape2D, "Collision shape should be circle in wheel mode")
	
	player._exit_wheel_mode()
	assert(player.current_state == HurricanPlayer.PlayerState.IDLE, "Player should return to IDLE")
	assert(player.collision_shape.shape is RectangleShape2D, "Collision shape should return to rect")
	
	player.queue_free()
	print("  -> HurricanPlayer State Machine & Gyro-Wheel OK.")
	return true

func _test_player_weapons() -> bool:
	print("[5/9] Testing HurricanPlayer weapon cycling & firing...")
	var player = HurricanPlayer.new()
	root.add_child(player)
	player._ready()
	
	assert(player.current_weapon == HurricanConfig.WeaponType.SPREAD, "Initial weapon should be SPREAD")
	player.cycle_weapon()
	assert(player.current_weapon == HurricanConfig.WeaponType.LASER, "Cycled weapon should be LASER")
	player.cycle_weapon()
	assert(player.current_weapon == HurricanConfig.WeaponType.BOUNCE, "Cycled weapon should be BOUNCE")
	player.cycle_weapon()
	assert(player.current_weapon == HurricanConfig.WeaponType.SPREAD, "Cycled weapon should return to SPREAD")
	
	# Test firing
	player.fire_weapon()
	assert(player.shot_cooldown > 0.0, "Shot cooldown should activate on fire")
	
	player.queue_free()
	print("  -> HurricanPlayer Weapon Systems OK.")
	return true

func _test_gamepad_mappings() -> bool:
	print("[6/9] Testing Gamepad InputMap actions & rumble support...")
	var required_actions = ["p1_left", "p1_right", "p1_up", "p1_down", "p1_jump", "p1_shoot", "p1_lightning", "p1_wheel", "p1_weapon_cycle"]
	for action in required_actions:
		assert(InputMap.has_action(action), "InputMap missing action: " + action)
		var events = InputMap.action_get_events(action)
		var has_joy = false
		for ev in events:
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				has_joy = true
				break
		assert(has_joy, "Action " + action + " should have joypad event mapped")
	
	var player = HurricanPlayer.new()
	root.add_child(player)
	player._ready()
	assert(player.has_method("trigger_rumble"), "Player must support rumble")
	assert(player.has_method("take_damage"), "Player must support take_damage")
	player.take_damage(20.0)
	assert(player.health == 80.0, "Player HP should decrease on damage")
	player.queue_free()
	
	print("  -> Gamepad Mappings & Rumble OK.")
	return true

func _test_dummy_target() -> bool:
	print("[7/9] Testing DummyTarget damage reception & destruction...")
	var target = DummyTarget.new()
	root.add_child(target)
	target._ready()
	
	var initial_hp = target.health
	target.take_damage(15.0)
	assert(target.health == initial_hp - 15.0, "Target HP should decrease by damage amount")
	
	var destroyed_flag = [false]
	target.destroyed.connect(func(): destroyed_flag[0] = true)
	target.take_damage(50.0) # Lethal damage
	assert(destroyed_flag[0], "Target should emit destroyed signal when HP reaches 0")
	
	print("  -> DummyTarget OK.")
	return true

func _test_level_loader() -> bool:
	print("[8/9] Testing HurricanLevelLoader parsing & level generation...")
	var tut_path = "res://assets/levels/tutorial.map"
	var tut_data = HurricanLevelLoader.load_level_data(tut_path)
	assert(tut_data != null, "Tutorial map should load successfully")
	assert(tut_data.size_x == 400, "Tutorial size_x should be 400")
	assert(tut_data.size_y == 300, "Tutorial size_y should be 300")
	assert(tut_data.num_objects == 220, "Tutorial num_objects should be 220")
	assert(tut_data.player_spawn_p1 == Vector2(299, 1740), "Tutorial P1 spawn mismatch: " + str(tut_data.player_spawn_p1))
	assert(tut_data.used_tilesets == 33, "Tutorial used_tilesets should be 33")
	
	var jungle_path = "res://assets/levels/jungle.map"
	var jungle_data = HurricanLevelLoader.load_level_data(jungle_path)
	assert(jungle_data != null, "Jungle map should load successfully")
	assert(jungle_data.size_x == 650, "Jungle size_x should be 650")
	assert(jungle_data.size_y == 256, "Jungle size_y should be 256")
	assert(jungle_data.num_objects == 1139, "Jungle num_objects should be 1139")
	assert(jungle_data.player_spawn_p1 == Vector2(1753, 2220), "Jungle P1 spawn mismatch: " + str(jungle_data.player_spawn_p1))
	assert(jungle_data.player_spawn_p2 == Vector2(1684, 2220), "Jungle P2 spawn mismatch: " + str(jungle_data.player_spawn_p2))
	
	# Node creation test
	var level_node = HurricanLevelLoader.build_level_node(tut_data)
	assert(level_node != null, "Level node should be constructed")
	var col_tiles = level_node.get_node_or_null("CollisionTiles") as TileMapLayer
	assert(col_tiles != null, "CollisionTiles layer should exist")
	assert(col_tiles.get_used_cells().size() > 0, "CollisionTiles should have solid cells")
	
	var objects = level_node.get_node_or_null("LevelObjects")
	assert(objects != null, "LevelObjects should exist")
	assert(objects.get_child_count() > 0, "Objects should be instantiated in level")
	
	level_node.queue_free()
	print("  -> HurricanLevelLoader OK.")
	return true

func _test_main_scene() -> bool:
	print("[9/9] Testing MainHurricanGame full orchestration & HUD...")
	var game = MainHurricanGame.new()
	root.add_child(game)
	game._ready()
	
	assert(game.player != null, "Game should have player instance")
	assert(game.hud != null, "Game should have HUD instance")
	assert(game.camera != null, "Game should have Camera2D instance")
	assert(game.level_path == "res://assets/levels/jungle.map", "Default level should be jungle.map (Level 1)")
	assert(game.active_level_data != null, "Active level data should be loaded")
	
	game.queue_free()
	print("  -> MainHurricanGame Full Orchestration OK.")
	return true

func _test_boss_and_music() -> bool:
	const HurricanBossTrigger = preload("res://scripts/objects/boss_trigger.gd")
	const HurricanSpiderBoss = preload("res://scripts/objects/spider_boss.gd")
	
	print("[10/10] Testing Boss Encounter & Music Assets...")
	assert(ResourceLoader.exists("res://assets/music/jungle.mp3"), "Jungle music must exist")
	assert(ResourceLoader.exists("res://assets/music/boss.mp3"), "Boss music must exist")
	
	var trigger = HurricanBossTrigger.new()
	root.add_child(trigger)
	trigger._ready()
	assert(trigger != null, "Boss trigger should initialize")
	
	var boss = HurricanSpiderBoss.new()
	root.add_child(boss)
	assert(boss.health == HurricanSpiderBoss.MAX_HP, "Boss should have full HP")
	boss.activate_boss()
	assert(boss.is_active, "Boss should be active")
	boss.take_damage(50.0)
	assert(boss.health == HurricanSpiderBoss.MAX_HP - 50.0, "Boss HP should decrease on hit")
	
	trigger.queue_free()
	boss.queue_free()
	print("  -> Boss Encounter & Music OK.")
	return true

func _test_hd_mode_and_lighting() -> bool:
	print("[11/11] Testing HD Mode (40px tiles, 0.5 scale) & 2D Dynamic Lights...")
	assert(ResourceLoader.exists("res://assets/textures/effects/light_glow.png"), "Radial light texture must exist")
	assert(ResourceLoader.exists("res://assets/textures/tilesets/s_Jungle_hd.png"), "HD jungle tileset must exist")
	assert(ResourceLoader.exists("res://assets/textures/environment/back_jungle_hd.png"), "HD jungle background must exist")
	
	# Test Bullet Light
	var bullet = HurricanBullet.new(HurricanConfig.WeaponType.LASER, Vector2.RIGHT)
	root.add_child(bullet)
	bullet._ready()
	var light = bullet.get_node_or_null("BulletLight")
	assert(light is PointLight2D, "Bullet should have PointLight2D attached")
	assert(light.color == Color(0.2, 0.8, 1.0), "Laser bullet light should be cyan")
	bullet.queue_free()
	
	# Test Level HD Mode Toggle
	var level_data = HurricanLevelLoader.load_level_data("res://assets/levels/jungle.map")
	var level_node = HurricanLevelLoader.build_level_node(level_data, false)
	root.add_child(level_node)
	
	var map_bg = level_node.get_node("BackgroundTiles") as TileMapLayer
	assert(map_bg.scale == Vector2(1.0, 1.0), "Retro mode should have 1.0 scale")
	assert(map_bg.tile_set.tile_size == Vector2i(20, 20), "Retro mode should have 20x20 tile size")
	
	# Toggle to HD
	HurricanLevelLoader.set_hd_mode(level_node, level_data, true)
	assert(map_bg.scale == Vector2(0.5, 0.5), "HD mode should scale TileMapLayer by 0.5")
	assert(map_bg.tile_set.tile_size == Vector2i(40, 40), "HD mode should have 40x40 tile size")
	
	# Toggle back to Retro
	HurricanLevelLoader.set_hd_mode(level_node, level_data, false)
	assert(map_bg.scale == Vector2(1.0, 1.0), "Retro mode should revert to 1.0 scale")
	assert(map_bg.tile_set.tile_size == Vector2i(20, 20), "Retro mode should revert to 20x20 tile size")
	
	level_node.queue_free()
	print("  -> HD Mode & 2D Lighting OK.")
	return true
