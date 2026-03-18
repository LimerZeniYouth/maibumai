# 买不买

一个用 Flutter 构建的本地理性消费 App，帮助用户把“想买”先记下来，再通过延迟决策降低冲动消费。

## 1 产品架构设计

- 产品定位：购物清单 + 心愿清单 + 理性消费工具
- 核心流程：记录想买 → 观察等待 → 左滑标记已购买 / 右滑标记不买了 → 自动累计节省金额
- 信息架构：`心愿单`、`历史`、`添加`、`统计`、`设置` 五个底部入口，中央 `+` 作为主操作
- 数据流：Flutter UI → `AppProvider` → `ItemRepository` → `SQLite`
- 设计原则：移动端优先、极简卡片、iOS 风格、柔和阴影、大圆角、轻动效

## 2 UI 页面结构

### 首页 / 心愿单
- 顶部标题与年度节省文案
- Hero 卡片展示总节省金额
- 物品卡片列表：名称、价格、类别、创建时间、备注
- 左右滑动操作：
  - 右滑：`不买了`
  - 左滑：`已购买`

### 历史页
- 查看全部已处理记录
- 支持 `全部` / `已购买` / `不买了` 三种筛选
- 顶部摘要卡展示购买次数、放弃次数、累计支出、累计节省
- 历史卡片展示状态、价格、分类、处理时间、备注

### 统计页
- 时间维度切换：今日 / 本周 / 本月 / 本年 / 全部
- 指标卡片：本周期节省、累计节省、放弃次数、当前想买
- 图表区域：折线图、柱状图、饼图

### 添加页
- Bottom Sheet 弹出
- 表单字段：名称、价格、类别、备注
- 支持自定义类别
- 添加成功有按钮缩放与反馈动效

### 设置页
- 浅色 / 深色 / 跟随系统
- 类别颜色展示
- 年度成果摘要
- 示例数据重置

## 3 Flutter 项目结构

```text
lib/
  data/
    app_database.dart
    item_repository.dart
  models/
    app_stats.dart
    category_tag.dart
    item_status.dart
    stats_filter.dart
    wish_item.dart
  providers/
    app_provider.dart
    theme_provider.dart
  screens/
    add/add_item_sheet.dart
    history/history_screen.dart
    home/home_screen.dart
    settings/settings_screen.dart
    stats/stats_screen.dart
  theme/app_theme.dart
  utils/
    default_categories.dart
    formatters.dart
  widgets/
    animated_primary_button.dart
    category_chip.dart
    empty_state.dart
    glass_card.dart
    hero_stat_card.dart
    stats_charts.dart
    wish_item_card.dart
  main.dart
```

## 4 本地数据库设计

### 表：`items`
- `id TEXT PRIMARY KEY`
- `name TEXT NOT NULL`
- `price REAL NOT NULL`
- `category TEXT NOT NULL`
- `note TEXT`
- `created_at INTEGER NOT NULL`
- `status TEXT NOT NULL`
- `skipped_at INTEGER`
- `bought_at INTEGER`

### 表：`categories`
- `name TEXT PRIMARY KEY`
- `color_value INTEGER NOT NULL`
- `is_default INTEGER NOT NULL`

### 表：`settings`
- 预留本地设置存储

## 5 UI 组件代码

关键组件：
- `GlassCard`：统一大圆角卡片与阴影
- `WishItemCard`：心愿卡片
- `HeroStatCard`：首页顶部视觉卡片
- `AnimatedPrimaryButton`：添加按钮点击反馈
- `SavingsLineChart` / `MonthlyBarChart` / `CategoryPieChart`：统计图表

## 6 核心页面代码

- `lib/main.dart`：应用入口、Provider 注入、根导航壳层与 5 等分底部导航
- `lib/screens/home/home_screen.dart`：心愿单与滑动操作
- `lib/screens/history/history_screen.dart`：已购买 / 不买了的历史记录与筛选
- `lib/screens/add/add_item_sheet.dart`：添加物品与自定义类别
- `lib/screens/stats/stats_screen.dart`：数据统计与筛选
- `lib/screens/settings/settings_screen.dart`：主题与分类展示

## 7 图表实现

使用 `fl_chart` 实现：
- 折线图：节省金额趋势
- 柱状图：近 6 个月节省金额
- 饼图：类别节省占比

图表数据来自 `ItemRepository.buildStats()`，按筛选维度动态聚合。

## 8 示例数据

首次启动自动写入：
- 降噪耳机：想买
- 咖啡课程：不买了
- 设计师台灯：已购买

## 运行方式

```bash
flutter pub get
flutter run
```

## 构建

### Android APK
```bash
flutter build apk
```

### iOS App
```bash
flutter build ios
```

## 依赖

- `sqflite`：本地数据库
- `provider`：状态管理
- `shared_preferences`：主题设置
- `fl_chart`：图表
- `intl`：金额与日期格式化
