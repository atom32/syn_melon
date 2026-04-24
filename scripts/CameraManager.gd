extends Camera2D

## 摄像机管理器 - 处理屏幕震动效果

# 震动参数
const SHAKE_DURATION: float = 0.6   # 震动持续时间（秒）
const SHAKE_MAX_OFFSET: float = 30.0  # 最大震动偏移量（像素）

# 震动状态
var _is_shaking: bool = false
var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0
var _original_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	# 保存原始偏移量
	_original_offset = offset

	# 订阅 EventBus 事件
	var event_bus = get_node("/root/EventBus")
	event_bus.fruit_merged.connect(_on_fruit_merged)
	event_bus.mega_fruit_merged.connect(_on_mega_fruit_merged)

	print("[CameraManager] 初始化完成，已订阅 EventBus 事件")


func _process(delta: float) -> void:
	if not _is_shaking:
		return

	# 震动计时器递减
	_shake_timer -= delta

	# 计算当前震动强度（随时间衰减）
	var current_intensity = _shake_intensity * (_shake_timer / SHAKE_DURATION)

	# 如果震动时间结束
	if _shake_timer <= 0:
		_is_shaking = false
		_shake_intensity = 0.0

		# 恢复原始位置
		offset = _original_offset

		print("[CameraManager] 震动结束")
		return

	# 计算随机偏移
	var max_offset = SHAKE_MAX_OFFSET * current_intensity
	var random_x = randf_range(-max_offset, max_offset)
	var random_y = randf_range(-max_offset, max_offset)

	# 应用偏移
	offset = _original_offset + Vector2(random_x, random_y)


## 普通合成震动
func _on_fruit_merged(old_level: int, new_level: int, position: Vector2) -> void:
	# 只在等级 >= 5 时震动
	if new_level < 5:
		return

	# 根据等级计算震动强度（等级越高，震动越大）
	# Level 5: 0.4, Level 6: 0.5, Level 7: 0.6, Level 8: 0.7, Level 9: 0.8, Level 10: 0.9
	var intensity = 0.4 + ((new_level - 5) * 0.1)

	print("[CameraManager] 普通震动 等级", new_level, "强度:", intensity)

	start_shake(intensity)


## 超大合成震动
func _on_mega_fruit_merged(position: Vector2) -> void:
	# 超大合成触发剧烈震动
	print("[CameraManager] 超大震动！强度: 1.2")

	start_shake(1.2)


## 开始震动
func start_shake(intensity: float) -> void:
	# 如果已经在震动，且新强度更大，则覆盖
	if _is_shaking and intensity <= _shake_intensity:
		return

	_shake_intensity = intensity
	_shake_timer = SHAKE_DURATION
	_is_shaking = true

	print("[CameraManager] 开始震动，强度:", intensity)


## 立即触发一次性震动（例如爆炸冲击）
func impulse_shake(intensity: float) -> float:
	"""立即施加一次震动冲击，返回施加的偏移量"""
	var max_offset = SHAKE_MAX_OFFSET * 1.5 * intensity
	var random_x = randf_range(-max_offset, max_offset)
	var random_y = randf_range(-max_offset, max_offset)
	var offset_vector = Vector2(random_x, random_y)

	offset += offset_vector

	# 短暂恢复到原位（模拟冲击后的回弹）
	var tween = create_tween()
	tween.tween_property(self, "offset", _original_offset, 0.1)

	print("[CameraManager] 冲击震动 强度:", intensity)

	return offset_vector.length()
