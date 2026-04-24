# AIHeadshot iOS 项目 GitHub Actions 编译风险报告

**审查日期**: 2025-04-24  
**审查范围**: `Sources/AIHeadshot` 全部 Swift 源文件、`Package.swift`、`.github/workflows/ios-ci.yml`、`.swiftlint.yml`、全部测试文件  
**审查环境**: macOS CommandLineTools（无 Xcode，无法本地编译 iOS 目标）

---

## 1. 预估结论

**第一次 GitHub Actions 跑通概率：≈ 0%**

当前配置存在 **3 个致命级（Critical）**问题，任意一个即可导致 CI 整体失败。另有多个高/中等级别问题。在不修复的情况下，Actions 几乎不可能一次通过。

---

## 2. 问题列表

### 🔴 Critical（致命）

| # | 问题 | 位置 | 说明 |
|---|------|------|------|
| C1 | **工作流路径过滤与 working-directory 错误** | `.github/workflows/ios-ci.yml` | 当前 `paths: - 'ios/**'` 与 `working-directory: ./ios` 暗示仓库根目录下有一个 `ios/` 子文件夹。但 `.github/workflows/` 本身就在 `ios/` 目录内，说明该目录即为仓库根。若直接推送，GitHub 找不到 `ios/` 子目录，`working-directory` 会报 "No such file or directory"；`paths` 过滤也永远匹配不到文件，导致工作流永不触发。 |
| C2 | **Xcode 15.0 硬编码路径不存在** | `.github/workflows/ios-ci.yml` | `sudo xcode-select -s /Applications/Xcode_15.0.app` 在 `macos-latest`（macOS 14）Runner 上大概率不存在，实际可用的是 `Xcode_15.0.1`、`Xcode_15.2`、`Xcode_15.4` 等。该步骤会直接失败，导致 build 与 lint 两个 job 全部挂掉。 |
| C3 | **单元测试断言错误** | `Tests/AIHeadshotTests/OrderTests.swift:38` | `testOrderDecoding` 中 JSON 的 `status` 为 `"COMPLETED"`，但 `Order.init(from decoder:)` 通过 `paid = (status == .paid)` 计算，结果应为 `false`。测试却 `XCTAssertTrue(order.paid)`，**必然失败**，导致 `xcodebuild test` 不通过。 |

### 🟠 High（高）

| # | 问题 | 位置 | 说明 |
|---|------|------|------|
| H1 | **SwiftLint `--strict` 多处违规** | 多处 | 工作流使用 `swiftlint --strict`（warning 也视为 error）。已确认以下违规：  |
| H1a | `force_unwrapping` | `Sources/AIHeadshot/Utils/Constants.swift:4` | `URL(string: "...")!` |
| H1b | `force_unwrapping` | 测试文件多处 | `json.data(using: .utf8)!`（`APIResponseTests.swift`、`OrderTests.swift`、`TemplateTests.swift`） |
| H1c | `force_cast` | `Tests/AIHeadshotTests/OrderTests.swift:45` | `as! [String: String]` |
| H1d | `line_length` > 160 (error) | `Sources/AIHeadshot/Views/ProfileView.swift:160-161` | `sampleOrders` 单行 190+/196+ 字符 |
| H1e | `line_length` > 140 (warning) | `Sources/AIHeadshot/ViewModels/GenerateViewModel.swift:39`、`Tests/AIHeadshotTests/APIResponseTests.swift:24,38` | 159/150/191 字符，在 `--strict` 下同样致命 |
| H1f | `identifier_name` 过短 | `Sources/AIHeadshot/ViewModels/CameraViewModel.swift:49,58` | `let s = session`（长度 1，低于 warning 阈值 2） |
| H2 | **没有 Xcode 工程文件** | 根目录 | 这是一个纯 SPM `Package.swift` 项目，无 `.xcodeproj`/`.xcworkspace`。`xcodebuild -scheme AIHeadshot` 在 Xcode 15 上**大概率可以**对 SPM 包隐式生成 workspace，但在 CI 无头环境下偶发不稳定；若 scheme 解析失败会直接导致 build 报错。 |

### 🟡 Medium（中）

| # | 问题 | 位置 | 说明 |
|---|------|------|------|
| M1 | **缺少 Code Signing 关闭参数** | `.github/workflows/ios-ci.yml` | iOS Simulator 构建通常不需签名，但 CI 中 `xcodebuild` 偶尔会因找不到 Team/Identity 报错。建议追加 `CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO`。 |
| M2 | **Simulator 目的地可能模糊** | `.github/workflows/ios-ci.yml` | `-destination 'platform=iOS Simulator,name=iPhone 15'` 若系统安装了多个 iOS 版本的 iPhone 15，可能报 "ambiguous destination"。建议追加 `OS=17.0` 或 `OS=latest`。 |
| M3 | **StrictConcurrency 实验特性导致大量警告** | `Package.swift` | 启用了 `StrictConcurrency`。`AVCaptureSession`、`JSONDecoder` 等非 `Sendable` 类型在 actor/`@Sendable` 闭包中传递会产生密集警告。虽然 Xcode 15 + Swift 5.9 下仍为 warning，但会让 build log 非常嘈杂，未来升级到 Swift 6 将直接变 error。 |
| M4 | **资源文件缺失** | `Sources/AIHeadshot/Resources/Assets.xcassets/AppIcon.appiconset` | `Contents.json` 引用了图标，但目录下无实际 PNG 文件。编译不会失败，但 Xcode 会产生警告。 |
| M5 | **`Order.paid` 语义不一致** | `Sources/AIHeadshot/Models/Order.swift` | `status == .completed` 时 `paid` 仍为 `false`，这与直觉及测试预期不符。运行时可能导致业务逻辑 Bug，但不是编译问题。 |

### 🟢 Low（低）

| # | 问题 | 位置 | 说明 |
|---|------|------|------|
| L1 | **测试覆盖不足** | `Tests/` | 现有测试仅覆盖 Model/Response 解析与 `FaceQualityResult` 工具类，缺少对 `ViewModel`、`Service`、`Upload` 等核心逻辑的单元测试。 |
| L2 | **重复构建** | `.github/workflows/ios-ci.yml` | `xcodebuild ... build` 与 `xcodebuild ... test` 分开执行，`test` 本身会触发 build，造成时间浪费。 |
| L3 | **`brew install swiftlint` 耗时** | `.github/workflows/ios-ci.yml` | `macos-latest` Runner 上 Homebrew 安装约 2-3 分钟；可换用已预装路径或 binary 下载加速。 |
| L4 | **`@main` 位于 library target** | `Sources/AIHeadshot/App.swift` | 在 `.library` 中放 `@main` 虽能编译，但不符合常规做法。若未来转为真正的 App target（加入 `.executable` 或 Xcode 工程），需重构。 |

---

## 3. 修复建议（按优先级排序）

### 立即修复（第一次跑通前必须做）

1. **修正仓库结构/工作流路径**
   - 如果仓库根就是 `ios/` 目录：
     ```yaml
     # 删除 paths 中的 ios/** 过滤
     paths:
       - '**/*.swift'
       - '.github/workflows/ios-ci.yml'
       - 'Package.swift'
     
     # 删除或修改 defaults
     defaults:
       run:
         working-directory: .  # 或删除整个 defaults 块
     ```
   - 如果是 monorepo，应将 `.github/workflows/ios-ci.yml` 上移至仓库根 `.github/workflows/`。

2. **移除或修正 Xcode 选择逻辑**
   ```yaml
   # 方案 A：直接使用 Runner 默认 Xcode（推荐）
   # 删除整个 "Select Xcode version" step
   
   # 方案 B：若必须固定版本，先判断存在性
   - name: Select Xcode version
     run: |
       sudo xcode-select -s /Applications/Xcode_15.4.app/Contents/Developer || \
       sudo xcode-select -s /Applications/Xcode_15.2.app/Contents/Developer
   ```

3. **修复测试断言**
   在 `Tests/AIHeadshotTests/OrderTests.swift` 中：
   ```swift
   // 原：XCTAssertTrue(order.paid)
   // 修正为：
   XCTAssertFalse(order.paid) // 因为 status 是 COMPLETED，不是 PAID
   ```
   或者修改 JSON 为 `"status": "PAID"` 以测试支付场景。

4. **修复 SwiftLint 违规**
   | 文件 | 修改 |
   |------|------|
   | `Constants.swift:4` | 使用 `guard let baseURL = URL(string: "...") else { fatalError(...) }` 或显式 unwrap 抑制（仍建议 guard） |
   | `CameraViewModel.swift:49,58` | `let s = session` → `let captureSession = session` |
   | `ProfileView.swift:160-161` | 将 `sampleOrders` 拆分为多行，每行属性换行 |
   | `GenerateViewModel.swift:39` | 拆分长条件为多个中间变量或换行 |
   | 测试文件中的 `json.data(using: .utf8)!` | 改为 `XCTUnwrap(json.data(using: .utf8))` 或 `try XCTUnwrap(...)` |
   | `OrderTests.swift:45` | `as! [String: String]` → `as? [String: String]` 后 `XCTAssertNotNil` / `XCTAssertEqual` |

   若希望暂时绕过（不推荐长期）：可在 `.swiftlint.yml` 的 `disabled_rules` 中增加 `- force_unwrapping`、`- force_cast`，并将 `line_length` 放宽，但这会降低代码质量。

5. **增强 xcodebuild 稳定性**
   ```yaml
   - name: Build
     run: |
       xcodebuild -scheme AIHeadshot \
         -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
         CODE_SIGNING_REQUIRED=NO \
         CODE_SIGNING_ALLOWED=NO \
         build
   
   - name: Run tests
     run: |
       xcodebuild -scheme AIHeadshot \
         -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
         CODE_SIGNING_REQUIRED=NO \
         CODE_SIGNING_ALLOWED=NO \
         test
   ```

### 建议修复（提升 CI 稳定性与代码质量）

6. **SwiftLint 安装优化**
   ```yaml
   - name: Run SwiftLint
     run: |
       if ! which swiftlint > /dev/null; then
         brew install swiftlint
       fi
       swiftlint lint --strict
   ```

7. **减少 StrictConcurrency 噪音**
   - 在 `CameraViewModel.swift` 的 `startSession`/`stopSession` 中，对 `DispatchQueue.global` 闭包使用 `@Sendable` 显式标注或提取为 `@Sendable` 方法，减少隐式警告。
   - 或者，若团队尚未准备好处理 Swift 6 并发，可暂时移除 `Package.swift` 中的 `enableExperimentalFeature("StrictConcurrency")`，待后续专项重构再开启。

8. **补全图标资源**
   在 `AppIcon.appiconset` 中放入实际的 1024x1024 PNG，或删除 `Assets.xcassets` 中的空引用，避免 Xcode 警告。

9. **补全单元测试**
   至少为 `APIService`（使用 `URLProtocol` mock）、`UploadService`、`IAPService` 的 happy path 与 error path 增加测试，提高 CI 价值。

10. **引入缓存**
    ```yaml
    - uses: actions/cache@v4
      with:
        path: .build
        key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}
    ```

---

## 4. 修复后预估

如果上述 **C1-C3 + H1 + M1** 全部修复，预估 Actions 首次通过率可提升至 **> 90%**。

剩余约 10% 的不确定性来自：
- `xcodebuild` 对纯 SPM 包在 CI 无头环境中的隐式 workspace 行为（极少数 Runner 上可能 scheme 解析异常）。
- iOS Simulator 启动/测试偶发的超时/挂起（可通过重试机制缓解）。

---

## 5. 附录：各文件风险速查

| 文件 | 风险点 |
|------|--------|
| `Package.swift` | `StrictConcurrency` 实验特性 |
| `.github/workflows/ios-ci.yml` | 路径、Xcode 版本、xcodebuild 参数 |
| `.swiftlint.yml` | 配置本身无错，但 `--strict` 会暴露代码违规 |
| `Constants.swift` | `force_unwrapping` |
| `CameraViewModel.swift` | `identifier_name` (`let s`)、`StrictConcurrency` 警告 |
| `ProfileView.swift` | `line_length` 超标 |
| `GenerateViewModel.swift` | `line_length` 超标 |
| `OrderTests.swift` | 测试断言错误、`force_unwrapping`、`force_cast`、`line_length` |
| `APIResponseTests.swift` | `force_unwrapping`、`line_length` |
| `TemplateTests.swift` | `force_unwrapping` |
| `Assets.xcassets` | 缺少实际 PNG 资源 |
| 其他 Swift 文件 | 未发现直接编译错误，但多数 UIKit/AVFoundation 相关文件在 macOS `swift build` 下会失败（CI 中通过 `xcodebuild` + iOS Simulator 可避免） |
