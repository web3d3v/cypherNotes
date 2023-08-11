//
//  NotesServices.swift
//  CypherNotes
//
//  Created by anon on 7/30/23.
//

import Foundation
import CoreData
import UIKit
import RNCryptor

protocol NotesService {

    /// Creates new note
    func newNote() -> Note
    
    /// Deletes note at index
    func deleteNote(at idx: Int)

    /// @return notes at index
    func note(at idx: Int) -> Note

    /// Upates note at index
    func storeNote(_ note: Note, at idx: Int)

    /// Count of stored notes
    func count() -> Int

    /// @return Decrypted `Note` body
    func decrypt(_ note: Note) -> String

    /// Encrypts `text`, sets as `Note`s
    func encrypt(_ note: Note, text: String)

    /// Remove database if present
    static func deleteStore()
}


class DefaultNotesService: NotesService {
    private var password: String
    private var notes: [Note] = []

    init(_ password: String) throws {
        self.password = password
        try validatePass(password)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willResignActive(_:)),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        updateCache()
    }

    func newNote() -> Note {
        let note = Note(entity: Note.entity(), insertInto: viewContext())
        note.modified = Date()
        updateCache()
        return note
    }

    func deleteNote(at idx: Int) {
        persistentContainer.viewContext.delete(note(at: idx))
        updateCache()
    }

    func note(at idx: Int) -> Note {
        notes[idx]
    }

    func storeNote(_ note: Note, at idx: Int) {
        note.modified = Date()
        saveContext()
        updateCache()
    }

    func count() -> Int {
        notes.count
    }

    // MARK: - Encryption

    func decrypt(_ note: Note) -> String {
        guard let cypherText = note.body else { return "" }
        guard let data = try? RNCryptor.decrypt(
            data: cypherText,
            withPassword: password
        ) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    func encrypt(_ note: Note, text: String) {
        guard let data = text.data(using: .utf8) else {
            return
        }
        let ciphertext = RNCryptor.encrypt(data: data, withPassword: password)
        note.body = ciphertext
    }

    private func validatePass(_ password: String) throws {
        guard let cypherText = UserDefaults.standard.data(forKey: passTestKey) else {
            var bytes = [Int8](repeating: 0, count: 32)
            _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            withUnsafeBytes(of: bytes) {
                let ct = RNCryptor.encrypt(data: Data($0), withPassword: password)
                UserDefaults.standard.set(ct, forKey: passTestKey)
                UserDefaults.standard.synchronize()
            }
            return
        }
        _ = try RNCryptor.decrypt(data: cypherText, withPassword: password)
    }


    // MARK: - Context saving

    private func updateCache() {
        notes = try! persistentContainer.viewContext.fetch(Note.fetchRequest())
    }

    @objc private func willResignActive(_ notification: NSNotification) {
        saveContext()
    }
    
    // MARK: - Core Data stack

    static func deleteStore() {
        let container = NSPersistentContainer(name: containerName)
        try? container
            .persistentStoreCoordinator
            .destroyPersistentStore(
                at: container.persistentStoreDescriptions.first!.url!,
                type: .sqlite,
                options: nil
            )
        UserDefaults.standard.set(nil, forKey: passTestKey)
        UserDefaults.standard.synchronize()
    }

    private lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: containerName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    private func viewContext() -> NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

private let containerName = "CypherNotes"
private let passTestKey = "initialized2Key"
