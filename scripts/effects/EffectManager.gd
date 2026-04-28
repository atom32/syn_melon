class_name EffectManager
extends Node

## 特效管理器 - 统一管理游戏中的视觉反馈特效

# 物理爆炸参数
const EXPLOSION_RADIUS: float = 150.0      # 爆炸影响半径
const EXPLOSION_FORCE: float = 800.0       # 爆炸冲力
const EXPLOSION_FORCE_MEGA: float = 2000.0 # 超大爆炸冲力


## 创建带物理效果的爆炸（普通合成）
static func create_explosion(parent: Node, position: Vector2, color: Color) -> void:
	# 先创建视觉粒子效果
	var container = Node2D.new()
	container.z_index = 500
	container.global_position = position
	parent.add_child(container)

	var particle_count = 24
	for i in range(particle_count):
		_create_particle(container, color, i)

	# 自动清理
	var cleanup_timer = parent.get_tree().create_timer(1.2)
	cleanup_timer.timeout.connect(container.queue_free)

	# 添加物理震飞效果
	_apply_physics_explosion(parent, position, EXPLOSION_RADIUS, EXPLOSION_FORCE)


## 创建超大爆炸（大西瓜合成，包含强物理效果）
static func create_mega_explosion(parent: Node, position: Vector2, color: Color) -> void:
	var mega_scene = preload("res://scenes/effects/MegaExplosionEffect.tscn")
	var mega_explosion = mega_scene.instantiate()
	mega_explosion.global_position = position
	parent.add_child(mega_explosion)
	mega_explosion.explode(color, position)

	# 添加更强的物理震飞效果
	_apply_physics_explosion(parent, position, EXPLOSION_RADIUS * 1.5, EXPLOSION_FORCE_MEGA)


## 应用物理爆炸效果（震飞周围水果）
static func _apply_physics_explosion(parent: Node, position: Vector2, radius: float, force: float) -> void:
	# 创建一个临时的 PhysicsBlastEffect 节点来处理物理爆炸
	var blast = PhysicsBlastEffect.new()
	parent.add_child(blast)
	blast.explode(position, radius, force)


## PhysicsBlastEffect 内部类 - 处理物理爆炸
class PhysicsBlastEffect extends Area2D:
	var _position: Vector2
	var _radius: float
	var _force: float

	func explode(position: Vector2, radius: float, force: float) -> void:
		_position = position
		_radius = radius
		_force = force

		global_position = position

		# 创建碰撞形状
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = radius
		collision.shape = shape
		add_child(collision)

		# 设置碰撞层
		collision_layer = 0
		collision_mask = 1

		# 监控开启
		monitoring = true
		monitorable = false

		# 使用延迟来确保 Area2D 生效
		await get_tree().process_frame
		_apply_blast()

	func _apply_blast() -> void:
		var overlapping_bodies = get_overlapping_bodies()

		for body in overlapping_bodies:
			if not body is RigidBody2D:
				continue

			var fruit = body as RigidBody2D
			var direction = (fruit.global_position - _position).normalized()
			var distance = fruit.global_position.distance_to(_position)

			# 力的大小根据距离衰减
			var distance_factor = 1.0 - (distance / _radius)
			distance_factor = max(distance_factor, 0.0)

			# 应用冲力
			var impulse = direction * _force * distance_factor
			fruit.apply_central_impulse(impulse)

			# 添加随机旋转
			var random_torque = randf_range(-1000, 1000) * distance_factor
			fruit.apply_torque_impulse(random_torque)

		print("[物理爆炸] 位置:", _position, "半径:", _radius, "力:", _force, "影响水果数:", overlapping_bodies.size())

		# 清理
		queue_free()


## 创建单个粒子
static func _create_particle(container: Node2D, color: Color, index: int) -> void:
	var particle = ColorRect.new()
	particle.size = Vector2(16, 16)
	particle.color = color
	particle.z_index = 501
	particle.position = Vector2(0, 0)

	container.add_child(particle)

	# 随机方向和速度
	var angle = randf() * TAU
	var speed = randf_range(150, 300)
	var velocity = Vector2.from_angle(angle) * speed

	# 动画
	var tween = particle.create_tween()
	tween.set_parallel()

	tween.tween_property(particle, "global_position", particle.global_position + velocity, 1.0)
	tween.tween_property(particle, "scale", Vector2.ZERO, 1.0)
	tween.tween_property(particle, "modulate:a", 0.0, 1.0)


## 创建飘字得分特效
static func create_floating_score(parent: Node, position: Vector2, points: int, multiplier: float = 1.0) -> void:
	var container = Control.new()
	container.z_index = 1000
	container.global_position = position
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	parent.add_child(container)

	var floating_score = RichTextLabel.new()

	# 如果有连击乘数，显示乘数
	if multiplier > 1.0:
		floating_score.text = "[center][color=white]+%d (x%.1f)[/color][/center]" % [points, multiplier]
	else:
		floating_score.text = "[center][color=white]+%d[/color][/center]" % points

	floating_score.fit_content = true
	floating_score.size = Vector2(300, 100)
	floating_score.bbcode_enabled = true

	# 添加描边效果
	floating_score.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	floating_score.add_theme_constant_override("outline_size", 6)
	floating_score.add_theme_font_size_override("normal_font_size", 60)

	# 根据乘数设置颜色
	if multiplier > 1.0:
		if multiplier >= 2.0:
			floating_score.modulate = Color(1.0, 0.4, 0.0, 1)  # 橙红色（高连击）
		else:
			floating_score.modulate = Color(1.0, 0.7, 0.0, 1)  # 金黄色（普通连击）
	else:
		floating_score.modulate = Color(1, 1, 1, 1)

	floating_score.visible = true

	container.add_child(floating_score)

	# 开始动画（如果有连击，放大更多）
	var start_scale = 1.8 if multiplier > 1.0 else 1.5
	_animate_floating_score(container, position, start_scale)


## 飘字动画
static func _animate_floating_score(container: Control, start_position: Vector2, start_scale: float = 1.5) -> void:
	container.modulate = Color(1, 1, 1, 1)
	container.scale = Vector2(start_scale, start_scale)

	var tween = container.create_tween()
	tween.set_parallel()

	# 向上移动
	var end_y = start_position.y - 150
	tween.tween_property(container, "global_position:y", end_y, 2.0)

	# 延迟淡出
	var fade_tween = container.create_tween()
	fade_tween.tween_interval(1.0)
	fade_tween.tween_property(container, "modulate:a", 0.0, 1.0)

	# 缩放动画
	var scale_tween = container.create_tween()
	scale_tween.tween_property(container, "scale", Vector2(start_scale + 0.3, start_scale + 0.3), 0.2)
	scale_tween.tween_property(container, "scale", Vector2(1.0, 1.0), 1.8)

	# 完成后销毁
	tween.tween_callback(container.queue_free)
