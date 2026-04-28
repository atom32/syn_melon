extends Control

## 主菜单场景

# UI 引用
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var high_score_label: Label = $VBoxContainer/HighScoreLabel
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton


func _ready() -> void:
	# 连接按钮信号
	start_button.pressed.connect(_on_start_button)
	quit_button.pressed.connect(_on_quit_button)

	# 加载并显示最高分
	_load_high_score()

	# 通知场景管理器加载完成
	var scene_mgr = get_node("/root/SceneManager")
	scene_mgr.on_scene_loaded()

	print("[MainMenu] 主菜单初始化完成")


## 开始游戏按钮回调
func _on_start_button() -> void:
	print("[MainMenu] 点击开始游戏")
	var scene_mgr = get_node("/root/SceneManager")
	scene_mgr.change_scene("res://scenes/main/MainGame.tscn")


## 退出游戏按钮回调
func _on_quit_button() -> void:
	print("[MainMenu] 点击退出游戏")
	var scene_mgr = get_node("/root/SceneManager")
	scene_mgr.quit_game()


## 加载最高分
func _load_high_score() -> void:
	var save_mgr = get_node("/root/SaveManager")
	var high_score = save_mgr.get_high_score()

	if high_score_label:
		high_score_label.text = "最高分: %d" % high_score

	print("[MainMenu] 最高分: ", high_score)
