import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  private var calendar: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Europe/Istanbul")!
    return c
  }
  private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
  }
  func testLeapMonthAndNoPastAlerts() {
    let events = MemoryCalendar.occurrences(after: date(2028, 2, 28), settings: ["enabled": true, "weekend": false, "year": false], calendar: calendar)
    XCTAssertEqual(events.first?.1["day"] as? Int, 29)
    XCTAssertEqual(events.first?.1["month"] as? Int, 2)
    XCTAssertTrue(events.allSatisfy { $0.0 > date(2028, 2, 28) })
  }
  func testCollidingSundayMonthAndYearAreCombined() {
    let events = MemoryCalendar.occurrences(after: date(2023, 12, 31), settings: ["enabled": true], calendar: calendar)
    XCTAssertEqual(events.first?.1["kinds"] as? String, "weekend,month,year")
    XCTAssertEqual(Set(events.map { $0.0 }).count, events.count)
    XCTAssertLessThanOrEqual(events.count, 60)
  }
  func testDisabledAndElapsedToday() {
    XCTAssertTrue(MemoryCalendar.occurrences(after: Date(), settings: [:]).isEmpty)
    let events = MemoryCalendar.occurrences(after: date(2023, 12, 31, 21), settings: ["enabled": true, "weekend": false, "month": false], calendar: calendar)
    XCTAssertEqual(events.first?.1["year"] as? Int, 2024)
  }
  func testDaylightSavingUsesCalendarTime() {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/New_York")!
    let now = c.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 12))!
    let events = MemoryCalendar.occurrences(after: now, settings: ["enabled": true, "month": false, "year": false, "hour": 20], calendar: c)
    XCTAssertEqual(c.component(.hour, from: events[0].0), 20)
    XCTAssertEqual(c.component(.day, from: events[0].0), 8)
  }

}
