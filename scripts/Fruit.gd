extends RigidBody2D
class_name Fruit

## 水果脚本 - 合成大西瓜

# 合成信号
signal fruit_merged(old_level: int, new_level: int, position: Vector2)

# 唯一 ID 计数器（用于防止双重触发）
static var _next_id: int = 0
var _fruit_id: int = 0

# 正在处理的合成对（防止双重触发）
static var _processing_merges: Dictionary = {}

# 合成锁（防止重复处理）
var _is_merging: bool = false

# 冷却时间（防止刚生成的水果立即合成）
var _spawn_cooldown: float = 0.0
const SPAWN_COOLDOWN_TIME: float = 0.1  # 100ms 冷却时间

# 水果场景引用
var _fruit_scene: PackedScene = preload("res://scenes/Fruit.tscn")

# 特效场景引用
var _explosion_scene: PackedScene = preload("res://scenes/ExplosionEffect.tscn")
var _floating_score_scene: PackedScene = preload("res://scenes/FloatingScore.tscn")

# 水果等级 (0-10)
@export var level: int = 0:
	set(value):
		level = clamp(value, 0, 10)
		_update_fruit_properties()

# 水果配置数据
const FRUIT_CONFIG: Dictionary = {
	0: {
		"name": "樱桃",
		"radius": 15.0,
		"mass": 1.0,
		"color": Color(1.0, 0.2, 0.2, 1.0)  # 红色
	},
	1: {
		"name": "草莓",
		"radius": 22.0,
		"mass": 2.0,
		"color": Color(1.0, 0.4, 0.7, 1.0)  # 粉色
	},
	2: {
		"name": "葡萄",
		"radius": 30.0,
		"mass": 3.0,
		"color": Color(0.6, 0.2, 0.8, 1.0)  # 紫色
	},
	3: {
		"name": "橙子",
		"radius": 38.0,
		"mass": 5.0,
		"color": Color(1.0, 0.6, 0.0, 1.0)  # 橙色
	},
	4: {
		"name": "柿子",
		"radius": 48.0,
		"mass": 8.0,
		"color": Color(1.0, 0.4, 0.2, 1.0)  # 橘红色
	},
	5: {
		"name": "桃子",
		"radius": 58.0,
		"mass": 12.0,
		"color": Color(1.0, 0.7, 0.6, 1.0)  # 桃色
	},
	6: {
		"name": "菠萝",
		"radius": 68.0,
		"mass": 18.0,
		"color": Color(1.0, 0.8, 0.2, 1.0)  # 黄色
	},
	7: {
		"name": "椰子",
		"radius": 80.0,
		"mass": 25.0,
		"color": Color(0.6, 0.4, 0.2, 1.0)  # 棕色
	},
	8: {
		"name": "半个西瓜",
		"radius": 95.0,
		"mass": 35.0,
		"color": Color(0.2, 0.7, 0.3, 1.0)  # 绿色
	},
	9: {
		"name": "大西瓜",
		"radius": 110.0,
		"mass": 50.0,
		"color": Color(0.3, 0.8, 0.4, 1.0)  # 浅绿色
	},
	10: {
		"name": "超级大西瓜",
		"radius": 130.0,
		"mass": 80.0,
		"color": Color(0.8, 1.0, 0.8, 1.0)  # 亮绿色
	}
}

# 节点引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# 分配唯一 ID
	_fruit_id = _next_id
	_next_id += 1

	# 设置碰撞层
	collision_layer = 1      # 水果在第 1 层
	collision_mask = 1       # 水果与第 1 层碰撞（其他水果和地面）

	# 创建统一的物理材质
	var physics_material = PhysicsMaterial.new()
	physics_material.friction = 0.3      # 较低的摩擦力，让水果容易滑动
	physics_material.bounce = 0.15       # 轻微弹性，有微弹效果但不会弹太高
	physics_material.rough = false       # 光滑表面

	# 应用物理材质
	physics_material_override = physics_material

	# 设置探测器区域（用于警戒线检测）
	if has_node("DetectorArea"):
		var detector = $DetectorArea
		detector.collision_layer = 8   # 探测器在第 8 层（可被警戒线检测）
		detector.collision_mask = 0    # 不主动检测任何物体（纯被动）
		detector.monitorable = true    # 允许被其他 Area2D 检测

	# 开启碰撞监控
	contact_monitor = true
	max_contacts_reported = 10

	# 连接碰撞信号
	body_entered.connect(_on_body_entered)

	# 开启持续碰撞检测（防止合成后的水果已经在接触状态）
	set_physics_process(true)

	# 初始化水果属性
	_update_fruit_properties()

	# 设置初始冷却时间
	_spawn_cooldown = SPAWN_COOLDOWN_TIME

	# 添加微小的随机初始角速度，让水果掉落时更生动
	# 范围：-5 到 +5 度每秒
	var random_angular_velocity = randf_range(-5.0, 5.0)
	angular_velocity = deg_to_rad(random_angular_velocity)

	print("水果等级 %d 初始化角速度: %.2f 度/秒" % [level, random_angular_velocity])


func _physics_process(delta: float) -> void:
	# 处理冷却时间
	if _spawn_cooldown > 0:
		_spawn_cooldown -= delta
	# 冷却结束后，尝试触发与正在接触的水果的合成
	elif not _is_merging:
		_try_merge_with_contacts()


## 尝试与正在接触的水果合成
func _try_merge_with_contacts() -> void:
	# 获取所有正在碰撞的物体
	var colliding_bodies = get_colliding_bodies()

	for body in colliding_bodies:
		# 检查是否是水果
		if not body is Fruit:
			continue

		var other_fruit: Fruit = body

		# 检查等级是否相同
		if level != other_fruit.level:
			continue

		# 检查是否达到最高等级
		if level >= 10:
			continue

		# 检查对方冷却时间
		if other_fruit._spawn_cooldown > 0:
			continue

		# 检查对方是否已经在处理合成
		if other_fruit._is_merging:
			continue

		# 创建合成对的唯一标识符
		var merge_key: String
		if _fruit_id < other_fruit._fruit_id:
			merge_key = "%d_%d" % [_fruit_id, other_fruit._fruit_id]
		else:
			merge_key = "%d_%d" % [other_fruit._fruit_id, _fruit_id]

		# 检查这个合成对是否已经在处理中
		if merge_key in _processing_merges:
			continue

		# 标记为正在处理
		_is_merging = true
		other_fruit._is_merging = true

		# 将合成对添加到处理集合中
		_processing_merges[merge_key] = true

		# 使用 call_deferred 延迟执行合成逻辑
		call_deferred("_merge_fruits", other_fruit, merge_key)

		# 每次只处理一个合成，避免快速连续触发
		break


## 根据等级更新水果属性
func _update_fruit_properties() -> void:
	var config: Dictionary = FRUIT_CONFIG[level]
	var radius: float = config["radius"]

	# 创建独立的碰撞形状（避免共享资源）
	var new_shape := CircleShape2D.new()
	new_shape.radius = radius

	# 设置新的碰撞形状
	if collision_shape:
		collision_shape.shape = new_shape

	# 同时更新探测器区域的碰撞形状
	if has_node("DetectorArea/DetectorShape"):
		var detector_shape = $DetectorArea/DetectorShape
		var detector_new_shape := CircleShape2D.new()
		detector_new_shape.radius = radius
		detector_shape.shape = detector_new_shape

	# 创建渐变圆形纹理
	if sprite:
		_create_gradient_texture(radius, config["color"])

	# 设置质量
	mass = config["mass"]


## 创建渐变圆形纹理
func _create_gradient_texture(radius: float, base_color: Color) -> void:
	var texture_size: int = int(radius * 2)

	# 创建图像
	var image := Image.create(texture_size, texture_size, false, Image.FORMAT_RGBA8)

	# 中心颜色（更亮）
	var center_color := base_color.lightened(0.3)
	# 边缘颜色（更暗）
	var edge_color := base_color.darkened(0.2)

	var center: Vector2 = Vector2(radius, radius)

	# 逐像素绘制径向渐变
	for y in range(texture_size):
		for x in range(texture_size):
			var pixel_pos: Vector2 = Vector2(x, y)
			var distance: float = pixel_pos.distance_to(center)

			# 只在圆内绘制
			if distance <= radius:
				var ratio: float = distance / radius
				var color: Color

				# 使用平滑的径向渐变
				if ratio < 0.5:
					# 中心到中间：中心颜色 -> 基础颜色
					var t: float = ratio * 2.0
					color = center_color.lerp(base_color, t)
				else:
					# 中间到边缘：基础颜色 -> 边缘颜色
					var t: float = (ratio - 0.5) * 2.0
					color = base_color.lerp(edge_color, t)

				image.set_pixel(x, y, color)
			else:
				# 圆外透明
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	# 创建纹理
	var texture := ImageTexture.create_from_image(image)

	# 应用纹理到精灵
	sprite.texture = texture

	# Sprite2D 默认居中显示，无需额外设置偏移
	# 纹理会自动以中心为原点显示


## 设置水果等级并立即应用
func set_fruit_level(new_level: int) -> void:
	level = new_level


## 获取水果配置
func get_config() -> Dictionary:
	return FRUIT_CONFIG[level]


## 获取水果名称
func get_fruit_name() -> String:
	return FRUIT_CONFIG[level]["name"]


## 碰撞检测处理
func _on_body_entered(body: Node) -> void:
	# 检查冷却时间
	if _spawn_cooldown > 0:
		return

	# 检查是否是水果
	if not body is Fruit:
		return

	# 检查是否已经在处理合成
	if _is_merging:
		return

	var other_fruit: Fruit = body

	# 检查对方冷却时间
	if other_fruit._spawn_cooldown > 0:
		return

	# 检查对方是否已经在处理合成
	if other_fruit._is_merging:
		return

	# 检查等级是否相同
	if level != other_fruit.level:
		return

	# 检查是否达到最高等级
	if level >= 10:
		return

	# 创建合成对的唯一标识符（使用较小的 ID 在前，确保一致性）
	var merge_key: String
	if _fruit_id < other_fruit._fruit_id:
		merge_key = "%d_%d" % [_fruit_id, other_fruit._fruit_id]
	else:
		merge_key = "%d_%d" % [other_fruit._fruit_id, _fruit_id]

	# 检查这个合成对是否已经在处理中
	if merge_key in _processing_merges:
		return

	# 标记为正在处理
	_is_merging = true
	other_fruit._is_merging = true

	# 将合成对添加到处理集合中
	_processing_merges[merge_key] = true

	# 使用 call_deferred 延迟执行合成逻辑
	call_deferred("_merge_fruits", other_fruit, merge_key)


## 合成两个水果
func _merge_fruits(other_fruit: Fruit, merge_key: String) -> void:
	# 检查节点是否仍然有效
	if not is_inside_tree() or not other_fruit.is_inside_tree():
		_cleanup_merge(merge_key)
		return

	# 计算新水果的生成位置（两个水果的中心点）
	var spawn_position: Vector2 = (global_position + other_fruit.global_position) / 2.0

	# 发射合成信号
	fruit_merged.emit(level, level + 1, spawn_position)

	# 创建爆炸粒子特效
	_create_explosion_effect(spawn_position)

	# 计算得分并创建飘字特效
	var points = (level + 1) * 10
	_create_floating_score(points, spawn_position)

	# 创建新的水果（等级 + 1）
	var new_fruit: Fruit = _fruit_scene.instantiate()
	new_fruit.level = level + 1
	new_fruit.global_position = spawn_position

	# 获取 GameManager 并连接合成信号
	var gm = get_node("/root/GameManager")
	new_fruit.fruit_merged.connect(gm._on_fruit_merged)

	# 添加到当前水果的父节点（而不是 current_scene）
	get_parent().add_child(new_fruit)

	# 延迟删除旧水果
	call_deferred("queue_free")
	other_fruit.call_deferred("queue_free")

	# 使用 call_deferred 延迟清理合成标记（确保在 queue_free 之后）
	call_deferred("_cleanup_merge", merge_key)


## 清理合成标记
func _cleanup_merge(merge_key: String) -> void:
	_is_merging = false
	if merge_key in _processing_merges:
		_processing_merges.erase(merge_key)


## 创建爆炸粒子特效（直接创建，不使用场景文件）
func _create_explosion_effect(position: Vector2) -> void:
	# 设置粒子颜色为当前水果的颜色
	var config = FRUIT_CONFIG[level]
	var color = config["color"]

	# 创建粒子容器
	var container = Node2D.new()
	container.z_index = 10000
	container.global_position = position
	get_tree().current_scene.add_child(container)

	# 创建多个粒子
	var particle_count = 24
	for i in range(particle_count):
		_create_single_particle(container, color, i)

	# 自动清理
	var cleanup_timer = get_tree().create_timer(1.2)
	cleanup_timer.timeout.connect(container.queue_free)

	print("创建爆炸特效，颜色:", color, "位置:", position, "粒子数:", particle_count)


## 创建单个粒子
func _create_single_particle(container: Node2D, color: Color, index: int) -> void:
	var particle = ColorRect.new()
	particle.size = Vector2(16, 16)
	particle.color = color
	particle.z_index = 10000
	particle.position = Vector2(0, 0)

	container.add_child(particle)

	# 随机方向和速度
	var angle = randf() * TAU
	var speed = randf_range(150, 300)
	var velocity = Vector2.from_angle(angle) * speed

	# 动画
	var tween = particle.create_tween()
	tween.set_parallel()

	# 移动
	tween.tween_property(particle, "global_position", particle.global_position + velocity, 1.0)

	# 缩小
	tween.tween_property(particle, "scale", Vector2.ZERO, 1.0)

	# 透明度
	tween.tween_property(particle, "modulate:a", 0.0, 1.0)

	print("粒子 %d 创建，位置:%s" % [index, particle.global_position])


## 创建飘字得分特效（直接创建，不使用场景文件）
func _create_floating_score(points: int, position: Vector2) -> void:
	# 直接创建 Label 节点
	var floating_score = Label.new()

	# 设置基本属性 - 使用 global_position 确保位置正确
	floating_score.text = "+%d" % points
	floating_score.z_index = 10001
	floating_score.global_position = position

	# 设置大小和对齐
	floating_score.size = Vector2(200, 60)
	floating_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating_score.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 设置字体大小（使用主题覆盖）
	floating_score.add_theme_font_size_override("font_size", 48)

	# 设置颜色（使用白色确保最显眼）
	floating_score.modulate = Color(1, 1, 1, 1)

	# 添加描边效果（黑色粗描边）
	floating_score.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	floating_score.add_theme_constant_override("outline_size", 5)

	# 添加到场景
	get_tree().current_scene.add_child(floating_score)

	# 验证节点状态
	print("飘字创建完成 - visible:", floating_score.visible, "position:", floating_score.global_position, "text:", floating_score.text, "size:", floating_score.size)

	# 开始动画
	_animate_floating_score(floating_score, position)


## 根据分数获取颜色
func _get_score_color(points: int) -> Color:
	if points <= 20:
		return Color(1, 1, 1, 1)  # 白色
	elif points <= 60:
		return Color(1, 1, 0, 1)  # 黄色
	elif points <= 90:
		return Color(1, 0.5, 0, 1)  # 橙色
	else:
		return Color(1, 0.8, 0, 1)  # 金色


## 飘字动画
func _animate_floating_score(label: Label, start_position: Vector2) -> void:
	# 确保初始状态完全可见
	label.modulate = Color(1, 1, 1, 1)
	label.scale = Vector2(1.5, 1.5)

	print("开始飘字动画 - 初始位置:", label.global_position, "初始透明度:", label.modulate.a)

	var tween = label.create_tween()
	tween.set_parallel()

	# 向上移动（从开始位置向上移动 150 像素）
	var end_y = start_position.y - 150
	tween.tween_property(label, "global_position:y", end_y, 2.0)

	# 延迟后才开始淡出（前 1 秒保持完全不透明）
	var fade_tween = label.create_tween()
	fade_tween.tween_interval(1.0)  # 等待 1 秒
	fade_tween.tween_property(label, "modulate:a", 0.0, 1.0)  # 然后淡出

	# 缩放动画：先缩小再放大
	var scale_tween = label.create_tween()
	scale_tween.tween_property(label, "scale", Vector2(1.8, 1.8), 0.2)
	scale_tween.tween_property(label, "scale", Vector2(1.0, 1.0), 1.8)

	# 完成后销毁
	tween.tween_callback(label.queue_free)
