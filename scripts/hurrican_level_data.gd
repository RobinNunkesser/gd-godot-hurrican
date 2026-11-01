class_name HurricanLevelData
extends RefCounted

const TILE_SIZE: int = 20

# Collision Blockwert Flags from Hurrican Tileengine.hpp
const BLOCKWERT_WAND: int           = 0x000001
const BLOCKWERT_GEGNERWAND: int     = 0x000002
const BLOCKWERT_PLATTFORM: int      = 0x000004
const BLOCKWERT_LIGHT: int          = 0x000008
const BLOCKWERT_VERDECKEN: int      = 0x000010
const BLOCKWERT_ANIMIERT_BACK: int  = 0x000020
const BLOCKWERT_ANIMIERT_FRONT: int = 0x000040
const BLOCKWERT_WASSER: int         = 0x000080
const BLOCKWERT_SCHADEN: int        = 0x000100
const BLOCKWERT_FLIESSBANDL: int    = 0x000200
const BLOCKWERT_FLIESSBANDR: int    = 0x000400
const BLOCKWERT_WENDEPUNKT: int     = 0x000800
const BLOCKWERT_DESTRUCTIBLE: int   = 0x001000
const BLOCKWERT_MOVELINKS: int      = 0x002000
const BLOCKWERT_OVERLAY_LIGHT: int  = 0x004000
const BLOCKWERT_SUMPF: int          = 0x008000
const BLOCKWERT_EIS: int            = 0x010000
const BLOCKWERT_MOVEVERTICAL: int   = 0x020000
const BLOCKWERT_WASSERFALL: int     = 0x040000
const BLOCKWERT_MOVERECHTS: int     = 0x080000
const BLOCKWERT_SCHRAEGE_L: int     = 0x200000
const BLOCKWERT_SCHRAEGE_R: int     = 0x400000
const BLOCKWERT_LIQUID: int         = 0x800000

var file_path: String = ""
var kennung: String = ""
var description: String = ""
var bg_file: String = ""
var parallax_a_file: String = ""
var parallax_b_file: String = ""
var cloud_file: String = ""
var timelimit: float = 500.0
var used_tilesets: int = 0
var tileset_names: Array[String] = []
var size_x: int = 0
var size_y: int = 0
var num_objects: int = 0
var scroll_bg: int = 0

var tile_data: PackedByteArray = PackedByteArray()
var objects: Array[Dictionary] = []

var player_spawn_p1: Vector2 = Vector2.ZERO
var player_spawn_p2: Vector2 = Vector2.ZERO
var player_p1_facing: int = 0 # 0 = right, 1 = left
var player_p2_facing: int = 0

var song_stage: String = ""
var song_boss: String = ""
var liquid_col1: Color = Color(0, 0.5, 0.8, 0.6)
var liquid_col2: Color = Color(0, 0.3, 0.6, 0.6)
var flashlight: bool = false

func get_pixel_size() -> Vector2:
	return Vector2(size_x * TILE_SIZE, size_y * TILE_SIZE)

func get_tile(x: int, y: int) -> Dictionary:
	if x < 0 or x >= size_x or y < 0 or y >= size_y:
		return {
			"back_set": 0, "front_set": 0, "back_art": 0, "front_art": 0,
			"r": 255, "g": 255, "b": 255, "a": 255, "block": 0
		}
	var offset: int = (x * size_y + y) * 12
	return {
		"back_set": tile_data[offset],
		"front_set": tile_data[offset + 1],
		"back_art": tile_data[offset + 2],
		"front_art": tile_data[offset + 3],
		"r": tile_data[offset + 4],
		"g": tile_data[offset + 5],
		"b": tile_data[offset + 6],
		"a": tile_data[offset + 7],
		"block": tile_data.decode_u32(offset + 8)
	}
