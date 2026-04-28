# 项目架构整理计划

## 当前文件结构

### 问题：
1. **大量 .uid 文件** - Godot 自动生成，不应提交到 git
2. **测试文件未清理** - DataTest, TestDualScreen
3. **文档散乱** - PHASE*.md, TEST_GUIDE.md, idea.md 等临时文档
4. **场景/脚本未分类** - 全部放在 scenes/ 和 scripts/ 根目录

---

## 建议的新结构

```
syn_melon/
├── autoload/              # 单例脚本
│   ├── AudioManager.gd
│   ├── ComboManager.gd
│   ├── DataManager.gd
│   ├── EventBus.gd
│   ├── GameManager.gd
│   ├── SaveManager.gd
│   └── SceneManager.gd
│
├── scenes/                # 场景文件（按功能分类）
│   ├── main/             # 主游戏场景
│   │   ├── MainMenu.tscn
│   │   ├── Main.tscn
│   │   ├── MainGame.tscn
│   │   ├── MergeArea.tscn
│   │   └── BattleArea.tscn
│   ├── effects/          # 特效场景
│   │   ├── ExplosionEffect.tscn
│   │   ├── MegaExplosionEffect.tscn
│   │   ├── FloatingScore.tscn
│   │   └── MergeEffects.tscn
│   └── ui/               # UI 场景
│       ├── ComboDisplay.tscn
│       ├── GameOverPanel.tscn
│       └── AudioManager.tscn
│
├── scripts/               # 脚本文件（按功能分类）
│   ├── main/             # 主游戏脚本
│   │   ├── MainMenu.gd
│   │   ├── Main.gd
│   │   ├── MainGame.gd
│   │   ├── MergeArea.gd
│   │   └── BattleArea.gd
│   ├── effects/          # 特效脚本
│   │   ├── EffectManager.gd
│   │   ├── ExplosionEffect.gd
│   │   ├── MegaExplosionEffect.gd
│   │   └── FloatingScore.gd
│   ├── ui/               # UI 脚本
│   │   ├── ComboDisplay.gd
│   │   └── GameOverPanel.gd
│   ├── systems/          # 系统脚本
│   │   ├── CameraManager.gd
│   │   ├── CrossScreenDragManager.gd
│   │   ├── WarningLine.gd
│   │   └── TextureGenerator.gd
│   └── core/             # 核心游戏逻辑
│       ├── Fruit.gd
│       └── FruitConfig.gd
│
├── data/                  # 数据文件
│   └── units_db.json
│
├── docs/                  # 文档（新建）
│   ├── COMBO_SYSTEM.md
│   └── ARCHITECTURE.md
│
├── assets/               # 资源文件
│   ├── audio/
│   ├── fonts/
│   ├── shaders/
│   └── sprites/
│
└── CLAUDE.md             # 项目说明（根目录保留）
```

---

## 清理操作

### 1. 删除无用文件

```bash
# 测试场景和脚本
rm scenes/DataTest.tscn
rm scripts/DataTest.gd
rm scenes/TestDualScreen.tscn
rm scripts/TestDualScreen.gd

# 临时文档
rm PHASE1_SUMMARY.md
rm PHASE2_SUMMARY.md
rm PHASE2_FIXES.md
rm PHASE2_COMPLETE.md
rm TEST_GUIDE.md
rm idea.md

# 所有 .uid 文件
find . -name "*.uid" -delete
```

### 2. 更新 .gitignore

确保 .uid 文件不再被追踪：

```gitignore
# Godot 4+ specific ignores
.godot/
/android/
*.uid
**/*.uid
```

### 3. 重组目录结构

创建新的子目录并移动文件：

```bash
# 创建新目录
mkdir -p scenes/main scenes/effects scenes/ui
mkdir -p scripts/main scripts/effects scripts/ui scripts/systems scripts/core
mkdir -p docs

# 移动场景文件
# Main 场景
mv scenes/MainMenu.tscn scenes/main/
mv scenes/Main.tscn scenes/main/
mv scenes/MainGame.tscn scenes/main/
mv scenes/MergeArea.tscn scenes/main/
mv scenes/BattleArea.tscn scenes/main/

# 特效场景
mv scenes/ExplosionEffect.tscn scenes/effects/
mv scenes/MegaExplosionEffect.tscn scenes/effects/
mv scenes/FloatingScore.tscn scenes/effects/
mv scenes/MergeEffects.tscn scenes/effects/

# UI 场景
mv scenes/ComboDisplay.tscn scenes/ui/
mv scenes/GameOverPanel.tscn scenes/ui/
mv scenes/AudioManager.tscn scenes/ui/

# 移动脚本文件
# Main 脚本
mv scripts/MainMenu.gd scripts/main/
mv scripts/Main.gd scripts/main/
mv scripts/MainGame.gd scripts/main/
mv scripts/MergeArea.gd scripts/main/
mv scripts/BattleArea.gd scripts/main/

# 特效脚本
mv scripts/EffectManager.gd scripts/effects/
mv scripts/ExplosionEffect.gd scripts/effects/
mv scripts/MegaExplosionEffect.gd scripts/effects/
mv scripts/FloatingScore.gd scripts/effects/

# UI 脚本
mv scripts/ComboDisplay.gd scripts/ui/
mv scripts/GameOverPanel.gd scripts/ui/

# 系统脚本
mv scripts/CameraManager.gd scripts/systems/
mv scripts/CrossScreenDragManager.gd scripts/systems/
mv scripts/WarningLine.gd scripts/systems/
mv scripts/TextureGenerator.gd scripts/systems/

# 核心脚本
mv scripts/Fruit.gd scripts/core/
mv scripts/FruitConfig.gd scripts/core/

# 移动文档
mv COMBO_SYSTEM.md docs/
```

### 4. 更新场景文件中的脚本路径

移动后需要更新所有 .tscn 文件中的 `ExtResource` 路径：

- `res://scripts/MainMenu.gd` → `res://scripts/main/MainMenu.gd`
- `res://scripts/Main.gd` → `res://scripts/main/Main.gd`
- 等等...

### 5. 更新 autoload 路径

如果 autoload 脚本移动了，需要更新 project.godot：

```ini
[autoload]
GameManager="res://autoload/GameManager.gd"
...
```

---

## 注意事项

1. **移动文件前先备份** - 确保可以回滚
2. **移动后测试所有场景** - 检查脚本引用是否正确
3. **更新 Godot 编辑器** - 可能需要重新加载项目
4. **分步执行** - 建议一次移动一个类别，测试后再继续

---

## 执行顺序

1. ✅ 删除无用文件（.uid, 测试文件, 临时文档）
2. ✅ 更新 .gitignore
3. ⚠️ 创建新目录结构
4. ⚠️ 移动场景文件
5. ⚠️ 移动脚本文件
6. ⚠️ 更新场景中的脚本引用
7. ⚠️ 测试所有功能
8. ⚠️ 提交到 git
