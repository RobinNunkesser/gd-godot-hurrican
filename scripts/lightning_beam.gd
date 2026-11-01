class_name LightningBeam
extends Node2D

const HurricanConfig = preload("res://scripts/hurrican_config.gd")

## 360° Rundum-Blitzstrahl (Lightning Beam) für Hurrican Godot
## Nutzt RayCast2D für kontinuierliche physikalische Trefferabfrage
## und Line2D mit prozeduralem elektrischem Jitter für den Plasma-Effekt.

var is_active: bool = false
var aim_angle: float = 0.0 # Bogenmaß (0 = rechts, PI = links, -PI/2 = oben)

var raycast: RayCast2D
var line_outer: Line2D
var line_core: Line2D
var tip_spark: Node2D
var audio_player: AudioStreamPlayer2D

var jitter_timer: float = 0.0
const JITTER_INTERVAL: float = 0.03

func _ready() -> void:
	name = "LightningBeam"
	
	# RayCast2D für kontinuierliche Kollisionsabfrage
	raycast = RayCast2D.new()
	raycast.name = "BeamRay"
	raycast.enabled = true
	raycast.collision_mask = 1 | 2 # World & Enemies
	raycast.target_position = Vector2(HurricanConfig.LIGHTNING_MAX_DISTANCE, 0)
	add_child(raycast)
	
	# Äußere elektrische Blitzlinie (Cyan / Neon-Blau)
	line_outer = Line2D.new()
	line_outer.name = "LineOuter"
	line_outer.width = 7.0
	line_outer.default_color = Color(0.25, 0.75, 1.0, 0.85)
	line_outer.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line_outer.end_cap_mode = Line2D.LINE_CAP_ROUND
	line_outer.visible = false
	add_child(line_outer)
	
	# Innerer energiereicher Kern (Weiß / Hellgelb)
	line_core = Line2D.new()
	line_core.name = "LineCore"
	line_core.width = 3.0
	line_core.default_color = Color(0.95, 0.98, 1.0, 1.0)
	line_core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line_core.end_cap_mode = Line2D.LINE_CAP_ROUND
	line_core.visible = false
	add_child(line_core)
	
	# Sound-Player für das charakteristische Blitzknistern
	audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "BlitzSound"
	var sfx_path = "res://assets/sfx/blitz.wav"
	if ResourceLoader.exists(sfx_path):
		audio_player.stream = load(sfx_path)
	add_child(audio_player)

func set_beam_active(active: bool) -> void:
	if is_active == active:
		return
	is_active = active
	line_outer.visible = active
	line_core.visible = active
	if active:
		if audio_player and audio_player.stream and not audio_player.playing:
			audio_player.play()
	else:
		if audio_player and audio_player.playing:
			audio_player.stop()

func update_aim(direction: Vector2) -> void:
	if direction.length_squared() > 0.05:
		aim_angle = direction.angle()
	raycast.target_position = Vector2(cos(aim_angle), sin(aim_angle)) * HurricanConfig.LIGHTNING_MAX_DISTANCE

func _process(delta: float) -> void:
	if not is_active:
		return
	
	raycast.force_raycast_update()
	var end_local: Vector2
	if raycast.is_colliding():
		end_local = to_local(raycast.get_collision_point())
		var collider = raycast.get_collider()
		if collider and collider.has_method("take_damage"):
			collider.take_damage(HurricanConfig.LIGHTNING_DAMAGE_RATE * delta)
	else:
		end_local = raycast.target_position
	
	# Prozeduralen Zick-Zack-Jitter berechnen
	jitter_timer -= delta
	if jitter_timer <= 0.0:
		jitter_timer = JITTER_INTERVAL
		_regenerate_lightning_path(Vector2.ZERO, end_local)

func _regenerate_lightning_path(start: Vector2, end: Vector2) -> void:
	var points = PackedVector2Array()
	points.append(start)
	
	var dir = end - start
	var dist = dir.length()
	var normal = Vector2(-dir.y, dir.x).normalized() if dist > 0.001 else Vector2.UP
	
	var segments = HurricanConfig.LIGHTNING_SEGMENTS
	for i in range(1, segments):
		var t = float(i) / float(segments)
		var base_point = start + dir * t
		# Zufällige Auslenkung senkrecht zur Strahlachse
		var jitter_amount = randf_range(-HurricanConfig.LIGHTNING_JITTER, HurricanConfig.LIGHTNING_JITTER)
		points.append(base_point + normal * jitter_amount)
	
	points.append(end)
	line_outer.points = points
	line_core.points = points
