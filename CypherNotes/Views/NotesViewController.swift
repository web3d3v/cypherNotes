//
//  NotesViewController.swift
//  CypherNotes
//
//  Created by anon on 7/30/23.
//

private let toNoteSegueId = "toNoteSegue"
private let noteCellId = "NoteCellId"

import UIKit

class NotesViewController: UITableViewController {

    var notesService: NotesService!

    @IBAction func newNoteAction(_ sender: Any) {
        let alertVc = UIAlertController(
                title: "Note name",
                message: nil, 
                preferredStyle: .alert
        )
        let action = UIAlertAction(title: "Create", style: .default) { action in
            self.createNewNote(alertVc.textFields?[0].text)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        alertVc.addTextField()
        alertVc.addAction(cancelAction)
        alertVc.addAction(action)
        present(alertVc, animated: true)
    }

    private func createNewNote(_ title: String? = nil) {
        let cnt = notesService.count()
        var note = notesService.newNote()
        note.title = title ?? "\(Date())"
        notesService.storeNote(note, at: cnt)
        tableView.reloadData()
        performSegue(withIdentifier: toNoteSegueId, sender: note)
    }


    // MARK: UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notesService.count()
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: noteCellId, for: indexPath)
        let note = notesService.note(at: indexPath.row)
        cell.textLabel?.text = note.title
        return cell
    }
    
    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            notesService.deleteNote(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let note = notesService.note(at: indexPath.row)
        performSegue(withIdentifier: toNoteSegueId, sender: note)
    }
    
    // MARK: UIViewController methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destVc = segue.destination as? NoteViewController, let note = sender as? Note {
            destVc.note = note
            destVc.idx = tableView.indexPathForSelectedRow?.row ?? 0
            destVc.notesService = notesService
        }
    }
    

}
