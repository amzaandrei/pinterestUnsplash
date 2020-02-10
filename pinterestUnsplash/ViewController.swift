//
//  ViewController.swift
//  pinterestUnsplash
//
//  Created by Andrew on 4/27/18.
//  Copyright © 2018 Andrew. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    
    let loginBtt: UIButton = {
        let btt = UIButton(type: .system)
        let image = UIImage(named: "logo")
        btt.setImage(image, for: .normal)
        btt.contentMode = .scaleAspectFit
        btt.translatesAutoresizingMaskIntoConstraints = false
        btt.addTarget(self, action: #selector(logInMe), for: .touchUpInside)
        return btt
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(loginBtt)
        addConstraints()
    }
    
    func addConstraints(){
        NSLayoutConstraint.activate([
                loginBtt.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                loginBtt.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                loginBtt.heightAnchor.constraint(equalToConstant: 150),
                loginBtt.widthAnchor.constraint(equalToConstant: 150),
            ])
    }

    @objc func logInMe(){
        let client_id = "86e8aae4ffa01d902628937eb1d491a2d4175419c51f7c116ad8bf148c5df831"
        let redirectUrl = "pinterestUnsplash://returnAfterLogin"
        let response_type = "code"
        let scope = "public+read_user+write_user+read_photos+write_photos+write_likes+write_followers+read_collections+write_collections"
        let stringUrl = "https://unsplash.com/oauth/authorize?client_id=" + client_id + "&redirect_uri=" + redirectUrl + "&response_type=" + response_type + "&scope=" + scope
        let url = URL(string: stringUrl)
        UIApplication.shared.open(url!)
    }

}

