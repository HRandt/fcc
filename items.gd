extends ScrollContainer


signal item_selected(path, type)
signal item_none(type)

const Item := preload("res://item.tscn")


func set_items(items: Array, n: String) -> void:
	name = n
	for i in items:
		var item := Item.instance()
		item.set_item(i, $HBox/None/TextureButton.group)
		$HBox.add_child(item)
		item.connect("item_selected", self, "on_item_selected")


func _on_TextureButton_toggled(button_pressed: bool) -> void:
	$HBox/None/TextureButton/TextureRect.visible = button_pressed
	if button_pressed:
		emit_signal("item_none", name)


func on_item_selected(path: String) -> void:
	emit_signal("item_selected", path, name)


func get_random_item() -> void:
	var i = (randi() % ($HBox.get_child_count() - 1)) + 1
	$HBox.get_child(i).get_node("TextureButton").pressed = true
	$HBox.get_child(i)._on_TextureButton_toggled(true)


func set_none() -> void:
	$HBox/None/TextureButton.pressed = true
	_on_TextureButton_toggled(true)


func set_item(path: String) -> void:
	if not path:
		$HBox/None/TextureButton.pressed = true
		_on_TextureButton_toggled(true)
	else:
		for item in $HBox.get_children():
			if item.get_child(0).texture_normal.resource_path == path:
				item.get_node("TextureButton").pressed = true
				item._on_TextureButton_toggled(true)
				return
