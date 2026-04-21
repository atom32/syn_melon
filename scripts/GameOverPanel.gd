class_name GameOverPanel
extends Panel

## 游戏结束结算面板

signal restart_requested

var score_label: Label = null
var restart_button: Button = null


func _ready() -> void:
	# 获取节点引用（添加延时确保场景树已准备好）
	await ready

	score_label = $VBoxContainer/ScoreLabel
	restart_button = $VBoxContainer/RestartButton

	# 调试：检查节点是否找到
	print("GameOverPanel _ready - score_label:", score_label != null, "restart_button:", restart_button != null)

	# 居中显示
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	size = Vector2(400, 300)

	# 设置面板样式
	add_theme_stylebox_override("panel", get_panel_style())

	# 连接按钮信号
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

	# 初始隐藏
	visible = false


func show_game_over(final_score: int) -> void:
	# 安全检查
	if not score_label:
		print("错误：score_label 为 null！")
		return

	score_label.text = "最终得分: %d" % final_score
	visible = true

	# 获取焦点以便按 Enter 键可以重新开始
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


func get_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.5, 0.5, 0.6, 1)
	return style
