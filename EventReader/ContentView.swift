//
//  ContentView.swift
//  EventReader
//
//  Created by Chris Yao on 2026-03-17.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var statusMsg = "No file selected"
    @State private var showImporter = false
    @State private var eventList: [Event] = []
    @State private var didTriggerPressHaptic = false
    @State private var showReminder = false
    @State private var currEvent: Event? = nil
    
//    init(statusMsg: String = "No file selected", showImporter: Bool = false, eventList: [Event] = []) {
//        self.statusMsg = statusMsg
//        self.showImporter = showImporter
//        self.eventList = eventList
//    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack{
                Text(statusMsg.uppercased())
                    .font(.title3)
                    .bold()
                
                Spacer()
                
                Button {
//                    let generator = UIImpactFeedbackGenerator(style: .rigid)
//                    generator.prepare()
//                    generator.impactOccurred()
                    showImporter = true
                }label: {
                    Text("Import")
                        .bold()
                        .padding(.horizontal,14)
                        .padding(.vertical,8)
                }
                .buttonStyle(GlassGrayButtonStyle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !didTriggerPressHaptic {
                                triggerPressHaptic()
                                didTriggerPressHaptic = true
                            }
                        }
                        .onEnded { _ in
                            didTriggerPressHaptic = false
                        }
                )
            }
            .padding(EdgeInsets(top: 6, leading: 20, bottom: 4, trailing: 20))
            
            List(eventList){ event in
                VStack(alignment: .leading, spacing: 4){
                    Text(event.summary)
                    
                    Button{
                        showReminder = true
                        currEvent = event
                    }label: {
                        Text(Event.date2String(event.dtstart!))
                            .foregroundStyle(.blue)
                            .underline()

                    }
                    .buttonStyle(.plain)
                    
                }
            }
//            .textSelection(.enabled)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
                
        }
//        .padding()
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.calendarEvent]) { result in
            switch result{
            case.success(let url):
                let granted = url.startAccessingSecurityScopedResource()
                defer {
                    if granted {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                do{
                    let content = try String(contentsOf: url, encoding: .utf8)
                    let parsedEvents = ICSParser.parseAll(from: content)
                    let sorted = parsedEvents
                        .filter {
                            $0.dtstart != nil
                        }
                        .sorted{a,b in
                            a.dtstart! < b.dtstart!
                        }
                    let savedData = SavedData(events: sorted, name: url.deletingPathExtension().lastPathComponent)
                    
                    do {
                        try SavedData.saveEvents(savedData)

                        DispatchQueue.main.async {
                            eventList = savedData.events
                            statusMsg = savedData.name
                        }
                    } catch {
                        DispatchQueue.main.async {
                            statusMsg = "Save failed"
                        }
                        print("Save failed:", error)
                    }
                }
                catch{
                    statusMsg = "read file failed"
                }
            case.failure(let error):
                statusMsg = "import failed"
            }
        }
        .onAppear {
            do{
                let savedEvents = try SavedData.loadEvents()
                eventList = savedEvents.events
                statusMsg = savedEvents.name
            }catch{
                statusMsg = "No saved events yet"
            }
        }
        .alert("Add to Reminder?", isPresented: $showReminder){
            Button("Cancel", role: .cancel){
                
            }
            Button("Add"){
                let reminderManager = ReminderManager()
                do{
                    try reminderManager.addReminder(for: currEvent!)
                }catch{
                    print(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
