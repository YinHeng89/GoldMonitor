import SwiftUI
import SwiftData

struct AlertView: View {
    @EnvironmentObject private var store: MarketStore
    @Environment(\.modelContext) private var context
    @Query(sort: \PriceAlert.createdAt, order: .reverse) private var alerts: [PriceAlert]
    @State private var editorTarget: PriceAlert?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("价格预警")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)
                    Text("达到条件时通过 macOS 通知中心提醒 · 触发后自动静默，价格回到条件外会重新武装")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondary)
                }
                Spacer()
                Button {
                    editorTarget = nil
                    showingEditor = true
                } label: {
                    Label("新建预警", systemImage: "plus")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.gold)
                .controlSize(.large)
            }

            if alerts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell")
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.gold)
                    Text("还没有价格预警")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.text)
                    Text("例如：工行积存金低于 760 元/克时提醒")
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 260)
                .gmCard()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(alerts) { alert in
                            alertRow(alert)
                        }
                    }
                }
            }
            Spacer(minLength: 4)
        }
        .padding(26)
        .background(Theme.background)
        .sheet(isPresented: $showingEditor) {
            AlertEditorView(existing: editorTarget)
                .environment(\.modelContext, context)
        }
    }

    @State private var showingEditor = false

    private func alertRow(_ alert: PriceAlert) -> some View {
        let current = store.quotes[alert.kind]?.price
        return HStack(spacing: 14) {
            Image(systemName: alert.kind == .london ? "globe.americas" : "banknote")
                .font(.system(size: 16))
                .foregroundStyle(Theme.gold)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 5) {
                Text(alert.title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Theme.text)
                HStack(spacing: 10) {
                    if alert.enabled {
                        Label(alert.armed ? "等待触发" : "已触发（静默中）", systemImage: alert.armed ? "circle" : "checkmark.circle")
                            .foregroundStyle(alert.armed ? Theme.secondary : Theme.gold)
                    } else {
                        Label("已停用", systemImage: "pause.circle")
                            .foregroundStyle(Theme.muted)
                    }
                    if let price = alert.lastTriggeredPrice, let time = alert.lastTriggeredAt {
                        Text("触发价 \(gmNumber(price)) · \(gmDateTime(time))")
                            .foregroundStyle(Theme.muted)
                    }
                }
                .font(.system(size: 10.5))
            }

            Spacer()

            if let current {
                VStack(alignment: .trailing, spacing: 3) {
                    Text("当前 \(gmNumber(current))")
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(Theme.text)
                    Text(alert.matches(price: current) ? "条件已满足" : "未达到")
                        .font(.system(size: 10))
                        .foregroundStyle(alert.matches(price: current) ? Theme.up : Theme.muted)
                }
            }

            Toggle("", isOn: Binding(get: { alert.enabled }, set: { alert.enabled = $0 }))
                .toggleStyle(.switch)
                .labelsHidden()
                .frame(width: 40)

            Button {
                editorTarget = alert
                showingEditor = true
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Theme.secondary)

            Button(role: .destructive) {
                context.delete(alert)
                try? context.save()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .gmCard(padding: 14)
    }
}

struct AlertEditorView: View {
    let existing: PriceAlert?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var kind: GoldQuote.Kind = .icbc
    @State private var direction: AlertDirection = .above
    @State private var target = ""
    @State private var enabled = true
    @State private var validation: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(existing == nil ? "新建价格预警" : "编辑价格预警")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.text)

            Form {
                Picker("监控品种", selection: $kind) {
                    ForEach(GoldQuote.Kind.allCases) { item in
                        Text(item.displayName).tag(item)
                    }
                }
                Picker("触发条件", selection: $direction) {
                    ForEach(AlertDirection.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                HStack {
                    Text("目标价格")
                    Spacer()
                    TextField(kind == .london ? "例如 3700.00" : "例如 760.00", text: $target)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180)
                    Text(kind.unit)
                        .foregroundStyle(Theme.secondary)
                }
                Toggle("启用此规则", isOn: $enabled)
            }
            .formStyle(.grouped)
            .frame(minHeight: 210)

            if let validation {
                Text(validation)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.up)
            }

            HStack {
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
        .onAppear {
            guard let existing else { return }
            kind = existing.kind
            direction = existing.direction
            target = String(format: "%.2f", existing.target)
            enabled = existing.enabled
        }
    }

    private func save() {
        guard let value = Double(target), value > 0 else {
            validation = "请输入大于 0 的目标价格"
            return
        }
        if let existing {
            existing.kind = kind
            existing.direction = direction
            existing.target = value
            existing.enabled = enabled
            existing.armed = true
        } else {
            context.insert(PriceAlert(kind: kind, direction: direction, target: value, enabled: enabled))
        }
        try? context.save()
        dismiss()
    }
}
