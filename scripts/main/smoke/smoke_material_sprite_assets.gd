extends SceneTree

const GreyboxAssetLookup := preload("res://scripts/world/greybox_asset_lookup.gd")
const GreyboxMaterialCandidates := preload("res://scripts/world/greybox_material_candidates.gd")
const GreyboxPropRenderer := preload("res://scripts/world/greybox_prop_renderer.gd")

const CASES := [
	{"id": "material_sprite_titanium", "type": "material_candidate", "material_id": "titanium_scrap", "kind": "wreck_fragment", "x": 1, "y": 1},
	{"id": "material_sprite_rubber", "type": "material_candidate", "material_id": "rubber_sheet", "kind": "wreck_fragment", "x": 2, "y": 1},
	{"id": "material_sprite_coil", "type": "material_candidate", "material_id": "conductive_coil", "kind": "crate", "x": 3, "y": 1},
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var parent := Node2D.new()
	get_root().add_child(parent)
	var lookup := GreyboxAssetLookup.new()
	var materials := GreyboxMaterialCandidates.new()
	materials.build(parent, CASES, 32, false, GreyboxPropRenderer.new(), lookup)
	materials.configure(CASES.map(func(value): return str(value["id"])), [])

	var source_by_id := {}
	for value in materials.candidates():
		source_by_id[str(value.get("id", ""))] = value
	for expected in CASES:
		var material_id := str(expected["material_id"])
		var texture: Texture2D = lookup.material_texture(material_id)
		_expect(texture != null and texture.get_size() == Vector2(32, 32), "%s texture was missing or not 32x32" % material_id)
		var root := parent.get_node_or_null(str(expected["id"])) as Node2D
		_expect(root != null and root.visible, "%s material node was not active" % material_id)
		if root == null:
			continue
		var sprite := root.get_node_or_null("MaterialSprite") as Sprite2D
		_expect(sprite != null and sprite.texture == texture, "%s did not use its named material texture" % material_id)
		_expect(root.get_node_or_null("PropSprite") == null, "%s retained the generic prop presentation" % material_id)
		_expect(root.modulate == Color.WHITE, "%s texture was still differentiated by tint" % material_id)
		var source: Dictionary = source_by_id.get(str(expected["id"]), {})
		_expect(source.get("material_id") == material_id and source.get("kind") == expected["kind"], "%s changed source identity or fallback kind" % material_id)

	parent.queue_free()
	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		quit(1)
		return
	print("PASS: material sprite assets ids=titanium_scrap,rubber_sheet,conductive_coil size=32x32 selection=material_id generic_prop=false tint=false source_metadata=stable.")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
