class_name EffectManager
extends Node

## 特效管理器 - 统一管理游戏中的视觉反馈特效


## 创建超大爆炸特效（大西瓜合成）
static func create_mega_explosion(parent: Node, position: Vector2, color: Color) -> void:
	var mega_scene = preload("res://scenes/MegaExplosionEffect.tscn")
	var mega_explosion = mega_scene.instantiate()
	mega_explosion.global_position = position
	parent.add_child(mega_explosion)
	mega_explosion.explode(color, position)


## 创建爆炸粒子特效
static func create_explosion(parent: Node, position: Vector2, color: Color) -> void:
	var container = Node2D.new()
	container.z_index = 10000
	container.global_position = position
	parent.add_child(container)

	var particle_count = 24
	for i in range(particle_count):
		_create_particle(container, color, i)

	# 自动清理
	var cleanup_timer = parent.get_tree().create_timer(1.2)
	cleanup_timer.timeout.connect(container.queue_free)


## 创建单个粒子
static func _create_particle(container: Node2D, color: Color, index: int) -> void:
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

	tween.tween_property(particle, "global_position", particle.global_position + velocity, 1.0)
	tween.tween_property(particle, "scale", Vector2.ZERO, 1.0)
	tween.tween_property(particle, "modulate:a", 0.0, 1.0)


## 创建飘字得分特效
static func create_floating_score(parent: Node, position: Vector2, points: int) -> void:
	var container = Control.new()
	container.z_index = 10001
	container.global_position = position
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	parent.add_child(container)

	var floating_score = RichTextLabel.new()
	floating_score.text = "[center][color=white]+%d[/color][/center]" % points
	floating_score.fit_content = true
	floating_score.size = Vector2(300, 100)
	floating_score.bbcode_enabled = true

	# 添加描边效果
	floating_score.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	floating_score.add_theme_constant_override("outline_size", 6)
	floating_score.add_theme_font_size_override("normal_font_size", 60)

	floating_score.modulate = Color(1, 1, 1, 1)
	floating_score.visible = true

	container.add_child(floating_score)

	# 开始动画
	_animate_floating_score(container, position)


## 飘字动画
static func _animate_floating_score(container: Control, start_position: Vector2) -> void:
	container.modulate = Color(1, 1, 1, 1)
	container.scale = Vector2(1.5, 1.5)

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
	scale_tween.tween_property(container, "scale", Vector2(1.8, 1.8), 0.2)
	scale_tween.tween_property(container, "scale", Vector2(1.0, 1.0), 1.8)

	# 完成后销毁
	tween.tween_callback(container.queue_free)
