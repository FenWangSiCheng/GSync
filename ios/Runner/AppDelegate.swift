import Flutter
import UniformTypeIdentifiers
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate, UIAdaptivePresentationControllerDelegate {
  private var directoryAccessCounts: [String: Int] = [:]
  private var directoryAccessUrls: [String: URL] = [:]
  private var directoryPickerResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard
      let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GitSyncDirectoryAccess")
    else {
      return
    }
    registerDirectoryAccessChannel(with: registrar.messenger())
  }

  private func registerDirectoryAccessChannel(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "cn.com.fenrir_inc.gsync/directory_access",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: "App delegate is unavailable.", details: nil))
        return
      }

      switch call.method {
      case "pickDirectory":
        self.pickDirectory(result: result)
      case "startAccessingDirectory":
        guard let path = self.directoryPath(from: call.arguments, result: result) else {
          return
        }
        result(self.startAccessingDirectory(at: path))
      case "stopAccessingDirectory":
        guard let path = self.directoryPath(from: call.arguments, result: result) else {
          return
        }
        self.stopAccessingDirectory(at: path)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func directoryPath(from arguments: Any?, result: FlutterResult) -> String? {
    guard
      let arguments = arguments as? [String: Any],
      let path = arguments["path"] as? String,
      !path.isEmpty
    else {
      result(FlutterError(code: "invalid_path", message: "A non-empty directory path is required.", details: nil))
      return nil
    }
    return path
  }

  private func pickDirectory(result: @escaping FlutterResult) {
    guard directoryPickerResult == nil else {
      result(FlutterError(code: "picker_busy", message: "Directory picker is already open.", details: nil))
      return
    }

    directoryPickerResult = result

    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
    } else {
      picker = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
    }

    picker.allowsMultipleSelection = false
    picker.delegate = self
    picker.presentationController?.delegate = self
    guard let viewController = visibleViewController() else {
      directoryPickerResult = nil
      result(FlutterError(code: "no_view_controller", message: "No view controller is available.", details: nil))
      return
    }

    viewController.present(picker, animated: true)
  }

  private func visibleViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }

    return visibleViewController(from: window?.rootViewController)
  }

  private func visibleViewController(from root: UIViewController?) -> UIViewController? {
    if let presented = root?.presentedViewController {
      return visibleViewController(from: presented)
    }
    if let navigationController = root as? UINavigationController {
      return visibleViewController(from: navigationController.visibleViewController)
    }
    if let tabBarController = root as? UITabBarController {
      return visibleViewController(from: tabBarController.selectedViewController)
    }
    return root
  }

  private func startAccessingDirectory(at path: String) -> Bool {
    if let count = directoryAccessCounts[path] {
      directoryAccessCounts[path] = count + 1
      return true
    }

    let url = directoryAccessUrls[path] ?? URL(fileURLWithPath: path, isDirectory: true)
    let didStart = url.startAccessingSecurityScopedResource()
    if didStart {
      directoryAccessCounts[path] = 1
      directoryAccessUrls[path] = url
    }
    return didStart
  }

  private func stopAccessingDirectory(at path: String) {
    guard let count = directoryAccessCounts[path] else {
      return
    }

    if count > 1 {
      directoryAccessCounts[path] = count - 1
      return
    }

    directoryAccessUrls[path]?.stopAccessingSecurityScopedResource()
    directoryAccessCounts.removeValue(forKey: path)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = directoryPickerResult else {
      return
    }

    guard let url = urls.first else {
      result(nil)
      directoryPickerResult = nil
      return
    }

    directoryAccessUrls[url.path] = url
    result(url.path)
    directoryPickerResult = nil
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    directoryPickerResult?(nil)
    directoryPickerResult = nil
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    directoryPickerResult?(nil)
    directoryPickerResult = nil
  }
}
