//
//  FeedVC.swift
//  Doki-Social
//
//  Created by Carlos Doki on 21/03/17.
//  Copyright © 2017 Carlos Doki. All rights reserved.
//

import UIKit
import Firebase
import SwiftKeychainWrapper
import GoogleMobileAds


class FeedVC: UIViewController {

    @IBOutlet weak var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        bannerView.adUnitID = "ca-app-pub-1468309003365349/4248304115"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
    }

    @IBAction func singoutBtnPressed(_ sender: UIButton) {
        let removeSuccessful: Bool = KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        print("DOKI: ID removed from keychain \(removeSuccessful)")
        try! FIRAuth.auth()?.signOut()
        performSegue(withIdentifier: "gotoSignUp", sender: nil)
    }
}
