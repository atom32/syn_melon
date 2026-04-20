# Claude Code - 项目笔记

## Godot 场景文件 (.tscn) 手写注意事项

### ⚠️ 重要规则

1. **不要手动添加 `unique_id` 属性**
   - `unique_id` 应该由 Godot 编辑器自动管理
   - 手写场景文件时，完全省略此属性
   - 错误示例：`[node name="Main" type="Node2D" unique_id=123456"]`
   - 正确示例：`[node name="Main" type="Node2D"]`

2. **节点声明格式**
   - 根节点：`[node name="NodeName" type="NodeType"]`
   - 子节点：`[node name="NodeName" type="NodeType" parent="ParentName"]`
   - 不要在行尾有多余的引号

3. **ExtResource ID 格式**
   - 必须遵循 `数字_字母数字` 格式
   - 错误示例：`id="2_fruit"` (自定义名称)
   - 正确示例：`id="2_h8k9m"` (随机字母数字)

4. **@export 变量不能在声明时赋值 preload()**
   - `@export` 变量应该在编辑器中赋值
   - 代码中用单独变量存储 preload 结果
   ```gdscript
   # 错误
   @export var scene: PackedScene = preload("res://scene.tscn")

   # 正确
   @export var scene: PackedScene
   var _scene_default: PackedScene = preload("res://scene.tscn")
   ```

5. **load_steps 计数**
   - 必须准确计算所有资源的数量
   - `[ext_resource ...]` 和 `[sub_resource ...]` 都要计入

### 场景文件结构模板

```
[gd_scene load_steps=N format=3 uid="uid://..."]

[ext_resource type="Script" path="res://script.gd" id="1_xxxxx"]
[ext_resource type="Texture2D" path="res://image.png" id="2_yyyyy"]

[sub_resource type="CircleShape2D" id="CircleShape2D_zzzzz"]
radius = 25.0

[node name="Root" type="Node2D"]
script = ExtResource("1_xxxxx")

[node name="Child" type="NodeType" parent="."]
property = value
```

## 项目结构

```
syn_melon/
├── scenes/          # 场景文件 (.tscn)
│   ├── Main.tscn
│   └── Fruit.tscn
├── scripts/         # GDScript 脚本 (.gd)
│   ├── Main.gd
│   └── Fruit.gd
├── assets/          # 资源文件
│   ├── sprites/
│   ├── sounds/
│   ├── music/
│   ├── fonts/
│   └── shaders/
├── autoload/        # 自动加载的单例脚本
├── themes/          # UI主题
└── addons/          # 插件/扩展
```

## 游戏设计

### 合成大西瓜

- **类型**: 2D 物理合成游戏
- **引擎**: Godot 4.6.2
- **语言**: GDScript

### 水果等级系统 (Level 0-10)

| Level | 名称 | 半径 | 质量 | 颜色 |
|-------|------|------|------|------|
| 0 | 樱桃 | 15px | 1.0 | 红色 |
| 1 | 草莓 | 22px | 2.0 | 粉色 |
| 2 | 葡萄 | 30px | 3.0 | 紫色 |
| 3 | 橙子 | 38px | 5.0 | 橙色 |
| 4 | 柿子 | 48px | 8.0 | 橘红色 |
| 5 | 桃子 | 58px | 12.0 | 桃色 |
| 6 | 菠萝 | 68px | 18.0 | 黄色 |
| 7 | 椰子 | 80px | 25.0 | 棕色 |
| 8 | 半个西瓜 | 95px | 35.0 | 绿色 |
| 9 | 大西瓜 | 110px | 50.0 | 浅绿色 |
| 10 | 超级大西瓜 | 130px | 80.0 | 亮绿色 |

## 当前实现状态

- [x] 项目文件夹结构
- [x] Main 场景（带地面碰撞）
- [x] Fruit 场景（带 RigidBody2D 和脚本）
- [x] Main.gd 脚本（点击生成水果）
- [x] Fruit.gd 脚本（等级系统）
- [ ] 水果碰撞检测
- [ ] 水果合成逻辑
- [ ] 游戏结束检测
- [ ] 计分系统
