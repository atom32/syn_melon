extends Node

## 场景管理器 - 全局单例
## 处理场景切换和淡入淡出过渡效果

# 淡入淡出参数
const FADE_DURATION: float = 0.3
const FADE_COLOR: Color = Color(0, 0, 0, 1)

# 淡入淡出覆盖层
var _fade_canvas: CanvasLayer = null
var _fade_rect: ColorRect = null
var _tween: Tween = null

# 当前是否正在切换场景
var _is_transitioning: bool = false


func _ready() -> void:
	print("[SceneManager] 初始化完成")
	# 不在 _ready() 中创建覆盖层，在首次使用时创建
	call_deferred("_ensure_fade_overlay_created")


## 确保淡入淡出覆盖层已创建
func _ensure_fade_overlay_created() -> void:
	if _fade_canvas != null:
		return  # 已经创建过了

	print("[SceneManager] 创建淡入淡出覆盖层")
	_setup_fade_overlay()


## 初始化淡入淡出覆盖层
func _setup_fade_overlay() -> void:
	# 创建 CanvasLayer（覆盖在所有内容之上）
	_fade_canvas = CanvasLayer.new()
	_fade_canvas.layer = 128  # 最高层级
	_fade_canvas.name = "FadeCanvas"
	_fade_canvas.visible = false  # 初始隐藏，避免阻挡鼠标事件
	get_tree().root.add_child(_fade_canvas)

	# 创建全屏 ColorRect
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0, 0, 0, 0)  # 初始透明
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不阻挡鼠标事件
	_fade_canvas.add_child(_fade_rect)


## 切换场景（带淡入淡出效果）
func change_scene(scene_path: String) -> void:
	if _is_transitioning:
		print("[SceneManager] 场景切换中，忽略请求")
		return

	_is_transitioning = true

	print("[SceneManager] 开始切换到场景: ", scene_path)

	# 确保覆盖层已创建
	_ensure_fade_overlay_created()

	# 显示覆盖层（确保可见性）
	_fade_canvas.visible = true
	_fade_rect.visible = true
	_fade_rect.color = Color(0, 0, 0, 0)  # 从透明开始

	# 创建 Tween
	_tween = create_tween()

	# 淡出（变黑）
	_tween.parallel().tween_property(_fade_rect, "color:a", 1.0, FADE_DURATION)

	# 淡出完成后切换场景
	_tween.tween_callback(_on_fade_out_complete.bind(scene_path))


## 淡出完成回调
func _on_fade_out_complete(scene_path: String) -> void:
	# 切换场景
	get_tree().change_scene_to_file(scene_path)

	# 等待场景加载完成后淡入
	# 注意：需要在新场景的 _ready 中调用 SceneManager.on_scene_loaded()
	call_deferred("_start_fade_in")


## 开始淡入
func _start_fade_in() -> void:
	# 等待一帧确保场景加载完成
	await get_tree().process_frame

	_tween = create_tween()

	# 淡入（变透明）
	_tween.parallel().tween_property(_fade_rect, "color:a", 0.0, FADE_DURATION)

	# 淡入完成后清理
	_tween.tween_callback(_on_transition_complete)


## 场景加载完成回调（由新场景调用）
func on_scene_loaded() -> void:
	# 这个方法可以由新场景在 _ready 中调用，确保场景完全加载后再淡入
	print("[SceneManager] 场景加载完成")
	_start_fade_in()


## 过渡完成回调
func _on_transition_complete() -> void:
	_is_transitioning = false
	print("[SceneManager] 场景切换完成")

	# 隐藏覆盖层，避免阻挡鼠标事件
	if _fade_canvas:
		_fade_canvas.visible = false
	if _fade_rect:
		_fade_rect.visible = false


## 立即切换场景（无淡入淡出，用于测试）
func change_scene_instant(scene_path: String) -> void:
	print("[SceneManager] 立即切换到场景: ", scene_path)
	get_tree().change_scene_to_file(scene_path)


## 退出游戏
func quit_game() -> void:
	print("[SceneManager] 退出游戏")
	get_tree().quit()
