class_name HurricanConfig
extends RefCounted

## Zentrale Physik- und Gameplay-Konfiguration für Hurrican Godot

# 1. Spieler-Bewegung & Kinematik
const MOVE_SPEED: float = 210.0
const ACCELERATION: float = 1200.0
const FRICTION: float = 1400.0
const AIR_ACCEL: float = 800.0

const GRAVITY: float = 980.0
const JUMP_VELOCITY: float = -490.0 # Ergibt ~123px Sprunghöhe, exakt wie PLAYER_MAXJUMP in Hurrican
const VARIABLE_JUMP_CUTOFF: float = -140.0

# 2. Gyro-Wheel (Stachelrad / Morph-Ball)
const WHEEL_SPEED: float = 280.0
const WHEEL_ENERGY_MAX: float = 100.0
const WHEEL_DRAIN_PER_SEC: float = 25.0
const WHEEL_RECHARGE_PER_SEC: float = 18.0
const WHEEL_COLLISION_RADIUS: float = 14.0
const NORMAL_COLLISION_WIDTH: float = 26.0
const NORMAL_COLLISION_HEIGHT: float = 56.0

# 3. 360° Rundum-Blitzstrahl (Lightning Beam)
const LIGHTNING_MAX_DISTANCE: float = 260.0
const LIGHTNING_SEGMENTS: int = 14
const LIGHTNING_JITTER: float = 12.0
const LIGHTNING_DAMAGE_RATE: float = 50.0

# 4. Waffen & Projektile
enum WeaponType {
	SPREAD,
	LASER,
	BOUNCE
}

const WEAPON_NAMES: Dictionary = {
	WeaponType.SPREAD: "SPREAD SHOT",
	WeaponType.LASER: "POWER LASER",
	WeaponType.BOUNCE: "BOUNCE SHOT"
}

const WEAPON_FIRE_DELAY: Dictionary = {
	WeaponType.SPREAD: 0.14,
	WeaponType.LASER: 0.20,
	WeaponType.BOUNCE: 0.18
}

const BULLET_SPEED: float = 550.0
const BULLET_LIFETIME: float = 1.8

