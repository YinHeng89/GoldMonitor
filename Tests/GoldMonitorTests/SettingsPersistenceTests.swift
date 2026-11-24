import XCTest
@testable import GoldMonitor

final class SettingsPersistenceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "goldmonitor.settings")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "goldmonitor.settings")
        super.tearDown()
    }

    func testSettingsRoundTrip() {
        var settings = AppSettings.defaults
        settings.londonProvider = .fx168
        settings.refreshInterval = 300
        settings.save()

        let loaded = AppSettings.load()
        XCTAssertEqual(loaded.londonProvider, .fx168)
        XCTAssertEqual(loaded.refreshInterval, 300)
    }

    // Swift 语义验证：didSet 中 settings 已是新值，oldValue 是旧值。
    // MarketStore 必须在 didSet 里调用 settings.save()，写 oldValue.save() 会存回旧设置。
    func testDidSetExposesNewValueAndOldValue() {
        struct Sample {
            var value: Int = 0
        }
        final class Holder {
            var state: Sample {
                didSet { capturedOld = oldValue.value; capturedNew = state.value }
            }
            var capturedOld = -1
            var capturedNew = -1
            init(_ state: Sample) { self.state = state }
        }

        let holder = Holder(Sample(value: 1))
        holder.state.value = 42
        XCTAssertEqual(holder.capturedOld, 1)
        XCTAssertEqual(holder.capturedNew, 42)
    }
}
