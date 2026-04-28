extends Node2D

## ==========================================
## 🍎 MergeArea - 合并区域控制器
## ==========================================
## 管理水果的生成、合成和物理模拟
## 与 Main.gd 类似，但移除 UI 逻辑（UI 在 MainGame.UILayer）

## 常量
const SPAWN_Y: float = 150.0
const WALL_MARGIN: float = 10.0
const COOLDOWN_TIME: float = 0.5

## 边界
var X_MIN_LIMIT: float = 0.0
var X_MAX_LIMIT: float = 0.0

## 状态
var _can_spawn: bool = true
var _preview_fruit: Fruit = null

## 场景引用
var cooldown_timer: Timer = null

## 信号（用于与 MainGame 通信）
signal fruit_spawned(fruit: Fruit, level: int)
signal fruit_merged(old_level: int, new_level: int, position: Vector2)


func _ready() -> void:
	print("[MergeArea] 初始化合并区域...")

	# 获取 Timer 节点引用
	cooldown_timer = $CooldownTimer
	if not cooldown_timer:
		push_error("[MergeArea] CooldownTimer 节点未找到！")
		return

	# 设置冷却计时器
	cooldown_timer.wait_time = COOLDOWN_TIME
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooling_finished)

	# 计算边界
	_calculate_game_boundaries()

	# 连接 EventBus
	_connect_eventbus_signals()

	# 初始化
	_update_preview()

	print("[MergeArea] ✅ 合并区域初始化完成")


func _process(delta: float) -> void:
	# 预览水果跟随鼠标
	if _preview_fruit and _preview_fruit.is_inside_tree():
		var local_mouse_pos = get_local_mouse_position()
		var clamped_x = clamp(local_mouse_pos.x, X_MIN_LIMIT, X_MAX_LIMIT)
		_preview_fruit.global_position = Vector2(clamped_x, SPAWN_Y)


## 计算游戏边界
func _calculate_game_boundaries() -> void:
	var left_wall = $LeftWall/CollisionShape2D
	var right_wall = $RightWall/CollisionShape2D

	if not left_wall or not right_wall:
		push_error("[MergeArea] 无法找到墙壁碰撞体！")
		X_MIN_LIMIT = 50.0
		X_MAX_LIMIT = 525.0
		return

	var left_shape = left_wall.shape as RectangleShape2D
	var right_shape = right_wall.shape as RectangleShape2D

	var left_global_pos = left_wall.global_position
	var right_global_pos = right_wall.global_position

	var left_wall_inner = left_global_pos.x + left_shape.size.x / 2.0
	var right_wall_inner = right_global_pos.x - right_shape.size.x / 2.0

	X_MIN_LIMIT = left_wall_inner + WALL_MARGIN
	X_MAX_LIMIT = right_wall_inner - WALL_MARGIN

	print("[MergeArea] 边界计算: X ∈ [%.1f, %.1f]" % [X_MIN_LIMIT, X_MAX_LIMIT])


## 输入处理
func _input(event: InputEvent) -> void:
	# 只处理鼠标左键
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return

	# 转换屏幕坐标到本地坐标
	var local_pos = get_local_mouse_position()

	# 检查是否在有效区域内
	if local_pos.y > 800 or local_pos.y < 0:
		return

	# 鼠标按下：开始预览
	if event.pressed:
		_on_mouse_pressed(local_pos.x)
	# 鼠标松开：发射
	else:
		_on_mouse_released()


## 鼠标按下
func _on_mouse_pressed(x_position: float) -> void:
	if not _can_spawn:
		return

	if _preview_fruit and is_instance_valid(_preview_fruit):
		return

	# 创建预览水果（传递 self 作为 parent）
	var gm = get_node("/root/GameManager")
	_preview_fruit = gm.spawn_fruit(Vector2(0, SPAWN_Y), self)

	_preview_fruit.freeze = true

	var clamped_x = clamp(x_position, X_MIN_LIMIT, X_MAX_LIMIT)
	_preview_fruit.global_position = Vector2(clamped_x, SPAWN_Y)

	print("[MergeArea] 创建预览水果等级 %d" % _preview_fruit.level)


## 鼠标松开
func _on_mouse_released() -> void:
	if not _preview_fruit or not is_instance_valid(_preview_fruit):
		return

	# 解冻并发射
	_preview_fruit.freeze = false
	_preview_fruit = null

	_can_spawn = false
	cooldown_timer.start()

	# 更新下一个预览
	_update_preview()

	print("[MergeArea] 发射水果")


## 冷却结束
func _on_cooling_finished() -> void:
	_can_spawn = true


## 更新预览
func _update_preview() -> void:
	# 这里可以触发信号通知 MainGame 更新 UI
	pass


## 连接 EventBus
func _connect_eventbus_signals() -> void:
	var bus = get_node("/root/EventBus")

	bus.fruit_spawned.connect(_on_fruit_spawned)
	bus.fruit_merged.connect(_on_fruit_merged)
	bus.game_over.connect(_on_game_over)


## EventBus 回调
func _on_fruit_spawned(fruit: Fruit, level: int) -> void:
	fruit_spawned.emit(fruit, level)


func _on_fruit_merged(old_level: int, new_level: int, position: Vector2) -> void:
	fruit_merged.emit(old_level, new_level, position)


func _on_game_over() -> void:
	_pause_all_fruits()


## 暂停所有水果
func _pause_all_fruits() -> void:
	var all_fruits = get_tree().get_nodes_in_group("fruits")

	for fruit in all_fruits:
		if fruit is RigidBody2D:
			fruit.freeze = true

	print("[MergeArea] 已暂停所有水果")


## 重置合并区域
func reset_merge_area() -> void:
	# 删除所有水果
	var all_fruits = get_tree().get_nodes_in_group("fruits")
	for fruit in all_fruits:
		if is_instance_valid(fruit):
			fruit.queue_free()

	# 重置状态
	_can_spawn = true
	_preview_fruit = null

	print("[MergeArea] 重置完成")


## 获取当前边界
func get_boundaries() -> Dictionary:
	return {
		"x_min": X_MIN_LIMIT,
		"x_max": X_MAX_LIMIT,
		"spawn_y": SPAWN_Y
	}
