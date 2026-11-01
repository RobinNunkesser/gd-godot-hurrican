class_name HurricanPlayer
extends CharacterBody2D

const HurricanConfig = preload("res://scripts/hurrican_config.gd")
const HurricanBullet = preload("res://scripts/bullet.gd")
const LightningBeam = preload("res://scripts/lightning_beam.gd")

signal health_changed(new_health: float, max_health: float)
signal wheel_energy_changed(new_energy: float, max_energy: float)
signal weapon_changed(weapon_type: HurricanConfig.WeaponType)

enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	CROUCH,
	WHEEL,
	LIGHTNING
}

# Zustands-Variablen
var current_state: PlayerState = PlayerState.IDLE
var facing_direction: int = 1 # 1 = rechts, -1 = links
var aim_direction: Vector2 = Vector2.RIGHT

var health: float = 100.0
const MAX_HEALTH: float = 100.0
var wheel_energy: float = HurricanConfig.WHEEL_ENERGY_MAX

# Waffen
var current_weapon: HurricanConfig.WeaponType = HurricanConfig.WeaponType.SPREAD
var shot_cooldown: float = 0.0

# Nodes
var sprite: Sprite2D
var collision_shape: CollisionShape2D
var lightning_beam: LightningBeam
var sfx_jump: AudioStreamPlayer2D
var sfx_shoot: AudioStreamPlayer2D

# Animation
var anim_timer: float = 0.0
var current_frame: int = 0

# Texturen-Cache
var tex_idle: Texture2D
var tex_run: Texture2D
var tex_jump: Texture2D
var tex_crouch: Texture2D
var tex_rad: Texture2D
var tex_rundum: Texture2D
var tex_shoot_diag: Texture2D
var tex_shoot_up: Texture2D

func _ready() -> void:
	name = "Player"
	collision_layer = 2 # Player layer
	collision_mask = 1  # Collides with World
	
	_load_textures()
	_setup_collision()
	_setup_sprite()
	_setup_lightning()
	_setup_audio()
	
	health_changed.emit(health, MAX_HEALTH)
	wheel_energy_changed.emit(wheel_energy, HurricanConfig.WHEEL_ENERGY_MAX)
	weapon_changed.emit(current_weapon)

func _load_textures() -> void:
	var base = "res://assets/textures/player/"
	if ResourceLoader.exists(base + "p1_hurri_idle.png"):
		tex_idle = load(base + "p1_hurri_idle.png")
	if ResourceLoader.exists(base + "p1_hurri_laufen.png"):
		tex_run = load(base + "p1_hurri_laufen.png")
	if ResourceLoader.exists(base + "p1_hurri_jump.png"):
		tex_jump = load(base + "p1_hurri_jump.png")
	if ResourceLoader.exists(base + "p1_hurri_crouch.png"):
		tex_crouch = load(base + "p1_hurri_crouch.png")
	if ResourceLoader.exists(base + "p1_hurri_rad.png"):
		tex_rad = load(base + "p1_hurri_rad.png")
	if ResourceLoader.exists(base + "p1_hurri_rundumschuss.png"):
		tex_rundum = load(base + "p1_hurri_rundumschuss.png")
	if ResourceLoader.exists(base + "p1_hurri_shootdiagonal.png"):
		tex_shoot_diag = load(base + "p1_hurri_shootdiagonal.png")
	if ResourceLoader.exists(base + "p1_hurri_shootup.png"):
		tex_shoot_up = load(base + "p1_hurri_shootup.png")

func _setup_collision() -> void:
	collision_shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(HurricanConfig.NORMAL_COLLISION_WIDTH, HurricanConfig.NORMAL_COLLISION_HEIGHT)
	collision_shape.shape = rect
	collision_shape.position = Vector2(0, 0)
	add_child(collision_shape)

func _setup_sprite() -> void:
	sprite = Sprite2D.new()
	sprite.name = "PlayerSprite"
	if tex_idle:
		sprite.texture = tex_idle
		sprite.hframes = 5
		sprite.vframes = 4
	sprite.position = Vector2(0, -6)
	add_child(sprite)

func _setup_lightning() -> void:
	lightning_beam = LightningBeam.new()
	lightning_beam.position = Vector2(0, -10)
	add_child(lightning_beam)

func _setup_audio() -> void:
	sfx_jump = AudioStreamPlayer2D.new()
	sfx_jump.name = "JumpSound"
	var j_path = "res://assets/sfx/landen.wav"
	if ResourceLoader.exists(j_path):
		sfx_jump.stream = load(j_path)
	add_child(sfx_jump)
	
	sfx_shoot = AudioStreamPlayer2D.new()
	sfx_shoot.name = "ShootSound"
	var s_path = "res://assets/sfx/abzug.wav"
	if ResourceLoader.exists(s_path):
		sfx_shoot.stream = load(s_path)
	add_child(sfx_shoot)

func _physics_process(delta: float) -> void:
	_handle_input(delta)
	_apply_gravity(delta)
	move_and_slide()
	_update_animation(delta)

func _handle_input(delta: float) -> void:
	shot_cooldown = maxf(0.0, shot_cooldown - delta)
	
	# Waffen-Wechsel
	if Input.is_action_just_pressed("p1_weapon_cycle"):
		cycle_weapon()
	
	# Gyro-Wheel (Stachelrad / Morph-Kugel) Trigger
	var wants_wheel = Input.is_action_pressed("p1_wheel") or (Input.is_action_pressed("p1_down") and Input.is_action_just_pressed("p1_jump") and is_on_floor())
	
	if wants_wheel and wheel_energy > 5.0:
		_enter_wheel_mode()
	elif current_state == PlayerState.WHEEL and (!Input.is_action_pressed("p1_wheel") or wheel_energy <= 0.0):
		_exit_wheel_mode()
	
	# Wheel-Physik
	if current_state == PlayerState.WHEEL:
		wheel_energy = maxf(0.0, wheel_energy - HurricanConfig.WHEEL_DRAIN_PER_SEC * delta)
		wheel_energy_changed.emit(wheel_energy, HurricanConfig.WHEEL_ENERGY_MAX)
		
		var h_dir = Input.get_axis("p1_left", "p1_right")
		if h_dir != 0:
			facing_direction = int(sign(h_dir))
			velocity.x = h_dir * HurricanConfig.WHEEL_SPEED
		else:
			velocity.x = move_toward(velocity.x, 0.0, HurricanConfig.FRICTION * delta)
		return
	else:
		# Wheel-Energie regeneriert sich am Boden
		if is_on_floor() and wheel_energy < HurricanConfig.WHEEL_ENERGY_MAX:
			wheel_energy = minf(HurricanConfig.WHEEL_ENERGY_MAX, wheel_energy + HurricanConfig.WHEEL_RECHARGE_PER_SEC * delta)
			wheel_energy_changed.emit(wheel_energy, HurricanConfig.WHEEL_ENERGY_MAX)

	# 360° Rundum-Blitzstrahl (Lightning Beam)
	var wants_lightning = Input.is_action_pressed("p1_lightning")
	if wants_lightning:
		current_state = PlayerState.LIGHTNING
		lightning_beam.set_beam_active(true)
		
		# Zielen via Maus oder Analogstick
		var mouse_pos = get_global_mouse_position()
		var aim_vec = (mouse_pos - global_position).normalized()
		
		# Tastatur-Fallback für Aim-Richtung
		var move_input = Vector2(Input.get_axis("p1_left", "p1_right"), Input.get_axis("p1_up", "p1_down"))
		if move_input.length_squared() > 0.1:
			aim_vec = move_input.normalized()
		
		aim_direction = aim_vec
		lightning_beam.update_aim(aim_vec)
		
		# Im Blitz-Zustand kann sich der Spieler langsamer bewegen
		velocity.x = move_toward(velocity.x, 0.0, HurricanConfig.FRICTION * delta)
		return
	else:
		lightning_beam.set_beam_active(false)

	# Standard-Bewegung (Laufen, Springen)
	var dir_x = Input.get_axis("p1_left", "p1_right")
	var is_crouching = Input.is_action_pressed("p1_down") and is_on_floor() and dir_x == 0
	
	if is_crouching:
		current_state = PlayerState.CROUCH
		velocity.x = move_toward(velocity.x, 0.0, HurricanConfig.FRICTION * delta)
	else:
		if dir_x != 0:
			facing_direction = int(sign(dir_x))
			aim_direction = Vector2(facing_direction, 0)
			var accel = HurricanConfig.ACCELERATION if is_on_floor() else HurricanConfig.AIR_ACCEL
			velocity.x = move_toward(velocity.x, dir_x * HurricanConfig.MOVE_SPEED, accel * delta)
			if is_on_floor():
				current_state = PlayerState.RUN
		else:
			velocity.x = move_toward(velocity.x, 0.0, HurricanConfig.FRICTION * delta)
			if is_on_floor():
				current_state = PlayerState.IDLE

	# Zielen nach oben / diagonal
	if Input.is_action_pressed("p1_up"):
		if dir_x != 0:
			aim_direction = Vector2(facing_direction, -1.0).normalized()
		else:
			aim_direction = Vector2.UP
	elif not is_crouching:
		aim_direction = Vector2(facing_direction, 0)

	# Springen
	if Input.is_action_just_pressed("p1_jump") and is_on_floor() and not is_crouching:
		velocity.y = HurricanConfig.JUMP_VELOCITY
		current_state = PlayerState.JUMP
		if sfx_jump and sfx_jump.stream:
			sfx_jump.play()
	
	# Variables Sprunghöhe-Gefühl (Taste früher loslassen kappt Sprunghöhe)
	if Input.is_action_just_released("p1_jump") and velocity.y < HurricanConfig.VARIABLE_JUMP_CUTOFF:
		velocity.y = HurricanConfig.VARIABLE_JUMP_CUTOFF

	if not is_on_floor():
		current_state = PlayerState.JUMP

	# Schießen
	if Input.is_action_pressed("p1_shoot") and shot_cooldown <= 0.0:
		fire_weapon()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += HurricanConfig.GRAVITY * delta

func _enter_wheel_mode() -> void:
	if current_state == PlayerState.WHEEL:
		return
	current_state = PlayerState.WHEEL
	lightning_beam.set_beam_active(false)
	
	# Kleinere Kollisionsbox fürs Stachelrad
	if collision_shape:
		var circle = CircleShape2D.new()
		circle.radius = HurricanConfig.WHEEL_COLLISION_RADIUS
		collision_shape.shape = circle
		collision_shape.position = Vector2(0, 14)

func _exit_wheel_mode() -> void:
	if current_state != PlayerState.WHEEL:
		return
	current_state = PlayerState.IDLE
	
	# Normale Spieler-Kollisionsbox wiederherstellen
	if collision_shape:
		var rect = RectangleShape2D.new()
		rect.size = Vector2(HurricanConfig.NORMAL_COLLISION_WIDTH, HurricanConfig.NORMAL_COLLISION_HEIGHT)
		collision_shape.shape = rect
		collision_shape.position = Vector2(0, 0)

func cycle_weapon() -> void:
	var total = HurricanConfig.WeaponType.size()
	current_weapon = ((int(current_weapon) + 1) % total) as HurricanConfig.WeaponType
	weapon_changed.emit(current_weapon)

func fire_weapon() -> void:
	shot_cooldown = HurricanConfig.WEAPON_FIRE_DELAY[current_weapon]
	if sfx_shoot and sfx_shoot.stream:
		sfx_shoot.play()
	
	var spawn_pos = global_position + aim_direction * 18.0 + Vector2(0, -6)
	
	match current_weapon:
		HurricanConfig.WeaponType.SPREAD:
			# 3 Schuss Streufächer (Original Turrican / Hurrican Fächer)
			var base_angle = aim_direction.angle()
			var angles = [-0.18, 0.0, 0.18]
			for offset in angles:
				var bullet = HurricanBullet.new(current_weapon, Vector2.RIGHT.rotated(base_angle + offset))
				bullet.global_position = spawn_pos
				get_parent().add_child(bullet)
		
		HurricanConfig.WeaponType.LASER:
			var bullet = HurricanBullet.new(current_weapon, aim_direction)
			bullet.global_position = spawn_pos
			get_parent().add_child(bullet)
		
		HurricanConfig.WeaponType.BOUNCE:
			# 2 leicht gestreute Bounce-Kugeln
			for off in [-0.1, 0.1]:
				var bullet = HurricanBullet.new(current_weapon, aim_direction.rotated(off))
				bullet.global_position = spawn_pos
				get_parent().add_child(bullet)

func _set_sprite_frame(frame_idx: int) -> void:
	if sprite and sprite.hframes * sprite.vframes > frame_idx:
		sprite.frame = frame_idx

func _update_animation(delta: float) -> void:
	if not sprite:
		return
	
	sprite.flip_h = (facing_direction < 0)
	
	match current_state:
		PlayerState.WHEEL:
			if sprite.texture != tex_rad and tex_rad:
				sprite.texture = tex_rad
				sprite.hframes = 4
				sprite.vframes = 2
			anim_timer += delta * (absf(velocity.x) * 0.08 + 8.0)
			_set_sprite_frame(int(anim_timer) % 8)
			sprite.position = Vector2(0, 14)
			return
		
		PlayerState.LIGHTNING:
			if sprite.texture != tex_rundum and tex_rundum:
				sprite.texture = tex_rundum
				sprite.hframes = 7
				sprite.vframes = 6
			# Frame basierend auf 360° Winkel (36 Richtungen)
			var norm_angle = fposmod(aim_direction.angle(), TAU)
			var dir_index = int(round((norm_angle / TAU) * 36.0)) % 36
			_set_sprite_frame(dir_index)
			sprite.position = Vector2(0, -6)
			return
		
		PlayerState.CROUCH:
			if sprite.texture != tex_crouch and tex_crouch:
				sprite.texture = tex_crouch
				sprite.hframes = 2
				sprite.vframes = 1
			_set_sprite_frame(1)
			sprite.position = Vector2(0, 4)
			return
		
		PlayerState.JUMP:
			if aim_direction == Vector2.UP and tex_jump:
				sprite.texture = tex_jump
				sprite.hframes = 4
				sprite.vframes = 3
			elif sprite.texture != tex_jump and tex_jump:
				sprite.texture = tex_jump
				sprite.hframes = 4
				sprite.vframes = 3
			# Sprungphasen abhängig von vertikaler Geschwindigkeit
			if velocity.y < -150:
				_set_sprite_frame(2) # Aufsteigend
			elif velocity.y > 150:
				_set_sprite_frame(8) # Fallend
			else:
				_set_sprite_frame(5) # Scheitelpunkt
			sprite.position = Vector2(0, -6)
			return
		
		PlayerState.RUN:
			if sprite.texture != tex_run and tex_run:
				sprite.texture = tex_run
				sprite.hframes = 5
				sprite.vframes = 4
			anim_timer += delta * (absf(velocity.x) * 0.08)
			_set_sprite_frame(int(anim_timer) % 20)
			sprite.position = Vector2(0, -6)
			return
		
		PlayerState.IDLE, _:
			if aim_direction == Vector2.UP and tex_shoot_up:
				sprite.texture = tex_shoot_up
				sprite.hframes = 2
				sprite.vframes = 1
				_set_sprite_frame(0)
			elif absf(aim_direction.y) > 0.3 and tex_shoot_diag:
				sprite.texture = tex_shoot_diag
				sprite.hframes = 2
				sprite.vframes = 1
				_set_sprite_frame(0)
			else:
				if sprite.texture != tex_idle and tex_idle:
					sprite.texture = tex_idle
					sprite.hframes = 5
					sprite.vframes = 4
				anim_timer += delta * 6.0
				_set_sprite_frame(int(anim_timer) % 20)
			sprite.position = Vector2(0, -6)
