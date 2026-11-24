import SwiftUI
import Charts

struct PriceChart: View {
    let points: [PriceSnapshot]
    var height: CGFloat = 180
    var showAxis: Bool = false

    // Swift Charts 默认 Y 轴会把 0 纳入范围，几块钱的波动会被压成一条直线。
    // 按当前数据的最小/最大值上下留 15% 边距，波动才会被看见。
    private var yDomain: ClosedRange<Double> {
        guard let low = points.map(\.price).min(),
              let high = points.map(\.price).max() else { return 0...1 }
        let padding = max((high - low) * 0.15, 0.02)
        return (low - padding)...(high + padding)
    }

    var body: some View {
        Group {
            if points.count < 2 {
                VStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.muted)
                    Text("历史数据积累中，至少两次刷新后显示走势")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: height)
            } else {
                Chart {
                    ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                        LineMark(
                            x: .value("时间", point.timestamp),
                            y: .value("价格", point.price)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.gold)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                        .symbolSize(0)
                    }
                }
                .chartYScale(domain: yDomain)
                .chartXAxis(showAxis ? .automatic : .hidden)
                .chartYAxis(showAxis ? .automatic : .hidden)
                .chartLegend(.hidden)
                .frame(height: height)
            }
        }
    }
}
