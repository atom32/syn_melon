class_name FruitConfig
extends Resource

## 水果配置数据 - 管理所有等级的水果属性

## 获取水果配置
static func get_config(level: int) -> Dictionary:
	level = clamp(level, 0, 10)
	return _FRUIT_DATA[level]


## 获取水果半径
static func get_radius(level: int) -> float:
	return get_config(level)["radius"]


## 获取水果质量
static func get_mass(level: int) -> float:
	return get_config(level)["mass"]


## 获取水果颜色
static func get_color(level: int) -> Color:
	return get_config(level)["color"]


## 获取水果名称
static func get_fruit_name(level: int) -> String:
	return get_config(level)["name"]


## 获取等级数量
static func get_max_level() -> int:
	return _FRUIT_DATA.size() - 1


## 水果配置数据
const _FRUIT_DATA: Dictionary = {
	0: {
		"name": "樱桃",
		"radius": 15.0,
		"mass": 1.0,
		"color": Color(1.0, 0.2, 0.2, 1.0)
	},
	1: {
		"name": "草莓",
		"radius": 22.0,
		"mass": 2.0,
		"color": Color(1.0, 0.4, 0.7, 1.0)
	},
	2: {
		"name": "葡萄",
		"radius": 30.0,
		"mass": 3.0,
		"color": Color(0.6, 0.2, 0.8, 1.0)
	},
	3: {
		"name": "橙子",
		"radius": 38.0,
		"mass": 5.0,
		"color": Color(1.0, 0.6, 0.0, 1.0)
	},
	4: {
		"name": "柿子",
		"radius": 48.0,
		"mass": 8.0,
		"color": Color(1.0, 0.4, 0.2, 1.0)
	},
	5: {
		"name": "桃子",
		"radius": 58.0,
		"mass": 12.0,
		"color": Color(1.0, 0.7, 0.6, 1.0)
	},
	6: {
		"name": "菠萝",
		"radius": 68.0,
		"mass": 18.0,
		"color": Color(1.0, 0.8, 0.2, 1.0)
	},
	7: {
		"name": "椰子",
		"radius": 80.0,
		"mass": 25.0,
		"color": Color(0.6, 0.4, 0.2, 1.0)
	},
	8: {
		"name": "半个西瓜",
		"radius": 95.0,
		"mass": 35.0,
		"color": Color(0.2, 0.7, 0.3, 1.0)
	},
	9: {
		"name": "大西瓜",
		"radius": 110.0,
		"mass": 50.0,
		"color": Color(0.3, 0.8, 0.4, 1.0)
	},
	10: {
		"name": "超级大西瓜",
		"radius": 130.0,
		"mass": 80.0,
		"color": Color(0.8, 1.0, 0.8, 1.0)
	}
}
