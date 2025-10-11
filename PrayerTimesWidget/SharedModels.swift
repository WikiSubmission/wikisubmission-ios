//
//  PrayerWidgetData.swift
//  QuranicLabs
//
//  Created by down time on 11/10/2025.
//


import Foundation
import ActivityKit

struct PrayerWidgetData: Codable, Hashable {
    let currentPrayer: PrayerInfo
    let nextPrayer: PrayerInfo
    let locationString: String
    let timePeriod: String

    struct PrayerInfo: Codable, Hashable {
        let name: String
        let displayName: String
        let time: Date
        let symbolName: String
    }
}

struct PrayerTimesAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentPrayer: PrayerWidgetData.PrayerInfo
        var nextPrayer: PrayerWidgetData.PrayerInfo
        var timePeriod: String
    }

    var locationName: String
}

struct TimePeriodColors {
    let topHex: String
    let bottomHex: String

    static let periods: [String: TimePeriodColors] = [
        "midnight": TimePeriodColors(topHex: "000000", bottomHex: "000033"),
        "deepNight": TimePeriodColors(topHex: "000033", bottomHex: "0a1a5c"),
        "predawn": TimePeriodColors(topHex: "0a1a5c", bottomHex: "1e3799"),
        "fajr": TimePeriodColors(topHex: "1e3799", bottomHex: "4a69bd"),
        "sunrise": TimePeriodColors(topHex: "4a69bd", bottomHex: "60a3bc"),
        "morning": TimePeriodColors(topHex: "60a3bc", bottomHex: "e8f6ff"),
        "noon": TimePeriodColors(topHex: "e8f6ff", bottomHex: "ffffff"),
        "earlyAfternoon": TimePeriodColors(topHex: "ffffff", bottomHex: "fff9c4"),
        "asr": TimePeriodColors(topHex: "fff9c4", bottomHex: "fad390"),
        "lateAfternoon": TimePeriodColors(topHex: "fad390", bottomHex: "fa983a"),
        "maghrib": TimePeriodColors(topHex: "fa983a", bottomHex: "e55039"),
        "earlyEvening": TimePeriodColors(topHex: "e55039", bottomHex: "b71540"),
        "isha": TimePeriodColors(topHex: "b71540", bottomHex: "800020"),
        "lateEvening": TimePeriodColors(topHex: "800020", bottomHex: "4a0080"),
        "night": TimePeriodColors(topHex: "4a0080", bottomHex: "000033")
    ]
}
