extends Control

## ==========================================
## 🎮 MainGame - 双屏游戏主控制器
## ==========================================

## 节点引用
var left_viewport: SubViewport = null
var right_viewport: SubViewport = null
var main_scene_instance: Node = null
var battle_area: Node = null

## UI 引用
var faction_label: Label = null
var score_label: Label = null
var timer_label: Label = null
var resources_label: Label = null

## 游戏状态
var current_faction: String = "abyss"
var score: int = 0
var resources: int = 100
var game_time: float = 90.0


func _ready() -> void:
	print("[MainGame] ========== 初始化双屏游戏 ==========")

	# 获取节点引用
	_get_node_references()

	# 加载场景
	_load_scenes()

	# 添加测试背景
	_add_test_backgrounds()

	# 初始化 UI
	_update_ui()

	# 连接事件
	_connect_events()

	print("[MainGame] ========== 初始化完成 ==========")


## 获取节点引用
func _get_node_references() -> void:
	left_viewport = get_node_or_null("ScreenContainer/LeftPanel/LeftViewportContainer/LeftViewport")
	right_viewport = get_node_or_null("ScreenContainer/RightPanel/RightViewportContainer/RightViewport")
	faction_label = get_node_or_null("TopBar/TopBarContent/FactionLabel")
	score_label = get_node_or_null("TopBar/TopBarContent/ScoreLabel")
	timer_label = get_node_or_null("TopBar/TopBarContent/TimerLabel")
	resources_label = get_node_or_null("BottomBar/BottomBarContent/ResourcesLabel")

	print("[MainGame] 节点引用获取完成")


## 加载子场景
func _load_scenes() -> void:
	if not left_viewport or not right_viewport:
		push_error("[MainGame] ViewPort 节点未找到")
		return

	# 加载 Main 场景到左侧
	print("[MainGame] 正在加载 Main.tscn...")
	var main_scene = load("res://scenes/main/Main.tscn")
	if main_scene:
		main_scene_instance = main_scene.instantiate()
		left_viewport.add_child(main_scene_instance)
		print("[MainGame] ✅ Main 场景已加载")
		_activate_camera(main_scene_instance)
	else:
		push_error("[MainGame] ❌ 无法加载 Main.tscn")

	# 加载 BattleArea 到右侧
	print("[MainGame] 正在加载 BattleArea.tscn...")
	var battle_scene = load("res://scenes/main/BattleArea.tscn")
	if battle_scene:
		battle_area = battle_scene.instantiate()
		right_viewport.add_child(battle_area)
		print("[MainGame] ✅ BattleArea 已加载")
		_activate_camera(battle_area)
	else:
		push_error("[MainGame] ❌ 无法加载 BattleArea.tscn")


## 激活场景中的 Camera2D
func _activate_camera(scene_node: Node) -> void:
	var cameras = scene_node.find_children("*", "Camera2D", true, false)
	if cameras.size() > 0:
		var camera = cameras[0] as Camera2D
		camera.enabled = true
		camera.make_current()
		print("[MainGame] ✅ 激活相机: ", camera.name)


## 添加测试背景
func _add_test_backgrounds() -> void:
	# 只在调试时使用，可以移除
	if false:  # 设置为 true 启用测试背景
		if left_viewport:
			var left_bg = ColorRect.new()
			left_bg.color = Color(1, 0, 0, 0.05)
			left_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			left_viewport.add_child(left_bg)

		if right_viewport:
			var right_bg = ColorRect.new()
			right_bg.color = Color(0, 0, 1, 0.05)
			right_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			right_viewport.add_child(right_bg)


## 连接事件
func _connect_events() -> void:
	var event_bus = get_node_or_null("/root/EventBus")
	if event_bus:
		event_bus.score_changed.connect(_on_score_changed)
		event_bus.fruit_merged.connect(_on_fruit_merged)
		event_bus.fruit_spawned.connect(_on_fruit_spawned)


## 水果生成回调
func _on_fruit_spawned(fruit: Node, level: int) -> void:
	if fruit is Fruit:
		# 连接拖拽信号到 CrossScreenDragManager
		var drag_manager = get_node_or_null("DragOverlay")
		if drag_manager and drag_manager.has_method("_on_fruit_spawned"):
			drag_manager._on_fruit_spawned(fruit)
			print("[MainGame] 连接水果拖拽信号: ", fruit.name)


## 更新 UI
func _update_ui() -> void:
	if faction_label:
		var faction_names = {"abyss": "深渊", "undead": "亡灵", "mechanical": "机械"}
		faction_label.text = "阵营: %s" % faction_names.get(current_faction, "深渊")

	if score_label:
		score_label.text = "分数: %d" % score

	if timer_label:
		timer_label.text = "%d" % int(game_time)

	if resources_label:
		resources_label.text = "资源: %d" % resources


## 事件处理
func _on_score_changed(new_score: int) -> void:
	score = new_score
	_update_ui()


func _on_fruit_merged(old_level: int, new_level: int, position: Vector2) -> void:
	# 合成获得资源
	var resource_gain = (old_level + 1) * 5
	resources += resource_gain
	_update_ui()

	print("[MainGame] 合成等级 %d → %d，获得资源: %d" % [old_level, new_level, resource_gain])


## 倒计时更新
func _process(delta: float) -> void:
	if game_time > 0:
		game_time -= delta
		if timer_label:
			timer_label.text = "%d" % int(game_time)

		if game_time <= 0:
			game_time = 0
			print("[MainGame] 时间到！")


## 获取 Main 场景实例
func get_main_scene() -> Node:
	return main_scene_instance


## 获取战斗区域
func get_battle_area() -> Node:
	return battle_area


## 坐标转换（供 CrossScreenDragManager 使用）
func get_left_world_position(screen_pos: Vector2) -> Vector2:
	if left_viewport and left_viewport.get_parent():
		# 获取 SubViewportContainer 的全局位置
		var container = left_viewport.get_parent() as Control
		# 屏幕坐标减去容器位置，得到相对于 ViewPort 的坐标
		return screen_pos - container.global_position
	return Vector2.ZERO


func get_right_world_position(screen_pos: Vector2) -> Vector2:
	if right_viewport and right_viewport.get_parent():
		var container = right_viewport.get_parent() as Control
		return screen_pos - container.global_position
	return Vector2.ZERO


## 区域检测
func is_position_in_left_area(screen_pos: Vector2) -> bool:
	var left_rect = Rect2(0, 0, 575, 850)
	return left_rect.has_point(screen_pos)


func is_position_in_right_area(screen_pos: Vector2) -> bool:
	var right_rect = Rect2(575, 0, 575, 850)
	return right_rect.has_point(screen_pos)


## 调试
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_print_debug_info()


func _print_debug_info() -> void:
	print("\n========== MainGame 调试信息 ==========")
	print("窗口大小: ", get_window().size)
	print("分数: ", score, "  资源: ", resources, "  时间: ", game_time)

	if left_viewport:
		print("左侧 ViewPort: ", left_viewport.size, "  子节点: ", left_viewport.get_child_count())

	if right_viewport:
		print("右侧 ViewPort: ", right_viewport.size, "  子节点: ", right_viewport.get_child_count())

	print("========================================\n")
