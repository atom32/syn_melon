extends Control

## 连击显示特效 - 屏幕中央的连击提示

# 节点引用
@onready var combo_label = $ComboLabel
@onready var multiplier_label = $MultiplierLabel

# 动画配置
const DISPLAY_DURATION: float = 0.8  # 显示时长
const MAX_SCALE: float = 1.5         # 最大缩放


func _ready() -> void:
	# 初始状态
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.5, 0.5)


## 显示连击
func show_combo(count: int, multiplier: float) -> void:
	# 设置文本
	combo_label.text = "%dx COMBO!" % count
	multiplier_label.text = "x%.1f" % multiplier

	# 根据连击数设置颜色
	var color = _get_combo_color(count)
	combo_label.modulate = color

	# 显示
	visible = true

	# 创建动画
	var tween = create_tween()
	tween.set_parallel()

	# 淡入
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

	# 放大效果
	tween.tween_property(self, "scale", Vector2(MAX_SCALE, MAX_SCALE), 0.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

	# 闪烁效果
	tween.tween_property(self, "modulate:a", 0.7, 0.1).set_delay(0.3)
	tween.tween_property(self, "modulate:a", 1.0, 0.1)

	# 保持一段时间后淡出
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_delay(DISPLAY_DURATION)

	# 完成后隐藏
	tween.tween_callback(_on_animation_complete).set_delay(DISPLAY_DURATION + 0.2)

	print("连击显示：%d连击，乘数 %.1f" % [count, multiplier])


## 动画完成回调
func _on_animation_complete() -> void:
	visible = false


## 根据连击数获取颜色
func _get_combo_color(count: int) -> Color:
	match count:
		2:
			return Color(0.3, 1.0, 0.3, 1)  # 绿色
		3:
			return Color(0.3, 0.8, 1.0, 1)  # 青色
		4:
			return Color(0.6, 0.3, 1.0, 1)  # 紫色
		_:
			return Color(1.0, 0.8, 0.0, 1)  # 金色（5+连击）
