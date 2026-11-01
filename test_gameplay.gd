extends SceneTree

const HurricanConfig = preload("res://scripts/hurrican_config.gd")
const HurricanBullet = preload("res://scripts/bullet.gd")
const LightningBeam = preload("res://scripts/lightning_beam.gd")
const HurricanPlayer = preload("res://scripts/player.gd")
const HurricanHUD = preload("res://scripts/hud.gd")
const DummyTarget = preload("res://scripts/dummy_target.gd")
const MainHurricanGame = preload("res://scenes/main.gd")

func _init() -> void:
	print("\n--- Running Headless Godot 4 Unit & Gameplay Tests for Hurrican Godot ---")
	var success = true
	success = success and _test_config()
	success = success and _test_bullet()
	success = success and _test_lightning_beam()
	success = success and _test_player_states_and_wheel()
	success = success and _test_player_weapons()
	success = success and _test_dummy_target()
	success = success and _test_main_scene()
	
	if success:
		print("=== ALL TESTS FOR HURRICAN GODOT PASSED SUCCESSFULLY! ===")
		quit(0)
	else:
		printerr("=== TESTS FAILED ===")
		quit(1)

func _test_config() -> bool:
	print("[1/7] Testing HurricanConfig parameters...")
	assert(HurricanConfig.MOVE_SPEED > 0.0, "Move speed must be positive")
	assert(HurricanConfig.JUMP_VELOCITY < 0.0, "Jump velocity must be negative (upwards)")
	assert(HurricanConfig.GRAVITY > 0.0, "Gravity must be positive")
	assert(HurricanConfig.WHEEL_ENERGY_MAX == 100.0, "Wheel energy max should be 100")
	assert(HurricanConfig.LIGHTNING_MAX_DISTANCE > 100.0, "Lightning beam distance should be > 100")
	print("  -> HurricanConfig OK.")
	return true

func _test_bullet() -> bool:
	print("[2/7] Testing HurricanBullet weapon types & behaviors...")
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
	
	spread_bullet.queue_free()
	bounce_bullet.queue_free()
	print("  -> HurricanBullet OK.")
	return true

func _test_lightning_beam() -> bool:
	print("[3/7] Testing LightningBeam 360° raycast & procedural jitter...")
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
	print("[4/7] Testing HurricanPlayer state machine & Gyro-Wheel transformation...")
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
	print("[5/7] Testing HurricanPlayer weapon cycling & firing...")
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

func _test_dummy_target() -> bool:
	print("[6/7] Testing DummyTarget damage reception & destruction...")
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

func _test_main_scene() -> bool:
	print("[7/7] Testing MainHurricanGame full orchestration & HUD...")
	var game = MainHurricanGame.new()
	root.add_child(game)
	game._ready()
	
	assert(game.player != null, "Game should have player instance")
	assert(game.hud != null, "Game should have HUD instance")
	assert(game.camera != null, "Game should have Camera2D instance")
	
	game.queue_free()
	print("  -> MainHurricanGame Full Orchestration OK.")
	return true
