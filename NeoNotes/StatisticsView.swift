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

    @Environment(\.calendar) var calendar
    @Environment(\.locale) var locale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                studySessionDurationChart
                numberOfCardsReviewedChart
                performanceMetricsChart
            }
            .padding(.leading)
        }
    }

    private var studySessionDurationChart: some View {
        VStack {
            chartTitle("Study Session Durations")
            Chart {
                ForEach(studySessions, id: \.self) { session in
                    if let startTime = session.startTime {
                        BarMark(
                            x: .value("Date", formattedDate(startTime)),
                            y: .value("Duration", session.duration / 60) // Convert to minutes
                        )
                        .foregroundStyle(.blue)
                        .annotation(position: .top, alignment: .center) {
                            Text("\(Int(session.duration / 60)) min")
                        }
                    }
                }
            }
            .frame(height: 200)
        }
    }

    private var numberOfCardsReviewedChart: some View {
        VStack {
            chartTitle("Number of Cards Reviewed")
            Chart {
                ForEach(studySessions, id: \.self) { session in
                    if let startTime = session.startTime {
                        BarMark(
                            x: .value("Date", formattedDate(startTime)),
                            y: .value("Cards Reviewed", session.cardsReviewed)
                        )
                        .foregroundStyle(.green)
                    }
                }
            }
            .frame(height: 200)
        }
    }
    
    private func countForRating(rating: Rating, in session: StudySession) -> Int {
        switch rating {
        case .Again:
            return Int(session.countAgain)
        case .Hard:
            return Int(session.countHard)
        case .Good:
            return Int(session.countGood)
        case .Easy:
            return Int(session.countEasy)
        }
    }
    
    private var performanceMetricsChart: some View {
        VStack {
            chartTitle("Performance Metrics")
            Chart {
                ForEach(studySessions, id: \.self) { session in
                    if let startTime = session.startTime {
                        ForEach(Rating.allCases, id: \.self) { rating in
                            BarMark(
                                x: .value("Rating", rating.description),
                                y: .value("Count", countForRating(rating: rating, in: session))
                            )
                            .foregroundStyle(by: .value("Rating", rating.description))
                        }
                    }
                }
            }
            .frame(height: 200)
        }
    }


    private func chartTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .padding([.top, .horizontal])
    }

    private func formattedDate(_ date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
    }
}

extension Rating: CaseIterable {
    public static var allCases: [Rating] {
        return [.Again, .Hard, .Good, .Easy]
    }
}
