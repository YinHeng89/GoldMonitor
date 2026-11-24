import Foundation
import UserNotifications

protocol Notifying: Sendable {
    func requestAuthorization() async throws
    func send(title: String, body: String) async
}

final class NotificationService: Notifying, @unchecked Sendable {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async throws {
        _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func send(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await center.add(request)
    }
}
