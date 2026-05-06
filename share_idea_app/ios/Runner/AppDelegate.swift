import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // TODO(stripe): Uncomment and set publishable key once Stripe is integrated.
    // import Stripe must be added at the top of this file.
    // StripeAPI.defaultPublishableKey = "pk_live_REPLACE_WITH_PUBLISHABLE_KEY"

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
