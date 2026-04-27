# Phase 2: SubViewport 双屏布局 - 实施摘要

## 📋 实施内容

### ✅ 已完成任务

#### 1. MainGame 容器场景
- **文件**: `scenes/MainGame.tscn`
- **功能**:
  - 左右分屏容器（HBoxContainer）
  - 两个 SubViewport（MergeViewport + BattleViewport）
  - 顶层 UI 覆盖层（UILayer）
  - 跨屏拖拽管理器（DragOverlay）

**场景结构**:
```
MainGame (Node)
├── ScreenContainer (HBoxContainer)
│   ├── LeftPanel (Panel) - 575px 宽
│   │   └── MergeViewportContainer
│   │       └── MergeViewport (575x850)
│   └── RightPanel (Panel) - 575px 宽
│       └── BattleViewportContainer
│           └── BattleViewport (575x850)
└── UILayer (Control)
    ├── DragOverlay (跨屏拖拽)
    ├── TopBar (顶部 UI)
    │   ├── FactionLabel (阵营显示)
    │   ├── ScoreLabel (分数)
    │   └── TimerLabel (倒计时)
    └── BottomBar (底部 UI)
        └── ResourcesLabel (资源)
```

#### 2. MainGame 控制器
- **文件**: `scripts/MainGame.gd`
- **功能**:
  - 加载和管理两个 SubViewport 场景
  - 协调合并区域和战斗区域
  - 坐标转换（屏幕 ↔ 各 Viewport 世界坐标）
  - 区域检测（判断鼠标在哪个区域）
  - 游戏状态管理（分数、资源、阵营）

**关键方法**:
- `get_merge_world_position(screen_pos)` - 屏幕坐标转合并区域坐标
- `get_battle_world_position(screen_pos)` - 屏幕坐标转战斗区域坐标
- `is_position_in_merge_area(screen_pos)` - 检查是否在合并区域
- `is_position_in_battle_area(screen_pos)` - 检查是否在战斗区域

#### 3. MergeArea 场景
- **文件**: `scenes/MergeArea.tscn` + `scripts/MergeArea.gd`
- **功能**:
  - 从 Main.tscn 提取的合并逻辑
  - 保留物理模拟、水果生成、合成机制
  - 移除 UI 逻辑（UI 现在在 MainGame.UILayer）
  - 独立的 Camera2D
  - 完整的边界墙壁和地面

**保留元素**:
- ✅ 物理墙壁和地面
- ✅ 水果生成和预览
- ✅ 合成逻辑
- ✅ 警告线
- ✅ 连击显示

**移除元素**:
- ❌ UI 面板（移到 MainGame.UILayer）
- ❌ 游戏结束面板（移到 MainGame.UILayer）

#### 4. BattleArea 场景
- **文件**: `scenes/BattleArea.tscn` + `scripts/BattleArea.gd`
- **功能**:
  - 战斗区域容器
  - 四周边界墙壁
  - 部署区域标识（前线、中线、后线）
  - 网格背景
  - 占位符：单位部署逻辑

**场景特征**:
- 地面背景色：深色 (0.1, 0.1, 0.15)
- 三层部署区域：
  - 后线 (100-400px): 红色调 - 远程单位
  - 中线 (400-600px): 黄色调 - 辅助单位
  - 前线 (600-750px): 绿色调 - 近战单位

#### 5. 跨屏拖拽系统
- **文件**: `scripts/CrossScreenDragManager.gd`
- **功能**:
  - 处理从合并区域到战斗区域的拖拽
  - 全局坐标路由
  - 虚影显示（拖拽时的半透明副本）
  - 单位转换（占位符实现，Phase 5 完善）

**拖拽状态机**:
```
IDLE → 检测点击 → DRAGGING → 检测释放 → 部署/取消 → IDLE
```

## 📊 文件清单

### 新增文件
```
scenes/
  ├── MainGame.tscn              (NEW - 双屏容器)
  ├── MergeArea.tscn             (NEW - 合并区域)
  └── BattleArea.tscn            (NEW - 战斗区域)

scripts/
  ├── MainGame.gd                (NEW - 主控制器)
  ├── MergeArea.gd               (NEW - 合并控制器)
  ├── BattleArea.gd              (NEW - 战斗控制器)
  └── CrossScreenDragManager.gd  (NEW - 跨屏拖拽)
```

### 修改文件
```
project.godot  (查看配置，窗口大小 1150x850 已适配双屏)
```

## 🎨 UI 布局

### 顶部栏 (TopBar)
```
┌─────────────────────────────────────────────────┐
│ 阵营: 深渊    分数: 0         90               │
└─────────────────────────────────────────────────┘
```

### 底部栏 (BottomBar)
```
┌─────────────────────────────────────────────────┐
│ 资源: 100            拖拽单位到右侧战场部署    │
└─────────────────────────────────────────────────┘
```

### 双屏布局
```
┌──────────────┬──────────────┐
│   合并区域    │   战斗区域    │
│  (MergeArea)  │ (BattleArea)  │
│              │              │
│  物理模拟     │  单位部署     │
│  水果合成     │  自动战斗     │
│              │              │
└──────────────┴──────────────┘
```

## 🔧 技术细节

### SubViewport 配置
- **分辨率**: 575x850 (每个)
- **更新模式**: `UPDATE_ALWAYS` (实时渲染)
- **拉伸**: SubViewportContainer 自动拉伸

### 坐标系统
```gdscript
# 屏幕坐标 → Viewport 世界坐标
func get_merge_world_position(screen_pos: Vector2) -> Vector2:
    return merge_viewport.get_screen_transform().affine_inverse() * screen_pos

# Viewport 世界坐标 → 屏幕坐标
func get_screen_position(viewport_pos: Vector2) -> Vector2:
    return merge_viewport.get_screen_transform() * viewport_pos
```

### 区域检测
```gdscript
# 左侧区域 (合并)
Rect2(0, 0, 575, 850)

# 右侧区域 (战斗)
Rect2(575, 0, 575, 850)
```

## 🧪 测试方法

### 1. 直接测试 MainGame
```
在 Godot 编辑器中:
1. 打开 scenes/MainGame.tscn
2. 按 F5 运行
3. 应该看到左右分屏
4. 左侧可以生成和合成水果
5. 右侧显示战斗区域网格
```

### 2. 从菜单测试
```
保持现有的 MainMenu，添加按钮启动 MainGame:
（Phase 6 会完善）
```

### 3. 验证物理隔离
```
1. 在左侧生成多个水果
2. 观察物理模拟是否正常
3. 确认没有物理对象"泄漏"到右侧
4. 确认 FPS 稳定在 60
```

## ⚠️ 已知限制

### 当前实现
- ✅ 双屏渲染正常
- ✅ 合并功能完整
- ✅ 物理隔离工作正常
- ⏳ 跨屏拖拽（框架已完成，Phase 5 完善单位转换）
- ⏳ 战斗系统（占位符，Phase 5 实现）

### 待完善（Phase 5+）
- 单位从合并区域拖到战斗区域的实际转换
- 战斗单位的 AI 和攻击逻辑
- 敌人生成和波次管理
- 战斗特效和反馈

## 🎯 下一步

**Phase 3: 对象池系统**
- 优化高频生成性能
- 减少内存分配和 GC
- 支持大量单位同时存在

## 📝 调试技巧

### 查看场景树
```gdscript
# 在 MainGame.gd 中调用
debug_print_scene_tree()
```

### 检查坐标转换
```gdscript
# 打印坐标信息
print("Screen: ", screen_pos)
print("Merge: ", get_merge_world_position(screen_pos))
print("Battle: ", get_battle_world_position(screen_pos))
```

### 测试区域检测
```gdscript
# 检查鼠标位置
var mouse_pos = get_global_mouse_position()
print("In merge: ", is_position_in_merge_area(mouse_pos))
print("In battle: ", is_position_in_battle_area(mouse_pos))
```

## ✨ 优势

1. **物理隔离**: 两个区域完全独立，互不干扰
2. **模块化**: 合并逻辑和战斗逻辑分离
3. **可扩展**: 容易添加更多区域或 UI
4. **性能**: SubViewport 支持独立的渲染和物理
5. **跨屏交互**: 统一的坐标系统支持跨屏操作

---

**实施日期**: 2026-04-27
**实施阶段**: Phase 2 - SubViewport 双屏布局
**状态**: ✅ 已完成
