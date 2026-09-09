import UIKit
import WebKit
import Capacitor

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Clear stale WKWebView data so updated web assets always load on dev installs.
        let types = Set([
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeOfflineWebApplicationCache,
            WKWebsiteDataTypeCookies,
        ])
        WKWebsiteDataStore.default().removeData(
            ofTypes: types,
            modifiedSince: Date.distantPast
        ) { }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.enableInspect() }
    }

    private func enableInspect() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            for window in scene.windows {
                walk(window.rootViewController)
                scanViews(window)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            for scene in scenes {
                for window in scene.windows { self.scanViews(window) }
            }
        }
    }

    private func scanViews(_ view: UIView) {
        if #available(iOS 16.4, *) {
            if let wv = view as? WKWebView { wv.isInspectable = true }
        }
        for sub in view.subviews { scanViews(sub) }
    }

    private func walk(_ vc: UIViewController?) {
        guard let vc = vc else { return }
        if let cap = vc as? CAPBridgeViewController {
            if #available(iOS 16.4, *) { cap.webView?.isInspectable = true }
        }
        walk(vc.presentedViewController)
        for child in vc.children { walk(child) }
    }
}
