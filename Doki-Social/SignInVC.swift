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

class SignInVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
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
            }
        })
    }
}

