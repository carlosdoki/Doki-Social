//
//  SignInVC
//  Doki-Social
//
//  Created by Carlos Doki on 19/03/17.
//  Copyright © 2017 Carlos Doki. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import SwiftKeychainWrapper
import GoogleMobileAds

class SignInVC: UIViewController {

    @IBOutlet weak var emailField: FancyField!
    @IBOutlet weak var passwordField: FancyField!
    @IBOutlet weak var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        bannerView.adUnitID = "ca-app-pub-1468309003365349/4248304115"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let _ = KeychainWrapper.standard.string(forKey: KEY_UID) {
            print("DOKI: ID found in keychain")
            performSegue(withIdentifier: "gotoFeed", sender: nil)
        }
    }
    
    @IBAction func facebookBtnTapped(_ sender: AnyObject) {
        let facebookLogin = FBSDKLoginManager()
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                print("DOKI: Unable to authenticate with Facebook - \(error)")
            } else if result?.isCancelled == true {
                print("DOKI: User cancelled Facebook authentication")
            } else {
                print("DOKI: Sucessfully authentication with Facebook")
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.firebaseAuth(credential)
            }
        }
    }
    
    func firebaseAuth(_ credential: FIRAuthCredential) {
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error != nil {
                print("DOKI: unable to authentication with Firebase - \(error)")
            } else {
                print("DOKI: Sucessfully authentication with Firebase")
                if let user = user {
                    let userData = [
                        "provider": credential.provider,
                        "username": user.displayName,
                        "photoUrl": user.photoURL?.absoluteString
                    ]
                    self.completeSignIn(id: user.uid, userData: userData as! Dictionary<String, String>)
                }
            }
        })
    }
    
    @IBAction func signinBtnTapped(_ sender: FancyBtn) {
        if let email = emailField.text, let pwd = passwordField.text {
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("DOKI: User authenticated with Firebase")
                    if let user = user {
                        let userData = ["provider": user.providerID]
                        self.completeSignIn(id: user.uid, userData: userData)
                    }
                } else {
                    FIRAuth.auth()?.createUser(withEmail: email, password: pwd, completion: {(user, error) in
                        if error != nil {
                            print("DOKI: Unable to authenticated using email - \(error)")
                        } else {
                            print("DOKI: Sucessfully authenticated with Firebase")
                            if let user = user {
                                let userData = ["provider": user.providerID]
                                self.completeSignIn(id: user.uid, userData: userData)
                            }
                        }
                    })
                }
            })
        }
    }
    
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        DataService.ds.createFirebaseDBUser(uid: id, userData: userData)
        let keychainResult = KeychainWrapper.standard.set(id, forKey: KEY_UID)
        print("DOKI: Data saved to keychain \(keychainResult)")
        performSegue(withIdentifier: "gotoFeed", sender: nil)
    }
}

