extends Panel

## 游戏结束结算面板

signal restart_requested

var title_label: Label = null
var score_label: Label = null
var restart_button: Button = null
var menu_button: Button = null


func _ready() -> void:
	# 等待场景完全准备好
	await ready

	# 设置面板自身居中
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	size = Vector2(400, 300)

	# 重要：设置为在暂停时仍可处理输入
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 动态创建 UI 元素
	_setup_ui()

	# 初始隐藏
	visible = false


func _setup_ui() -> void:
	# 创建 VBoxContainer（使用相对布局）
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"

	# 设置 anchors 为全填充，然后通过 offsets 居中
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 50
	vbox.offset_top = 50
	vbox.offset_right = -50
	vbox.offset_bottom = -50

	# 或者直接设置大小和居中
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-150, -100)
	vbox.size = Vector2(300, 200)

	vbox.add_theme_constant_override("separation", 30)
	add_child(vbox)

	print("GameOverPanel: VBoxContainer 创建完成，连接按钮信号...")

	# 创建标题
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "游戏结束"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.size = Vector2(300, 60)
	vbox.add_child(title_label)

	# 创建分数标签
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "最终得分: 0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.size = Vector2(300, 50)
	vbox.add_child(score_label)

	# 创建重新开始按钮
	restart_button = Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "重新开始 (Restart)"
	restart_button.add_theme_font_size_override("font_size", 24)
	restart_button.size = Vector2(300, 60)

	# 重要：按钮需要在暂停时工作
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS

	# 连接信号
	restart_button.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_button)

	# 创建返回主菜单按钮
	menu_button = Button.new()
	menu_button.name = "MenuButton"
	menu_button.text = "返回主菜单 (Back to Menu)"
	menu_button.add_theme_font_size_override("font_size", 24)
	menu_button.size = Vector2(300, 60)

	# 重要：按钮需要在暂停时工作
	menu_button.process_mode = Node.PROCESS_MODE_ALWAYS

	# 连接信号
	menu_button.pressed.connect(_on_menu_button_pressed)
	vbox.add_child(menu_button)

	print("GameOverPanel UI 创建完成，按钮节点:", restart_button, menu_button)


func show_game_over(final_score: int) -> void:
	if score_label:
		score_label.text = "最终得分: %d" % final_score

	visible = true

	if restart_button:
		restart_button.grab_focus()
		print("GameOverPanel: 按钮已获得焦点，可按 Enter 或点击")

	print("游戏结束！显示结算面板，得分:", final_score)


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		# 按 R 键重新开始
		if event.keycode == KEY_R:
			print("[GameOverPanel] 检测到 R 键，触发重新开始")
			_on_restart_pressed()
		# 按 ESC 键返回主菜单
		elif event.keycode == KEY_ESCAPE:
			print("[GameOverPanel] 检测到 ESC 键，返回主菜单")
			_on_menu_button_pressed()


func hide_panel() -> void:
	visible = false


func _on_restart_pressed() -> void:
	print("[GameOverPanel] 重新开始游戏按钮被点击")

	# 先取消暂停（非常重要！）
	get_tree().paused = false

	# 延迟一帧确保暂停状态完全解除
	await get_tree().process_frame

	var scene_mgr = get_node("/root/SceneManager")
	if scene_mgr:
		scene_mgr.change_scene("res://scenes/Main.tscn")
		print("[GameOverPanel] SceneManager 调用完成")
	else:
		print("[GameOverPanel] 错误：找不到 SceneManager")


func _on_menu_button_pressed() -> void:
	print("[GameOverPanel] 返回主菜单按钮被点击")

	# 先取消暂停（非常重要！）
	get_tree().paused = false

	# 延迟一帧确保暂停状态完全解除
	await get_tree().process_frame

	var scene_mgr = get_node("/root/SceneManager")
	if scene_mgr:
		scene_mgr.change_scene("res://scenes/MainMenu.tscn")
		print("[GameOverPanel] SceneManager 调用完成")
	else:
		print("[GameOverPanel] 错误：找不到 SceneManager")
