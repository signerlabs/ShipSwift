# 8. 数据导出 (Export & Share)

iOS 应用中导出报告为 PDF、图片，以及导出数据为 JSON/CSV 格式的最佳实践。

## 一、导出 PDF

### 推荐方案：ImageRenderer (iOS 16+)

iOS 16 引入的 `ImageRenderer` API 是目前最简洁的 SwiftUI 视图导出方案。

#### 基础实现

```swift
import SwiftUI

@MainActor
func exportToPDF<Content: View>(
    view: Content,
    filename: String = "report.pdf"
) -> URL? {
    // 1. 创建渲染器
    let renderer = ImageRenderer(content: view)

    // 2. 设置渲染比例（提高清晰度）
    renderer.scale = UIScreen.main.scale

    // 3. 获取临时文件路径
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(filename)

    // 4. 渲染 PDF
    renderer.render { size, context in
        var box = CGRect(origin: .zero, size: size)

        guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
            return
        }

        pdf.beginPDFPage(nil)
        context(pdf)
        pdf.endPDFPage()
        pdf.closePDF()
    }

    return url
}
```

#### 多页 PDF 导出

```swift
@MainActor
func exportMultiPagePDF<Content: View>(
    pages: [Content],
    pageSize: CGSize = CGSize(width: 612, height: 792), // A4: 8.5" x 11" @ 72dpi
    filename: String = "report.pdf"
) -> URL? {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(filename)

    guard let pdfContext = CGContext(url as CFURL, mediaBox: nil, nil) else {
        return nil
    }

    for page in pages {
        let renderer = ImageRenderer(content: page.frame(width: pageSize.width, height: pageSize.height))
        renderer.scale = UIScreen.main.scale

        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: pageSize)
            pdfContext.beginPDFPage(nil)

            // 在页面上下文中绘制
            context(pdfContext)

            pdfContext.endPDFPage()
        }
    }

    pdfContext.closePDF()
    return url
}
```

#### 添加 PDF 元数据

```swift
import UIKit

@MainActor
func exportToPDFWithMetadata<Content: View>(
    view: Content,
    title: String,
    author: String,
    filename: String = "report.pdf"
) -> URL? {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(filename)

    let renderer = ImageRenderer(content: view)
    renderer.scale = UIScreen.main.scale

    // PDF 元数据
    let metadata: [CFString: Any] = [
        kCGPDFContextTitle: title,
        kCGPDFContextAuthor: author,
        kCGPDFContextCreator: "UtilityMax",
        kCGPDFContextCreationDate: Date()
    ]

    renderer.render { size, context in
        var box = CGRect(origin: .zero, size: size)

        guard let pdf = CGContext(url as CFURL, mediaBox: &box, metadata as CFDictionary) else {
            return
        }

        pdf.beginPDFPage(nil)
        context(pdf)
        pdf.endPDFPage()
        pdf.closePDF()
    }

    return url
}
```

---

## 二、导出图片

### 使用 ImageRenderer 导出 UIImage

```swift
@MainActor
func exportToImage<Content: View>(view: Content) -> UIImage? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage
}

// 导出为 PNG Data
@MainActor
func exportToPNG<Content: View>(view: Content) -> Data? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage?.pngData()
}

// 导出为 JPEG Data（带压缩质量）
@MainActor
func exportToJPEG<Content: View>(view: Content, quality: CGFloat = 0.9) -> Data? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage?.jpegData(compressionQuality: quality)
}
```

---

## 三、数据格式选择

### 格式对比

| 格式 | 适用场景 | 优点 | 缺点 |
|------|----------|------|------|
| **JSON** | API、Web 服务、跨平台 | 轻量、现代标准、易解析、支持层级结构 | 不适合纯表格数据 |
| **CSV** | 表格数据、Excel 导入、大数据量 | 简单、处理速度快(3GB/s)、体积小 | 无层级结构、无类型信息 |
| **XML** | 监管合规、复杂文档结构 | 强验证、生态完善 | 冗长、处理慢(150MB/s) |

### 性能对比

| 格式 | 解析速度 | 文件大小（相对） |
|------|----------|-----------------|
| CSV | ~3 GB/s (Apache Arrow) | 1x |
| JSON | ~1 GB/s (simdjson) | 2-3x |
| XML | ~150 MB/s | 5-10x |

### 推荐策略

**财务报告导出建议：**

1. **JSON** - 供程序/API 使用
   - 现代 Web/App 原生支持
   - 易于转换为其他格式
   - 保留数据结构和类型

2. **CSV** - 供 Excel/电子表格使用
   - Excel、Google Sheets 直接打开
   - 体积最小
   - 用户熟悉度高

3. **同时支持两种格式** - 覆盖面最广

---

## 四、JSON 导出实现

### 基础导出

```swift
import Foundation

struct ReportExporter {

    /// 导出报告为 JSON 文件
    static func exportToJSON<T: Encodable>(
        data: T,
        filename: String = "report.json"
    ) -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let jsonData = try encoder.encode(data)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(filename)
            try jsonData.write(to: url)
            return url
        } catch {
            print("JSON export error: \(error)")
            return nil
        }
    }

    /// 导出报告为 JSON Data
    static func toJSONData<T: Encodable>(data: T) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(data)
    }
}
```

### 财务报告 JSON 结构示例

```swift
// 定义可导出的报告结构
struct ExportableFinancialReport: Codable {
    let metadata: ReportMetadata
    let summary: ReportSummary
    let details: [ReportDetail]
    let generatedAt: Date
}

struct ReportMetadata: Codable {
    let reportId: String
    let reportType: String
    let title: String
    let version: String
}

struct ReportSummary: Codable {
    let totalScore: Double
    let grade: String
    let description: String
}

struct ReportDetail: Codable {
    let name: String
    let value: Double
    let score: Double
    let recommendation: String
}
```

---

## 五、CSV 导出实现

### 通用 CSV 导出器

```swift
import Foundation

struct CSVExporter {

    /// 导出数据为 CSV 文件
    static func exportToCSV(
        headers: [String],
        rows: [[String]],
        filename: String = "report.csv"
    ) -> URL? {
        var csvString = headers.map { escapeCSV($0) }.joined(separator: ",") + "\n"

        for row in rows {
            csvString += row.map { escapeCSV($0) }.joined(separator: ",") + "\n"
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        do {
            // 使用 UTF-8 BOM 确保 Excel 正确识别中文
            let bom = "\u{FEFF}"
            try (bom + csvString).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("CSV export error: \(error)")
            return nil
        }
    }

    /// 转义 CSV 特殊字符
    private static func escapeCSV(_ string: String) -> String {
        let needsQuoting = string.contains(",") ||
                          string.contains("\"") ||
                          string.contains("\n") ||
                          string.contains("\r")

        if needsQuoting {
            let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return string
    }
}
```

### 财务报告 CSV 导出示例

```swift
extension CSVExporter {

    /// 导出财务健康指标为 CSV
    static func exportFinancialHealthReport(
        indicators: [FinancialHealthIndicator],
        filename: String = "financial_health_report.csv"
    ) -> URL? {
        let headers = ["指标名称", "当前值", "得分", "建议"]

        let rows: [[String]] = indicators.map { indicator in
            [
                indicator.indicatorName,
                String(format: "%.2f", indicator.value),
                String(format: "%.0f", indicator.score),
                indicator.recommendation
            ]
        }

        return exportToCSV(headers: headers, rows: rows, filename: filename)
    }

    /// 导出养老金明细为 CSV
    static func exportPensionDetails(
        details: SocialSecurityDetails,
        filename: String = "pension_details.csv"
    ) -> URL? {
        let headers = ["项目", "金额(元/月)"]

        let rows: [[String]] = [
            ["基础养老金 (BP)", String(format: "%.2f", details.basicPension.BP)],
            ["个人账户养老金 (PA)", String(format: "%.2f", details.personalAccount.monthlyPersonalAccountPension)],
            ["过渡性养老金 (TP)", String(format: "%.2f", details.transitional.TP)],
            ["职业年金 (PP)", String(format: "%.2f", details.occupational.monthlyOccupationalPension)],
            ["养老金合计", String(format: "%.2f", details.totalPension)],
            ["公积金总计", String(format: "%.2f", details.housingFund.HF)]
        ]

        return exportToCSV(headers: headers, rows: rows, filename: filename)
    }
}
```

---

## 六、分享功能集成

### 使用 ShareLink (iOS 16+)

```swift
import SwiftUI

struct ReportShareView: View {
    let reportData: ExportableFinancialReport

    var body: some View {
        VStack {
            // 分享 JSON
            if let jsonURL = ReportExporter.exportToJSON(data: reportData) {
                ShareLink(
                    item: jsonURL,
                    subject: Text("财务报告"),
                    message: Text("这是我的财务健康报告")
                ) {
                    Label("导出 JSON", systemImage: "doc.text")
                }
            }

            // 分享 PDF
            ShareLink(
                item: pdfURL,
                preview: SharePreview("财务报告.pdf", image: Image(systemName: "doc.fill"))
            ) {
                Label("导出 PDF", systemImage: "doc.fill")
            }
        }
    }
}
```

### 使用 UIActivityViewController（兼容旧版本）

```swift
import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?

    init(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.items = items
        self.excludedActivityTypes = excludedActivityTypes
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// 使用示例
struct ExportButton: View {
    @State private var showingShareSheet = false
    @State private var exportURL: URL?

    var body: some View {
        Button("导出报告") {
            if let url = exportReport() {
                exportURL = url
                showingShareSheet = true
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    func exportReport() -> URL? {
        // 导出逻辑
        return nil
    }
}
```

---

## 七、完整导出服务

### ExportService 实现

```swift
import SwiftUI
import UniformTypeIdentifiers

enum ExportFormat {
    case pdf
    case json
    case csv
    case image
}

@MainActor
class ExportService {

    static let shared = ExportService()

    private init() {}

    // MARK: - PDF 导出

    func exportToPDF<Content: View>(
        view: Content,
        title: String
    ) -> URL? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale

        let filename = "\(title).pdf"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        let metadata: [CFString: Any] = [
            kCGPDFContextTitle: title,
            kCGPDFContextAuthor: "UtilityMax",
            kCGPDFContextCreationDate: Date()
        ]

        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdf = CGContext(url as CFURL, mediaBox: &box, metadata as CFDictionary) else {
                return
            }
            pdf.beginPDFPage(nil)
            context(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }

        return url
    }

    // MARK: - JSON 导出

    func exportToJSON<T: Encodable>(data: T, filename: String) -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let jsonData = try encoder.encode(data)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(filename)
            try jsonData.write(to: url)
            return url
        } catch {
            print("JSON export error: \(error)")
            return nil
        }
    }

    // MARK: - CSV 导出

    func exportToCSV(
        headers: [String],
        rows: [[String]],
        filename: String
    ) -> URL? {
        var csvString = headers.map { escapeCSV($0) }.joined(separator: ",") + "\n"

        for row in rows {
            csvString += row.map { escapeCSV($0) }.joined(separator: ",") + "\n"
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        do {
            let bom = "\u{FEFF}"
            try (bom + csvString).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("CSV export error: \(error)")
            return nil
        }
    }

    // MARK: - 图片导出

    func exportToImage<Content: View>(view: Content) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    func exportToPNG<Content: View>(view: Content, filename: String) -> URL? {
        guard let image = exportToImage(view: view),
              let data = image.pngData() else {
            return nil
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Helper

    private func escapeCSV(_ string: String) -> String {
        let needsQuoting = string.contains(",") ||
                          string.contains("\"") ||
                          string.contains("\n")

        if needsQuoting {
            let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return string
    }

    // MARK: - 清理临时文件

    func cleanupTempFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: tempDir,
                includingPropertiesForKeys: nil
            )
            for file in files {
                let ext = file.pathExtension.lowercased()
                if ["pdf", "json", "csv", "png", "jpg"].contains(ext) {
                    try? FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            print("Cleanup error: \(error)")
        }
    }
}
```

---

## 八、最佳实践

### 1. PDF 导出注意事项

- **必须使用 `@MainActor`**：`ImageRenderer` 需要在主线程执行
- **设置 `scale`**：使用 `UIScreen.main.scale` 确保高清晰度
- **给视图设置固定宽度**：避免布局问题

```swift
// ✅ 好：固定宽度
let content = reportView.frame(width: 612) // A4 宽度
let renderer = ImageRenderer(content: content)

// ❌ 差：依赖自动布局
let renderer = ImageRenderer(content: reportView)
```

### 2. CSV 导出注意事项

- **添加 UTF-8 BOM**：确保 Excel 正确识别中文
- **转义特殊字符**：处理逗号、引号、换行符
- **使用一致的数字格式**：避免区域设置问题

### 3. 文件管理

- **使用临时目录**：`FileManager.default.temporaryDirectory`
- **及时清理**：分享完成后清理临时文件
- **使用有意义的文件名**：包含报告类型和日期

### 4. 用户体验

- **显示导出进度**：大文件导出时显示进度指示器
- **提供预览**：导出前允许用户预览
- **支持多种格式**：让用户选择所需格式

---

## 九、参考资料

- [Apple - ImageRenderer Documentation](https://developer.apple.com/documentation/swiftui/imagerenderer)
- [Hacking with Swift - Render SwiftUI View to PDF](https://www.hackingwithswift.com/quick-start/swiftui/how-to-render-a-swiftui-view-to-a-pdf)
- [AppCoda - SwiftUI ImageRenderer PDF](https://www.appcoda.com/swiftui-imagerenderer-pdf/)
- [XBRL Report Formats](https://www.xbrl.org/guidance/xbrl-report-formats/)
- [JSON vs CSV vs XML Comparison](https://sonra.io/csv-vs-json-vs-xml/)

---

## 十、总结

**导出方案选择：**

| 需求 | 推荐方案 |
|------|----------|
| 生成可打印报告 | PDF（ImageRenderer） |
| 供程序/API 使用 | JSON |
| 供 Excel 使用 | CSV（带 BOM） |
| 社交分享 | 图片（PNG/JPEG） |
| 最大兼容性 | 同时支持 JSON + CSV |

**关键代码：**

```swift
// PDF
let renderer = ImageRenderer(content: view)
renderer.render { size, context in ... }

// JSON
let data = try JSONEncoder().encode(report)

// CSV
let csv = headers.joined(separator: ",") + "\n" + rows.map { $0.joined(separator: ",") }.joined(separator: "\n")

// 分享
ShareLink(item: url) { Label("分享", systemImage: "square.and.arrow.up") }
```
