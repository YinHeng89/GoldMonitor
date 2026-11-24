import SwiftUI
import Charts

struct PriceChart: View {
    let points: [PriceSnapshot]
    var height: CGFloat = 180
    var showAxis: Bool = false

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
                .chartXAxis(showAxis ? .automatic : .hidden)
                .chartYAxis(showAxis ? .automatic : .hidden)
                .chartLegend(.hidden)
                .frame(height: height)
            }
        }
    }
}
