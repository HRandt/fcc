extends Control


const LAYERS_DISPLAY_ORDER := [
	"Chins",
	"Cheeks",
	"Ears",
	"Chest Patterns",
	"Face Patterns",
	"Mouths",
	"Noses",
	"Eyes",
	"Eyebrows",
	"Hair Front",
	"Hair Back",
]
const LAYERS_ACTUAL_ORDER := [
	"Hair Back",
	"Chest Patterns",
	"Chins",
	"Cheeks",
	"Ears",
	"Face Patterns",
	"Mouths",
	"Noses",
	"Eyes",
	"Eyebrows",
	"Hair Front",
]
const COLORS := {
	"fur": 3,
	"inner_ear": 2,
	"chest_patterns": 2,
	"face_patterns": 2,
	"teeth": 2,
	"nose": 2,
	"sclera": 2,
	"iris": 4,
	"eyebrows": 2,
	"hair_front": 2,
	"hair_back": 3,
}
const BASE_DIR := "res://character/"
const ITEM_SHADER := preload("res://item_shader.tres")
const SAVE_PATH := "user://"
const Items := preload("res://items.tscn")
const Save := preload("res://save.tscn")

var saves := []


func _ready() -> void:
	randomize()
	
	for child in $Content/Colors/Content.get_children():
		child.get_child(0).connect("color_changed", self, "on_color_changed", [child.name])
	
	var dir := Directory.new()
	for layer in LAYERS_DISPLAY_ORDER:
		dir.open(BASE_DIR + layer)
		dir.list_dir_begin(true, true)
		var items := []
		var file := dir.get_next()
		while file:
			if not dir.current_is_dir() and file.ends_with(".import"):
				items.append(BASE_DIR + layer + "/" + file.replace(".import", ""))
			file = dir.get_next()
		dir.list_dir_end()
		var items_node := Items.instance()
		items_node.set_items(items, layer)
		$Content/Tabs.add_child(items_node)
		items_node.connect("item_selected", self, "on_item_selected")
		items_node.connect("item_none", self, "on_item_none")
	for layer in LAYERS_ACTUAL_ORDER:
		var t := TextureRect.new()
		t.name = layer
		$VC/Viewport/Base.add_child(t)
		t.use_parent_material = true
		
	dir.open(SAVE_PATH)
	dir.list_dir_begin(false, false)
	var file := dir.get_next()
	while file:
		if file.ends_with(".ini"):
			saves.append(SAVE_PATH + file)
		file = dir.get_next()
	dir.list_dir_end()
	saves.invert()
	var i = 0
	while i < saves.size():
		var config_file := ConfigFile.new()
		if not config_file.load(saves[i]) == OK:
			saves.remove(i)
			continue
		var s := Save.instance()
		$SaveLoad/Scroll/VBox.add_child_below_node($SaveLoad/Scroll/VBox/New, s)
		var date: Dictionary = config_file.get_value("metadata", "date", {})
		var n: String = config_file.get_value("metadata", "name", "Name")
		s.text = "%s - %04d/%02d/%02d %02d:%02d:%02d" % [n, date.year, date.month, date.day, date.hour, date.minute, date.second]
		s.get_popup().connect("id_pressed", self, "on_save_id_pressed", [s])
		i += 1


func on_save_id_pressed(id: int, s: MenuButton) -> void:
	if id == 0:
		$SaveLoad.hide()
		var config_file := ConfigFile.new()
		config_file.load(saves[s.get_index() - 1])
		var data: Dictionary = config_file.get_value("data", "items", {})
		for layer in data:
			$Content/Tabs.get_node(layer).set_item(data[layer])
		var colors: Dictionary = config_file.get_value("data", "colors", {})
		for type in colors:
			$Content/Colors/Content.get_node(type).get_child(0).color = colors[type]
			on_color_changed(colors[type], type)
	else:
		s.queue_free()
		var dir := Directory.new()
		dir.remove(saves[s.get_index() - 1])
		saves.remove(s.get_index() - 1)


func on_item_selected(path: String, type: String) -> void:
	get_node("VC/Viewport/Base/%s" % type).texture = load(path)


func on_item_none(type: String) -> void:
	get_node("VC/Viewport/Base/%s" % type).texture = null


func _on_Random_pressed() -> void:
	for layer in LAYERS_ACTUAL_ORDER:
		get_node("Content/Tabs/%s" % layer).get_random_item()
	for color in $Content/Colors/Content.get_children():
		var c := Color(randf(), randf(), randf(), 1.0)
		color.get_child(0).color = c
		on_color_changed(c, color.name)


func on_color_changed(color: Color, n: String) -> void:
	var snek := n.to_lower().replace(" ", "_")
	for i in COLORS[snek]:
		$VC/Viewport/Base.material.set("shader_param/new_%s_color_%s" % [snek, i], color.darkened(0.25 * i))
		ITEM_SHADER.set("shader_param/new_%s_color_%s" % [snek, i], color.darkened(0.25 * i))


func _on_Clear_All_pressed() -> void:
	for layer in LAYERS_ACTUAL_ORDER:
		get_node("Content/Tabs/%s" % layer).set_none()


func _on_SaveLoad_pressed() -> void:
	$SaveLoad.popup_centered()


func _on_New_pressed() -> void:
	$Name.popup_centered()


func _on_OK_pressed() -> void:
	var items = {}
	for layer in LAYERS_ACTUAL_ORDER:
		if $VC/Viewport/Base.get_node(layer).texture == null:
			items[layer] = ""
		else:
			items[layer] = $VC/Viewport/Base.get_node(layer).texture.resource_path
	var colors = {}
	for child in $Content/Colors/Content.get_children():
		colors[child.name] = child.get_child(0).color
	var n = $Name/VBoxContainer/LineEdit.text
	if not n:
		n = "Name"
	var date := Time.get_datetime_dict_from_system()
	var config_file := ConfigFile.new()
	config_file.set_value("metadata", "date", date)
	config_file.set_value("metadata", "name", n)
	config_file.set_value("data", "items", items)
	config_file.set_value("data", "colors", colors)
	var path := SAVE_PATH + str(Time.get_unix_time_from_system()) + str(Time.get_ticks_usec()) + ".ini"
	config_file.save(path)
	var s := Save.instance()
	$SaveLoad/Scroll/VBox.add_child_below_node($SaveLoad/Scroll/VBox/New, s)
	s.text = "%s - %04d/%02d/%02d %02d:%02d:%02d" % [n, date.year, date.month, date.day, date.hour, date.minute, date.second]
	s.get_popup().connect("id_pressed", self, "on_save_id_pressed", [s])
	saves.push_front(path)


func _on_LineEdit_text_entered(_new_text: String) -> void:
	$Name.hide()
	_on_OK_pressed()


func _on_DeleteAll_pressed() -> void:
	for child in $SaveLoad/Scroll/VBox.get_children():
		if not child.name == "New" and not child.name == "DeleteAll":
			child.queue_free()
	var dir := Directory.new()
	for save in saves:
		dir.remove(save)
	saves = []


func _on_Download_pressed() -> void:
	var img: Image = $VC/Viewport.get_texture().get_data()
	img.flip_y()
	HTML5File.save_image(img, "furry.png")
