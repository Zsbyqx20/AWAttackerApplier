# AWAttacker 项目设计文档

## 1. 项目结构

```
lib/
├── constants/        # 常量定义
├── models/          # 数据模型
├── services/        # 服务层
├── widgets/         # UI组件
├── pages/           # 页面
└── main.dart        # 应用入口
```

## 2. 模块说明

### 2.1 常量模块 (constants/)
- `storage_keys.dart`: 存储相关的键名常量
  - `apiUrlKey`: API服务器地址的存储键
  - `wsUrlKey`: WebSocket服务器地址的存储键
  - `rulesKey`: 规则列表的存储键

### 2.2 数据模型 (models/)
- `rule.dart`: 规则模型类
  - `Rule`: 规则数据模型，包含基本信息和悬浮窗样式列表
  - `OverlayStyle`: 悬浮窗样式数据模型，包含位置、大小、颜色等属性

### 2.3 服务模块 (services/)
- `permission_service.dart`: 权限管理服务
  - `checkOverlayPermission()`: 检查悬浮窗权限
  - `requestOverlayPermission()`: 请求悬浮窗权限

- `storage_service.dart`: 存储服务
  - `saveUrls()`: 保存服务器地址配置
  - `loadUrls()`: 加载服务器地址配置
  - `saveRules()`: 保存规则列表
  - `loadRules()`: 加载规则列表

- `connection_service.dart`: 连接服务
  - 管理与服务器的连接状态
  - 处理 API 和 WebSocket 连接
  - 提供连接状态监听

### 2.4 UI组件 (widgets/)
- `permission_card.dart`: 权限状态卡片
  - 显示权限状态
  - 提供授权按钮

- `server_config_card.dart`: 服务器配置卡片
  - API服务器地址输入
  - WebSocket服务器地址输入

- `server_status_card.dart`: 服务器状态卡片
  - 显示API服务器连接状态
  - 显示WebSocket服务器连接状态

### 2.5 页面 (pages/)
- `server_config_page.dart`: 服务器配置页面
  - 集成权限管理
  - 服务器配置
  - 状态显示
  - 规则列表入口

- `rule_list_page.dart`: 规则列表页面
  - 显示规则列表
  - 规则的增删改查
  - 规则启用/禁用状态切换
  - 显示悬浮窗数量

- `rule_edit_page.dart`: 规则编辑页面
  - 基本信息编辑（规则名称、包名、活动名）
  - 悬浮窗配置
    - UI Automator 代码
    - 位置和大小设置（x、y、宽度、高度）
    - 背景颜色设置
  - 文字风格设置
    - 文字内容
    - 文字大小
    - 文字颜色
    - 文字对齐（水平和垂直）
    - 内边距设置
  - 多悬浮窗管理（最多10个）

## 3. 功能特性

### 3.1 权限管理
- 悬浮窗权限检查和请求
- 权限状态实时更新
- 权限状态持久化

### 3.2 服务器连接
- API服务器连接状态管理
- WebSocket连接状态管理
- 连接状态实时显示
- 服务启动/停止控制

### 3.3 规则管理
- 规则的增删改查
- 规则启用/禁用
- 规则数据持久化
- 多悬浮窗支持
- 悬浮窗样式完整配置

### 3.4 UI交互
- 响应式布局
- 实时预览
- 友好的错误提示
- 统一的视觉风格

## 4. 技术实现

### 4.1 状态管理
- 使用 StatefulWidget 管理页面状态
- 使用 StreamController 管理连接状态
- 使用 SharedPreferences 持久化数据

### 4.2 UI实现
- Material Design 风格
- 自定义组件封装
- 统一的输入控件样式
- 合理的布局结构

### 4.3 数据处理
- JSON序列化和反序列化
- 数据模型验证
- 错误处理和异常捕获

## 5. 开发规范

### 5.1 代码组织
- 功能模块化
- 组件复用
- 清晰的目录结构

### 5.2 命名规范
- 文件名使用小写下划线命名法
- 类名使用大驼峰命名法
- 变量和方法使用小驼峰命名法
- 常量使用大写下划线命名法

### 5.3 注释规范
- 类级别文档注释
- 方法级别文档注释
- 关键逻辑说明

## 6. 依赖说明

- Flutter SDK: ^3.2.0
- shared_preferences: ^2.2.2
- flutter_overlay_window: ^0.4.5
- http: ^1.1.0
- web_socket_channel: ^2.4.0

## 7. 注意事项

1. 权限管理
   - Android 悬浮窗权限处理
   - 权限状态检查机制
   - 权限请求异常处理

2. 数据存储
   - 使用 SharedPreferences 存储配置
   - 规则数据的序列化和反序列化
   - 数据迁移和版本控制

3. 性能优化
   - 避免不必要的重建
   - 合理使用 const 构造函数
   - 资源释放和内存管理

4. 错误处理
   - 网络错误处理
   - 权限错误处理
   - 数据验证和错误提示 