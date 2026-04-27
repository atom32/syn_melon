extends Control

## ==========================================
## 🖱️ CrossScreenDragManager - 跨屏拖拽管理器
## ==========================================
## 接收 Fruit 发送的拖拽信号

var _main_game: Node = null
var _dragged_unit: Node2D = null
var _ghost_sprite: Sprite2D = null
var _is_dragging: bool = false


func _ready() -> void:
	_main_game = get_parent()
	if not _main_game:
		push_error("[CrossScreenDrag] 无法获取 MainGame 引用")
		return

	print("[CrossScreenDrag] ✅ 跨屏拖拽管理器初始化完成")
	print("[CrossScreenDrag] 📝 操作方式：右键点击水果拖到右侧战场")


## 连接水果信号
func _on_fruit_spawned(fruit: Node) -> void:
	if fruit is Fruit:
		if not fruit.drag_to_battle_requested.is_connected(_on_drag_requested):
			fruit.drag_to_battle_requested.connect(_on_drag_requested)


## 处理拖拽请求
func _on_drag_requested(fruit: Fruit) -> void:
	print("[CrossScreenDrag] 收到拖拽请求: ", fruit.name)

	_dragged_unit = fruit
	_is_dragging = true

	# 创建虚影
	var mouse_pos = get_global_mouse_position()
	_create_ghost(mouse_pos)

	# 隐藏原水果
	fruit.visible = false
	fruit.freeze = true

	print("[CrossScreenDrag] 开始拖拽")


func _input(event: InputEvent) -> void:
	# 只在拖拽状态下处理鼠标移动和右键松开
	if not _is_dragging:
		return

	if event is InputEventMouseMotion:
		_update_ghost_position(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if not event.pressed:
			_end_drag(event.position)


func _update_ghost_position(pos: Vector2) -> void:
	if _ghost_sprite:
		_ghost_sprite.global_position = pos


## 结束拖拽
func _end_drag(screen_pos: Vector2) -> void:
	print("[CrossScreenDrag] 结束拖拽，位置: ", screen_pos)

	if not _dragged_unit:
		_cancel_drag()
		return

	# 检查是否在右侧区域
	if _main_game.is_position_in_right_area(screen_pos):
		_deploy_to_battle(screen_pos)
	else:
		_cancel_drag()


## 部署到战场
func _deploy_to_battle(screen_pos: Vector2) -> void:
	var battle_pos = _main_game.get_right_world_position(screen_pos)
	var battle_area = _main_game.get_battle_area()

	if not battle_area:
		_cancel_drag()
		return

	# 获取单位等级
	var unit_level = 0
	if _dragged_unit.has_method("get_level"):
		unit_level = _dragged_unit.level

	# 在战斗区域创建部署标记
	_create_deployment_marker(battle_area, battle_pos, unit_level)

	# 删除原水果
	if is_instance_valid(_dragged_unit):
		_dragged_unit.queue_free()

	# 清理
	_cleanup_ghost()
	_reset_state()

	print("[CrossScreenDrag] ✅ 部署到战场: 等级 ", unit_level)


## 取消拖拽
func _cancel_drag() -> void:
	print("[CrossScreenDrag] 取消拖拽")

	if _dragged_unit and is_instance_valid(_dragged_unit):
		_dragged_unit.visible = true
		_dragged_unit.freeze = false

	_cleanup_ghost()
	_reset_state()


## 重置状态
func _reset_state() -> void:
	_is_dragging = false
	_dragged_unit = null


## 创建虚影
func _create_ghost(screen_pos: Vector2) -> void:
	_ghost_sprite = Sprite2D.new()
	_ghost_sprite.position = screen_pos
	_ghost_sprite.modulate = Color(1, 1, 1, 0.7)
	_ghost_sprite.z_index = 1000

	var texture = null
	var unit_scale = Vector2(1, 1)

	if _dragged_unit.has_node("Sprite2D"):
		var unit_sprite = _dragged_unit.get_node("Sprite2D")
		if unit_sprite is Sprite2D and unit_sprite.texture:
			texture = unit_sprite.texture
			unit_scale = unit_sprite.scale

	if texture:
		_ghost_sprite.texture = texture
		_ghost_sprite.scale = unit_scale
	else:
		var radius = 30.0
		var image = Image.create(int(radius * 2), int(radius * 2), false, Image.FORMAT_RGBA8)
		image.fill(Color(1, 0.5, 0.5, 0.7))
		texture = ImageTexture.create_from_image(image)
		_ghost_sprite.texture = texture

	add_child(_ghost_sprite)


## 清理虚影
func _cleanup_ghost() -> void:
	if _ghost_sprite and is_instance_valid(_ghost_sprite):
		_ghost_sprite.queue_free()
		_ghost_sprite = null


## 创建部署标记
func _create_deployment_marker(battle_area: Node, position: Vector2, level: int) -> void:
	var marker = ColorRect.new()
	marker.size = Vector2(50, 50)
	marker.position = position - Vector2(25, 25)

	var colors = [
		Color(1, 0.2, 0.2),
		Color(1, 0.4, 0.7),
		Color(0.6, 0.2, 0.8),
		Color(1, 0.6, 0),
		Color(1, 0.4, 0.2)
	]

	var color_idx = min(level, colors.size() - 1)
	marker.color = colors[color_idx]

	battle_area.add_child(marker)

	var label = Label.new()
	label.text = "Lv%d" % level
	label.position = Vector2(5, 5)
	label.add_theme_font_size_override("font_size", 16)
	label.z_index = 1
	marker.add_child(label)
