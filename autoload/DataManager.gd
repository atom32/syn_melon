extends Node

## ==========================================
## 🗃️ DataManager - JSON 数据管理器
## ==========================================
## 负责加载和解析游戏数据 JSON 文件
## 提供统一的数据访问接口

## 信号定义
signal data_loaded()
signal data_load_failed(error_message: String)

## 数据缓存
var _units_data: Dictionary = {}
var _game_config: Dictionary = {}
var _is_loaded: bool = false

## 调试模式
const DEBUG_MODE: bool = true


func _ready() -> void:
	# 自动加载数据
	load_all_data()


## ==========================================
## 数据加载 (Data Loading)
## ==========================================

## 加载所有游戏数据
func load_all_data() -> void:
	print("[DataManager] 开始加载游戏数据...")

	# 加载单位数据库
	var error = load_units_db()
	if error != OK:
		push_error("[DataManager] 加载单位数据库失败！")
		emit_signal("data_load_failed", "Failed to load units database")
		return

	_is_loaded = true
	print("[DataManager] ✅ 游戏数据加载完成！")
	emit_signal("data_loaded")


## 加载单位数据库
func load_units_db() -> Error:
	var file_path = "res://data/units_db.json"

	if not FileAccess.file_exists(file_path):
		push_error("[DataManager] 文件不存在: %s" % file_path)
		return ERR_FILE_NOT_FOUND

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		var error = FileAccess.get_open_error()
		push_error("[DataManager] 无法打开文件: %s, 错误码: %d" % [file_path, error])
		return error

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("[DataManager] JSON 解析失败: %s" % json.get_error_message())
		return ERR_INVALID_DATA

	var data = json.data

	# 验证数据结构
	if not _validate_units_data(data):
		push_error("[DataManager] 数据结构验证失败")
		return ERR_INVALID_DATA

	# 缓存数据
	_units_data = data
	if data.has("game_config"):
		_game_config = data["game_config"]

	if DEBUG_MODE:
		print("[DataManager] 单位数据库加载成功")
		_print_data_summary()

	return OK


## 验证单位数据结构
func _validate_units_data(data: Dictionary) -> bool:
	# 检查必需的顶层键
	if not data.has("factions"):
		push_error("[DataManager] 缺少 'factions' 字段")
		return false

	if not data.has("game_config"):
		push_error("[DataManager] 缺少 'game_config' 字段")
		return false

	# 检查阵营数据
	var factions = data["factions"]
	for faction_id in factions:
		var faction = factions[faction_id]
		if not faction.has("units"):
			push_error("[DataManager] 阵营 '%s' 缺少 'units' 字段" % faction_id)
			return false

		# 检查单位数据
		var units = faction["units"]
		for unit in units:
			if not _validate_unit(unit):
				push_error("[DataManager] 阵营 '%s' 中有无效单位数据" % faction_id)
				return false

	return true


## 验证单个单位数据
func _validate_unit(unit: Dictionary) -> bool:
	var required_fields = ["level", "name", "radius", "mass", "color", "cost", "battle_stats"]
	for field in required_fields:
		if not unit.has(field):
			push_error("[DataManager] 单位缺少必需字段: %s" % field)
			return false

	# 验证战斗属性
	var battle_stats = unit["battle_stats"]
	var required_stats = ["hp", "damage", "attack_speed", "range", "movement_speed"]
	for stat in required_stats:
		if not battle_stats.has(stat):
			push_error("[DataManager] 单位缺少战斗属性: %s" % stat)
			return false

	return true


## 打印数据摘要（调试用）
func _print_data_summary() -> void:
	if not _units_data.has("factions"):
		return

	var factions = _units_data["factions"]
	print("[DataManager] 📊 数据摘要:")
	print("  - 阵营数量: %d" % factions.size())

	for faction_id in factions:
		var faction = factions[faction_id]
		var unit_count = faction["units"].size()
		print("  - [%s] %s: %d 个单位" % [faction_id, faction["name"], unit_count])

	if _units_data.has("foreign_units"):
		var foreign_count = _units_data["foreign_units"]["units"].size()
		print("  - 异种单位: %d 个" % foreign_count)

	if _game_config.has("max_level"):
		print("  - 最大等级: %d" % _game_config["max_level"])


## ==========================================
## 单位数据访问 (Unit Data Access)
## ==========================================

## 获取指定阵营和等级的单位数据
func get_unit(faction_id: String, level: int) -> Dictionary:
	if not _is_loaded:
		push_error("[DataManager] 数据尚未加载")
		return {}

	if not _units_data.has("factions"):
		push_error("[DataManager] 缺少阵营数据")
		return {}

	var factions = _units_data["factions"]
	if not factions.has(faction_id):
		push_error("[DataManager] 阵营不存在: %s" % faction_id)
		return {}

	var faction = factions[faction_id]
	var units = faction["units"]

	for unit in units:
		if unit["level"] == level:
			return unit.duplicate()

	push_error("[DataManager] 阵营 %s 中没有等级 %d 的单位" % [faction_id, level])
	return {}


## 获取单位属性（向后兼容 FruitConfig）
func get_unit_radius(faction_id: String, level: int) -> float:
	var unit = get_unit(faction_id, level)
	if unit.is_empty():
		return 15.0  # 默认值
	return unit["radius"]


func get_unit_mass(faction_id: String, level: int) -> float:
	var unit = get_unit(faction_id, level)
	if unit.is_empty():
		return 1.0  # 默认值
	return unit["mass"]


func get_unit_color(faction_id: String, level: int) -> Color:
	var unit = get_unit(faction_id, level)
	if unit.is_empty():
		return Color.WHITE  # 默认值

	var color_array = unit["color"]
	return Color(color_array[0], color_array[1], color_array[2], color_array[3])


func get_unit_name(faction_id: String, level: int) -> String:
	var unit = get_unit(faction_id, level)
	if unit.is_empty():
		return "未知单位"
	return unit["name"]


func get_unit_cost(faction_id: String, level: int) -> int:
	var unit = get_unit(faction_id, level)
	if unit.is_empty():
		return 10  # 默认值
	return unit["cost"]


func get_unit_battle_stats(faction_id: String, level: int) -> Dictionary:
	var unit = get_unit(faction_id, level)
	if unit.is_empty():
		return {}

	return unit["battle_stats"].duplicate()


## 获取阵营信息
func get_faction_info(faction_id: String) -> Dictionary:
	if not _is_loaded:
		return {}

	if not _units_data.has("factions"):
		return {}

	var factions = _units_data["factions"]
	if not factions.has(faction_id):
		return {}

	return factions[faction_id].duplicate()


## 获取所有阵营 ID
func get_faction_ids() -> Array:
	if not _is_loaded:
		return []

	if not _units_data.has("factions"):
		return []

	return _units_data["factions"].keys()


## 获取阵营单位数量
func get_faction_unit_count(faction_id: String) -> int:
	var faction = get_faction_info(faction_id)
	if faction.is_empty():
		return 0

	if not faction.has("units"):
		return 0

	return faction["units"].size()


## ==========================================
## 游戏配置访问 (Game Config Access)
## ==========================================

## 获取游戏配置
func get_game_config() -> Dictionary:
	if _game_config.is_empty():
		return {}
	return _game_config.duplicate()


## 获取最大等级
func get_max_level() -> int:
	if _game_config.has("max_level"):
		return _game_config["max_level"]
	return 10  # 默认值


## 获取生成等级范围
func get_spawn_level_range() -> Dictionary:
	var result = {"min": 0, "max": 3}
	if _game_config.has("min_spawn_level"):
		result["min"] = _game_config["min_spawn_level"]
	if _game_config.has("max_spawn_level"):
		result["max"] = _game_config["max_spawn_level"]
	return result


## ==========================================
## 异种单位数据 (Foreign Units)
## ==========================================

## 获取所有异种单位
func get_foreign_units() -> Array:
	if not _is_loaded:
		return []

	if not _units_data.has("foreign_units"):
		return []

	if not _units_data["foreign_units"].has("units"):
		return []

	return _units_data["foreign_units"]["units"].duplicate()


## 根据 ID 获取异种单位
func get_foreign_unit(unit_id: String) -> Dictionary:
	var foreign_units = get_foreign_units()
	for unit in foreign_units:
		if unit.has("id") and unit["id"] == unit_id:
			return unit.duplicate()
	return {}


## 获取异种单位生成概率
func get_foreign_unit_spawn_rate() -> float:
	if _game_config.has("foreign_unit_spawn_rate"):
		return _game_config["foreign_unit_spawn_rate"]
	return 0.05  # 默认 5%


## ==========================================
## 默认阵营支持 (Default Faction)
## ==========================================

## 默认阵营（用于向后兼容）
const DEFAULT_FACTION: String = "abyss"


## 获取默认阵营的单位数据（向后兼容）
func get_unit_default(level: int) -> Dictionary:
	return get_unit(DEFAULT_FACTION, level)


func get_radius(level: int) -> float:
	return get_unit_radius(DEFAULT_FACTION, level)


func get_mass(level: int) -> float:
	return get_unit_mass(DEFAULT_FACTION, level)


func get_color(level: int) -> Color:
	return get_unit_color(DEFAULT_FACTION, level)


func get_name_default(level: int) -> String:
	return get_unit_name(DEFAULT_FACTION, level)


## ==========================================
## 工具方法 (Utility Methods)
## ==========================================

## 检查数据是否已加载
func is_data_loaded() -> bool:
	return _is_loaded


## 重新加载数据
func reload_data() -> void:
	_is_loaded = false
	_units_data.clear()
	_game_config.clear()
	load_all_data()


## 获取数据版本
func get_schema_version() -> String:
	if _units_data.has("schema_version"):
		return _units_data["schema_version"]
	return "unknown"
