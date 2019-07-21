//
//  ScheduleViewController.swift
//  CampClub
//
//  Created by Luochun on 2019/5/3.
//  Copyright © 2019 Mantis group. All rights reserved.
//

import UIKit

class ScheduleViewController: MTBaseViewController {

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var upButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imgView.addTapGesture { (_) in
            MutilImageViewer.init([""], imageViews: [self.imgView]).show(at: 0)
        }
        
        if User.shared.role != .manager {
            upButton.isHidden = true
        }
        
        imgView.kf.setImage(with: URL(string: BaseUrl + "downloadImage?imageName=DateImg.jpg"))
    }

    @IBAction func upload(_ sender: UIButton) {
        self.selectPhoto { (img) in
            MTHUD.showLoading()
            HttpApi.uploadImage(img.jpegData(compressionQuality: 1)!, completion: { (res) in
                MTHUD.hide()
                if let result = res["result"] as? String, result == "SUCCESS" {
                    showMessage("上传成功")
                    self.imgView.kf.setImage(with: URL(string: BaseUrl + "downloadImage?imageName=DateImg.jpg"))
                } else {
                    showMessage(res["error"] as! String)
                }
            })
        }
    }
    
}
