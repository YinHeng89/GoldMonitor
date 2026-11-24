import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \PriceSnapshot.timestamp, order: .reverse) private var snapshots: [PriceSnapshot]
    @State private var kind: GoldQuote.Kind = .icbc
    @State private var range: HistoryRange = .day

    private var filtered: [PriceSnapshot] {
        let cutoff = Date().addingTimeInterval(-range.seconds)
        return snapshots.filter { $0.kind == kind && $0.timestamp >= cutoff }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("历史记录")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)
                    Text("每次成功刷新后本地保存一条快照 · 最多保留 5000 条")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondary)
                }
                Spacer()
                Picker("品种", selection: $kind) {
                    ForEach(GoldQuote.Kind.allCases) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 280)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("价格走势（\(filtered.count) 条记录）")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Picker("", selection: $range) {
                        ForEach(HistoryRange.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)
                }
                PriceChart(points: filtered.reversed(), height: 240, showAxis: true)
            }
            .gmCard()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("时间").frame(width: 150, alignment: .leading)
                    Text("品种").frame(width: 110, alignment: .leading)
                    Text("价格").frame(width: 120, alignment: .trailing)
                    Spacer()
                    Text("数据来源")
                }
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(Theme.secondary)
                .padding(.bottom, 10)

                Divider().background(Theme.border)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered.prefix(200), id: \.persistentModelID) { item in
                            HStack {
                                Text(gmFullDateTime(item.timestamp)).frame(width: 150, alignment: .leading)
                                Text(item.kind.shortName).frame(width: 110, alignment: .leading)
                                Text(gmNumber(item.price)).frame(width: 120, alignment: .trailing)
                                Spacer()
                                Text(item.sourceName)
                                    .lineLimit(1)
                                    .foregroundStyle(Theme.secondary)
                            }
                            .font(.system(size: 11.5))
                            .monospacedDigit()
                            .foregroundStyle(Theme.text)
                            .padding(.vertical, 8)
                            Divider().background(Theme.border.opacity(0.5))
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .gmCard()
            Spacer(minLength: 4)
        }
        .padding(26)
        .background(Theme.background)
    }
}
