import Flutter
import UIKit
import UserNotifications
import Vision
import CoreImage

/// Calendar semantics match Android. Date collisions produce a single alert.
enum MemoryCalendar {
  static let prefix = "albumium.memory."
  static var current: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
  }
  static func occurrences(after now: Date, settings: [String: Any], calendar: Calendar = MemoryCalendar.current) -> [(Date, [String: Any])] {
    guard settings["enabled"] as? Bool == true else { return [] }
    let hour = min(23, max(0, settings["hour"] as? Int ?? 20))
    let minute = min(59, max(0, settings["minute"] as? Int ?? 0))
    var day = calendar.startOfDay(for: now)
    var events: [(Date, [String: Any])] = []
    for _ in 0..<740 {
      let c = calendar.dateComponents([.year, .month, .day, .weekday], from: day)
      var kinds: [String] = []
      if settings["weekend"] as? Bool != false && c.weekday == 1 { kinds.append("weekend") }
      if settings["month"] as? Bool != false && c.day == calendar.range(of: .day, in: .month, for: day)?.count { kinds.append("month") }
      if settings["year"] as? Bool != false && c.month == 12 && c.day == 31 { kinds.append("year") }
      if !kinds.isEmpty, let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day), fire > now {
        events.append((fire, ["kinds": kinds.joined(separator: ","), "year": c.year!, "month": c.month!, "day": c.day!]))
        if events.count == 60 { break }
      }
      guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
      day = next
    }
    return events
  }
}

final class AlbumiumPlatformBridge {
  private var memories: FlutterMethodChannel?
  private var packages: FlutterMethodChannel?
  private var support: FlutterMethodChannel?
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
      UIApplication.shared.open(URL(string: "https://sites.google.com/view/albumium-privacy/ana-sayfa")!, options: [:]) { success in
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
    let value: [String: Any] = ["kinds": kinds, "year": year, "month": month, "day": day]
    // A cold notification launch can arrive through both scene and app delegates.
    let key = "\(kinds):\(year):\(month):\(day)"
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
            content.title = english ? "Your memories are waiting" : "Anıların seni bekliyor"
            content.body = english ? "Turn your photos into an album." : "Fotoğraflarını bir albümde buluştur."
            content.sound = .default; content.userInfo = payload
            var components = MemoryCalendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            components.calendar = MemoryCalendar.current
            components.timeZone = .current
            let id = MemoryCalendar.prefix + "\(payload["year"]!)-\(payload["month"]!)-\(payload["day"]!)"
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
        let buffer = try observation.generateMaskedImage(ofInstances: observation.allInstances, from: handler, croppedToInstances: false)
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
