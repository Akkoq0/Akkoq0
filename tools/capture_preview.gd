extends Node
## Captures a 1280x720 live render screenshot of `main.tscn` to `res://reports/night_preview.png`.


func _ready() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var packed: PackedScene = ResourceLoader.load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		get_tree().quit(1)
		return
	var scene: Node = packed.instantiate()
	add_child(scene)
	for _i: int in range(6):
		await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("res://reports/night_preview.png")
		print("[PREVIEW] Saved res://reports/night_preview.png (%dx%d)" % [img.get_width(), img.get_height()])
	remove_child(scene)
	scene.free()
	get_tree().quit(0)
