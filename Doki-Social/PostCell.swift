//
//  PostCell.swift
//  Doki-Social
//
//  Created by Carlos Doki on 3/22/17.
//  Copyright © 2017 Carlos Doki. All rights reserved.
//

import UIKit
import Firebase

class PostCell: UITableViewCell {
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var postImg: UIImageView!
    @IBOutlet weak var caption: UITextView!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var likesImg: CircleView!
    @IBOutlet weak var dateLbl: UILabel!
    
    var post: Post!
    var likesref : FIRDatabaseReference!
    var userref: FIRDatabaseReference!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(likeTapped))
        tap.numberOfTapsRequired = 1
        likesImg.addGestureRecognizer(tap)
        likesImg.isUserInteractionEnabled = true
    }
    func configureCell(post: Post, img: UIImage? = nil) {
        userref = DataService.ds.REF_USER_CURRENT
        userref.observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            if let username = value?["username"] as? String {
                self.usernameLbl.text = username
            }
            if let img = value?["photoUrl"] as? String {
                if let data = NSData(contentsOf: NSURL(string: img) as! URL) {
                    self.profileImg.image  = UIImage(data: data as Data)
                }
            }
        })
        
        self.post = post
        likesref = DataService.ds.REF_USER_CURRENT.child("likes").child(post.postKey)
        self.caption.text = post.caption
        self.likesLbl.text = "\(post.likes)"
        
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        let data = NSDate(timeIntervalSince1970: post.postedDate/1000)
        self.dateLbl.text = dayTimePeriodFormatter.string(from: data as Date)
        
        if img != nil {
            self.postImg.image = img
        } else {
            let ref = FIRStorage.storage().reference(forURL: post.imageUrl)
            ref.data(withMaxSize: 2 * 1024 * 1024, completion: { (data, error) in
                if error != nil {
                    print("DOKI: Unable to download image from Firebase storage")
                } else {
                    print("DOKI: Image download from Firebase storage")
                    if let imgData = data {
                        if let img = UIImage(data: imgData) {
                            self.postImg.image = img
                            FeedVC.imageCache.setObject(img, forKey: post.imageUrl as AnyObject)
                        }
                    }
                }
            })
        }
    
        likesref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                self.likesImg.image = UIImage(named: "empty-heart")
            } else {
                self.likesImg.image = UIImage(named: "filled-heart")
            }
        })
    }
    
    func likeTapped(sender: UITapGestureRecognizer) {
        likesref.observeSingleEvent(of: .value, with: { (snapshot) in
            if let _ = snapshot.value as? NSNull {
                self.likesImg.image = UIImage(named: "filled-heart")
                self.post.adjustLikes(addLike: true)
                self.likesref.setValue(true)
            } else {
                self.likesImg.image = UIImage(named: "empty-heart")
                self.post.adjustLikes(addLike: false)
                self.likesref.removeValue()
            }
        })
    }
}
