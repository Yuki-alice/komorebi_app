# Komorebi - 光隙笔记 🚀

**记录灵感，如光隙般自然**

Komorebi 是一款优雅的跨平台笔记应用，让记录变得轻盈而愉悦。捕捉每一个灵感瞬间，构建属于你的知识花园。

---

## ✨ 核心特性

### 🎨 现代感设计
- **Material Design 3**：全量应用 MD3 规范，支持深色/浅色模式自动切换
- **响应式布局**：桌面端侧边栏 + 移动端底部导航，自适应屏幕尺寸
- **流畅体验**：基于 Isar 高性能数据库，所有操作即时响应
- **自定义主题**：多种主题风格，支持纯色和渐变两种氛围

### 📝 强大的编辑器
- **富文本编辑**：基于 Flutter Quill，支持图片插入、列表、任务清单、超链接等
- **Markdown 快捷输入**：支持 Markdown 语法快捷输入
- **AI 伴写**：集成智谱 GLM-4 模型，支持流式响应的智能润色、扩写、总结、翻译
- **文档大纲**：自动提取标题层级，快速导航
- **生成长图**：一键分享笔记为图片

### 🔐 隐私保护
- **私密笔记**：PBKDF2 密钥派生 + AES 加密，商业级安全标准
- **自动锁定**：应用后台运行自动锁定，保护敏感内容
- **本地生物认证**：支持指纹/面部识别解锁
- **数据安全**：本地存储优先，同步可控

### 📅 待办清单
- **任务管理**：创建、编辑、完成待办事项，支持子任务
- **日历视图**：基于 table_calendar，直观查看任务安排
- **进度追踪**：实时显示完成情况

### 🔄 双引擎同步系统
- **WebDAV 云端同步**：支持坚果云、Nextcloud 等标准协议，双向增量合并
- **局域网 P2P 同步**：基于 mDNS 服务发现，零配置发现，高速物理传输
- **Supabase 云同步**：可选的云端同步服务，支持多设备实时同步
- **冲突解决**：Last-Write-Wins 策略，智能处理同步冲突

### 🧠 智能整理
- **分类系统**：多级分类管理笔记
- **标签系统**：灵活标记和筛选
- **搜索功能**：快速找到所需内容，支持高亮显示
- **回收站**：误删笔记可恢复，也可彻底删除

### 📊 数据统计
- **笔记统计**：查看笔记数量、字数等统计信息
- **存储配额**：云端存储空间使用情况

---

## 🛠️ 技术栈

### 核心框架
- **Framework**: [Flutter](https://flutter.dev) (跨平台，SDK >=3.7.0)
- **Database**: [Isar](https://isar.dev) (NoSQL, 高性能本地存储)
- **State Management**: [Provider](https://pub.dev/packages/provider)

### 编辑器与 AI
- **Editor**: [Flutter Quill](https://pub.dev/packages/flutter_quill) (富文本编辑器)
- **AI Integration**: 智谱 GLM-4-Flash 模型 (流式 API 响应)

### 同步与云端
- **WebDAV**: [webdav_client](https://pub.dev/packages/webdav_client)
- **LAN Sync**: [nsd](https://pub.dev/packages/nsd) + [shelf](https://pub.dev/packages/shelf) (mDNS 服务发现 + HTTP 服务器)
- **Cloud**: [Supabase](https://supabase.com) (可选云端服务)

### 安全与加密
- **Encryption**: [encrypt](https://pub.dev/packages/encrypt) + [crypto](https://pub.dev/packages/crypto) (AES + PBKDF2)
- **Secure Storage**: [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- **Local Auth**: [local_auth](https://pub.dev/packages/local_auth) (生物认证)

### 其他核心依赖
- **Window Management**: [window_manager](https://pub.dev/packages/window_manager) (桌面端窗口控制)
- **File Picker**: [file_picker](https://pub.dev/packages/file_picker) + [image_picker](https://pub.dev/packages/image_picker)
- **Export**: [pdf](https://pub.dev/packages/pdf) + [share_plus](https://pub.dev/packages/share_plus)
- **Calendar**: [table_calendar](https://pub.dev/packages/table_calendar)
- **Environment**: [flutter_dotenv](https://pub.dev/packages/flutter_dotenv)

---

## 📱 支持平台

- **Windows** ✅ (完整支持，自定义窗口控制栏)
- **Android** ✅ (完整支持)
- **iOS** 🚧 (开发中)
- **macOS** 🚧 (开发中)
- **Linux** 🚧 (开发中)

---

## 🚀 快速开始

### 环境要求
- Flutter SDK >= 3.7.0
- Dart SDK >= 3.7.0

### 安装

1. 克隆项目
   ```bash
   git clone https://github.com/Yuki-alice/komorebi_app.git
   cd komorebi_app
   ```

2. 配置环境变量
   ```bash
   # 复制 .env 示例文件并填写必要的配置
   cp .env.example .env  # 如果存在
   # 编辑 .env 文件，配置 AI API Key 等
   ```

3. 安装依赖
   ```bash
   flutter pub get
   ```

4. 生成 Isar 数据库代码
   ```bash
   dart run build_runner build
   ```

5. 运行应用
   ```bash
   # 运行 Windows 版本
   flutter run -d windows
   
   # 运行 Android 版本
   flutter run -d android
   ```

### 快捷键
- `Ctrl + N`：新建笔记

---

## 💡 功能亮点

### AI 伴写
基于智谱 GLM-4-Flash 模型，支持流式响应：
- **润色排版**：智能优化文字表达，修正错别字
- **扩写内容**：基于现有内容生成更多相关文字
- **提炼总结**：自动概括长文要点，使用 Markdown 项目符号
- **智能翻译**：多语言互译，保持上下文一致

### 多端同步
- **WebDAV**：支持主流云存储服务，双向增量合并同步
- **局域网同步**：基于 mDNS 服务发现，设备间直接传输，无需云端
- **Supabase 云同步**：实时同步，支持多设备协作
- **增量同步**：只传输变化部分，节省流量

### 导出功能
- **Markdown**：导出为标准 Markdown 文件
- **图片**：生成长图分享到社交平台
- **PDF**：导出为 PDF 文档

### 隐私安全
- **PBKDF2 密钥派生**：从用户密码派生 256 位密钥
- **AES 加密**：笔记内容加密存储
- **自动锁定**：应用进入后台自动启动锁定计时器
- **生物认证**：支持指纹/面部识别快速解锁

---

## 🎯 应用场景

- **灵感捕捉**：随时记录闪现的创意
- **知识管理**：构建个人知识库
- **日程规划**：待办事项与时间管理
- **学习笔记**：整理学习资料和心得
- **工作记录**：会议纪要和项目文档
- **私密日记**：加密保护个人隐私内容

---

## 📁 项目结构

```
lib/
├── main.dart                 # 应用入口
├── app/                      # 应用层
│   ├── main_screen.dart      # 主屏幕
│   └── layouts/              # 响应式布局
├── core/                     # 核心模块
│   ├── database/             # 数据库服务
│   ├── init/                 # 应用初始化
│   ├── providers/            # 状态管理
│   ├── repositories/         # 数据仓库
│   ├── routes/               # 路由配置
│   ├── services/             # 核心服务
│   │   ├── privacy_service.dart      # 隐私加密服务
│   │   ├── webdav_sync_service.dart  # WebDAV 同步
│   │   ├── lan_sync_service.dart     # 局域网同步
│   │   ├── supabase_sync_service.dart # Supabase 同步
│   │   └── glm_ai_service.dart       # AI 伴写服务
│   └── theme/                # 主题配置
├── features/                 # 功能模块
│   ├── notes/                # 笔记功能
│   ├── todos/                # 待办功能
│   ├── settings/             # 设置功能
│   ├── auth/                 # 认证功能
│   └── trash/                # 回收站
├── models/                   # 数据模型
│   ├── note.dart             # 笔记模型
│   ├── todo.dart             # 待办模型
│   ├── category.dart         # 分类模型
│   └── tag.dart              # 标签模型
└── widgets/                  # 通用组件
```

---

## 📞 支持与反馈

- **GitHub Issues**：[提交问题](https://github.com/Yuki-alice/komorebi_app/issues)
- **邮件反馈**：support@komorebi.app

---

## 📄 许可证

MIT License

---

## 🤝 贡献

欢迎提交 Pull Request 和 Issue，一起让 Komorebi 变得更好！

---

**Komorebi - 让记录成为一种享受**
