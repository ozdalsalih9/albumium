import Flutter
import UIKit
import UserNotifications
import Vision
import CoreImage
import UniformTypeIdentifiers

/// Calendar semantics match Android. Date collisions produce a single alert.
enum MemoryCalendar {
  static let prefix = "albumium.memory."
  static var current: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
  }
  static func occurrences(after now: Date, settings: [String: Any], calendar: Calendar = MemoryCalendar.current) -> [(Date, [String: Any])] {
    guard settings["enabled"] as? Bool != false else { return [] }
    let hour = min(23, max(0, settings["hour"] as? Int ?? 20))
    let minute = min(59, max(0, settings["minute"] as? Int ?? 0))
    let activity = (settings["lastActivity"] as? NSNumber)?.doubleValue ?? 0
    let after = max(now, Date(timeIntervalSince1970: activity / 1000 + 36 * 3600))
    var day = calendar.startOfDay(for: after)
    var events: [(Date, [String: Any])] = []
    for _ in 0..<740 {
      let c = calendar.dateComponents([.year, .month, .day, .weekday], from: day)
      var kinds: [String] = []
      if settings["weekend"] as? Bool != false && c.weekday == 1 { kinds.append("weekend") }
      if settings["month"] as? Bool != false && c.day == calendar.range(of: .day, in: .month, for: day)?.count { kinds.append("month") }
      if settings["year"] as? Bool != false && c.month == 12 && c.day == 31 { kinds.append("year") }
      if !kinds.isEmpty, let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day), fire > after {
        events.append((fire, ["kinds": kinds.joined(separator: ","), "year": c.year!, "month": c.month!, "day": c.day!]))
        if events.count == 60 { break }
      }
      guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
      day = next
    }
    var merged: [TimeInterval: (Date, [String: Any])] = [:]
    for event in events { merged[event.0.timeIntervalSince1970] = event }
    if settings["continuation"] as? Bool != false,
       let data = (settings["followUps"] as? String)?.data(using: .utf8),
       let jobs = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] {
      for job in jobs {
        guard let kind = job["kinds"] as? String, settings[kind] as? Bool != false,
              let updated = job["updatedAt"] as? NSNumber, let delay = job["delayDays"] as? Int,
              let date = calendar.date(byAdding: .day, value: delay, to: Date(timeIntervalSince1970: updated.doubleValue / 1000)),
              let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date), fire > after else { continue }
        merged[fire.timeIntervalSince1970] = (fire, job)
      }
    }
    var spaced: [(Date, [String: Any])] = []
    for event in merged.values.sorted(by: { $0.0 < $1.0 }) {
      if let previous = spaced.last, event.0.timeIntervalSince(previous.0) < 36 * 3600 {
        // A personal invitation takes priority over a nearby calendar prompt.
        if event.1["albumId"] != nil && previous.1["albumId"] == nil {
          spaced[spaced.count - 1] = event
        }
        continue
      }
      spaced.append(event)
      if spaced.count == 60 { break }
    }
    return spaced
  }

}

final class AlbumiumPlatformBridge {
  private let backupDocuments = AlbumBackupDocuments()
  private var backups: FlutterMethodChannel?
  private var memories: FlutterMethodChannel?
  private var packages: FlutterMethodChannel?
  private var support: FlutterMethodChannel?
  private var updates: FlutterMethodChannel?
  private var memoryReady = false
  private var packageReady = false
  private var pendingMemory: [String: Any]?
  private var lastMemoryKey = ""
  private var lastMemoryTime = Date.distantPast
  private var pendingPackages: [String] = []
  private var pendingErrors: [String] = []
  private var scheduleGeneration = 0
  private var observers: [NSObjectProtocol] = []
  private let defaultsKey = "albumium.native.reminders"
  private let workers = DispatchQueue(label: "albumium.media", qos: .userInitiated)
  deinit { observers.forEach { NotificationCenter.default.removeObserver($0) } }

  func register(messenger: FlutterBinaryMessenger) {
    updates = FlutterMethodChannel(name: "com.albumium.albumium/app_updates", binaryMessenger: messenger)
    updates?.setMethodCallHandler { call, result in
      switch call.method {
      case "check":
        result([
          "bundleId": Bundle.main.bundleIdentifier ?? "com.albumium.albumium",
          "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
          "systemVersion": UIDevice.current.systemVersion,
          "country": Locale.current.region?.identifier ?? "US"
        ])
      case "openStore":
        guard let args = call.arguments as? [String: Any],
              let raw = args["url"] as? String, let url = URL(string: raw),
              url.scheme == "https", url.host == "apps.apple.com" else {
          result(false); return
        }
        UIApplication.shared.open(url, options: [:]) { result($0) }
      default: result(FlutterMethodNotImplemented)
      }
    }
    backups = FlutterMethodChannel(name: "com.albumium.albumium/album_backup", binaryMessenger: messenger)
    backups?.setMethodCallHandler { [weak self] call, result in
      self?.backupDocuments.handle(call, result: result)
    }
    memories = FlutterMethodChannel(name: "com.albumium.albumium/memories", binaryMessenger: messenger)
    packages = FlutterMethodChannel(name: "com.albumium.albumium/incoming_album_package", binaryMessenger: messenger)
    support = FlutterMethodChannel(name: "com.albumium.albumium/app_support", binaryMessenger: messenger)
    memories?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "initialMemory":
        self.memoryReady = true; result(self.pendingMemory); self.pendingMemory = nil
      case "requestPermission":
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { allowed, error in
          DispatchQueue.main.async {
            if let error = error { result(FlutterError(code: "notification_permission", message: error.localizedDescription, details: nil)) }
            else { result(allowed) }
          }
        }
      case "openNotificationSettings":
        DispatchQueue.main.async {
          UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:]) { result($0) }
        }
      case "permissionStatus":
        UNUserNotificationCenter.current().getNotificationSettings { settings in
          DispatchQueue.main.async { result([.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)) }
        }
      case "configure":
        guard let settings = call.arguments as? [String: Any] else {
          result(FlutterError(code: "invalid_settings", message: "Invalid reminder settings", details: nil)); return
        }
        UserDefaults.standard.set(settings, forKey: self.defaultsKey)
        self.refreshReminders { error in
          if let error = error { result(FlutterError(code: "notification_schedule", message: error.localizedDescription, details: nil)) }
          else { result(nil) }
        }
      case "segment":
        guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
          result(FlutterError(code: "invalid_path", message: "Missing image", details: nil)); return
        }
        self.segment(path, result: result)
      default: result(FlutterMethodNotImplemented)
      }
    }
    packages?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      guard call.method == "startListening" else { result(FlutterMethodNotImplemented); return }
      self.packageReady = true
      result(self.pendingPackages.isEmpty ? nil : self.pendingPackages.removeFirst())
      DispatchQueue.main.async {
        self.pendingPackages.forEach { self.packages?.invokeMethod("albumPackageReceived", arguments: $0) }
        self.pendingErrors.forEach { self.packages?.invokeMethod("albumPackageReceiveError", arguments: $0) }
        self.pendingPackages.removeAll(); self.pendingErrors.removeAll()
      }
    }
    support?.setMethodCallHandler { call, result in
      guard call.method == "openPrivacyPolicy" else { result(FlutterMethodNotImplemented); return }
      UIApplication.shared.open(URL(string: "https://albumiumapp.com/privacy.html")!, options: [:]) { success in
        if success { result(nil) }
        else { result(FlutterError(code: "browser_unavailable", message: "Cannot open privacy policy", details: nil)) }
      }
    }
    if observers.isEmpty {
      for name in [UIApplication.didBecomeActiveNotification, UIApplication.significantTimeChangeNotification, NSNotification.Name.NSSystemTimeZoneDidChange] {
        observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in self?.refreshReminders() })
      }
    }
    refreshReminders()
  }

  func openMemory(_ payload: [AnyHashable: Any]) {
    guard let kinds = payload["kinds"] as? String, let year = payload["year"] as? Int,
      let month = payload["month"] as? Int, let day = payload["day"] as? Int else { return }
    var value: [String: Any] = ["kinds": kinds, "year": year, "month": month, "day": day]
    if let album = payload["albumId"] as? String { value["albumId"] = album }
    // A cold notification launch can arrive through both scene and app delegates.
    let key = "\(value["albumId"] ?? kinds):\(year):\(month):\(day)"
    let now = Date()
    if key == lastMemoryKey && now.timeIntervalSince(lastMemoryTime) < 2 { return }
    lastMemoryKey = key; lastMemoryTime = now
    if memoryReady { memories?.invokeMethod("openMemory", arguments: value) }
    else { pendingMemory = value }
  }

  func refreshReminders(completion: ((Error?) -> Void)? = nil) {
    scheduleGeneration += 1
    let generation = scheduleGeneration
    let settings = UserDefaults.standard.dictionary(forKey: defaultsKey) ?? [:]
    let center = UNUserNotificationCenter.current()
    center.getNotificationSettings { authorization in
      center.getPendingNotificationRequests { pending in
        DispatchQueue.main.async { [weak self] in
          guard let self = self, self.scheduleGeneration == generation else { completion?(nil); return }
          center.removePendingNotificationRequests(withIdentifiers: pending.filter { $0.identifier.hasPrefix(MemoryCalendar.prefix) }.map { $0.identifier })
          guard [.authorized, .provisional, .ephemeral].contains(authorization.authorizationStatus) else { completion?(nil); return }
          let english = settings["language"] as? String == "en"
          let group = DispatchGroup()
          var firstError: Error?
          for (date, payload) in MemoryCalendar.occurrences(after: Date(), settings: settings) {
            let content = UNMutableNotificationContent()
            content.title = payload["title"] as? String ?? (english ? "A little moment worth keeping" : "Saklamaya değer küçük bir an")
            let kind = payload["kinds"] as? String ?? ""
            let invitation: String
            switch kind {
            case "weekend": invitation = english ? "A photo, a sentence. What would you like to keep from this week?" : "Bir fotoğraf, bir cümle. Bu haftadan neyi saklamak istersin?"
            case "month": invitation = english ? "Gather this month's lovely little moments in your album." : "Bu ayın küçük güzelliklerini albümünde buluşturabilirsin."
            case "year": invitation = english ? "Let's close the year with the moments you loved." : "Yılı sevdiğin anlarla kapatalım mı?"
            default: invitation = english ? "Small moments make a lovely story. Keep one in your album." : "Küçük anlar güzel bir hikâye olur. Birini albümüne ekle."
            }
            content.body = payload["body"] as? String ?? invitation
            content.sound = .default; content.userInfo = payload
            var components = MemoryCalendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            components.calendar = MemoryCalendar.current
            components.timeZone = .current
            let id = MemoryCalendar.prefix + "\(Int(date.timeIntervalSince1970))"
            group.enter()
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))) { error in
              DispatchQueue.main.async {
                if firstError == nil { firstError = error }
                group.leave()
              }
            }
          }
          group.notify(queue: .main) { completion?(firstError) }
        }
      }
    }
  }

  func receive(_ url: URL) {
    guard url.isFileURL, url.pathExtension.lowercased() == "albumium" else { return }
    workers.async { [weak self] in
      guard let self = self else { return }
      let scoped = url.startAccessingSecurityScopedResource()
      defer { if scoped { url.stopAccessingSecurityScopedResource() } }
      var copied: URL?
      do {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("albumium_incoming", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        // Only our own old staging files; active imports remain untouched.
        let oldFiles = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        for file in oldFiles where file.pathExtension == "albumium" {
          if let modified = try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
             modified < Date().addingTimeInterval(-7 * 86400) { try? FileManager.default.removeItem(at: file) }
        }
        let output = folder.appendingPathComponent(UUID().uuidString + ".albumium"); copied = output
        var coordinationError: NSError?
        var readError: Error?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { readable in
          do {
            guard let input = InputStream(url: readable), let target = OutputStream(url: output, append: false) else { throw CocoaError(.fileReadUnknown) }
            input.open(); target.open()
            defer { input.close(); target.close() }
            var buffer = [UInt8](repeating: 0, count: 65536)
            var total = 0
            while true {
              let count = input.read(&buffer, maxLength: buffer.count)
              if count < 0 { throw input.streamError ?? CocoaError(.fileReadUnknown) }
              if count == 0 { break }
              total += count
              guard total <= 160 * 1024 * 1024 else { throw CocoaError(.fileReadTooLarge) }
              try buffer.withUnsafeBufferPointer { bytes in
                var written = 0
                while written < count {
                  let n = target.write(bytes.baseAddress!.advanced(by: written), maxLength: count - written)
                  guard n > 0 else { throw target.streamError ?? CocoaError(.fileWriteUnknown) }
                  written += n
                }
              }
            }
            guard total > 0 else { throw CocoaError(.fileReadCorruptFile) }
          } catch { readError = error }
        }
        if let error = coordinationError { throw error }
        if let error = readError { throw error }
        DispatchQueue.main.async {
          if self.packageReady { self.packages?.invokeMethod("albumPackageReceived", arguments: output.path) }
          else { self.pendingPackages.append(output.path) }
        }
      } catch {
        if let output = copied { try? FileManager.default.removeItem(at: output) }
        DispatchQueue.main.async {
          let message = Locale.current.language.languageCode?.identifier == "tr" ? "Albüm dosyası açılamadı." : "Could not open the album file."
          if self.packageReady { self.packages?.invokeMethod("albumPackageReceiveError", arguments: message) }
          else { self.pendingErrors.append(message) }
        }
      }
    }
  }

  private func segment(_ path: String, result: @escaping FlutterResult) {
    workers.async {
      do {
        let handler = VNImageRequestHandler(url: URL(fileURLWithPath: path), options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()
        try handler.perform([request])
        guard let observation = request.results?.first, !observation.allInstances.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
        let buffer = try observation.generateMaskedImage(ofInstances: observation.allInstances, from: handler, croppedToInstancesExtent: false)
        let image = CIImage(cvPixelBuffer: buffer)
        guard let cg = CIContext().createCGImage(image, from: image.extent), let png = UIImage(cgImage: cg).pngData() else { throw CocoaError(.fileWriteUnknown) }
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("sticker_\(UUID().uuidString).png")
        try png.write(to: output, options: .atomic)
        DispatchQueue.main.async { result(output.path) }
      } catch {
        DispatchQueue.main.async { result(FlutterError(code: "segmentation_unavailable", message: "Automatic cutout unavailable; use the manual eraser.", details: nil)) }
      }
    }
  }
}


/// Files handles iCloud authentication and upload; no private iCloud container is needed.
private final class AlbumBackupDocuments: NSObject, UIDocumentPickerDelegate {
  private var pending: FlutterResult?
  private var saving = false
  private let worker = DispatchQueue(label: "albumium.backup", qos: .userInitiated)

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "save" || call.method == "pick" else { result(FlutterMethodNotImplemented); return }
    guard pending == nil else { result(FlutterError(code: "busy", message: "A document picker is already open", details: nil)); return }
    guard let window = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
      .filter({ $0.activationState == .foregroundActive }).flatMap({ $0.windows }).first(where: { $0.isKeyWindow }),
      var presenter = window.rootViewController else {
      result(FlutterError(code: "document_unavailable", message: "No active window", details: nil)); return
    }
    while let presented = presenter.presentedViewController { presenter = presented }
    guard !presenter.isBeingDismissed else {
      result(FlutterError(code: "document_unavailable", message: "Please try again", details: nil)); return
    }
    saving = call.method == "save"
    let picker: UIDocumentPickerViewController
    if saving {
      guard let args = call.arguments as? [String: Any], let path = args["path"] as? String else {
        result(FlutterError(code: "invalid_path", message: "Missing album", details: nil)); return
      }
      let url = URL(fileURLWithPath: path).resolvingSymlinksInPath()
      let roots = [FileManager.default.temporaryDirectory] + FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
      guard roots.contains(where: { url.path.hasPrefix($0.resolvingSymlinksInPath().path + "/") }),
            url.pathExtension == "albumium", let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
            let bytes = attributes[.size] as? NSNumber, bytes.int64Value > 0, bytes.int64Value <= 160 * 1024 * 1024 else {
        result(FlutterError(code: "invalid_path", message: "Album is missing or too large", details: nil)); return
      }
      picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
    } else {
      picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: false)
    }
    picker.allowsMultipleSelection = false
    picker.delegate = self
    pending = result
    presenter.present(picker, animated: true)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = pending; pending = nil
    result?(saving ? false : nil)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = pending else { return }
    guard let url = urls.first else { pending = nil; result(saving ? false : nil); return }
    if saving { pending = nil; result(true); return }
    let scoped = url.startAccessingSecurityScopedResource()
    worker.async {
      defer { if scoped { url.stopAccessingSecurityScopedResource() } }
      var output: URL?
      do {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("albumium_backup_import", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for file in (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.contentModificationDateKey])) ?? [] {
          if let modified = try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
             modified < Date().addingTimeInterval(-7 * 86400) { try? FileManager.default.removeItem(at: file) }
        }
        let destination = folder.appendingPathComponent("\(UUID().uuidString).albumium")
        output = destination
        var coordinationError: NSError?
        var readError: Error?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { readable in
          do {
            guard let input = InputStream(url: readable), let target = OutputStream(url: destination, append: false) else { throw CocoaError(.fileReadUnknown) }
            input.open(); target.open()
            defer { input.close(); target.close() }
            var buffer = [UInt8](repeating: 0, count: 65536)
            var total = 0
            while true {
              let count = input.read(&buffer, maxLength: buffer.count)
              if count < 0 { throw input.streamError ?? CocoaError(.fileReadUnknown) }
              if count == 0 { break }
              total += count
              guard total <= 160 * 1024 * 1024 else { throw CocoaError(.fileReadTooLarge) }
              try buffer.withUnsafeBufferPointer { bytes in
                var written = 0
                while written < count {
                  let n = target.write(bytes.baseAddress!.advanced(by: written), maxLength: count - written)
                  guard n > 0 else { throw target.streamError ?? CocoaError(.fileWriteUnknown) }
                  written += n
                }
              }
            }
            guard total > 0 else { throw CocoaError(.fileReadCorruptFile) }
          } catch { readError = error }
        }
        if let error = coordinationError { throw error }
        if let error = readError { throw error }
        DispatchQueue.main.async { self.pending = nil; result(destination.path) }
      } catch {
        if let output = output { try? FileManager.default.removeItem(at: output) }
        DispatchQueue.main.async { self.pending = nil; result(FlutterError(code: "document_failed", message: error.localizedDescription, details: nil)) }
      }
    }
  }
}
