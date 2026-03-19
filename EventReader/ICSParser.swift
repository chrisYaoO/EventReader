//
//  IcsParser.swift
//  EventReader
//
//  Created by Chris Yao on 2026-03-17.
//

import Foundation

class ICSParser{
    static func parseAll(from content: String)-> [Event]{
        var eventList: [Event] = []
        let res = unfold(from: content)
        let events = res.components(separatedBy: "BEGIN:VEVENT")
        for block in events{
            if let event  =  Event.parse(from: block)
            {
                eventList.append(event)
            }
        }
        return eventList
    }
    
    static func unfold(from content: String) -> String {
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        var unfoldedLines: [String] = []
        let lines = normalized.components(separatedBy: "\n")

        for line in lines {
            if line.isEmpty {
                continue
            }

            if line.hasPrefix(" ") || line.hasPrefix("\t") {
                if !unfoldedLines.isEmpty {
                    unfoldedLines[unfoldedLines.count - 1] += String(line.dropFirst())
                }
            } else {
                unfoldedLines.append(line)
            }
        }

        return unfoldedLines.joined(separator: "\n")
    }
}
