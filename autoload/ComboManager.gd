extends Node

## 连击管理器 - 单例
## 管理连击计数、时间窗口和分数乘数

# 信号
signal combo_activated(count: int, multiplier: float, position: Vector2)
signal combo_reset()

# 连击配置
const COMBO_TIME_WINDOW: float = 1.5  # 判定时间窗口（秒）
const COMBO_DECAY_TIME: float = 0.5   # 连击结束后的延迟时间

# 连击状态
var combo_count: int = 0        # 当前连击数
var combo_timer: float = 0.0    # 连击计时器
var is_active: bool = false     # 是否在连击窗口内
var decay_timer: float = 0.0    # 衰减计时器（连击结束后延迟重置）

# 当前连击乘数
var current_multiplier: float = 1.0


func _ready() -> void:
	# 设置每帧处理
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if is_active:
		# 连击窗口倒计时
		combo_timer -= delta
		if combo_timer <= 0:
			# 连击窗口结束，开始衰减
			is_active = false
			decay_timer = COMBO_DECAY_TIME
			print("连击窗口结束，连击数：%d，总乘数：%.1f" % [combo_count, current_multiplier])

	elif decay_timer > 0:
		# 衰减计时器倒计时
		decay_timer -= delta
		if decay_timer <= 0:
			# 完全重置连击
			_reset_combo()


## 触发连击（当合成发生时调用）
func trigger_merge(merge_position: Vector2) -> float:
	# 增加连击计数
	combo_count += 1

	# 计算乘数
	current_multiplier = _calculate_multiplier(combo_count)

	# 重置连击窗口计时器
	combo_timer = COMBO_TIME_WINDOW
	is_active = true
	decay_timer = 0

	# 发射连击激活信号
	combo_activated.emit(combo_count, current_multiplier, merge_position)

	print("连击触发！次数：%d，乘数：%.1f，剩余时间：%.2f秒" % [combo_count, current_multiplier, combo_timer])

	return current_multiplier


## 计算连击乘数
func _calculate_multiplier(count: int) -> float:
	# 2次: x1.5
	# 3次: x2.0
	# 4次: x2.5
	# 5次及以上: x3.0
	if count <= 1:
		return 1.0
	elif count == 2:
		return 1.5
	elif count == 3:
		return 2.0
	elif count == 4:
		return 2.5
	else:
		return 3.0


## 获取当前连击信息
func get_combo_info() -> Dictionary:
	return {
		"count": combo_count,
		"multiplier": current_multiplier,
		"is_active": is_active,
		"time_remaining": combo_timer if is_active else 0.0
	}


## 重置连击
func _reset_combo() -> void:
	if combo_count > 1:
		print("连击重置，最高连击数：%d" % combo_count)
		combo_reset.emit()

	combo_count = 0
	current_multiplier = 1.0
	combo_timer = 0
	is_active = false
	decay_timer = 0


## 手动重置连击（用于游戏重新开始）
func reset() -> void:
	_reset_combo()
