class_name FruitConfig
extends Resource

## ==========================================
## 🍎 FruitConfig - 单位配置数据包装器
## ==========================================
## 向后兼容层，将现有代码桥接到新的 DataManager 系统
## 支持阵营选择和 JSON 数据驱动

## 当前选择的阵营（默认使用深渊阵营）
static var _current_faction: String = "abyss"

## DataManager 引用
static var _data_manager: Node = null


## 初始化（获取 DataManager 引用）
static func _init() -> void:
	if _data_manager == null:
		_data_manager = get_data_manager()


## 获取 DataManager 单例
static func get_data_manager() -> Node:
	if _data_manager != null:
		return _data_manager

	if Engine.has_singleton("DataManager"):
		_data_manager = Engine.get_singleton("DataManager")
	else:
		# 如果 DataManager 未注册，尝试从节点树获取
		var tree = Engine.get_main_loop() as SceneTree
		if tree and tree.root.has_node("DataManager"):
			_data_manager = tree.root.get_node("DataManager")

	return _data_manager


## ==========================================
## 向后兼容 API (Backward Compatibility)
## ==========================================
## 这些方法保持原有签名，内部委托给 DataManager

## 获取水果配置（向后兼容）
static func get_config(level: int) -> Dictionary:
	if _ensure_data_manager():
		return _data_manager.get_unit_default(level)
	return {}


## 获取水果半径
static func get_radius(level: int) -> float:
	if _ensure_data_manager():
		return _data_manager.get_radius(level)
	return 15.0


## 获取水果质量
static func get_mass(level: int) -> float:
	if _ensure_data_manager():
		return _data_manager.get_mass(level)
	return 1.0


## 获取水果颜色
static func get_color(level: int) -> Color:
	if _ensure_data_manager():
		return _data_manager.get_color(level)
	return Color.WHITE


## 获取水果名称
static func get_fruit_name(level: int) -> String:
	if _ensure_data_manager():
		return _data_manager.get_name_default(level)
	return "未知单位"


## 获取等级数量
static func get_max_level() -> int:
	if _ensure_data_manager():
		return _data_manager.get_max_level()
	return 10


## ==========================================
## 新 API - 阵营支持 (Faction Support)
## ==========================================

## 设置当前阵营
static func set_faction(faction_id: String) -> void:
	_current_faction = faction_id
	print("[FruitConfig] 阵营设置为: %s" % faction_id)


## 获取当前阵营
static func get_faction() -> String:
	return _current_faction


## 获取指定阵营的单位数据
static func get_unit(faction_id: String, level: int) -> Dictionary:
	if _ensure_data_manager():
		return _data_manager.get_unit(faction_id, level)
	return {}


## 获取指定阵营的单位半径
static func get_unit_radius(faction_id: String, level: int) -> float:
	if _ensure_data_manager():
		return _data_manager.get_unit_radius(faction_id, level)
	return 15.0


## 获取指定阵营的单位质量
static func get_unit_mass(faction_id: String, level: int) -> float:
	if _ensure_data_manager():
		return _data_manager.get_unit_mass(faction_id, level)
	return 1.0


## 获取指定阵营的单位颜色
static func get_unit_color(faction_id: String, level: int) -> Color:
	if _ensure_data_manager():
		return _data_manager.get_unit_color(faction_id, level)
	return Color.WHITE


## 获取指定阵营的单位名称
static func get_unit_name(faction_id: String, level: int) -> String:
	if _ensure_data_manager():
		return _data_manager.get_unit_name(faction_id, level)
	return "未知单位"


## 获取指定阵营的单位消耗
static func get_unit_cost(faction_id: String, level: int) -> int:
	if _ensure_data_manager():
		return _data_manager.get_unit_cost(faction_id, level)
	return 10


## 获取指定阵营的单位战斗属性
static func get_unit_battle_stats(faction_id: String, level: int) -> Dictionary:
	if _ensure_data_manager():
		return _data_manager.get_unit_battle_stats(faction_id, level)
	return {}


## 获取阵营信息
static func get_faction_info(faction_id: String) -> Dictionary:
	if _ensure_data_manager():
		return _data_manager.get_faction_info(faction_id)
	return {}


## 获取所有阵营 ID
static func get_faction_ids() -> Array:
	if _ensure_data_manager():
		return _data_manager.get_faction_ids()
	return []


## ==========================================
## 工具方法 (Utility Methods)
## ==========================================

## 确保 DataManager 可用
static func _ensure_data_manager() -> bool:
	_data_manager = get_data_manager()
	return _data_manager != null


## 检查数据是否已加载
static func is_data_loaded() -> bool:
	if _ensure_data_manager():
		return _data_manager.is_data_loaded()
	return false


## 重新加载数据
static func reload_data() -> void:
	if _ensure_data_manager():
		_data_manager.reload_data()
