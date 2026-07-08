extends RefCounted

const CAVE_TILESET_TEXTURE := "res://assets/terrain_tiles/cave_tileset_v2.png"
const BACKGROUND_ROCKS_TEXTURE := "res://assets/terrain/background_rocks_02.png"
const BACKGROUND_ROCKS_FALLBACK_TEXTURE := "res://assets/terrain/background_rocks_01.png"
const BOAT_SPAWN_TEXTURE := "res://assets/vehicles/boat_spawn_01.png"

const PROP_SPRITE_TEXTURES := {
	"crate": "res://assets/props/salvage_crate_01.png",
	"wreck_fragment": "res://assets/props/wreck_fragment_01.png",
	"relic": "res://assets/props/relic_01.png",
	"mine": "res://assets/props/mine_01.png",
	"jellyfish": "res://assets/props/jellyfish_01.png",
}

var _prop_texture_cache := {}


func load_png_texture(texture_path: String) -> Texture2D:
	var packaged_texture := _packaged_texture(texture_path)
	if packaged_texture != null:
		return packaged_texture

	if ResourceLoader.exists(texture_path):
		var resource := load(texture_path)
		if resource is Texture2D:
			return resource

	var file := FileAccess.open(texture_path, FileAccess.READ)
	if file == null:
		push_warning("Unable to open texture asset: %s" % texture_path)
		return null

	var image := Image.new()
	var error := image.load_png_from_buffer(file.get_buffer(file.get_length()))
	if error != OK:
		push_warning("Unable to decode texture asset: %s" % texture_path)
		return null

	return ImageTexture.create_from_image(image)


func prop_texture(kind: String, fallback_kind: String) -> Texture2D:
	var sprite_kind := kind
	if not PROP_SPRITE_TEXTURES.has(sprite_kind):
		sprite_kind = fallback_kind

	if _prop_texture_cache.has(sprite_kind):
		var cached = _prop_texture_cache[sprite_kind]
		if cached is Texture2D:
			return cached
		return null

	var texture_path := str(PROP_SPRITE_TEXTURES.get(sprite_kind, ""))
	if texture_path.is_empty():
		return null

	var texture := load_png_texture(texture_path)
	_prop_texture_cache[sprite_kind] = texture
	return texture


func cave_tileset_texture() -> Texture2D:
	return load_png_texture(CAVE_TILESET_TEXTURE)


func cave_tileset_texture_path() -> String:
	return CAVE_TILESET_TEXTURE


func _packaged_texture(texture_path: String) -> Texture2D:
	if ResourceLoader.exists(texture_path):
		var resource := load(texture_path)
		if resource is Texture2D:
			return resource
	return null
