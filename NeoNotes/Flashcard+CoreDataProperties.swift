//
//  Flashcard+CoreDataProperties.swift
//  NeoNotes
//
//  Created by Danny Ramírez on 27.11.23.
//
//

import Foundation
import CoreData


extension Flashcard {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Flashcard> {
        return NSFetchRequest<Flashcard>(entityName: "Flashcard")
    }

    @NSManaged public var answer: String?
    @NSManaged public var answerAudioFilename: String?
    @NSManaged public var audioPath: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var difficulty: Double
    @NSManaged public var due: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var imagePath: String?
    @NSManaged public var lapses: Int16
    @NSManaged public var lastReview: Date?
    @NSManaged public var question: String?
    @NSManaged public var questionAudioFilename: String?
    @NSManaged public var reps: Int16
    @NSManaged public var stability: Double
    @NSManaged public var status: Int16
    @NSManaged public var category: Category?

}

extension Flashcard : Identifiable {

}
