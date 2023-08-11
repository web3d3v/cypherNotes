//
//  Note+CoreDataProperties.swift
//  CypherNotes
//
//  Created by anon on 06/08/2023.
//
//

import Foundation
import CoreData


extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var title: String?
    @NSManaged public var body: Data?
    @NSManaged public var modified: Date?

}

extension Note : Identifiable {

}
