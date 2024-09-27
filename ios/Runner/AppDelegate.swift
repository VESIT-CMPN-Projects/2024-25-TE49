import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register Flutter plugins and configure the Flutter environment
        GeneratedPluginRegistrant.register(with: self)

        // Call the super class method to ensure Flutter is properly set up
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
