import Cocoa
import FlutterMacOS
import IOKit.ps

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    let channel = FlutterMethodChannel(name: "cloud.phylum.drive/clippy",
                                       binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler(handle)
    
    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "files":
      files(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func files(result: FlutterResult) {
    guard let urlList = NSPasteboard.general.readObjects(forClasses: [NSURL.self], options: nil) else {
      result(nil)
      return
    }

    var resultFiles: [String] = []

    urlList.forEach { url in
      if let path = (url as? NSURL)?.path {
        resultFiles.append(path)
      }
    }
    result(resultFiles)
  }
}
