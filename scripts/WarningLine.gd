extends Area2D

## 警戒线 - 失败判定

# 检测到的水果及其进入时间
var _detected_fruits: Dictionary = {}

# 超时时间（秒）
const TIMEOUT_TIME: float = 2.0

# 排除刚发射的水果的冷却时间
const SPAWN_COOLDOWN: float = 0.5


func _ready() -> void:
	# 设置碰撞层和遮罩
	collision_layer = 8        # 警戒线在第 8 层
	collision_mask = 8         # 检测第 8 层的物体（水果的探测器）

	# 开启监控
	monitoring = true         # 主动检测进入的 Area2D
	monitorable = false       # 不需要被其他 Area2D 检测

	# 监控区域
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	print("警戒线：初始化完成")
	print("警戒线：position =", position)
	print("警戒线：collision_layer =", collision_layer)
	print("警戒线：collision_mask =", collision_mask)
	print("警戒线：monitoring =", monitoring)


## 水果进入警戒区域
func _on_area_entered(area: Area2D) -> void:
	print("警戒线：检测到 Area2D 进入")

	# 检查是否是水果的碰撞区域
	var fruit = _get_fruit_from_area(area)
	if not fruit:
		print("警戒线：不是水果的探测器，忽略")
		return

	print("警戒线：检测到水果等级 %d，冷却时间: %.2f" % [fruit.level, fruit._spawn_cooldown])

	# 检查是否在冷却期内
	if fruit._spawn_cooldown > SPAWN_COOLDOWN:
		print("警戒线：水果在冷却期内，忽略")
		return

	# 如果已经在追踪中，重置计时器
	if fruit in _detected_fruits:
		_detected_fruits[fruit] = Time.get_ticks_msec()
		print("警戒线：重置计时器")
	else:
		# 开始追踪这个水果
		_detected_fruits[fruit] = Time.get_ticks_msec()
		print("警戒线：开始计时")


## 水果离开警戒区域
func _on_area_exited(area: Area2D) -> void:
	var fruit = _get_fruit_from_area(area)
	if not fruit:
		return

	# 停止追踪这个水果
	if fruit in _detected_fruits:
		_detected_fruits.erase(fruit)
		print("警戒线：水果等级 %d 离开区域" % fruit.level)


## 从 Area2D 获取 Fruit 节点
func _get_fruit_from_area(area: Area2D):
	if not area:
		print("警戒线：area 是 null")
		return null

	print("警戒线：area 名称:", area.name, "类型:", area.get_class())

	# area 参数是进入的 Area2D（DetectorArea）
	# DetectorArea 的父节点就是 RigidBody2D (Fruit)
	if area.get_parent():
		var parent = area.get_parent()
		print("警戒线：父节点:", parent.name if parent else "null", "类型:", parent.get_class() if parent else "null")
		if parent and parent is Fruit:
			print("警戒线：找到 Fruit！等级:", parent.level)
			return parent

	print("警戒线：未找到 Fruit")
	return null


## 物理更新中检测超时
func _physics_process(delta: float) -> void:
	# 调试：每 60 帧打印一次状态
	if Engine.get_process_frames() % 60 == 0:
		print("警戒线：正在监控，追踪的水果数:", _detected_fruits.size())

	var current_time = Time.get_ticks_msec()

	# 检查所有追踪的水果
	var fruits_to_remove = []

	for fruit in _detected_fruits:
		# 检查水果是否仍然有效
		if not is_instance_valid(fruit):
			fruits_to_remove.append(fruit)
			continue

		# 检查水果是否已经被合并（不在场景树中）
		if not fruit.is_inside_tree():
			fruits_to_remove.append(fruit)
			continue

		# 检查是否还在冷却期
		if fruit._spawn_cooldown > SPAWN_COOLDOWN:
			fruits_to_remove.append(fruit)
			continue

		# 计算停留时间
		var entry_time = _detected_fruits[fruit]
		var elapsed = _calculate_elapsed_time(entry_time, current_time)

		# 调试：显示停留时间（每 60 帧）
		if Engine.get_process_frames() % 60 == 0:
			print("警戒线：水果等级 %d 已停留 %.2f 秒" % [fruit.level, elapsed])

		if elapsed >= TIMEOUT_TIME:
			# 触发游戏结束
			_trigger_game_over(fruit)
			fruits_to_remove.append(fruit)

	# 清理无效的水果
	for fruit in fruits_to_remove:
		_detected_fruits.erase(fruit)


## 计算经过的时间（秒）
func _calculate_elapsed_time(start_time: int, end_time: int) -> float:
	var elapsed_ms = end_time - start_time
	return elapsed_ms / 1000.0


## 触发游戏结束
func _trigger_game_over(fruit: Fruit) -> void:
	print("=" .repeat(50))
	print("游戏结束！水果等级 %d 在警戒线停留超过 %.1f 秒" % [fruit.level, TIMEOUT_TIME])
	print("=" .repeat(50))

	# 发射游戏结束信号
	var gm = get_node("/root/GameManager")
	gm.game_over.emit()

	# 暂停物理引擎
	get_tree().paused = true
