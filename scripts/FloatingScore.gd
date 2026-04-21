extends Label

## 浮动得分飘字特效

# 飘动距离
const FLOAT_DISTANCE: float = 50.0

# 飘动时间
const FLOAT_DURATION: float = 0.8


func _ready() -> void:
	# 设置字体大小
	add_theme_font_size_override("font_size", 24)

	# 可选：添加文字阴影效果
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)


## 设置分数并开始动画
func show_score(points: int, start_position: Vector2) -> void:
	# 设置初始位置
	global_position = start_position

	# 设置分数文本
	text = "+%d" % points

	# 根据分数大小设置颜色
	var color = get_score_color(points)
	modulate = color

	# 开始动画
	var tween = create_tween()
	tween.set_parallel()

	# 向上移动
	tween.tween_property(self, "position:y", global_position.y - FLOAT_DISTANCE, FLOAT_DURATION)

	# 透明度渐变
	tween.tween_property(self, "modulate:a", 0.0, FLOAT_DURATION)

	# 稍微放大
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), FLOAT_DURATION * 0.5)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), FLOAT_DURATION * 0.5)

	# 完成后自动销毁
	tween.tween_callback(_on_animation_complete)

	print("飘字特效：+%d 在位置" % [points, start_position])


## 动画完成回调
func _on_animation_complete() -> void:
	queue_free()


## 根据分数获取颜色
func get_score_color(points: int) -> Color:
	# 低分：白色
	if points <= 20:
		return Color(1, 1, 1, 1)
	# 中分：黄色
	elif points <= 60:
		return Color(1, 1, 0, 1)
	# 高分：橙色
	elif points <= 90:
		return Color(1, 0.5, 0, 1)
	# 超高分：金色
	else:
		return Color(1, 0.8, 0, 1)
