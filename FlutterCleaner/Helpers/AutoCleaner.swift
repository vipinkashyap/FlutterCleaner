import Foundation
import UserNotifications

struct AutoCleaner {
    static func run() {
        print("Running scheduled Flutter auto-clean...")
        AppLogger.log("AutoCleaner started")


        let defaults = UserDefaults.standard
        guard let lastPath = defaults.string(forKey: "lastFolder") else {
            print("No last folder saved — skipping.")
            return
        }

        let url = URL(fileURLWithPath: lastPath)
        let scanner = ProjectScanner()
        scanner.scan(in: url)
        // Wait briefly for scan to finish
        
            for project in scanner.projects {
                Cleaner.shared.clean(project: project, includePods: defaults.bool(forKey: "deepClean")) { _ in }
            }
            AppLogger.log("AutoCleaner finished cleaning \(scanner.projects.count) projects")
            // Notification 
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                guard granted else { return }
                let content = UNMutableNotificationContent()
                content.title = "Flutter Cleaner"
                content.body = "Automatic cleanup completed successfully."
                let request = UNNotificationRequest(identifier: UUID().uuidString,
                                                    content: content,
                                                    trigger: nil)
                UNUserNotificationCenter.current().add(request)
            }
        
    }
}
