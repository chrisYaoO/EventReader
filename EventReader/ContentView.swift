//
//  ContentView.swift
//  EventReader
//
//  Created by Chris Yao on 2026-03-17.
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct EventState{
    var statusMsg = "No file selected"
    var showImporter = false
    var didTriggerPressHaptic = false
    var highlightID: UUID? = nil
}
struct ReminderState{
    var showReminder = false
    var showSave = false
    var showSaveMsg = ""
    var currEvent: Event? = nil
}

struct ContentView: View {
    @State private var eventState = EventState()
    @State private var reminderState = ReminderState()
    @State private var eventList: [Event] = []
    let reminderManager = ReminderManager()
    private let sampleCalendarFiles = ["event", "Formula_1"]

    
    var body: some View {
        VStack(spacing: 8) {
            HStack{
                Text(eventState.statusMsg.uppercased())
                    .font(.title3)
//                    .bold()
                
                Spacer()
                
                Button {
//                    let generator = UIImpactFeedbackGenerator(style: .rigid)
//                    generator.prepare()
//                    generator.impactOccurred()
                    eventState.showImporter = true
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
                            if !eventState.didTriggerPressHaptic {
                                triggerPressHaptic()
                                eventState.didTriggerPressHaptic = true
                            }
                        }
                        .onEnded { _ in
                            eventState.didTriggerPressHaptic = false
                        }
                )
            }
            .padding(EdgeInsets(top: 6, leading: 20, bottom: 4, trailing: 20))
            
            ScrollViewReader{ proxy in
                ZStack(alignment: .bottomTrailing){
                    List(eventList){ event in
                        VStack(alignment: .leading, spacing: 8){
                            Text(event.summary)
                            
                            HStack{
//                                Spacer()
                                Button{
                                    reminderState.showReminder = true
                                    reminderState.currEvent = event
                                }label: {
                                    Text(Event.date2String(event.dtstart!))
                                        .foregroundStyle(.blue)
//                                        .underline()

                                }
                                .buttonStyle(.plain)
                            }
                            
                            
                        }
                        .id(event.id)
    //                    .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowBackground(event.id == eventState.highlightID ? Color.gray.opacity(0.25): Color.clear)
                        
                    }
        //            .textSelection(.enabled)
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    
                    if !eventList.isEmpty {
                        Button{
                            if let nextEvent = Event.nextevent(events: eventList){
                                withAnimation {
                                    proxy.scrollTo(nextEvent.id, anchor: .center)
                                }
                                
                                withAnimation {
                                    eventState.highlightID = nextEvent.id
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        eventState.highlightID = nil
                                    }
                                }
                            }
                        }label: {
                            ZStack{
                                Image(systemName: "location")
                                    .font(.title2)
    //                                .shadow(radius: 4)
                                    .frame(width: 60, height: 60)
                            }
                            
                            
                        }
                        .glassEffect(.clear.interactive(), in: .circle)
                        .shadow(radius: 4)
                        .padding()
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !eventState.didTriggerPressHaptic {
                                        triggerPressHaptic()
                                        eventState.didTriggerPressHaptic = true
                                    }
                                }
                                .onEnded { _ in
                                    eventState.didTriggerPressHaptic = false
                                }
                        )
                    }
                }
            }
        }
//        .padding()
        .sheet(isPresented: $eventState.showImporter) {
            CalendarDocumentPicker(initialDirectoryURL: documentsURL) { url in
                let granted = url.startAccessingSecurityScopedResource()
                defer {
                    if granted {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                do {
                    try importCalendar(from: url)
                }
                catch{
                    eventState.statusMsg = "Read file failed"
                }
            }
        }
        .onAppear {
            copySampleCalendarsToDocuments()
            do{
                let savedEvents = try SavedData.loadEvents()
                eventList = savedEvents.events
                eventState.statusMsg = savedEvents.name
            }catch{
                eventState.statusMsg = "No events yet"
            }
        }
        .alert("Add to Reminder?", isPresented: $reminderState.showReminder){
            Button("Cancel", role: .cancel){
                
            }
            Button("Add"){
                reminderManager.addReminder(for: reminderState.currEvent!){success, errorMsg in
                    DispatchQueue.main.async{
                        if success{
                            reminderState.showSaveMsg = "reminder saved"
                        }else{
                            reminderState.showSaveMsg = errorMsg!
                        }
                        reminderState.showSave = true
                    }
                }
            }
        }
        .alert(reminderState.showSaveMsg, isPresented: $reminderState.showSave) {
            Button("Ok", role: .cancel) { }
        }
    }

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func importCalendar(from url: URL) throws {
        let content = try String(contentsOf: url, encoding: .utf8)
        let sorted = ICSParser.parseAll(from: content)
            .filter {
                $0.dtstart != nil
            }
            .sorted { a, b in
                a.dtstart! < b.dtstart!
            }
        let savedData = SavedData(events: sorted, name: url.deletingPathExtension().lastPathComponent)

        do {
            try SavedData.saveEvents(savedData)
            eventList = savedData.events
            eventState.statusMsg = savedData.name
        } catch {
            eventState.statusMsg = "Save failed"
            print("Save failed:", error)
        }
    }

    private func copySampleCalendarsToDocuments() {
        for fileName in sampleCalendarFiles {
            guard let sourceURL = Bundle.main.url(forResource: fileName, withExtension: "ics") else {
                continue
            }

            let destinationURL = documentsURL.appendingPathComponent("\(fileName).ics")

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                continue
            }

            do {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            } catch {
                print("Copy sample calendar failed:", error)
            }
        }
    }
}

struct CalendarDocumentPicker: UIViewControllerRepresentable {
    let initialDirectoryURL: URL
    let onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let icsType = UTType(filenameExtension: "ics") ?? .calendarEvent
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [icsType, .calendarEvent], asCopy: false)
        picker.directoryURL = initialDirectoryURL
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                return
            }

            onPick(url)
        }
    }
}

#Preview {
    ContentView()
}
