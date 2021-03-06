//
//  LoginVC.swift
//  GoWhipIt
//
//  Created by Takis Tap on 07/09/16.
//  Copyright © 2016 CommunicatieToegepast. All rights reserved.
//

import UIKit
import FirebaseStorage
import FirebaseAuth
import Firebase

class LoginVC: UIViewController {
    
    let usrDefaults = UserDefaults.standard
    
    @IBOutlet weak var emailField: RoundTextField!
    @IBOutlet weak var passwordField: RoundTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Keyboard verbergen als er naast het inlog formulier gedrukt wordt
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginVC.dismissKeyboard))
        
        view.addGestureRecognizer(tap)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        guard FIRAuth.auth()?.currentUser == nil else {
            guard usrDefaults.string(forKey: "loggedInUser") == nil else {
                performSegue(withIdentifier: "loggedIn", sender: nil)
                return
            }
            return
        }
        
    }

    //Verberg keyboard functie
    func dismissKeyboard() {
        //element terug naar zijn initiele staat
        view.endEditing(true)
    }

    @IBAction func loginBtnPressed(_ sender: AnyObject) {
        let email = emailField.text
        let pass = passwordField.text
        
        if((email?.characters.count)! > 0 && (pass?.characters.count)! > 0 ) {
            
            AuthService.instance.login(email: email!, password: pass!, onComplete: { (errMsg, data) in
                guard errMsg == nil else {
                    print("Error")
                    let alert = UIAlertController(title: "Error Authentication", message: errMsg, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                // Set USERID to local storage
                self.usrDefaults.setValue(email, forKey: "loggedInUser")
                self.saveImageOverlay(completion: { (state) in
                    self.performSegue(withIdentifier: "loggedIn", sender: self)
                })
                
                //self.dismiss(animated: true, completion: nil)
                
                
            })
            
        } else {
            
            let alert = UIAlertController(title: "Email and password required", message: "You must enter both an email and a password", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            
        }
        
    }

    @IBAction func privacyBtnPressed(_ sender: Any) {
        let url = URL(string: "http://gowhipit.com/privacypolicy.pdf")!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func saveImageOverlay(completion: @escaping (Bool) -> ())
    {
        let fileManager = FileManager.default
        let filename = getDocumentsDirectory().appendingPathComponent("photoframe.png")
        if fileManager.fileExists(atPath: filename.path) {
            
            try! fileManager.removeItem(atPath: filename.path)
        }
        
        let userName = usrDefaults.string(forKey: "loggedInUser")
        
        let storageRef = FIRStorage.storage().reference()
        let photoRef = storageRef.child("Overlays").child(userName!).child("photoframe.png")
        photoRef.downloadURL { (url, error) in
            if error == nil {
                let data = NSData(contentsOf: url!)
                let image = UIImage(data: data! as Data)
                if let data = UIImagePNGRepresentation(image!) {
                    
                    let filename = self.getDocumentsDirectory().appendingPathComponent("photoframe.png")
                    try? data.write(to: filename)
                    let nc = NotificationCenter.default
                    nc.post(name: Foundation.Notification.Name(rawValue: "RefreshOverlay"), object: nil);
                    completion(true)
                }
            } else {
                print(error?.localizedDescription ?? "")
                completion(false)
            }
            
        }
    }
}
