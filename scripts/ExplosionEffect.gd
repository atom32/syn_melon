extends Node2D

## 简单爆炸特效 - 合成反馈

# 爆炸粒子数量
const PARTICLE_COUNT: int = 24

# 爆炸速度
const SPEED_MIN: float = 100.0
const SPEED_MAX: float = 200.0

# 存活时间
const LIFETIME: float = 1.0


func _ready() -> void:
	pass


## 触发爆炸特效
func explode(color: Color, position: Vector2) -> void:
	global_position = position

	# 确保 z_index 足够高，显示在所有水果前面
	z_index = 999

	# 创建爆炸粒子
	for i in range(PARTICLE_COUNT):
		_create_particle(color, i)

	# 设置自动销毁
	var timer = get_tree().create_timer(LIFETIME + 0.1)
	timer.timeout.connect(_on_finished)

	print("爆炸特效触发，颜色:", color, "粒子数:", PARTICLE_COUNT)


## 创建单个粒子
func _create_particle(color: Color, index: int) -> void:
	var sprite = ColorRect.new()
	sprite.size = Vector2(12, 12)  # 增大粒子
	sprite.color = color

	# 设置极高的 z_index 确保粒子显示在最上层
	sprite.z_index = 10000

	# 计算随机方向和速度
	var angle = randf() * TAU  # 0 到 360 度
	var speed = randf_range(SPEED_MIN, SPEED_MAX)
	var velocity = Vector2.from_angle(angle) * speed

	# 设置初始位置
	sprite.global_position = global_position

	# 创建节点来控制这个粒子
	var particle_node = Node2D.new()
	particle_node.add_child(sprite)
	add_child(particle_node)

	# 使用 Tween 动画
	var tween = particle_node.create_tween()
	tween.set_parallel()

	# 移动
	tween.tween_property(sprite, "global_position", sprite.global_position + velocity, LIFETIME)

	# 缩小到消失
	tween.tween_property(sprite, "scale", Vector2.ZERO, LIFETIME)

	# 透明度渐变
	tween.tween_property(sprite, "modulate:a", 0.0, LIFETIME)

	# 完成后清理
	tween.tween_callback(_on_particle_finished.bind(particle_node))


## 粒子动画完成
func _on_particle_finished(particle_node: Node2D) -> void:
	particle_node.queue_free()


## 特效完成回调
func _on_finished() -> void:
	queue_free()
