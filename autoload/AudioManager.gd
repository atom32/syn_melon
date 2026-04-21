extends Node

## 音效管理器 - 全局单例
## 管理游戏中的所有音效

# 音效播放器
var collision_player: AudioStreamPlayer = null
var merge_player: AudioStreamPlayer = null
var game_over_player: AudioStreamPlayer = null


func _ready() -> void:
	# 动态创建 AudioStreamPlayer 节点
	collision_player = AudioStreamPlayer.new()
	collision_player.name = "CollisionPlayer"
	add_child(collision_player)

	merge_player = AudioStreamPlayer.new()
	merge_player.name = "MergePlayer"
	add_child(merge_player)

	game_over_player = AudioStreamPlayer.new()
	game_over_player.name = "GameOverPlayer"
	add_child(game_over_player)

	print("AudioManager: 音效播放器初始化完成")


## 播放水果碰撞音效
func play_collision(level: int) -> void:
	if not collision_player:
		return

	# 根据等级轻微调整音量
	var volume = 0.3 + (level * 0.05)  # 等级越高音量稍大
	volume = min(volume, 1.0)

	# 设置音量并播放
	# TODO: 当添加实际音频文件后，设置 collision_player.stream
	# collision_player.volume_db = linear_to_db(volume)
	collision_player.play()

	print(" AudioManager: 碰撞音效 等级%d" % level)


## 播放合成音效（根据等级调整音高）
func play_merge(level: int) -> void:
	if not merge_player:
		return

	# 根据等级计算音高
	# Level 0-4: 较高音 (1.1 - 1.0)
	# Level 5-7: 正常音 (1.0 - 0.9)
	# Level 8-10: 较低音 (0.9 - 0.75)
	var base_pitch = 1.0
	if level <= 4:
		base_pitch = 1.1 - (level * 0.02)  # 1.1 -> 1.0
	elif level <= 7:
		base_pitch = 1.0 - ((level - 5) * 0.03)  # 1.0 -> 0.91
	else:
		base_pitch = 0.9 - ((level - 8) * 0.05)  # 0.9 -> 0.75

	# 添加轻微随机变化，避免单调
	var random_variation = randf_range(-0.05, 0.05)
	var final_pitch = base_pitch + random_variation

	# 限制在合理范围内
	final_pitch = clamp(final_pitch, 0.5, 1.5)

	# 应用音高并播放
	merge_player.pitch_scale = final_pitch

	# TODO: 当添加实际音频文件后，设置 merge_player.stream
	merge_player.play()

	print("AudioManager: 合成音效 等级%d 音高%.2f" % [level, final_pitch])


## 播放超大合成音效（大西瓜）
func play_mega_merge() -> void:
	if not merge_player:
		return

	# 超大合成使用更低沉的音高
	merge_player.pitch_scale = 0.6

	# 增加音量
	# TODO: merge_player.volume_db = linear_to_db(0.8)

	# TODO: 当添加实际音频文件后，设置 merge_player.stream
	merge_player.play()

	print("AudioManager: 超大合成音效！🎉")


## 播放游戏结束音效
func play_game_over() -> void:
	if not game_over_player:
		return

	# 游戏结束使用较低音高
	game_over_player.pitch_scale = 0.8

	# TODO: 当添加实际音频文件后，设置 game_over_player.stream
	game_over_player.play()

	print("AudioManager: 游戏结束音效")
