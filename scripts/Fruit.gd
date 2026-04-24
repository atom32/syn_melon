extends RigidBody2D
class_name Fruit

## 水果脚本 - 核心物理和碰撞逻辑

# 作弊功能开关（可在编辑器中设置，或通过 GameManager 全局控制）
@export var enable_cheat_drag: bool = true

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

# 拖拽状态
var _is_being_dragged: bool = false


func _ready() -> void:
	# 分配唯一 ID
	_fruit_id = _next_id
	_next_id += 1

	# 添加到 "fruits" 组，便于全局管理
	add_to_group("fruits")

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

	# 连接碰撞音效信号（落地时播放）
	body_entered.connect(_on_collision_sound)


func _input(event: InputEvent) -> void:
	# 检查是否启用作弊功能
	if not enable_cheat_drag:
		return

	# 只处理鼠标右键
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT):
		return

	# 右键按下：开始拖拽
	if event.pressed:
		# 检查鼠标是否悬停在这个水果上
		if _is_mouse_hovering():
			_start_dragging()
	# 右键松开：停止拖拽
	else:
		if _is_being_dragged:
			_stop_dragging()


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
	var scene_root = get_tree().current_scene
	var audio = get_node("/root/AudioManager")
	var combo_mgr = get_node("/root/ComboManager")
	var event_bus = get_node("/root/EventBus")

	# 获取连击乘数
	var combo_info = combo_mgr.get_combo_info()
	var multiplier: float = combo_info.multiplier

	# 检查是否是最高等级合成（大西瓜）
	if level >= FruitConfig.get_max_level():
		# 发射合成信号到 EventBus
		event_bus.emit_fruit_merged(level, level, spawn_position)

		# 发射大西瓜合成特殊事件
		event_bus.emit_mega_fruit_merged(spawn_position)

		# 触发超大爆炸特效
		EffectManager.create_mega_explosion(scene_root, spawn_position, fruit_color)

		# 显示超大得分飘字（带乘数）
		var mega_points = 1000
		EffectManager.create_floating_score(scene_root, spawn_position, mega_points, multiplier)

		# 播放超大合成音效
		audio.play_mega_merge()

		# 删除旧水果（不生成新水果）
		call_deferred("queue_free")
		other_fruit.call_deferred("queue_free")
		call_deferred("_cleanup_merge", merge_key)

		print("🎉 大西瓜合成！不生成新水果")
		return

	# 正常合成流程
	# 发射合成信号到 EventBus
	event_bus.emit_fruit_merged(level, level + 1, spawn_position)

	# 触发特效
	EffectManager.create_explosion(scene_root, spawn_position, fruit_color)

	var points = (level + 1) * 10
	EffectManager.create_floating_score(scene_root, spawn_position, points, multiplier)

	# 播放合成音效
	audio.play_merge(level)

	# 创建新的水果
	var new_fruit: Fruit = _fruit_scene.instantiate()
	new_fruit.level = level + 1
	new_fruit.global_position = spawn_position

	get_parent().add_child(new_fruit)

	# 删除旧水果
	call_deferred("queue_free")
	other_fruit.call_deferred("queue_free")
	call_deferred("_cleanup_merge", merge_key)


## 播放碰撞音效（仅首次碰撞，避免重复）
func _on_collision_sound(body: Node) -> void:
	# 只在冷却结束后才播放碰撞音效（避免合成时也播放）
	if _spawn_cooldown <= 0:
		var audio = get_node("/root/AudioManager")
		audio.play_collision(level)


## 清理合成标记
func _cleanup_merge(merge_key: String) -> void:
	_is_merging = false
	if merge_key in _processing_merges:
		_processing_merges.erase(merge_key)


## 设置水果等级并立即应用
func set_fruit_level(new_level: int) -> void:
	level = new_level


## ==========================================
## 作弊功能：右键拖拽
## ==========================================

## 检查鼠标是否悬停在这个水果上
func _is_mouse_hovering() -> bool:
	var mouse_pos = get_global_mouse_position()
	var distance = global_position.distance_to(mouse_pos)
	var radius = FruitConfig.get_radius(level)
	return distance <= radius


## 开始拖拽
func _start_dragging() -> void:
	_is_being_dragged = true

	# 冻结物理
	freeze = true

	# 禁用碰撞检测，避免拖拽时意外触发合成
	collision_layer = 0
	collision_mask = 0

	# 设置更高的 z_index，确保拖拽时显示在最上层
	z_index = 1000

	print("[作弊] 开始拖拽水果等级", level)


## 停止拖拽
func _stop_dragging() -> void:
	_is_being_dragged = false

	# 恢复物理
	freeze = false

	# 恢复碰撞检测
	collision_layer = 1
	collision_mask = 1

	# 恢复 z_index
	z_index = 0

	# 给一个向下的冲力，让它自然落下
	apply_central_impulse(Vector2(0, 100))

	print("[作弊] 停止拖拽水果等级", level)


## 在拖拽时跟随鼠标
func _process(delta: float) -> void:
	if _is_being_dragged:
		# 获取鼠标位置
		var mouse_pos = get_global_mouse_position()

		# 限制在游戏区域内（可选）
		var x_min = 50.0
		var x_max = 1100.0
		var y_min = 150.0
		var y_max = 800.0

		var clamped_x = clamp(mouse_pos.x, x_min, x_max)
		var clamped_y = clamp(mouse_pos.y, y_min, y_max)

		global_position = Vector2(clamped_x, clamped_y)
