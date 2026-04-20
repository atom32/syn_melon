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

	# 初始化水果属性
	_update_fruit_properties()

	# 设置初始冷却时间
	_spawn_cooldown = SPAWN_COOLDOWN_TIME


func _physics_process(delta: float) -> void:
	# 处理冷却时间
	if _spawn_cooldown > 0:
		_spawn_cooldown -= delta


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

	# 创建新的水果（等级 + 1）
	var new_fruit: Fruit = _fruit_scene.instantiate()
	new_fruit.level = level + 1
	new_fruit.global_position = spawn_position

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
