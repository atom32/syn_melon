extends Panel

## 游戏结束结算面板

signal restart_requested

var title_label: Label = null
var score_label: Label = null
var restart_button: Button = null


func _ready() -> void:
	# 等待场景完全准备好
	await ready

	# 动态创建 UI 元素
	_setup_ui()

	# 初始隐藏
	visible = false


func _setup_ui() -> void:
	# 创建 VBoxContainer
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.position = Vector2(-150, -100)
	vbox.size = Vector2(300, 200)
	vbox.theme_override_constants/separation = 30
	add_child(vbox)

	# 创建标题
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "游戏结束"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.theme_override_font_sizes/font_size = 48
	title_label.size = Vector2(300, 60)
	vbox.add_child(title_label)

	# 创建分数标签
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "最终得分: 0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.theme_override_font_sizes/font_size = 32
	score_label.size = Vector2(300, 50)
	vbox.add_child(score_label)

	# 创建重新开始按钮
	restart_button = Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "重新开始 (Restart)"
	restart_button.theme_override_font_sizes/font_size = 24
	restart_button.size = Vector2(300, 60)
	restart_button.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_button)

	print("GameOverPanel UI 创建完成")


func show_game_over(final_score: int) -> void:
	if score_label:
		score_label.text = "最终得分: %d" % final_score

	visible = true

	if restart_button:
		restart_button.grab_focus()

	print("游戏结束！显示结算面板，得分:", final_score)


func hide_panel() -> void:
	visible = false


func _on_restart_pressed() -> void:
	print("重新开始游戏")
	hide_panel()
	restart_requested.emit()
	get_tree().reload_current_scene()
