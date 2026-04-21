extends Node2D

## 合成大西瓜 - 主场景脚本

# 发射器位置
const SPAWN_Y: float = 150.0

# 边界限制（动态计算）
var X_MIN_LIMIT: float = 0.0
var X_MAX_LIMIT: float = 0.0

# 边界安全距离（px）
const WALL_MARGIN: float = 10.0

# 发射冷却时间（秒）
const COOLDOWN_TIME: float = 0.5

# UI 引用
@onready var ui_label_next: Label = $UIBackground/NextLabel
@onready var ui_label_score: Label = $UIBackground/ScoreLabel
@onready var ui_preview_container: Control = $UIBackground/PreviewContainer
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var game_over_panel: Panel = $GameOverPanel

# 当前预览水果（跟随鼠标）
var _preview_fruit: Fruit = null

# UI 预览水果（固定在 UI 上）
var _ui_preview_fruit: Fruit = null

# 水果场景引用
var _fruit_scene: PackedScene = preload("res://scenes/Fruit.tscn")

# 是否可以发射
var _can_spawn: bool = true


func _ready() -> void:
	# 设置冷却计时器
	cooldown_timer.wait_time = COOLDOWN_TIME
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_finished)

	# 动态计算游戏边界
	_calculate_game_boundaries()

	# 延迟连接 GameManager 信号（避免 autoload 初始化问题）
	call_deferred("_connect_game_manager_signals")

	# 更新初始 UI
	_update_ui()


## 动态计算游戏边界（基于墙壁碰撞体）
func _calculate_game_boundaries() -> void:
	# 获取左右墙的碰撞形状
	var left_wall = $LeftWall/CollisionShape2D
	var right_wall = $RightWall/CollisionShape2D

	if not left_wall or not right_wall:
		push_error("无法找到墙壁碰撞体！使用默认边界")
		X_MIN_LIMIT = 100.0
		X_MAX_LIMIT = 1050.0
		return

	# 获取碰撞形状和全局位置
	var left_shape = left_wall.shape as RectangleShape2D
	var right_shape = right_wall.shape as RectangleShape2D

	var left_global_pos = left_wall.global_position
	var right_global_pos = right_wall.global_position

	# 计算实际碰撞边界（碰撞形状是矩形，中心在global_position）
	var left_wall_inner = left_global_pos.x + left_shape.size.x / 2.0
	var right_wall_inner = right_global_pos.x - right_shape.size.x / 2.0

	# 设置边界（留出安全距离）
	X_MIN_LIMIT = left_wall_inner + WALL_MARGIN
	X_MAX_LIMIT = right_wall_inner - WALL_MARGIN

	print("Main.gd: 动态计算边界")
	print("  左墙内边界: %.1f, 右墙内边界: %.1f" % [left_wall_inner, right_wall_inner])
	print("  X范围: %.1f 到 %.1f" % [X_MIN_LIMIT, X_MAX_LIMIT])


func _process(delta: float) -> void:
	# 如果有预览水果，跟随鼠标移动
	if _preview_fruit and _preview_fruit.is_inside_tree():
		var mouse_pos = get_global_mouse_position()
		var clamped_x = clamp(mouse_pos.x, X_MIN_LIMIT, X_MAX_LIMIT)
		_preview_fruit.global_position = Vector2(clamped_x, SPAWN_Y)


## 冷却结束回调
func _on_cooldown_finished() -> void:
	_can_spawn = true
	print("Main.gd: 冷却结束，可以再次发射")


## 连接 GameManager 信号
func _connect_game_manager_signals() -> void:
	# 检查 GameManager 是否存在
	if not has_node("/root/GameManager"):
		push_error("GameManager autoload not found!")
		return

	var gm = get_node("/root/GameManager")
	gm.fruit_spawned.connect(_on_fruit_spawned)
	gm.fruit_merged.connect(_on_fruit_merged)
	gm.score_changed.connect(_on_score_changed)
	gm.game_over.connect(_on_game_over)


func _input(event: InputEvent) -> void:
	# 只处理鼠标左键
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return

	# 检查是否在 UI 区域内
	if event.position.y <= 100:
		return

	# 按下鼠标：创建预览水果
	if event.pressed:
		_on_mouse_pressed(event.position.x)
	# 松开鼠标：发射水果
	else:
		_on_mouse_released()


## 鼠标按下处理
func _on_mouse_pressed(x_position: float) -> void:
	# 检查冷却状态
	if not _can_spawn:
		print("Main.gd: 冷却中，无法生成预览水果")
		return

	# 检查是否已有预览水果
	if _preview_fruit and is_instance_valid(_preview_fruit):
		print("Main.gd: 已有预览水果")
		return

	# 创建预览水果
	var gm = get_node("/root/GameManager")
	_preview_fruit = gm.spawn_fruit(Vector2(0, SPAWN_Y))
	add_child(_preview_fruit)

	# 冻结物理（不受重力影响）
	_preview_fruit.freeze = true

	# 设置初始位置
	var clamped_x = clamp(x_position, X_MIN_LIMIT, X_MAX_LIMIT)
	_preview_fruit.global_position = Vector2(clamped_x, SPAWN_Y)

	print("Main.gd: 创建预览水果等级 %d 在 x=%.0f" % [_preview_fruit.level, clamped_x])


## 鼠标松开处理
func _on_mouse_released() -> void:
	# 检查是否有预览水果
	if not _preview_fruit or not is_instance_valid(_preview_fruit):
		return

	# 解冻物理
	_preview_fruit.freeze = false

	# 清空预览引用
	_preview_fruit = null

	# 开始冷却
	_can_spawn = false
	cooldown_timer.start()

	# 更新 UI 显示下一个水果
	_update_ui()

	print("Main.gd: 发射水果，开始冷却")


## 水果发射回调
func _on_fruit_spawned(fruit: Fruit, level: int) -> void:
	# 可以在这里添加音效、动画等
	pass


## 水果合成回调
func _on_fruit_merged(old_level: int, new_level: int, position: Vector2) -> void:
	# 可以在这里添加特效、音效等
	pass


## 分数变化回调
func _on_score_changed(new_score: int) -> void:
	ui_label_score.text = "分数: %d" % new_score


## 游戏结束回调
func _on_game_over() -> void:
	print("Main.gd: 游戏结束信号已接收")

	# 暂停游戏
	get_tree().paused = true

	# 显示游戏结束面板
	var gm = get_node("/root/GameManager")
	var final_score = gm.get_score()
	game_over_panel.call("show_game_over", final_score)


## 更新 UI 显示
func _update_ui() -> void:
	# 获取 GameManager 引用
	var gm = get_node("/root/GameManager")

	# 更新下一个水果文本（显示当前待发射的）
	var next_level: int = gm.get_current_fruit_level()
	var fruit_names: Array = ["樱桃", "草莓", "葡萄", "橙子", "柿子", "桃子", "菠萝", "椰子", "半个西瓜", "大西瓜", "超级大西瓜"]
	ui_label_next.text = "下一个: %s" % fruit_names[next_level]

	# 更新 UI 预览水果
	if _ui_preview_fruit and is_instance_valid(_ui_preview_fruit):
		_ui_preview_fruit.queue_free()

	_ui_preview_fruit = _fruit_scene.instantiate()
	_ui_preview_fruit.level = next_level
	_ui_preview_fruit.freeze = true

	# 将水果放置在容器中心
	var container_size = ui_preview_container.size
	_ui_preview_fruit.position = Vector2(container_size.x / 2, container_size.y / 2)

	ui_preview_container.add_child(_ui_preview_fruit)
