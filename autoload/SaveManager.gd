extends Node

## 保存管理器 - 全局单例
## 处理游戏数据的持久化

const SAVE_FILE_PATH: String = "user://save_data.cfg"
const SECTION_NAME: String = "game_data"
const KEY_HIGH_SCORE: String = "high_score"

# 默认最高分
var high_score: int = 0


func _ready() -> void:
	# 游戏启动时加载保存数据
	load_data()


## 加载保存数据
func load_data() -> void:
	var config = ConfigFile.new()

	# 检查文件是否存在
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("SaveManager: 保存文件不存在，使用默认值")
		high_score = 0
		return

	# 加载配置文件
	var error = config.load(SAVE_FILE_PATH)
	if error != OK:
		print("SaveManager: 加载文件失败，错误码: ", error)
		high_score = 0
		return

	# 读取最高分
	high_score = config.get_value(SECTION_NAME, KEY_HIGH_SCORE, 0)

	print("SaveManager: 加载成功，最高分: ", high_score)


## 保存数据
func save_data() -> void:
	var config = ConfigFile.new()

	# 设置最高分
	config.set_value(SECTION_NAME, KEY_HIGH_SCORE, high_score)

	# 保存到文件
	var error = config.save(SAVE_FILE_PATH)
	if error != OK:
		print("SaveManager: 保存文件失败，错误码: ", error)
		return

	print("SaveManager: 保存成功，最高分: ", high_score)


## 获取最高分
func get_high_score() -> int:
	return high_score


## 检查并更新最高分
## 返回 true 如果是新纪录
func check_and_update_high_score(current_score: int) -> bool:
	if current_score > high_score:
		var old_score = high_score
		high_score = current_score
		save_data()
		print("SaveManager: 新纪录！%d → %d" % [old_score, high_score])

		# 发射最高分更新事件到 EventBus
		var event_bus = get_node("/root/EventBus")
		event_bus.emit_high_score_updated(high_score)

		return true
	return false


## 重置最高分（用于测试）
func reset_high_score() -> void:
	high_score = 0
	save_data()
	print("SaveManager: 最高分已重置")
