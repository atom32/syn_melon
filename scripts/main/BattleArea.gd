extends Node2D

## ==========================================
## ⚔️ BattleArea - 战斗区域控制器
## ==========================================
## 管理战斗单位的部署、移动和战斗逻辑
## Phase 5 会实现完整的战斗系统

## 常量
const WALL_MARGIN: float = 10.0

## 边界
var X_MIN_LIMIT: float = 0.0
var X_MAX_LIMIT: float = 0.0
var Y_TOP_LIMIT: float = 0.0
var Y_BOTTOM_LIMIT: float = 0.0

## 部署的单位
var deployed_units: Array = []

## 敌人（Phase 5 实现）
var enemies: Array = []

## 信号
signal unit_deployed(unit: Node2D, position: Vector2)
signal unit_destroyed(unit: Node2D)
signal enemy_spawned(enemy: Node2D)
signal enemy_destroyed(enemy: Node2D)


func _ready() -> void:
	print("[BattleArea] 初始化战斗区域...")

	# 计算边界
	_calculate_boundaries()

	print("[BattleArea] ✅ 战斗区域初始化完成")
	print("  边界: X ∈ [%.1f, %.1f], Y ∈ [%.1f, %.1f]" % [X_MIN_LIMIT, X_MAX_LIMIT, Y_TOP_LIMIT, Y_BOTTOM_LIMIT])


## 计算边界
func _calculate_boundaries() -> void:
	var left_wall = $LeftWall/CollisionShape2D
	var right_wall = $RightWall/CollisionShape2D
	var top_wall = $TopWall/CollisionShape2D
	var bottom_wall = $BottomWall/CollisionShape2D

	if left_wall and right_wall:
		var left_shape = left_wall.shape as RectangleShape2D
		var right_shape = right_wall.shape as RectangleShape2D
		X_MIN_LIMIT = left_wall.global_position.x + left_shape.size.x / 2.0 + WALL_MARGIN
		X_MAX_LIMIT = right_wall.global_position.x - right_shape.size.x / 2.0 - WALL_MARGIN
	else:
		X_MIN_LIMIT = 50.0
		X_MAX_LIMIT = 525.0

	if top_wall and bottom_wall:
		var top_shape = top_wall.shape as RectangleShape2D
		var bottom_shape = bottom_wall.shape as RectangleShape2D
		Y_TOP_LIMIT = top_wall.global_position.y + top_shape.size.y / 2.0 + WALL_MARGIN
		Y_BOTTOM_LIMIT = bottom_wall.global_position.y - bottom_shape.size.y / 2.0 - WALL_MARGIN
	else:
		Y_TOP_LIMIT = 100.0
		Y_BOTTOM_LIMIT = 700.0


## 部署单位（Phase 5 完善实现）
func deploy_unit(unit_data: Dictionary, position: Vector2) -> Node2D:
	print("[BattleArea] 部署单位: ", unit_data.get("name", "未知"))

	# 占位符：创建简单的标记
	var marker = ColorRect.new()
	marker.size = Vector2(40, 40)
	marker.position = position - Vector2(20, 20)
	marker.color = Color(0.5, 1.0, 0.5, 0.8)
	add_child(marker)

	deployed_units.append(marker)

	unit_deployed.emit(marker, position)

	return marker


## 移除单位
func remove_unit(unit: Node2D) -> void:
	if unit in deployed_units:
		deployed_units.erase(unit)

	if is_instance_valid(unit):
		unit.queue_free()

	unit_destroyed.emit(unit)


## 清理所有单位
func clear_all_units() -> void:
	for unit in deployed_units:
		if is_instance_valid(unit):
			unit.queue_free()

	deployed_units.clear()

	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()

	enemies.clear()

	print("[BattleArea] 已清理所有单位")


## 获取有效的部署位置
func get_valid_deploy_position(target_position: Vector2) -> Vector2:
	var clamped_x = clamp(target_position.x, X_MIN_LIMIT, X_MAX_LIMIT)
	var clamped_y = clamp(target_position.y, Y_TOP_LIMIT, Y_BOTTOM_LIMIT)
	return Vector2(clamped_x, clamped_y)


## 检查位置是否在有效范围内
func is_position_valid(position: Vector2) -> bool:
	return position.x >= X_MIN_LIMIT and position.x <= X_MAX_LIMIT and \
		   position.y >= Y_TOP_LIMIT and position.y <= Y_BOTTOM_LIMIT


## 获取边界信息
func get_boundaries() -> Dictionary:
	return {
		"x_min": X_MIN_LIMIT,
		"x_max": X_MAX_LIMIT,
		"y_top": Y_TOP_LIMIT,
		"y_bottom": Y_BOTTOM_LIMIT
	}


## ==========================================
## Phase 5: 战斗系统占位符
## ==========================================

## 生成敌人（占位符）
func spawn_enemy(enemy_data: Dictionary) -> void:
	# Phase 5 实现
	pass


## 更新战斗逻辑（占位符）
func _process(delta: float) -> void:
	# Phase 5 实现战斗循环
	pass
