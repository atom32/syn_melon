extends Node

## 对象池管理器 - 简化版本
## 用于管理高频创建/销毁的对象，减少 GC 压力

## 池数据结构
var _pools: Dictionary = {}  # pool_type -> {available: [], in_use: {}}

## 调试模式
const DEBUG: bool = true


func _ready() -> void:
	print("[ObjectPoolManager] 初始化")


## 创建对象池
## pool_type: 池类型名称
## scene: 要池化的场景
## initial_size: 初始创建的对象数量
func create_pool(pool_type: String, scene: PackedScene, initial_size: int) -> void:
	if _pools.has(pool_type):
		push_warning("[ObjectPoolManager] 池 '%s' 已存在" % pool_type)
		return

	var pool_data = {
		"scene": scene,
		"available": [],
		"in_use": {}
	}

	_pools[pool_type] = pool_data

	# 预创建对象
	for i in range(initial_size):
		var obj = _create_object(pool_data)
		if obj:
			_return_to_pool(pool_type, obj)

	if DEBUG:
		print("[ObjectPoolManager] 创建池 '%s'，初始大小: %d" % [pool_type, initial_size])


## 从池中获取对象
## pool_type: 池类型
## args: 传递给 on_spawn 的参数
func spawn(pool_type: String, args: Array = []) -> Node:
	if not _pools.has(pool_type):
		push_error("[ObjectPoolManager] 池 '%s' 不存在" % pool_type)
		return null

	var pool_data = _pools[pool_type]

	# 从可用列表获取
	if pool_data.available.is_empty():
		if DEBUG:
			print("[ObjectPoolManager] 警告：池 '%s' 为空，临时创建新对象" % pool_type)
		var obj = _create_object(pool_data)
		if not obj:
			return null
		_mark_in_use(pool_data, obj)
		_init_object(obj, args)
		return obj

	var obj = pool_data.available.pop_back()
	_mark_in_use(pool_data, obj)
	_init_object(obj, args)

	if DEBUG:
		print("[ObjectPoolManager] Spawn '%s' -> 活跃: %d, 可用: %d" %
			[pool_type, pool_data.in_use.size(), pool_data.available.size()])

	return obj


## 归还对象到池
func despawn(obj: Node) -> void:
	if not obj or not is_instance_valid(obj):
		return

	if not obj.has_meta("pooled"):
		# 非池化对象，直接删除
		obj.queue_free()
		return

	var pool_type = obj.get_meta("pool_type")
	if not _pools.has(pool_type):
		obj.queue_free()
		return

	var pool_data = _pools[pool_type]
	var obj_id = obj.get_instance_id()

	if not pool_data.in_use.has(obj_id):
		push_warning("[ObjectPoolManager] 对象不在使用中")
		return

	# 从 in_use 移除
	pool_data.in_use.erase(obj_id)

	# 调用清理回调
	if obj.has_method("on_despawn"):
		obj.on_despawn()

	# 从场景树移除
	if obj.get_parent():
		obj.get_parent().remove_child(obj)

	# 返回到可用列表
	_return_to_pool(pool_type, obj)

	if DEBUG:
		print("[ObjectPoolManager] Despawn '%s' -> 活跃: %d, 可用: %d" %
			[pool_type, pool_data.in_use.size(), pool_data.available.size()])


## 创建新对象
func _create_object(pool_data: Dictionary) -> Node:
	var scene = pool_data["scene"]
	if not scene:
		return null

	var obj = scene.instantiate()
	if not obj:
		return null

	# 标记为池化对象
	obj.set_meta("pooled", true)
	obj.set_meta("pool_type", "")  # 稍后设置

	return obj


## 标记对象为使用中
func _mark_in_use(pool_data: Dictionary, obj: Node) -> void:
	var obj_id = obj.get_instance_id()
	pool_data.in_use[obj_id] = obj
	obj.set_meta("pool_type", _get_pool_type_for_data(pool_data))


## 根据数据获取池类型（辅助方法）
func _get_pool_type_for_data(pool_data: Dictionary) -> String:
	for pool_type in _pools:
		if _pools[pool_type] == pool_data:
			return pool_type
	return ""


## 初始化对象
func _init_object(obj: Node, args: Array) -> void:
	if obj.has_method("on_spawn"):
		# 将 args 包装成单个参数传递，因为 on_spawn 定义为 on_spawn(args: Array)
		obj.callv("on_spawn", [args])


## 返回对象到池
func _return_to_pool(pool_type: String, obj: Node) -> void:
	obj.set_meta("pool_type", pool_type)
	_pools[pool_type].available.push_back(obj)


## 获取池统计信息
func get_stats(pool_type: String) -> Dictionary:
	if not _pools.has(pool_type):
		return {}

	var pool_data = _pools[pool_type]
	return {
		"type": pool_type,
		"available": pool_data.available.size(),
		"in_use": pool_data.in_use.size(),
		"total": pool_data.available.size() + pool_data.in_use.size()
	}


## 打印所有池的统计信息
func print_stats() -> void:
	print("\n========== 对象池统计 ==========")
	for pool_type in _pools:
		var stats = get_stats(pool_type)
		print("%s: 可用=%d, 活跃=%d, 总计=%d" %
			[pool_type, stats.available, stats.in_use, stats.total])
	print("================================\n")
