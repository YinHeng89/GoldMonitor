import AppKit

// Gold Monitor app icon — 深色 squircle + 金色上升曲线 + 数据光点。
// 用法: swift scripts/generate_icon.swift <输出 PNG 路径>

let output = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "/tmp/goldmonitor_icon.png"

let S: CGFloat = 1024

func rgba(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [r / 255, g / 255, b / 255, a])!
}

let goldLight = rgba(0xFF, 0xE6, 0xA8)
let gold = rgba(0xE8, 0xC5, 0x79)
let goldDeep = rgba(0x9A, 0x73, 0x1A)

let image = NSImage(size: NSSize(width: S, height: S))
image.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("no graphics context") }

// 背景：对角线深蓝黑渐变（贴合 Theme.background 0x0B0E13 / panel 0x141922）
let pad: CGFloat = 64
let rect = CGRect(x: pad, y: pad, width: S - 2 * pad, height: S - 2 * pad)
let corner: CGFloat = (S - 2 * pad) * 0.2237
let squircle = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)

ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()
let bgColors = [rgba(0x1B, 0x22, 0x2D), rgba(0x0B, 0x0E, 0x13)] as CFArray
let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: bgColors, locations: [0, 1])!
ctx.drawLinearGradient(bgGradient, start: CGPoint(x: pad, y: S - pad), end: CGPoint(x: S - pad, y: pad), options: [])

// 顶部柔光
let glowColors = [rgba(0xE8, 0xC5, 0x79, 0.10), rgba(0xE8, 0xC5, 0x79, 0.0)] as CFArray
let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: glowColors, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: S * 0.5, y: S * 0.98), startRadius: 0,
                       endCenter: CGPoint(x: S * 0.5, y: S * 0.98), endRadius: S * 0.75, options: [])

// 网格线（低对比，金融终端质感）
ctx.setStrokeColor(gold.copy(alpha: 0.10)!)
ctx.setLineWidth(2)
for i in 1..<6 {
    let y = pad + (S - 2 * pad) * CGFloat(i) / 6
    ctx.move(to: CGPoint(x: pad + 60, y: y))
    ctx.addLine(to: CGPoint(x: S - pad - 60, y: y))
}
for i in 1..<5 {
    let x = pad + (S - 2 * pad) * CGFloat(i) / 5
    ctx.move(to: CGPoint(x: x, y: pad + 50))
    ctx.addLine(to: CGPoint(x: x, y: S - pad - 50))
}
ctx.strokePath()
ctx.restoreGState()

// 上升折线：低 → 震荡 → 拉高
let points: [CGPoint] = [
    CGPoint(x: 182, y: 300),
    CGPoint(x: 300, y: 372),
    CGPoint(x: 414, y: 340),
    CGPoint(x: 530, y: 470),
    CGPoint(x: 644, y: 430),
    CGPoint(x: 756, y: 560),
    CGPoint(x: 866, y: 740)
]

func smoothPath(_ pts: [CGPoint]) -> CGPath {
    let path = CGMutablePath()
    guard pts.count >= 2 else { return path }
    path.move(to: pts[0])
    for i in 0..<(pts.count - 1) {
        let p0 = pts[max(0, i - 1)]
        let p1 = pts[i]
        let p2 = pts[i + 1]
        let p3 = pts[min(pts.count - 1, i + 2)]
        let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
        let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
        path.addCurve(to: p2, control1: c1, control2: c2)
    }
    return path
}

let line = smoothPath(points)

// 曲线下方渐变填充
ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()
let area = CGMutablePath()
area.addPath(line)
area.addLine(to: CGPoint(x: points.last!.x, y: pad))
area.addLine(to: CGPoint(x: points.first!.x, y: pad))
area.closeSubpath()
ctx.addPath(area)
ctx.clip()
let fillColors = [rgba(0xE8, 0xC5, 0x79, 0.32), rgba(0xE8, 0xC5, 0x79, 0.0)] as CFArray
let fillGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: fillColors, locations: [0, 1])!
ctx.drawLinearGradient(fillGradient, start: CGPoint(x: 0, y: S - pad), end: CGPoint(x: 0, y: pad + 40), options: [])

// 横向淡出：让填充在右侧自然消失，避免末端形成一条突兀的垂直"柱子"
let fadeColors = [rgba(0x0B, 0x0E, 0x13, 0.0), rgba(0x0B, 0x0E, 0x13, 0.92)] as CFArray
let fadeGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: fadeColors, locations: [0, 1])!
ctx.drawLinearGradient(fadeGradient, start: CGPoint(x: S * 0.42, y: 0), end: CGPoint(x: S - pad, y: 0), options: [])
ctx.restoreGState()

// 曲线：底层暗金描边 + 上层亮金
ctx.saveGState()
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.addPath(line)
ctx.setStrokeColor(goldDeep)
ctx.setLineWidth(30)
ctx.strokePath()
ctx.addPath(line)
ctx.setStrokeColor(gold)
ctx.setLineWidth(18)
ctx.strokePath()
ctx.restoreGState()

// 数据点：小金珠
for p in points.dropLast() {
    ctx.setFillColor(goldLight)
    ctx.fillEllipse(in: CGRect(x: p.x - 9, y: p.y - 9, width: 18, height: 18))
}

// 末端光点：光晕 + 实心
let last = points.last!
ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()
let dotGlow = [rgba(0xFF, 0xE6, 0xA8, 0.55), rgba(0xFF, 0xE6, 0xA8, 0.0)] as CFArray
let dotGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: dotGlow, locations: [0, 1])!
ctx.drawRadialGradient(dotGradient, startCenter: last, startRadius: 0, endCenter: last, endRadius: 92, options: [])
ctx.setFillColor(goldLight)
ctx.fillEllipse(in: CGRect(x: last.x - 24, y: last.y - 24, width: 48, height: 48))
ctx.setFillColor(rgba(0xFF, 0xFF, 0xFF, 0.9))
ctx.fillEllipse(in: CGRect(x: last.x - 8, y: last.y - 8, width: 16, height: 16))
ctx.restoreGState()

// 外描边
ctx.setStrokeColor(gold.copy(alpha: 0.55)!)
ctx.setLineWidth(5)
ctx.addPath(squircle)
ctx.strokePath()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("PNG 生成失败")
}
try png.write(to: URL(fileURLWithPath: output))
print("written: \(output)")
