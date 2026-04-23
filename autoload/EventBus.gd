extends Node

## ==========================================
## 🍉 合成大西瓜 - 全局事件总线 (EventBus)
## ==========================================

## 调试模式开关：迁移阶段建议开启，方便在控制台观察事件流
const DEBUG_MODE: bool = true

## ==========================================
## 1. 信号定义 (Signals)
## ==========================================

## --- 水果相关 ---
signal fruit_spawned(fruit: Node2D, level: int)
signal fruit_merged(old_level: int, new_level: int, position: Vector2)
signal mega_fruit_merged(position: Vector2)

## --- 连击相关 ---
signal combo_activated(count: int, multiplier: float, position: Vector2)
signal combo_reset()

## --- 分数相关 ---
signal score_changed(new_score: int)
signal high_score_updated(new_high_score: int)

## --- 游戏流程 ---
signal game_over()
signal game_restarted()

## ==========================================
## 2. 发射器方法 (Emitters)
## ==========================================

func emit_fruit_spawned(fruit: Node2D, level: int) -> void:
	_log_event("fruit_spawned", [fruit, level])
	fruit_spawned.emit(fruit, level)


func emit_fruit_merged(old_level: int, new_level: int, position: Vector2) -> void:
	_log_event("fruit_merged", [old_level, new_level, position])
	fruit_merged.emit(old_level, new_level, position)


func emit_mega_fruit_merged(position: Vector2) -> void:
	_log_event("mega_fruit_merged", [position])
	mega_fruit_merged.emit(position)


func emit_combo_activated(count: int, multiplier: float, position: Vector2) -> void:
	_log_event("combo_activated", [count, multiplier, position])
	combo_activated.emit(count, multiplier, position)


func emit_combo_reset() -> void:
	_log_event("combo_reset", [])
	combo_reset.emit()


func emit_score_changed(new_score: int) -> void:
	_log_event("score_changed", [new_score])
	score_changed.emit(new_score)


func emit_high_score_updated(new_high_score: int) -> void:
	_log_event("high_score_updated", [new_high_score])
	high_score_updated.emit(new_high_score)


func emit_game_over() -> void:
	_log_event("game_over", [])
	game_over.emit()


func emit_game_restarted() -> void:
	_log_event("game_restarted", [])
	game_restarted.emit()


## ==========================================
## 3. 内部辅助方法
## ==========================================

func _log_event(event_name: String, args: Array = []) -> void:
	if DEBUG_MODE:
		print("[EventBus] Emitted: '", event_name, "' | Args: ", args)


func _ready() -> void:
	print("[EventBus] 初始化完成 - 调试模式: ", DEBUG_MODE)
