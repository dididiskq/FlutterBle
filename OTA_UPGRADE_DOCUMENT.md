# OTA 升级流程文档

## 1. 项目概述

这是一个基于 BLE (蓝牙低功耗) 的 Android OTA (空中下载) 升级应用，用于通过蓝牙对设备进行固件升级。

## 2. 项目结构

```
NSAndroidUtil/
├── app/              # 主应用模块
├── ble/              # BLE 通信模块
├── scanner/          # 设备扫描模块
├── build.gradle      # 项目构建配置
└── settings.gradle   # 模块配置
```

## 3. 核心类与功能

### 3.1 BleOTA.java (OTA 升级核心类)

**位置**: `app/src/main/java/com/nsandroidutil/ble/BleOTA.java`

**主要功能**:
- 实现 OTA 升级的完整流程
- 处理升级文件的解析和发送
- 与 BLE 设备进行命令交互

**关键常量**:
```java
// OTA 命令定义
private byte OTA_CMD_CONN_PARAM_UPDATE = 0x01;      // 连接参数更新
private byte OTA_CMD_MTU_UPDATE = 0x02;             // MTU 更新
private byte OTA_CMD_VERSION = 0x03;                // 版本请求
private byte OTA_CMD_CREATE_OTA_SETTING = 0x04;     // 创建设置传输
private byte OTA_CMD_CREATE_OTA_IMAGE = 0x05;       // 创建镜像传输
private byte OTA_CMD_VALIDATE_OTA_IMAGE = 0x06;     // 验证镜像
private byte OTA_CMD_ACTIVATE_OTA_IMAGE = 0x07;     // 激活镜像
private byte OTA_CMD_JUMP_IMAGE_UPDATE = 0x08;      // 跳转至镜像更新

// 错误代码
private byte OTA_CMD_ERROR_CODE_SUCCESS = 0x00;     // 成功
private byte OTA_CMD_ERROR_CODE_INVALID_PARAM = 0x01; // 参数无效
private byte OTA_CMD_ERROR_CODE_CRC_FAIL = 0x02;    // CRC 校验失败
private byte OTA_CMD_ERROR_CODE_SIGNATURE_FAIL = 0x03; // 签名失败
```

### 3.2 BleManager.java (BLE 通信管理类)

**位置**: `app/src/main/java/com/nsandroidutil/ble/BleManager.java`

**主要功能**:
- 管理 BLE 连接
- 处理 BLE 服务和特征
- 提供读写特征值的方法

**关键 UUID**:
```java
// OTA 相关服务和特征
private final static UUID IUS_SERVICE_UUID = UUID.fromString("11110001-1111-1111-1111-111111111111");
private final static UUID IUS_RC_UUID = UUID.fromString("11110002-1111-1111-1111-111111111111"); // 读写特征
private final static UUID IUS_CC_UUID = UUID.fromString("11110003-1111-1111-1111-111111111111"); // 命令控制特征
```

### 3.3 MainActivity.java (应用主界面)

**位置**: `app/src/main/java/com/nsandroidutil/MainActivity.java`

**主要功能**:
- 用户交互界面
- 设备连接管理
- 显示升级状态和进度
- 处理权限请求

### 3.4 工具类

#### 3.4.1 ZipHelper.java

**位置**: `app/src/main/java/com/nsandroidutil/utility/ZipHelper.java`

**主要功能**:
- 解压 OTA 升级包 (ZIP 文件)
- 读取 ZIP 文件中的内容
- 提供压缩和解压缩功能

**关键方法**:
```java
// 解压 ZIP 文件到指定目录
public static void UnZipFolder(String zipFileString, String outPathString) throws Exception

// 获取 ZIP 文件中的指定文件输入流
public static InputStream UpZip(String zipFileString, String fileString) throws Exception

// 获取 ZIP 中的文件列表
public static List<File> GetFileList(String zipFileString, boolean bContainFolder, boolean bContainFile) throws Exception
```

#### 3.4.2 FileUtils.java

**位置**: `app/src/main/java/com/nsandroidutil/utility/FileUtils.java`

**主要功能**:
- 处理 Android 系统中的文件路径问题
- 兼容不同 Android 版本的文件访问方式
- 从 Uri 获取实际文件路径

**关键方法**:
```java
// 根据 Uri 获取文件路径（兼容不同 Android 版本）
public String getPath(final Uri uri)

// 检查文件是否存在
private boolean fileExists(String filePath)

// 复制文件到内部存储
private String copyFileToInternalStorage(Uri uri, String newDirName)
```

## 4. OTA 升级流程

### 4.1 升级前准备

1. **选择升级包**:
   - 用户通过 `btn_ota_file` 按钮选择 OTA 升级包 (ZIP 文件)
   - 应用调用 `BleOTA.fileOpen()` 方法解析升级包

2. **解析升级包**:
   - 调用 `BleOTA.fileOpen()` 方法
   - 使用 `ZipHelper.UnZipFolder()` 解压 ZIP 文件到 `/OTA` 目录
   - 读取配置文件 `config.txt`
   - 检查升级包内容 (APP1.bin, APP2.bin, ImageUpdate.bin, dfu_setting.dat)
   - 解析并显示升级包信息

3. **文件路径处理**:
   - 使用 `FileUtils.getPath()` 处理用户选择的文件 Uri
   - 兼容不同 Android 版本和存储位置
   - 确保应用能正确访问用户选择的升级包文件

### 4.2 连接设备

1. **扫描设备**:
   - 用户点击 `btn_device_connect` 按钮扫描 BLE 设备
   - 调用 `ScannerFragment` 显示扫描结果

2. **建立连接**:
   - 用户选择设备后，应用调用 `bleManager.connect()` 建立 BLE 连接
   - 连接成功后，更新 UI 显示设备信息

### 4.3 开始升级

1. **用户触发升级**:
   - 当升级包准备就绪且设备已连接时，用户点击 `btn_ota` 按钮开始升级
   - 应用调用 `BleOTA.start()` 方法启动升级流程

2. **升级线程**:
   - 升级在单独的线程中执行，避免阻塞 UI
   - 通过 `EventBus` 发送升级状态和进度信息

### 4.4 升级核心流程

```
开始升级 → 连接参数更新 → MTU 更新 → 版本请求 → 创建设置传输 →
发送设置数据 → 创建镜像传输 → 发送镜像数据 → 验证新镜像 →
激活新镜像 → 结束升级
```

**详细步骤**:

1. **连接参数更新** (`connection_update()`):
   - 更新 BLE 连接的间隔、延迟和超时参数
   - 提高数据传输效率

2. **MTU 更新** (`mtu_update()`):
   - 请求增大 MTU (最大传输单元) 大小
   - 默认设置为 247 字节，提高传输速度

3. **版本请求** (`version_request()`):
   - 向设备发送版本请求命令
   - 设备返回当前版本信息和升级方式
   - 根据返回结果确定升级文件路径和大小

4. **创建设置传输** (`create_ota_setting_transfer()`):
   - 通知设备即将发送设置文件
   - 发送设置文件大小信息

5. **发送设置数据** (`send_setting_data()`):
   - 分块发送 `dfu_setting.dat` 文件内容
   - 通过 IUS_RC 特征发送数据
   - 设备通过 IUS_CC 特征返回结果

6. **创建镜像传输** (`create_ota_image_transfer()`):
   - 通知设备即将发送固件数据
   - 发送固件块偏移、大小和 CRC 校验值

7. **发送镜像数据** (`send_image_data()`):
   - 分块发送固件数据 (APP1.bin/APP2.bin/ImageUpdate.bin)
   - 每块大小由 PRN (Packet Reorder Number) 决定，默认 2048 字节
   - 发送过程中通过 `WriteProgressCallback` 更新升级进度

8. **验证新镜像** (`validate_new_image()`):
   - 向设备发送验证命令
   - 设备对新固件进行 CRC 校验和签名验证

9. **激活新镜像** (`activate_new_image()`):
   - 向设备发送激活命令
   - 设备切换到新固件运行

### 4.5 特殊情况处理

**单 Bank 升级**:
- 如果升级方式为单 Bank (ota_selection == 3 或 4)
- 升级完成后，设备需要重启进入 Image Update 程序
- 应用自动重新连接到 Image Update 程序 (MAC 地址最后一位 +1)
- 再次执行升级流程，升级 Bank 1

**超时处理**:
- 每个命令都有超时时间
- 使用 `threadBlock()` 方法等待命令响应
- 超时后发送错误信息并终止升级

## 5. 数据传输机制

### 5.1 分块传输

- 固件数据被分成多个块进行传输
- 每个块有固定大小 (默认 2048 字节)
- 每块包含 CRC32 校验值，确保数据完整性

### 5.2 命令响应机制

- 应用发送命令后，等待设备响应
- 使用 `LockSupport.parkNanos()` 和 `LockSupport.unpark()` 实现线程同步
- 设备通过 BLE 通知返回命令执行结果

## 6. 状态管理与通知

应用使用 `EventBus` 发送以下事件:

| 事件类型 | 常量值 | 描述 |
|---------|-------|------|
| TYPE_MTU_UPDATE | 1 | MTU 更新通知，包含新的 MTU 大小 |
| TYPE_OTA_ERROR_MESSAGE | 2 | OTA 错误信息，包含错误描述和错误代码 |
| TYPE_OTA_MESSAGE | 3 | OTA 状态信息，显示当前升级步骤 |
| TYPE_OTA_FINISH | 4 | OTA 升级完成通知 |
| TYPE_OTA_CONFIG_FILE | 5 | OTA 配置文件信息，包含升级包的配置内容 |
| TYPE_DIS_INFO | 6 | 设备信息，用于显示设备的各种属性 |
| TYPE_OTA_PROGRESS | 7 | OTA 升级进度，包含当前进度百分比 |
| TYPE_OTA_ALERT_NOTIFY | 8 | OTA 提示信息，用于显示重要的提示 |
| TYPE_ATM_UPDATE_GRAPH | 9 | ATM 更新图表（可能用于其他功能） |
| TYPE_OTA_CONFIG_FILE_ERROR | 10 | OTA 配置文件错误，提示升级包问题 |

**事件处理**:
- 在 `MainActivity.java` 中通过 `@Subscribe` 注解的 `onBleMessageEvent()` 方法处理这些事件
- 事件处理程序根据不同的事件类型更新 UI 界面或执行相应的逻辑

**示例**:
```java
@Subscribe(threadMode = ThreadMode.MAIN)
public void onBleMessageEvent(BleMessageEvent event) {
    switch (event.type) {
        case BleMessageEvent.TYPE_OTA_PROGRESS:
            // 更新升级进度条
            pb_ota.setProgress(event.number);
            tv_ota_status.setText("OTA Progress: " + event.number + "%");
            break;
        case BleMessageEvent.TYPE_OTA_ERROR_MESSAGE:
            // 显示错误信息
            tv_ota_status.setText("Error: " + event.errorMessage);
            break;
        // 其他事件处理...
    }
}

## 7. 错误处理

| 错误代码 | 描述 |
|---------|------|
| 0x00 | 成功 |
| 0x01 | 参数无效 |
| 0x02 | CRC 校验失败 |
| 0x03 | 签名验证失败 |

## 8. 核心 API 说明

### BleOTA 类

| 方法 | 功能 |
|------|------|
| fileOpen() | 解析 OTA 升级包 |
| start() | 开始 OTA 升级 |
| update_images() | 执行升级核心流程 |
| connection_update() | 更新连接参数 |
| mtu_update() | 更新 MTU 大小 |
| version_request() | 请求设备版本信息 |
| create_ota_setting_transfer() | 创建设置传输 |
| send_setting_data() | 发送设置数据 |
| create_ota_image_transfer() | 创建镜像传输 |
| send_image_data() | 发送镜像数据 |
| validate_new_image() | 验证新镜像 |
| activate_new_image() | 激活新镜像 |

### BleManager 类

| 方法 | 功能 |
|------|------|
| connect() | 连接 BLE 设备 |
| disconnect() | 断开 BLE 连接 |
| writeCharacteristic() | 写入 BLE 特征值 |
| enableNotifications() | 启用 BLE 通知 |
| getMTU() | 获取当前 MTU 大小 |
| setMTU() | 设置 MTU 大小 |

## 9. 界面交互

### 主界面元素

| 元素 | 功能 |
|------|------|
| btn_device_connect | 连接/断开设备按钮 |
| edt_device_name_filter | 设备名称过滤器 |
| tv_device_name | 显示设备名称 |
| tv_device_mac | 显示设备 MAC 地址 |
| btn_ota | 开始 OTA 升级按钮 |
| btn_ota_file | 选择 OTA 升级包按钮 |
| pb_ota | OTA 升级进度条 |
| tv_ota_status | OTA 升级状态显示 |
| tv_ota_file_config | OTA 升级包配置信息 |

## 10. 总结

该 OTA 升级应用实现了完整的 BLE 固件升级流程，支持单 Bank 和双 Bank 升级方式，具有以下特点:

- 基于 BLE 低功耗蓝牙通信
- 支持大文件分块传输
- 数据完整性校验
- 详细的升级状态和进度显示
- 超时和错误处理机制
- 支持不同的升级方式

这个项目展示了如何在 Android 平台上实现可靠的 BLE OTA 升级功能，对于理解和学习 OTA 升级技术具有很好的参考价值。