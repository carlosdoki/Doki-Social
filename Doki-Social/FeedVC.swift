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


class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var imageAdd: CircleView!
    @IBOutlet weak var captionField: FancyField!
    
    var posts = [Post]()
    var imagePicker: UIImagePickerController!
    static var imageCache: NSCache<AnyObject, UIImage> = NSCache()
    var imageSelected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    print("DOKI: \(snap)")
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, postData: postDict)
                        self.posts.append(post)
                    }
                }
            }
            self.tableView.reloadData()
        })
        
//        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        bannerView.adUnitID = "ca-app-pub-1468309003365349/4248304115"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as? PostCell {
            if let img  = FeedVC.imageCache.object(forKey: post.imageUrl as NSString) {
                cell.configureCell(post: post, img: img)
            } else {
                cell.configureCell(post: post)
            }
            return cell
        } else {
            return PostCell()
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageAdd.image = image
            imageSelected = true
        } else {
            print("DOKI: A valid image wasn't selected")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }

    @IBAction func addImageTapped(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func postBtnTapped(_ sender: Any) {
        guard let caption = captionField.text, caption != "" else {
            print("DOKI: Caption must be entered")
            return
        }
        guard  let img = imageAdd.image, imageSelected == true else {
            print("DOKI: An image must be selected")
            return
        }
        if let imgData = UIImageJPEGRepresentation(img, 0.2) {
            let imguid = NSUUID().uuidString
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_POST_IMAGES.child(imguid).put(imgData, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("DOKI: Unabled to upload to Firebase storage")
                } else {
                    print("DOKI: Successfully uploaded image to Firebase storage")
                    let downloadUrl = metadata?.downloadURL()?.absoluteURL
                    if let url = downloadUrl {
                        self.postToFirebase(imgUrl: url.absoluteString)
                    }
                }
            }
        }
    }
    
    func postToFirebase(imgUrl: String) {
        let post : Dictionary<String, AnyObject> = [
            "caption": captionField.text as AnyObject,
            "imageUrl": imgUrl as AnyObject,
            "likes": 0 as AnyObject,
            "postedDate": FIRServerValue.timestamp() as AnyObject
        ]
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        captionField.text = ""
        imageSelected = false
        imageAdd.image = UIImage(named: "add-image")
        
        tableView.reloadData()
    }
    
    @IBAction func singoutBtnPressed(_ sender: UIButton) {
        let removeSuccessful: Bool = KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        print("DOKI: ID removed from keychain \(removeSuccessful)")
        try! FIRAuth.auth()?.signOut()
        performSegue(withIdentifier: "gotoSignUp", sender: nil)
    }
}
