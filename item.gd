extends VBoxContainer


signal item_selected(path)


func set_item(path: String, button_group: ButtonGroup) -> void:
	$TextureButton.texture_normal = load(path)
	$Label.text = path.get_file().replace(".png", "").substr(4)
	$TextureButton.group = button_group


func _on_TextureButton_toggled(button_pressed: bool) -> void:
	$TextureButton/Toggled.visible = button_pressed
	if button_pressed:
		emit_signal("item_selected", $TextureButton.texture_normal.resource_path)
