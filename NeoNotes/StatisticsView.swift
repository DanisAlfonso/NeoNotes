//
//  StatisticsView.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 27.11.23.
//

import SwiftUI
import CoreData
import Charts

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StudySession.startTime, ascending: true)],
        animation: .default)
    private var studySessions: FetchedResults<StudySession>

    var body: some View {
        VStack {
            Text("Study Session Durations")
                .font(.title)
                .padding()

            Chart {
                ForEach(studySessions, id: \.self) { session in
                    if let startTime = session.startTime {
                        BarMark(
                            x: .value("Date", formattedDate(startTime)),
                            y: .value("Duration", session.duration / 60) // Assuming duration is in seconds, converting to minutes
                        )
                        .foregroundStyle(by: .value("Date", formattedDate(startTime)))
                        .annotation(position: .top, alignment: .center) {
                            Text("\(Int(session.duration / 60)) min")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: Calendar.Component.day)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
        }
        .padding()
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}


struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .environment(\.managedObjectContext, mockManagedObjectContext())
    }

    static func mockManagedObjectContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "NeoNotesModel")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType // Set the store type to in-memory
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        let context = container.viewContext

        // Create a few dummy StudySession entities
        for _ in 0..<5 {
            let newSession = StudySession(context: context)
            newSession.id = UUID()
            newSession.startTime = Date()
            newSession.endTime = Date().addingTimeInterval(3600) // 1 hour later
            newSession.duration = 3600 // 1 hour in seconds
        }

        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            fatalError("Failed to save in-memory context: \(error)")
        }

        return context
    }

}
