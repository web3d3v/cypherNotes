//
//  NoteController.swift
//  CypherNotes
//
//  Created by anon on 7/30/23.
//

import UIKit

class NoteViewController: UIViewController,  UITextViewDelegate {
 
    @IBOutlet weak var textView: UITextView!
    
    var notesService: NotesService!
    var note: Note!
    var idx: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = note?.title ?? ""
        decryptAndSetText()
        configureUI()
        addObservers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if textView.text.isEmpty {
            textView.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        encryptAndStoreNote()
    }
    
    // MARK: - Actions

    @IBAction func shareAction(_ sender: Any) {
        let activityVc = UIActivityViewController(
            activityItems: [textView.text ?? ""],
            applicationActivities: nil
        )
        present(activityVc, animated: true)
    }
    
    @objc func doneAction(_ sender: Any) {
        textView.resignFirstResponder()
        encryptAndStoreNote()
    }
    
    // MARK: - Encrypt / Decrypt
    
    func decryptAndSetText() {
        textView.text = notesService.decrypt(note)
    }
    
    func encryptAndStoreNote() {
        notesService.encrypt(note, text: textView.text)
        notesService.storeNote(note, at: idx)
    }

    // MARK: - Private
    
    func configureUI() {
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .plain,
            target: self,
            action: #selector(doneAction(_:))
        )
        
        let toolBar = UIToolbar(frame: CGRect.zero)
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.items = [flexibleSpace(), doneButton]
        textView.inputAccessoryView = toolBar
    }

    private func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willResignActive(_:)),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc private func adjustForKeyboard(notification: Notification) {
        let key = UIResponder.keyboardFrameEndUserInfoKey

        guard let keyboardValue = notification.userInfo?[key] as? NSValue else {
            return
        }

        let keyboardWindowFrame = keyboardValue.cgRectValue
        let keyboardViewFrame = view.convert(
            keyboardWindowFrame,
            from: view.window
        )

        if notification.name == UIResponder.keyboardWillHideNotification {
            textView.contentInset = .zero
        } else {
            textView.contentInset = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: keyboardViewFrame.height - view.safeAreaInsets.bottom,
                right: 0
            )
        }

        textView.scrollIndicatorInsets = textView.contentInset
        textView.scrollRangeToVisible(textView.selectedRange)
    }

    @objc private func willResignActive(_ notification: NSNotification) {
        encryptAndStoreNote()
    }

    private func flexibleSpace() -> UIBarButtonItem {
        UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
    }
}
