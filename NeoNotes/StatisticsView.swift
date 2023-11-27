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

