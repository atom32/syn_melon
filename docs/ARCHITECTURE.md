# Syn Melon 项目架构

## 目录结构

```
syn_melon/
├── autoload/              # 自动加载单例（全局管理器）
│   ├── AudioManager.gd       # 音频管理
│   ├── ComboManager.gd       # 连击系统
│   ├── DataManager.gd        # JSON 数据加载
│   ├── EventBus.gd           # 事件总线
│   ├── GameManager.gd        # 游戏状态管理
│   ├── SaveManager.gd        # 存档管理
│   └── SceneManager.gd       # 场景切换（带淡入淡出）
│
├── scenes/                # 场景文件
│   ├── main/                 # 主游戏场景
│   │   ├── MainMenu.tscn         # 主菜单
│   │   ├── Main.tscn             # 经典合成模式
│   │   ├── MainGame.tscn         # 双屏模式（合成+战场）
│   │   ├── MergeArea.tscn        # 合成区域（SubViewport 左屏）
│   │   ├── BattleArea.tscn       # 战斗区域（SubViewport 右屏）
│   │   └── Fruit.tscn            # 水果预制体
│   ├── effects/              # 特效场景
│   │   ├── ExplosionEffect.tscn     # 普通爆炸特效
│   │   ├── MegaExplosionEffect.tscn # 大西瓜爆炸特效
│   │   ├── FloatingScore.tscn       # 浮动分数
│   │   └── MergeEffects.tscn        # 合成特效容器
│   └── ui/                   # UI 场景
│       ├── ComboDisplay.tscn        # 连击显示
│       ├── GameOverPanel.tscn       # 游戏结束面板
│       └── AudioManager.tscn        # 音频管理器节点
│
├── scripts/               # 脚本文件
│   ├── main/                 # 主游戏脚本
│   │   ├── MainMenu.gd            # 主菜单逻辑
│   │   ├── Main.gd                # 经典模式控制器
│   │   ├── MainGame.gd            # 双屏模式控制器
│   │   ├── MergeArea.gd           # 合成区域逻辑
│   │   └── BattleArea.gd          # 战斗区域逻辑
│   ├── effects/              # 特效脚本
│   │   ├── EffectManager.gd          # 特效管理器
│   │   ├── ExplosionEffect.gd        # 爆炸特效
│   │   ├── MegaExplosionEffect.gd    # 超大爆炸特效
│   │   └── FloatingScore.gd          # 浮动分数
│   ├── ui/                   # UI 脚本
│   │   ├── ComboDisplay.gd          # 连击显示逻辑
│   │   └── GameOverPanel.gd         # 游戏结束面板
│   ├── systems/              # 游戏系统
│   │   ├── CameraManager.gd         # 相机管理（屏幕震动）
│   │   ├── CrossScreenDragManager.gd # 跨屏拖拽系统
│   │   ├── WarningLine.gd           # 警戒线系统
│   │   └── TextureGenerator.gd      # 纹理生成器
│   └── core/                 # 核心游戏逻辑
│       ├── Fruit.gd                # 水果物理和合成逻辑
│       └── FruitConfig.gd          # 水果配置（JSON 包装器）
│
├── data/                  # 数据文件
│   └── units_db.json          # 单位数据库
│
├── docs/                  # 文档
│   ├── ARCHITECTURE.md         # 本文件
│   └── COMBO_SYSTEM.md         # 连击系统文档
│
├── assets/               # 资源文件
│   ├── audio/                 # 音频文件
│   ├── fonts/                 # 字体文件
│   ├── shaders/               # 着色器
│   └── sprites/               # 精灵图
│
└── CLAUDE.md             # 项目说明（给 Claude AI）
```

---

## 核心系统

### 1. 单例系统（Autoload）

| 单例 | 职责 |
|------|------|
| `GameManager` | 管理分数、待发射水果、游戏状态 |
| `EventBus` | 全局事件通信（解耦系统） |
| `DataManager` | 加载和管理 JSON 数据 |
| `AudioManager` | 音效播放管理 |
| `SaveManager` | 存档读写 |
| `SceneManager` | 场景切换（带淡入淡出效果） |
| `ComboManager` | 连击检测和乘数计算 |

### 2. 场景架构

#### 经典模式（Main.tscn）
```
Main (Node2D)
├── Ground (StaticBody2D)           # 地面
├── LeftWall (StaticBody2D)         # 左墙
├── RightWall (StaticBody2D)        # 右墙
├── WarningLine (Area2D)            # 警戒线
├── CooldownTimer (Timer)           # 发射冷却
├── UIBackground (Control)          # UI 容器
└── GameOverPanel (Panel)           # 游戏结束
```

#### 双屏模式（MainGame.tscn）
```
MainGame (Control)
├── ScreenContainer (HBoxContainer)
│   ├── LeftPanel (PanelContainer)
│   │   └── LeftViewport (SubViewport) → Main 场景
│   └── RightPanel (PanelContainer)
│       └── RightViewport (SubViewport) → BattleArea 场景
├── TopBar (PanelContainer)         # 顶部 UI
├── BottomBar (PanelContainer)      # 底部 UI
└── DragOverlay (Control)           # 跨屏拖拽管理器
```

### 3. 事件流

#### 水果合成事件流
```
Fruit._on_body_entered()
    ↓
Fruit._merge_fruits()
    ↓
EventBus.emit_fruit_merged()
    ↓
├── ComboManager.trigger_merge()    # 计算连击
├── EffectManager.create_explosion() # 播放特效
├── GameManager._on_fruit_merged()   # 更新分数
└── EventBus.emit_score_changed()    # 通知 UI
```

#### 跨屏拖拽事件流
```
Fruit._input() (右键检测)
    ↓
Fruit.drag_to_battle_requested.emit()
    ↓
CrossScreenDragManager._on_drag_requested()
    ↓
创建虚影精灵跟随鼠标
    ↓
鼠标释放 → 在 BattleArea 创建部署标记
```

---

## 数据流

### 配置数据（JSON → 代码）
```
data/units_db.json
    ↓ (DataManager 加载)
DataManager.get_unit(faction, level)
    ↓
FruitConfig.get_radius/level/mass()
    ↓
Fruit._update_fruit_properties()
```

### 游戏状态
```
GameManager
├── score: int                 # 当前分数
├── current_fruit_level: int   # 待发射水果等级
└── next_fruit_level: int      # 下一个水果等级
```

---

## 关键设计模式

### 1. 事件总线模式
使用 `EventBus` 单例实现松耦合通信：
- 发射方：`EventBus.emit_fruit_merged(...)`
- 接收方：`EventBus.fruit_merged.connect(_callback)`

### 2. 对象池模式（已废弃）
之前实现的对象池系统因初始化问题已废弃，恢复直接实例化。

### 3. 预制体模式
`Fruit.tscn` 作为预制体，通过 `instantiate()` 动态创建。

---

## 扩展点

### 添加新单位类型
1. 更新 `data/units_db.json`
2. 重启游戏，DataManager 自动加载

### 添加新特效
1. 创建场景文件（如 `scenes/effects/NewEffect.tscn`）
2. 在 `EffectManager.gd` 添加播放方法
3. 在需要的地方调用

### 添加新游戏模式
1. 创建新场景（继承或复用现有组件）
2. 在 `MainMenu.gd` 添加入口
3. 通过 `SceneManager.change_scene()` 切换
