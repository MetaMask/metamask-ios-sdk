import UIKit

public class BackgroundTaskManager {
    static var task: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 0)
    
    public static func start() {
        task = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            self.stop()
        })
    }
    
    public static func stop() {
        UIApplication.shared.endBackgroundTask(task)
        task = UIBackgroundTaskIdentifier.invalid
    }
}
