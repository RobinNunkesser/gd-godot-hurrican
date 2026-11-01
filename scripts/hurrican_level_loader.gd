class_name HurricanLevelLoader
extends RefCounted

const HurricanLevelData = preload("res://scripts/hurrican_level_data.gd")
const HurricanDiamond = preload("res://scripts/objects/diamond.gd")
const HurricanPowerBlock = preload("res://scripts/objects/powerblock.gd")
const HurricanWalkerEnemy = preload("res://scripts/objects/walker_enemy.gd")
const HurricanDroneEnemy = preload("res://scripts/objects/drone_enemy.gd")
const HurricanBossTrigger = preload("res://scripts/objects/boss_trigger.gd")
const HurricanSpiderBoss = preload("res://scripts/objects/spider_boss.gd")

static func clean_string(bytes: PackedByteArray) -> String:
	var null_idx = bytes.find(0)
	if null_idx != -1:
		bytes = bytes.slice(0, null_idx)
	return bytes.get_string_from_ascii().strip_edges()

static func load_level_data(path: String) -> HurricanLevelData:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("HurricanLevelLoader: Failed to open level file: " + path)
		return null
	
	var data = HurricanLevelData.new()
	data.file_path = path
	
	var header = file.get_buffer(1292)
	if header.size() < 1292:
		push_error("HurricanLevelLoader: Header too short in: " + path)
		return null
	
	data.kennung = clean_string(header.slice(0, 46))
	data.description = clean_string(header.slice(46, 146))
	data.bg_file = clean_string(header.slice(146, 170))
	data.parallax_a_file = clean_string(header.slice(170, 194))
	data.parallax_b_file = clean_string(header.slice(194, 218))
	data.cloud_file = clean_string(header.slice(218, 242))
	
	data.timelimit = float(header.decode_u32(244))
	data.used_tilesets = header[248]
	
	for i in range(data.used_tilesets):
		var s_name = clean_string(header.slice(249 + i * 16, 249 + (i + 1) * 16))
		data.tileset_names.append(s_name)
	
	data.size_x = header.decode_u32(1276)
	data.size_y = header.decode_u32(1280)
	data.num_objects = header.decode_u32(1284)
	data.scroll_bg = header[1288]
	
	# Tile Daten lesen (size_x * size_y * 12)
	var total_tiles: int = data.size_x * data.size_y
	data.tile_data = file.get_buffer(total_tiles * 12)
	
	# Objekt Daten lesen (num_objects * 24)
	if data.num_objects > 0:
		var obj_buf = file.get_buffer(data.num_objects * 24)
		for i in range(data.num_objects):
			var off: int = i * 24
			var obj_id: int = obj_buf.decode_u32(off)
			var x_pos: int = obj_buf.decode_s32(off + 4)
			var y_pos: int = obj_buf.decode_s32(off + 8)
			var c_light: int = obj_buf[off + 12]
			var skill: int = obj_buf[off + 13]
			var val1: int = obj_buf.decode_s32(off + 16)
			var val2: int = obj_buf.decode_s32(off + 20)
			
			if obj_id == 0:
				if val2 == 0:
					data.player_spawn_p1 = Vector2(x_pos, y_pos)
					data.player_p1_facing = val1
				else:
					data.player_spawn_p2 = Vector2(x_pos, y_pos)
					data.player_p2_facing = val1
			
			data.objects.append({
				"id": obj_id,
				"pos": Vector2(x_pos, y_pos),
				"change_light": c_light,
				"skill": skill,
				"val1": val1,
				"val2": val2
			})
	
	# Appendix (84 Bytes)
	if file.get_position() + 84 <= file.get_length():
		var app_buf = file.get_buffer(84)
		data.song_stage = clean_string(app_buf.slice(0, 30))
		data.song_boss = clean_string(app_buf.slice(30, 60))
		data.flashlight = (app_buf[76] != 0)
	
	file.close()
	return data

static func find_tileset_texture(filename: String) -> Texture2D:
	var clean = filename.strip_edges()
	var base_paths = [
		"res://assets/textures/tilesets/" + clean,
		"res://assets/textures/tilesets/" + clean.to_lower()
	]
	for p in base_paths:
		if ResourceLoader.exists(p):
			return load(p)
	
	# Case-insensitive fallback
	var dir = DirAccess.open("res://assets/textures/tilesets")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.to_lower() == clean.to_lower():
				var full_p = "res://assets/textures/tilesets/" + file_name
				if ResourceLoader.exists(full_p):
					return load(full_p)
			file_name = dir.get_next()
	return null

static func create_collision_tileset() -> TileSet:
	var ts = TileSet.new()
	ts.tile_size = Vector2i(HurricanLevelData.TILE_SIZE, HurricanLevelData.TILE_SIZE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1) # Layer 1 = World
	ts.set_physics_layer_collision_mask(0, 0)
	
	# 4 Collision Tile Types:
	# 0: Solid Box 20x20
	# 1: One-way Platform 20x20
	# 2: Slope Left 45°
	# 3: Slope Right 45°
	var img = Image.create(80, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0)) # Fully transparent
	var tex = ImageTexture.create_from_image(img)
	
	var src = TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(20, 20)
	ts.add_source(src, 0)
	
	# 0: Solid Box
	src.create_tile(Vector2i(0, 0))
	var td0 = src.get_tile_data(Vector2i(0, 0), 0)
	td0.add_collision_polygon(0)
	td0.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)
	]))
	
	# 1: One-Way Platform (thin top bar)
	src.create_tile(Vector2i(1, 0))
	var td1 = src.get_tile_data(Vector2i(1, 0), 0)
	td1.add_collision_polygon(0)
	td1.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-10, -10), Vector2(10, -10), Vector2(10, -4), Vector2(-10, -4)
	]))
	td1.set_collision_polygon_one_way(0, 0, true)
	td1.set_collision_polygon_one_way_margin(0, 0, 6.0)
	
	# 2: Slope Left (ramping down to the right: top-left (-10,-10) to bottom-right (10,10))
	src.create_tile(Vector2i(2, 0))
	var td2 = src.get_tile_data(Vector2i(2, 0), 0)
	td2.add_collision_polygon(0)
	td2.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-10, -10), Vector2(10, 10), Vector2(-10, 10)
	]))
	
	# 3: Slope Right (ramping up to the right: bottom-left (-10,10) to top-right (10,-10))
	src.create_tile(Vector2i(3, 0))
	var td3 = src.get_tile_data(Vector2i(3, 0), 0)
	td3.add_collision_polygon(0)
	td3.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-10, 10), Vector2(10, -10), Vector2(10, 10)
	]))
	
	return ts

static func build_level_node(data: HurricanLevelData) -> Node2D:
	var level_root = Node2D.new()
	level_root.name = "HurricanLevel"
	
	# 1. Backgrounds & Parallax
	var bg_layer = CanvasLayer.new()
	bg_layer.name = "BackgroundCanvas"
	bg_layer.layer = -10
	var bg_rect = TextureRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	var bg_candidate = data.bg_file
	if bg_candidate == "" or not ResourceLoader.exists("res://assets/textures/environment/" + bg_candidate):
		bg_candidate = data.parallax_a_file
	if bg_candidate == "" or not ResourceLoader.exists("res://assets/textures/environment/" + bg_candidate):
		bg_candidate = "back_jungle.png"
	
	var bg_tex_path = "res://assets/textures/environment/" + bg_candidate
	if ResourceLoader.exists(bg_tex_path):
		bg_rect.texture = load(bg_tex_path)
	bg_layer.add_child(bg_rect)
	level_root.add_child(bg_layer)
	
	# 2. Visual TileSet
	var visual_tileset = TileSet.new()
	visual_tileset.tile_size = Vector2i(HurricanLevelData.TILE_SIZE, HurricanLevelData.TILE_SIZE)
	
	for i in range(data.used_tilesets):
		var set_name = data.tileset_names[i]
		var tex = find_tileset_texture(set_name)
		if tex:
			var atlas_src = TileSetAtlasSource.new()
			atlas_src.texture = tex
			atlas_src.texture_region_size = Vector2i(HurricanLevelData.TILE_SIZE, HurricanLevelData.TILE_SIZE)
			visual_tileset.add_source(atlas_src, i)
			for cy in range(12):
				for cx in range(12):
					atlas_src.create_tile(Vector2i(cx, cy))
	
	# 3. TileMapLayers
	var map_bg = TileMapLayer.new()
	map_bg.name = "BackgroundTiles"
	map_bg.tile_set = visual_tileset
	map_bg.z_index = -1
	level_root.add_child(map_bg)
	
	var map_fg = TileMapLayer.new()
	map_fg.name = "ForegroundTiles"
	map_fg.tile_set = visual_tileset
	map_fg.z_index = 1
	level_root.add_child(map_fg)
	
	var col_tileset = create_collision_tileset()
	var map_col = TileMapLayer.new()
	map_col.name = "CollisionTiles"
	map_col.tile_set = col_tileset
	map_col.z_index = 0
	map_col.visible = false
	level_root.add_child(map_col)
	
	# 4. Fill Tile Cells
	var sx: int = data.size_x
	var sy: int = data.size_y
	var tile_buf: PackedByteArray = data.tile_data
	
	for x in range(sx):
		var col_off: int = x * sy * 12
		for y in range(sy):
			var off: int = col_off + y * 12
			var back_set: int = tile_buf[off]
			var front_set: int = tile_buf[off + 1]
			var back_art: int = tile_buf[off + 2]
			var front_art: int = tile_buf[off + 3]
			var block: int = tile_buf.decode_u32(off + 8)
			
			var cell_pos = Vector2i(x, y)
			
			# Back Tile
			if back_art > 0 and back_set < data.used_tilesets:
				var art_idx = back_art - 1
				map_bg.set_cell(cell_pos, back_set, Vector2i(art_idx % 12, art_idx / 12))
			
			# Front Tile
			if front_art > 0 and front_set < data.used_tilesets:
				var art_idx = front_art - 1
				map_fg.set_cell(cell_pos, front_set, Vector2i(art_idx % 12, art_idx / 12))
			
			# Collision
			if block & HurricanLevelData.BLOCKWERT_WAND:
				map_col.set_cell(cell_pos, 0, Vector2i(0, 0))
			elif block & HurricanLevelData.BLOCKWERT_PLATTFORM:
				map_col.set_cell(cell_pos, 0, Vector2i(1, 0))
			elif block & HurricanLevelData.BLOCKWERT_SCHRAEGE_L:
				map_col.set_cell(cell_pos, 0, Vector2i(2, 0))
			elif block & HurricanLevelData.BLOCKWERT_SCHRAEGE_R:
				map_col.set_cell(cell_pos, 0, Vector2i(3, 0))
	
	# 5. Spawn Objects & Enemies
	var obj_container = Node2D.new()
	obj_container.name = "LevelObjects"
	level_root.add_child(obj_container)
	
	for obj in data.objects:
		var oid: int = obj.id
		var pos: Vector2 = obj.pos
		
		match oid:
			2: # DIAMANT
				var diamond = HurricanDiamond.new()
				diamond.position = pos
				obj_container.add_child(diamond)
			3: # POWERBLOCK
				var pb = HurricanPowerBlock.new()
				pb.position = pos
				obj_container.add_child(pb)
			5: # WALKER
				var walker = HurricanWalkerEnemy.new()
				walker.position = pos
				obj_container.add_child(walker)
			46: # DRONE
				var drone = HurricanDroneEnemy.new()
				drone.position = pos
				obj_container.add_child(drone)
			122: # RIESENSPINNE (Giant Spider Boss)
				var boss = HurricanSpiderBoss.new()
				boss.position = pos
				obj_container.add_child(boss)
			164: # WARNING TRIGGER
				var trigger = HurricanBossTrigger.new()
				trigger.position = pos
				obj_container.add_child(trigger)
	
	return level_root
