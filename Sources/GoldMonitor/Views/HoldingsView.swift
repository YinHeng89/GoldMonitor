import SwiftUI
import SwiftData

struct HoldingsView: View {
    @EnvironmentObject private var store: MarketStore
    @Environment(\.modelContext) private var context
    @Query(sort: \GoldHolding.createdAt, order: .reverse) private var holdings: [GoldHolding]
    @State private var editorTarget: GoldHolding?
    @State private var showingEditor = false

    private var summary: HoldingSummary {
        HoldingSummary.make(holdings, quotes: store.quotes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("我的持仓")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)
                    Text("手动录入成本价与克数，按实时赎回价计算浮动盈亏 · 数据仅存本机")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondary)
                }
                Spacer()
                Button {
                    editorTarget = nil
                    showingEditor = true
                } label: {
                    Label("添加持仓", systemImage: "plus")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.gold)
                .controlSize(.large)
            }

            summaryCard

            if holdings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "briefcase")
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.gold)
                    Text("还没有持仓记录")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.text)
                    Text("录入你在工行积存金的实际买入价和克数，即可实时查看收益")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 220)
                .gmCard()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(holdings) { holding in
                            holdingRow(holding)
                        }
                    }
                }
            }
            Spacer(minLength: 4)
        }
        .padding(26)
        .background(Theme.background)
        .tint(Theme.gold)
        .sheet(isPresented: $showingEditor) {
            HoldingEditorView(existing: editorTarget)
                .environment(\.modelContext, context)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                metricCell(title: "持仓成本", value: gmNumber(summary.cost), unit: "元", color: Theme.text)
                metricCell(title: "当前市值", value: gmNumber(summary.marketValue), unit: "元", color: Theme.text)
                metricCell(title: "浮动盈亏", value: gmSigned(summary.profit), unit: "元", color: Theme.priceColor(summary.profit))
                metricCell(title: "收益率", value: gmPercent(summary.profitPercent), unit: "", color: Theme.priceColor(summary.profit))
            }
            if summary.hasUnpriced {
                Text("\(summary.pricedCount)/\(summary.totalCount) 笔已获取行情，未计价的持仓暂不参与汇总")
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .gmCard()
    }

    private func metricCell(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(Theme.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(color)
                    .lineLimit(1)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func holdingRow(_ holding: GoldHolding) -> some View {
        let metrics = holding.metrics(quote: store.quotes[holding.kind])
        return HStack(spacing: 14) {
            Image(systemName: holding.kind == .london ? "globe.americas" : "banknote")
                .font(.system(size: 16))
                .foregroundStyle(Theme.gold)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 5) {
                Text("\(holding.kind.shortName) · \(gmNumber(holding.grams)) 克")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Theme.text)
                HStack(spacing: 10) {
                    Text("成本 \(gmNumber(holding.costPrice)) \(holding.kind.unit)")
                    if let date = holding.purchasedAt {
                        Text("购入 \(gmDate(date))")
                    }
                    if !holding.note.isEmpty {
                        Text(holding.note)
                    }
                }
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                if metrics.isPriced {
                    Text("现价 \(gmNumber(metrics.price))")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.secondary)
                    Text("\(gmSigned(metrics.profit)) 元 · \(gmPercent(metrics.profitPercent))")
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.priceColor(metrics.profit))
                } else {
                    Text("等待行情")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }
            }

            Button {
                editorTarget = holding
                showingEditor = true
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Theme.secondary)

            Button(role: .destructive) {
                context.delete(holding)
                try? context.save()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .gmCard(padding: 14)
    }
}

struct HoldingEditorView: View {
    let existing: GoldHolding?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var kind: GoldQuote.Kind = .icbc
    @State private var costPrice = ""
    @State private var grams = ""
    @State private var note = ""
    @State private var hasPurchaseDate = false
    @State private var purchasedAt = Date()
    @State private var validation: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(existing == nil ? "添加持仓" : "编辑持仓")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.text)

            VStack(spacing: 0) {
                editorRow("品种") {
                    Picker("", selection: $kind) {
                        ForEach(GoldQuote.Kind.allCases) { item in
                            Text(item.displayName).tag(item)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 250, alignment: .leading)
                }
                rowDivider
                editorRow("成本价") {
                    HStack(spacing: 8) {
                        editorField("例如 760.00", text: $costPrice, width: 150)
                        Text("元/克")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.secondary)
                            .frame(width: 42, alignment: .leading)
                    }
                }
                rowDivider
                editorRow("持仓克数") {
                    HStack(spacing: 8) {
                        editorField("例如 100", text: $grams, width: 150)
                        Text("克")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.secondary)
                            .frame(width: 42, alignment: .leading)
                    }
                }
                rowDivider
                editorRow("记录购买日期") {
                    Toggle("", isOn: $hasPurchaseDate)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .frame(width: 44, alignment: .leading)
                }
                if hasPurchaseDate {
                    rowDivider
                    editorRow("购买日期") {
                        DatePicker("", selection: $purchasedAt, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .frame(width: 250, alignment: .leading)
                    }
                }
                rowDivider
                editorRow("备注（可选）") {
                    editorField("可填写购买渠道等信息", text: $note, width: 250)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Theme.border, lineWidth: 1)
            }

            if let validation {
                Text(validation)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.up)
            }

            HStack(spacing: 10) {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("保存") { save() }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.gold)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 470)
        .background(Theme.background)
        .tint(Theme.gold)
        .onAppear {
            guard let existing else { return }
            kind = existing.kind
            costPrice = String(format: "%.2f", existing.costPrice)
            grams = "\(existing.grams)"
            note = existing.note
            if let date = existing.purchasedAt {
                hasPurchaseDate = true
                purchasedAt = date
            }
        }
    }

    private var rowDivider: some View {
        Divider()
            .foregroundStyle(Theme.border)
            .padding(.leading, 104)
    }

    private func editorRow(_ label: String, @ViewBuilder control: () -> some View) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Theme.text)
                .frame(width: 92, alignment: .leading)
            control()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 42)
    }

    private func editorField(_ placeholder: String, text: Binding<String>, width: CGFloat) -> some View {
        EditorField(placeholder: placeholder, text: text, width: width)
    }

    private func save() {
        guard let priceValue = Double(costPrice), priceValue > 0 else {
            validation = "请输入大于 0 的成本价"
            return
        }
        guard let gramValue = Double(grams), gramValue > 0 else {
            validation = "请输入大于 0 的持仓克数"
            return
        }
        let date = hasPurchaseDate ? purchasedAt : nil
        if let existing {
            existing.kind = kind
            existing.costPrice = priceValue
            existing.grams = gramValue
            existing.note = note
            existing.purchasedAt = date
            existing.updatedAt = Date()
        } else {
            context.insert(GoldHolding(
                kind: kind,
                costPrice: priceValue,
                grams: gramValue,
                note: note,
                purchasedAt: date
            ))
        }
        try? context.save()
        dismiss()
    }
}

/// 自绘输入框：避免 Form 把 prompt 挤到框外，且焦点环跟随主题金色而非系统蓝。
private struct EditorField: View {
    let placeholder: String
    @Binding var text: String
    let width: CGFloat
    @FocusState private var focused: Bool

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Theme.muted))
            .textFieldStyle(.plain)
            .focused($focused)
            .font(.system(size: 13))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 10)
            .frame(width: width, height: 30, alignment: .leading)
            .background(Theme.panelElevated, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(focused ? Theme.gold : Theme.border, lineWidth: focused ? 1.5 : 1)
            }
    }
}

private func gmDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}
