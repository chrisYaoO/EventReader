//
//  Event.swift
//  EventReader
//
//  Created by Chris Yao on 2026-03-17.
//

import Foundation

struct Event: Codable, Identifiable{
    var summary = ""
    var dtstart: Date?
    let id: UUID
    
    init(summary: String = "", dtstart: Date? = nil, id: UUID = UUID()) {
        self.summary = summary
        self.dtstart = dtstart
        self.id = id
    }
    
    static func parse(from block: String) -> Event? {
        var event = Event()

        let lines = block.components(separatedBy: "\n")

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .newlines)

            guard let idx = line.firstIndex(of: ":") else {
                continue
            }

            let rawKey = String(line[..<idx])
            let value = String(line[line.index(after: idx)...])

            let key = rawKey.components(separatedBy: ";")[0]

//            print("RAW LINE:", rawLine.debugDescription)
//            print("KEY:", key, "\nVALUE:", value)

            switch key {
            case "SUMMARY":
                event.summary = value
            case "DTSTART":
                event.dtstart = string2Date(value)
            default:
                break
            }
        }

        if event.summary.isEmpty {
            return nil
        }
        return event
    }
    
    // convert string to time
    static func string2Date(_ text: String) -> Date?{
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        inputFormatter.timeZone = TimeZone(abbreviation: "UTC")
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        return inputFormatter.date(from: text)
        
    }
    
    static func date2String( _ date: Date) -> String{
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        outputFormatter.timeStyle = .short
        return outputFormatter.string(from: date)
    }
    
}

struct SavedData: Codable{
    var events: [Event]
    let name: String
    
    init(events: [Event], name: String) {
        self.events = events
        self.name = name
    }
    
    static func saveEvents(_ events: SavedData) throws{
        let encoder = JSONEncoder()
        let data = try encoder.encode(events)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("events.json")
        try data.write(to: fileURL)
    }
    
    static func loadEvents() throws ->SavedData{
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("events.json")
        let jsonData = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let events = try decoder.decode(SavedData.self, from: jsonData)
        return events
    }
}
