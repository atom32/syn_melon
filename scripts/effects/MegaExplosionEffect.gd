class_name MegaExplosionEffect
extends Node2D

## 超大爆炸特效 - 大西瓜合成时触发

const PARTICLE_COUNT: int = 60
const EXPLOSION_FORCE: float = 500.0
const LIFETIME: float = 1.5


func _ready() -> void:
	pass


## 触发超大爆炸特效
func explode(color: Color, position: Vector2) -> void:
	global_position = position
	z_index = 2000

	# 创建爆炸粒子
	for i in range(PARTICLE_COUNT):
		_create_particle(color, i)

	# 创建冲击波效果
	_create_shockwave()

	# 震动屏幕
	_shake_screen()

	# 自动清理
	var cleanup_timer = get_tree().create_timer(LIFETIME)
	cleanup_timer.timeout.connect(_on_finished)

	print("🎉 超大爆炸！位置:", position, "粒子数:", PARTICLE_COUNT)


## 创建单个粒子
func _create_particle(color: Color, index: int) -> void:
	var particle = ColorRect.new()
	var size = randf_range(20, 40)
	particle.size = Vector2(size, size)
	particle.color = color
	particle.z_index = 2001
	particle.position = Vector2(0, 0)

	add_child(particle)

	# 更高的速度和更远的距离
	var angle = randf() * TAU
	var speed = randf_range(300, 600)
	var velocity = Vector2.from_angle(angle) * speed

	var tween = particle.create_tween()
	tween.set_parallel()

	tween.tween_property(particle, "global_position", particle.global_position + velocity, LIFETIME)
	tween.tween_property(particle, "scale", Vector2.ZERO, LIFETIME)
	tween.tween_property(particle, "modulate:a", 0.0, LIFETIME)


## 创建冲击波效果
func _create_shockwave() -> void:
	var shockwave = ColorRect.new()
	shockwave.size = Vector2(10, 10)
	shockwave.color = Color(1, 1, 1, 0.8)
	shockwave.z_index = 1999
	shockwave.position = Vector2(-5, -5)

	add_child(shockwave)

	var tween = shockwave.create_tween()
	tween.set_parallel()

	# 冲击波快速扩散
	tween.tween_property(shockwave, "size", Vector2(800, 800), 0.5)
	tween.tween_property(shockwave, "position", Vector2(-400, -400), 0.5)
	tween.tween_property(shockwave, "modulate:a", 0.0, 0.5)


## 屏幕震动效果
func _shake_screen() -> void:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return

	var original_position = camera.global_position
	var shake_duration = 0.3
	var shake_magnitude = 10.0

	var shake_tween = create_tween()
	shake_tween.set_parallel()

	for i in range(10):  # 震动 10 次
		var offset = Vector2(
			randf_range(-shake_magnitude, shake_magnitude),
			randf_range(-shake_magnitude, shake_magnitude)
		)
		shake_tween.tween_property(camera, "global_position", original_position + offset, shake_duration / 10)
		shake_tween.tween_property(camera, "global_position", original_position, shake_duration / 10)


## 特效完成回调
func _on_finished() -> void:
	queue_free()
