class_name HurricanHUD
extends CanvasLayer

const HurricanConfig = preload("res://scripts/hurrican_config.gd")

var label_title: Label
var label_weapon: Label
var label_controls: Label
var health_bar: ProgressBar
var wheel_bar: ProgressBar

func _ready() -> void:
	layer = 10
	
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	
	# Top Header Panel (Retro Look)
	var panel = Panel.new()
	panel.position = Vector2(16, 16)
	panel.size = Vector2(608, 64)
	container.add_child(panel)
	
	label_title = Label.new()
	label_title.position = Vector2(16, 8)
	label_title.size = Vector2(250, 24)
	label_title.text = "★ HURRICAN GODOT 4 ★"
	label_title.add_theme_font_size_override("font_size", 16)
	label_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	panel.add_child(label_title)
	
	# Health Bar
	var lbl_hp = Label.new()
	lbl_hp.position = Vector2(16, 34)
	lbl_hp.text = "SHIELD:"
	lbl_hp.add_theme_font_size_override("font_size", 12)
	panel.add_child(lbl_hp)
	
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(70, 36)
	health_bar.size = Vector2(120, 14)
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.show_percentage = false
	panel.add_child(health_bar)
	
	# Wheel Energy Bar
	var lbl_wheel = Label.new()
	lbl_wheel.position = Vector2(210, 34)
	lbl_wheel.text = "RAD-ENERGY:"
	lbl_wheel.add_theme_font_size_override("font_size", 12)
	panel.add_child(lbl_wheel)
	
	wheel_bar = ProgressBar.new()
	wheel_bar.position = Vector2(295, 36)
	wheel_bar.size = Vector2(110, 14)
	wheel_bar.max_value = HurricanConfig.WHEEL_ENERGY_MAX
	wheel_bar.value = HurricanConfig.WHEEL_ENERGY_MAX
	wheel_bar.show_percentage = false
	panel.add_child(wheel_bar)
	
	# Weapon Indicator
	label_weapon = Label.new()
	label_weapon.position = Vector2(430, 20)
	label_weapon.size = Vector2(170, 28)
	label_weapon.text = "WEAPON: SPREAD SHOT"
	label_weapon.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_weapon.add_theme_font_size_override("font_size", 13)
	label_weapon.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	panel.add_child(label_weapon)
	
	# Bottom Controls Helper
	label_controls = Label.new()
	label_controls.position = Vector2(16, 448)
	label_controls.size = Vector2(608, 24)
	label_controls.text = "[A/D] Laufen  [Space] Sprung  [S+Space / L] Gyro-Wheel  [J] Schuss  [K / R-Maus] 360° Blitz  [E] Waffe"
	label_controls.add_theme_font_size_override("font_size", 11)
	label_controls.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.8))
	container.add_child(label_controls)

func set_health(hp: float, max_hp: float) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp

func set_wheel_energy(energy: float, max_energy: float) -> void:
	if wheel_bar:
		wheel_bar.max_value = max_energy
		wheel_bar.value = energy

func set_weapon(weapon_type: HurricanConfig.WeaponType) -> void:
	if label_weapon:
		label_weapon.text = "WEAPON: %s" % HurricanConfig.WEAPON_NAMES.get(weapon_type, "UNKNOWN")
