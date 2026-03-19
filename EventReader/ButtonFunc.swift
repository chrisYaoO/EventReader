//
//  ButtonFunc.swift
//  EventReader
//
//  Created by Chris Yao on 2026-03-18.
//

import Foundation
import SwiftUI
import EventKit

struct GlassGrayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
            .background(configuration.isPressed ? .gray.opacity(0.2): .gray.opacity(0.3))
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ?
                         1.1 : 1)

    }
}

func triggerPressHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .rigid)
    generator.prepare()
    generator.impactOccurred()
}

class ReminderManager{
    let eventStore = EKEventStore()
    
    func addReminder(for event: Event, completion: @escaping (Bool, String?) -> Void) {
        eventStore.requestFullAccessToReminders{ granted, error in
            if granted{
                self.createReminder(event, completion: completion)
            }else{
                completion(false, "no access to reminder")
            }
        }
    }
        
    func createReminder(_ event: Event, completion: @escaping (Bool, String?) -> Void){ 
        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        reminder.title = event.summary
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: event.dtstart!
        )
        reminder.dueDateComponents = components
        
        do {
            try eventStore.save(reminder, commit: true)
            print("saved")
            completion(true, nil)
        }catch{
            print("save failed: \(error.localizedDescription)")
            completion(false, error.localizedDescription)
        }
    }
}

