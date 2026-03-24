# Ultra BMS 项目 - Trae 安装和编译指南

## 目录

1. [环境要求](#环境要求)
2. [Trae 安装](#trae-安装)
3. [项目依赖安装](#项目依赖安装)
4. [iOS 平台配置](#ios-平台配置)
5. [Android 平台配置](#android-平台配置)
6. [编译和运行](#编译和运行)
7. [常见问题解决](#常见问题解决)

***

## 环境要求

### 必需软件

* **Trae IDE**：最新版本

* **Flutter SDK**：>= 2.19.6 < 3.0.0

* **Dart SDK**：>= 2.19.6 < 3.0.0（随Flutter SDK自动安装）

### 推荐软件

* **Git**：用于版本控制

* **Android Studio**：用于Android开发和调试

* **Xcode**：用于iOS开发和调试（仅macOS）

* **VS Code**：作为Trae的替代选择

### 操作系统要求

* **Windows**：Windows 10 或更高版本

* **macOS**：macOS 10.14 或更高版本

***

## Trae 安装

### 1. 下载 Trae IDE

访问 Trae 官方网站下载最新版本的 Trae IDE：

* Windows：下载 `.exe` 安装包

* macOS：下载 `.dmg` 安装包

* Linux：下载 `.AppImage` 或源码编译

### 2. 安装 Trae IDE

#### Windows

1. 双击下载的 `.exe` 安装包
2. 按照安装向导完成安装
3. 安装完成后启动 Trae IDE

#### macOS

1. 双击下载的 `.dmg` 文件
2. 将 Trae 拖拽到 Applications 文件夹
3. 从 Applications 启动 Trae IDE

#

### 3. 安装 Flutter 插件

Trae IDE 通常会自动检测并提示安装 Flutter 插件。如果没有自动安装：

1. 打开 Trae IDE
2. 进入 **设置** → **插件**
3. 搜索 "Flutter"
4. 安装 **Flutter** 插件
5. 重启 Trae IDE

### 4. 配置 Flutter SDK

Trae IDE 会自动检测系统中的 Flutter SDK。如果没有检测到：

1. 进入 **设置** → **Flutter**
2. 点击 **安装 Flutter SDK**
3. 选择安装路径（推荐使用默认路径）
4. 等待安装完成

***

## 项目依赖安装

### 1. 打开项目

1. 启动 Trae IDE
2. 选择 **打开项目**
3. 导航到项目根目录：`d:\pro\vscodePro\FlutterPro\untitled1`
4. 选择项目文件夹

### 2. 自动依赖安装

Trae IDE 会自动检测 `pubspec.yaml` 文件并提示安装依赖：

1. 项目打开后，Trae 会自动运行 `flutter pub get`
2. 等待依赖下载和安装完成
3. 查看底部状态栏确认安装成功

### 3. 手动依赖安装（如果自动安装失败）

如果自动安装失败，可以在 Trae IDE 的终端中手动运行：

```bash
# 清理缓存
flutter clean

# 获取依赖
flutter pub get

# 升级依赖（可选）
flutter pub upgrade
```

### 4. 验证依赖安装

检查以下依赖是否正确安装：

#### 核心依赖

* ✅ `flutter_reactive_ble: ^5.0.0` - BLE蓝牙通信

* ✅ `permission_handler: ^11.0.0` - 权限处理

* ✅ `provider: ^6.0.5` - 状态管理

#### 功能依赖

* ✅ `camera: ^0.10.5+2` - 相机功能

* ✅ `qr_code_scanner: ^1.0.1` - 二维码扫描

* ✅ `file_picker: ^5.3.1` - 文件选择

* ✅ `http: ^0.13.6` - HTTP通信

* ✅ `archive: ^3.4.10` - 压缩包处理

#### UI依赖

* ✅ `cupertino_icons: ^1.0.2` - iOS风格图标

***

## iOS 平台配置

### 1. 安装 Xcode

#### 要求

* macOS 系统

* Xcode 14.0 或更高版本

* iOS SDK 17.0 或更高版本

#### 安装步骤

1. 从 Mac App Store 下载并安装 Xcode
2. 打开 Xcode 并接受许可协议
3. 安装 Xcode 命令行工具：

   ```bash
   xcode-select --install
   ```

### 2. 安装 CocoaPods

CocoaPods 是 iOS 依赖管理工具，必需安装：

```bash
# 安装 CocoaPods
sudo gem install cocoapods

# 验证安装
pod --version
```

### 3. 配置 iOS 权限

在 `ios/Runner/Info.plist` 中添加必要的权限：

```xml
<!-- 蓝牙权限 -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要蓝牙权限来连接BMS设备</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要蓝牙权限来连接BMS设备</string>

<!-- 相机权限 -->
<key>NSCameraUsageDescription</key>
<string>需要相机权限来扫描二维码</string>

<!-- 位置权限（蓝牙扫描需要） -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>需要位置权限来扫描蓝牙设备</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>需要位置权限来扫描蓝牙设备</string>
```

### 4. 安装 iOS 依赖

在项目根目录运行：

```bash
# 进入 iOS 目录
cd ios

# 安装 CocoaPods 依赖
pod install

# 返回项目根目录
cd ..
```

### 5. 配置签名和证书

#### 开发环境

1. 在 Xcode 中打开 `ios/Runner.xcworkspace`
2. 选择 **Signing & Capabilities**
3. 选择开发团队
4. Xcode 会自动配置签名

#### 生产环境

1. 准备 Apple Developer 账号
2. 在 Apple Developer 网站创建 App ID
3. 创建开发证书和发布证书
4. 在 Xcode 中配置签名

### 6. 验证 iOS 配置

在 Trae IDE 终端运行：

```bash
# 检查 iOS 设备连接
flutter devices

# 检查 iOS 配置
flutter doctor -v
```

确保没有 iOS 相关的错误或警告。

***

## Android 平台配置

### 1. 安装 Android Studio

#### 要求

* Android Studio Hedgehog (2023.1.1) 或更高版本

* Android SDK 34 (Android 14) 或更高版本

#### 安装步骤

1. 下载 Android Studio
2. 按照安装向导完成安装
3. 安装 Android SDK 和必要的工具
4. 配置 Android SDK 路径

### 2. 配置 Android SDK

在 Android Studio 中：

1. 打开 **SDK Manager**
2. 安装以下 SDK：

   * Android 14.0 (API 34)

   * Android 13.0 (API 33)

   * Android 12.0 (API 31)
3. 安装 Android SDK Build-Tools
4. 安装 Android SDK Platform-Tools

### 3. 配置 Gradle

项目使用 Gradle 进行构建，确保配置正确：

#### `android/build.gradle`

```gradle
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

#### `android/app/build.gradle`

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.example.ultra_bms"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}
```

### 4. 配置 Android 权限

在 `android/app/src/main/AndroidManifest.xml` 中添加必要的权限：

```xml
<!-- 蓝牙权限 -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- 位置权限（蓝牙扫描需要） -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- 相机权限 -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- 存储权限 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- Android 12+ 的蓝牙权限 -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" 
                 android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

### 5. 配置 ProGuard（可选）

如果需要代码混淆，配置 ProGuard：

在 `android/app/build.gradle` 中：

```gradle
android {
    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt')
        }
    }
}
```

### 6. 验证 Android 配置

在 Trae IDE 终端运行：

```bash
# 检查 Android 设备连接
flutter devices

# 检查 Android 配置
flutter doctor -v
```

确保没有 Android 相关的错误或警告。

***

## 编译和运行

### 1. 选择目标设备

#### iOS 设备

1. 连接 iOS 设备到 Mac
2. 在 Trae IDE 底部设备列表中选择设备
3. 或选择 iOS 模拟器

#### Android 设备

1. 启用 USB 调试模式
2. 连接 Android 设备到电脑
3. 在 Trae IDE 底部设备列表中选择设备
4. 或选择 Android 模拟器

### 2. 运行项目

#### 在 Trae IDE 中运行

1. 点击顶部工具栏的 **运行** 按钮（绿色三角形）
2. 或按快捷键 `F5`
3. 等待应用编译和安装到设备

#### 在 Trae IDE 终端运行

```bash
# 运行 Debug 版本
flutter run

# 运行 Release 版本
flutter run --release

# 指定设备运行
flutter run -d <device_id>

# 查看可用设备
flutter devices
```

### 3. 编译 APK 或 IPA

#### 编译 Android APK

```bash
# 编译 Debug APK
flutter build apk --debug

# 编译 Release APK
flutter build apk --release

# 编译 APK 并拆分 ABI
flutter build apk --split-per-abi

# 编译 App Bundle（用于 Google Play）
flutter build appbundle --release
```

APK 输出位置：`build/app/outputs/flutter-apk/`

#### 编译 iOS IPA

```bash
# 编译 iOS 应用（需要在 Mac 上运行）
flutter build ios --release

# 编译后使用 Xcode 打包
open ios/Runner.xcworkspace
```

### 4. 清理构建缓存

如果遇到编译问题，可以清理缓存：

```bash
# 清理 Flutter 缓存
flutter clean

# 清理 iOS 缓存
cd ios && rm -rf Pods && cd ..

# 清理 Android 缓存
cd android && ./gradlew clean && cd ..

# 重新获取依赖
flutter pub get
```

***

## 常见问题解决

### 1. Flutter SDK 未找到

**问题**：Trae IDE 提示找不到 Flutter SDK

**解决方案**：

1. 进入 **设置** → **Flutter**
2. 点击 **安装 Flutter SDK**
3. 或手动配置 Flutter SDK 路径

### 2. 依赖安装失败

**问题**：`flutter pub get` 失败

**解决方案**：

```bash
# 清理 Flutter 缓存
flutter pub cache repair

# 使用国内镜像（如果在中国）
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 重新获取依赖
flutter pub get
```

### 3. iOS 编译失败

**问题**：iOS 编译时出现错误

**解决方案**：

```bash
# 重新安装 CocoaPods
cd ios
pod deintegrate
pod install
cd ..

# 清理 Xcode 缓存
rm -rf ~/Library/Developer/Xcode/DerivedData

# 在 Xcode 中清理项目
open ios/Runner.xcworkspace
# Product → Clean Build Folder
```

### 4. Android 编译失败

**问题**：Android 编译时出现 Gradle 错误

**解决方案**：

```bash
# 清理 Gradle 缓存
cd android
./gradlew clean
./gradlew build --refresh-dependencies
cd ..

# 删除 .gradle 文件夹
rm -rf ~/.gradle

# 重新编译
flutter clean
flutter pub get
flutter build apk
```

### 5. 蓝牙权限问题

**问题**：应用无法获取蓝牙权限

**解决方案**：

#### iOS

1. 检查 `Info.plist` 中的权限描述
2. 确保描述文本清晰易懂
3. 在真机上测试（模拟器不支持蓝牙）

#### Android

1. 检查 `AndroidManifest.xml` 中的权限声明
2. 运行时请求权限：

   ```dart
   import 'package:permission_handler/permission_handler.dart';

   final status = await Permission.bluetooth.request();
   if (!status.isGranted) {
     // 处理权限拒绝
   }
   ```

### 6. 设备连接问题

**问题**：无法连接到蓝牙设备

**解决方案**：

1. 确保设备蓝牙已开启
2. 确保位置权限已授予（Android）
3. 重启应用和蓝牙
4. 检查设备是否已被其他应用连接

### 7. 二维码扫描问题

**问题**：二维码扫描无法工作

**解决方案**：

1. 确保相机权限已授予
2. 检查相机是否被其他应用占用
3. 在真机上测试（模拟器相机可能不工作）
4. 确保光线充足

### 8. 文件选择问题

**问题**：无法选择固件文件

**解决方案**：

1. 确保存储权限已授予
2. 检查文件格式是否支持（.zip）
3. 确保文件未被其他应用占用

***

## 性能优化建议

### 1. 减少应用体积

#### Android

```bash
# 编译 APK 时拆分 ABI
flutter build apk --split-per-abi

# 启用代码混淆
flutter build apk --obfuscate --split-debug-info=./obfuscate.map
```

#### iOS

```bash
# 在 Xcode 中启用优化
# Build Settings → Optimization Level → Fastest, Smallest [-Os]
```

### 2. 提升启动速度

1. 使用 `deferred loading` 延迟加载非关键代码
2. 优化图片资源
3. 减少初始化时的网络请求

### 3. 内存优化

1. 使用 `const` 构造函数
2. 及时释放不再使用的资源
3. 使用 `ListView.builder` 而不是 `ListView`

***

## 调试技巧

### 1. 使用 Flutter DevTools

```bash
# 启动 DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### 2. 日志输出

在代码中使用 `print()` 输出调试信息：

```dart
print('[Debug] 设备连接状态: $isConnected');
```

在 Trae IDE 终端查看日志输出。

### 3. 断点调试

1. 在代码行号左侧点击设置断点
2. 以 Debug 模式运行应用
3. 当执行到断点时，应用会暂停
4. 查看变量值和调用栈

***

## 版本更新

### 更新 Flutter SDK

```bash
# 升级 Flutter SDK
flutter upgrade

# 检查 Flutter 版本
flutter --version
```

### 更新依赖

```bash
# 升级所有依赖到最新版本
flutter pub upgrade

# 查看过时的依赖
flutter pub outdated
```

***

## 联系支持

如果遇到无法解决的问题：

1. 查看 [Flutter 官方文档](https://flutter.dev/docs)
2. 查看 [Trae IDE 文档](https://trae.io/docs)
3. 在项目 Issues 中搜索类似问题
4. 提交新的 Issue 并附上详细的错误信息

***

## 附录

### A. 项目依赖清单

| 依赖包                    | 版本        | 用途      |
| ---------------------- | --------- | ------- |
| flutter\_reactive\_ble | ^5.0.0    | BLE蓝牙通信 |
| permission\_handler    | ^11.0.0   | 权限处理    |
| provider               | ^6.0.5    | 状态管理    |
| camera                 | ^0.10.5+2 | 相机功能    |
| qr\_code\_scanner      | ^1.0.1    | 二维码扫描   |
| file\_picker           | ^5.3.1    | 文件选择    |
| http                   | ^0.13.6   | HTTP通信  |
| archive                | ^3.4.10   | 压缩包处理   |
| cupertino\_icons       | ^1.0.2    | iOS风格图标 |

### B. 常用命令

```bash
# 查看连接的设备
flutter devices

# 查看环境配置
flutter doctor

# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 运行应用
flutter run

# 编译 APK
flutter build apk

# 编译 iOS
flutter build ios

# 运行测试
flutter test
```

### C. 环境变量

```bash
# Flutter 镜像（中国用户）
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# Android SDK 路径
export ANDROID_HOME=/path/to/android-sdk

# Java 路径
export JAVA_HOME=/path/to/java
```

***

**文档版本**：1.0\
**最后更新**：2026-02-06\
**适用项目**：Ultra BMS v1.0.0+1
