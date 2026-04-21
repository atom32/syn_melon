extends RigidBody2D
class_name Fruit

## 水果脚本 - 核心物理和碰撞逻辑

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
const SPAWN_COOLDOWN_TIME: float = 0.1

# 水果场景引用
var _fruit_scene: PackedScene = preload("res://scenes/Fruit.tscn")

# 水果等级 (0-10)
@export var level: int = 0:
	set(value):
		level = clamp(value, 0, FruitConfig.get_max_level())
		_update_fruit_properties()

# 节点引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	# 分配唯一 ID
	_fruit_id = _next_id
	_next_id += 1

	# 设置碰撞层
	collision_layer = 1
	collision_mask = 1

	# 创建统一的物理材质
	var physics_material = PhysicsMaterial.new()
	physics_material.friction = 0.3
	physics_material.bounce = 0.15
	physics_material.rough = false
	physics_material_override = physics_material

	# 设置探测器区域（用于警戒线检测）
	if has_node("DetectorArea"):
		var detector = $DetectorArea
		detector.collision_layer = 8
		detector.collision_mask = 0
		detector.monitorable = true

	# 开启碰撞监控
	contact_monitor = true
	max_contacts_reported = 10
	body_entered.connect(_on_body_entered)

	# 初始化水果属性
	_update_fruit_properties()

	# 设置初始冷却时间
	_spawn_cooldown = SPAWN_COOLDOWN_TIME

	# 添加微小的随机初始角速度
	var random_angular_velocity = randf_range(-5.0, 5.0)
	angular_velocity = deg_to_rad(random_angular_velocity)


func _physics_process(delta: float) -> void:
	if _spawn_cooldown > 0:
		_spawn_cooldown -= delta
	elif not _is_merging:
		_try_merge_with_contacts()


## 尝试与正在接触的水果合成
func _try_merge_with_contacts() -> void:
	var colliding_bodies = get_colliding_bodies()

	for body in colliding_bodies:
		if not body is Fruit:
			continue

		var other_fruit: Fruit = body

		if level != other_fruit.level:
			continue

		if level >= FruitConfig.get_max_level():
			continue

		if other_fruit._spawn_cooldown > 0:
			continue

		if other_fruit._is_merging:
			continue

		var merge_key: String
		if _fruit_id < other_fruit._fruit_id:
			merge_key = "%d_%d" % [_fruit_id, other_fruit._fruit_id]
		else:
			merge_key = "%d_%d" % [other_fruit._fruit_id, _fruit_id]

		if merge_key in _processing_merges:
			continue

		_is_merging = true
		other_fruit._is_merging = true
		_processing_merges[merge_key] = true

		call_deferred("_merge_fruits", other_fruit, merge_key)
		break


## 根据等级更新水果属性
func _update_fruit_properties() -> void:
	var radius: float = FruitConfig.get_radius(level)
	var color: Color = FruitConfig.get_color(level)

	# 创建独立的碰撞形状
	var new_shape := CircleShape2D.new()
	new_shape.radius = radius

	if collision_shape:
		collision_shape.shape = new_shape

	# 更新探测器区域的碰撞形状
	if has_node("DetectorArea/DetectorShape"):
		var detector_shape = $DetectorArea/DetectorShape
		var detector_new_shape := CircleShape2D.new()
		detector_new_shape.radius = radius
		detector_shape.shape = detector_new_shape

	# 创建纹理
	if sprite:
		sprite.texture = TextureGenerator.create_fruit_texture(radius, color)

	# 设置质量
	mass = FruitConfig.get_mass(level)


## 碰撞检测处理
func _on_body_entered(body: Node) -> void:
	if _spawn_cooldown > 0:
		return

	if not body is Fruit:
		return

	if _is_merging:
		return

	var other_fruit: Fruit = body

	if other_fruit._spawn_cooldown > 0:
		return

	if other_fruit._is_merging:
		return

	if level != other_fruit.level:
		return

	if level >= FruitConfig.get_max_level():
		return

	var merge_key: String
	if _fruit_id < other_fruit._fruit_id:
		merge_key = "%d_%d" % [_fruit_id, other_fruit._fruit_id]
	else:
		merge_key = "%d_%d" % [other_fruit._fruit_id, _fruit_id]

	if merge_key in _processing_merges:
		return

	_is_merging = true
	other_fruit._is_merging = true
	_processing_merges[merge_key] = true

	call_deferred("_merge_fruits", other_fruit, merge_key)


## 合成两个水果
func _merge_fruits(other_fruit: Fruit, merge_key: String) -> void:
	if not is_inside_tree() or not other_fruit.is_inside_tree():
		_cleanup_merge(merge_key)
		return

	var spawn_position: Vector2 = (global_position + other_fruit.global_position) / 2.0
	var fruit_color: Color = FruitConfig.get_color(level)

	# 发射合成信号
	fruit_merged.emit(level, level + 1, spawn_position)

	# 触发特效（通过 EffectManager）
	var scene_root = get_tree().current_scene
	EffectManager.create_explosion(scene_root, spawn_position, fruit_color)

	var points = (level + 1) * 10
	EffectManager.create_floating_score(scene_root, spawn_position, points)

	# 创建新的水果
	var new_fruit: Fruit = _fruit_scene.instantiate()
	new_fruit.level = level + 1
	new_fruit.global_position = spawn_position

	# 连接合成信号
	var gm = get_node("/root/GameManager")
	new_fruit.fruit_merged.connect(gm._on_fruit_merged)

	get_parent().add_child(new_fruit)

	# 删除旧水果
	call_deferred("queue_free")
	other_fruit.call_deferred("queue_free")
	call_deferred("_cleanup_merge", merge_key)


## 清理合成标记
func _cleanup_merge(merge_key: String) -> void:
	_is_merging = false
	if merge_key in _processing_merges:
		_processing_merges.erase(merge_key)


## 设置水果等级并立即应用
func set_fruit_level(new_level: int) -> void:
	level = new_level
