extends Node

## 游戏管理器 - 单例
## 管理待发射水果、分数、游戏状态
## 注意：autoload 注册名称为 "GameManager"，不需要 class_name

# 信号
signal fruit_spawned(fruit, level: int)
signal fruit_merged(old_level: int, new_level: int, position: Vector2)
signal mega_fruit_merged(position: Vector2)  # 大西瓜合成信号
signal score_changed(new_score: int)
signal game_over()

# 游戏配置
const MIN_SPAWN_LEVEL: int = 0
const MAX_SPAWN_LEVEL: int = 3

# 游戏状态
var current_fruit_level: int = 0  # 待发射水果等级
var next_fruit_level: int = 0     # 下一个水果等级
var score: int = 0                 # 当前分数

# 水果场景引用
var _fruit_scene: PackedScene = preload("res://scenes/Fruit.tscn")


func _ready() -> void:
	# 初始化水果
	_randomize_next_fruit()
	current_fruit_level = next_fruit_level
	_randomize_next_fruit()


## 随机生成下一个水果（0-3级）
func _randomize_next_fruit() -> void:
	next_fruit_level = randi_range(MIN_SPAWN_LEVEL, MAX_SPAWN_LEVEL)


## 获取当前待发射水果等级
func get_current_fruit_level() -> int:
	return current_fruit_level


## 获取下一个水果等级
func get_next_fruit_level() -> int:
	return next_fruit_level


## 发射水果
func spawn_fruit(spawn_position: Vector2):
	# 创建水果
	var fruit = _fruit_scene.instantiate()
	fruit.level = current_fruit_level
	fruit.global_position = spawn_position

	# 连接合成信号
	fruit.fruit_merged.connect(_on_fruit_merged)

	# 发射信号
	fruit_spawned.emit(fruit, current_fruit_level)

	# 更新水果
	current_fruit_level = next_fruit_level
	_randomize_next_fruit()

	return fruit


## 处理合成事件
func _on_fruit_merged(old_level: int, new_level: int, position: Vector2) -> void:
	# 获取连击乘数
	var combo_mgr = get_node("/root/ComboManager")
	var multiplier: float = combo_mgr.trigger_merge(position)

	# 计算基础得分（等级越高，分数越多）
	var base_points: int = (old_level + 1) * 10

	# 应用连击乘数
	var final_points: int = int(base_points * multiplier)
	score += final_points

	# 发射分数变化信号
	score_changed.emit(score)

	# 发射合成信号
	fruit_merged.emit(old_level, new_level, position)

	# 打印合成信息
	if multiplier > 1.0:
		print("合成！等级 %d → %d，基础分：%d，连击乘数：%.1f，最终得分：%d，总分：%d" % [old_level, new_level, base_points, multiplier, final_points, score])
	else:
		print("合成！等级 %d → %d，得分：%d，总分：%d" % [old_level, new_level, final_points, score])


## 获取当前分数
func get_score() -> int:
	return score


## 重置游戏
func reset_game() -> void:
	score = 0
	_randomize_next_fruit()
	current_fruit_level = next_fruit_level
	_randomize_next_fruit()
	score_changed.emit(0)

	# 重置连击系统
	var combo_mgr = get_node("/root/ComboManager")
	combo_mgr.reset()


## 处理大西瓜合成（特殊奖励）
func on_mega_fruit_merged(position: Vector2) -> void:
	var bonus_points: int = 1000
	score += bonus_points
	score_changed.emit(score)
	mega_fruit_merged.emit(position)

	print("🎉 大西瓜合成！奖励 %d 分，总分：%d" % [bonus_points, score])
