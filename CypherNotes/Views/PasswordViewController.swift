//
//  PasswordViewController.swift
//  CypherNotes
//
//  Created by anon on 7/30/23.
//

import UIKit

private let toNotesSequeId = "toNotesSeque"
private let initializedKey = "initializedKey"

class PasswordViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var stackViewYConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUIInit()
        configureUI(isInitialized())
        addObservers()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let destVc = segue.destination as? NotesViewController {
            destVc.notesService = try! DefaultNotesService(
                passwordTextField.text ?? ""
            )
            passwordTextField.text = nil
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        unlockAction(textField)
        return true
    }

    // MARK: - Actions

    @IBAction func unlockAction(_ sender: Any) {
        if isInitialized() == false {
            if (passwordTextField.text ?? "").count < 4 {
                presentShortPasswordAlert()
            }
            initialize()
        }
        if (passwordTextField.text ?? "").isEmpty {
            presentWrongPasswordAlert()
            return
        }
        do {
            _ = try DefaultNotesService(passwordTextField.text ?? "")
            performSegue(withIdentifier: toNotesSequeId, sender: self)
            dismissKeyboard()
        } catch {
            presentWrongPasswordAlert()
        }
    }

    @IBAction func deleteDBAction(_ sender: Any) {
        let alertVc = UIAlertController(
            title: "🚨Extreme DANGER 🚨",
            message: "Are you sure you want to delete all notes ?! This will permanently delete all notes",
            preferredStyle: .alert
        )
        let deleteAction = UIAlertAction(
            title: "Delete all notes 🚨",
            style: .destructive
        ) { _ in
            DefaultNotesService.deleteStore()
            UserDefaults.standard.set(false, forKey: initializedKey)
            UserDefaults.standard.synchronize()
            self.configureUI(false)
        }

        alertVc.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertVc.addAction(deleteAction)
        present(alertVc, animated: true)
    }

    // MARK: - Alerts

    private func presentShortPasswordAlert() {
        let alertVc = UIAlertController(
            title: "Password needs to be at least 5 characters",
            message: "Longer it is, more secure it is",
            preferredStyle: .alert
        )
        alertVc.addAction(UIAlertAction(title: "Ok", style: .default))
        present(alertVc, animated: true)
    }

    private func presentWrongPasswordAlert() {
        let alertVc = UIAlertController(
                title: "Wrong password",
                message: nil,
                preferredStyle: .alert
        )
        alertVc.addAction(UIAlertAction(title: "Retry", style: .cancel))
        present(alertVc, animated: true)
    }

    // MARK: - Private

    private func isInitialized() -> Bool {
        UserDefaults.standard.bool(forKey: initializedKey)
    }

    private func initialize() {
        UserDefaults.standard.set(true, forKey: initializedKey)
        UserDefaults.standard.synchronize()
        configureUI(true)
    }

    private func configureUI(_ initialized: Bool) {
        if initialized {
            actionButton.setTitle("Unlock", for: .normal)
            title = "Unlock"
        } else {
            actionButton.setTitle("Create", for: .normal)
            title = "Create secure store"
        }
    }

    private func configureUIInit() {
        actionButton.layer.borderWidth = 1
        actionButton.layer.borderColor = actionButton.tintColor.cgColor
        actionButton.layer.cornerRadius = 8

        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .plain,
            target: self,
            action: #selector(dismissKeyboard)
        )

        let toolBar = UIToolbar(frame: CGRect.zero)
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        toolBar.items = [flexibleSpace(), doneButton]
        passwordTextField.inputAccessoryView = toolBar
    }

    // MARK: - Keyboard handling

    private func flexibleSpace() -> UIBarButtonItem {
        UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
    }

    @objc func dismissKeyboard() {
        passwordTextField.resignFirstResponder()
    }

    private func addObservers() {
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
            stackViewYConstraint.constant = 0
        } else {
            stackViewYConstraint.constant = -44
        }

        UIView.animate(withDuration: 0.1, animations: {
            self.view.layoutIfNeeded()
        })
    }
}
