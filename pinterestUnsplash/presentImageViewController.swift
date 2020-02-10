
//
//  presentImage.swift
//  pinterestUnsplash
//
//  Created by Andrew on 4/29/18.
//  Copyright © 2018 Andrew. All rights reserved.
//

import UIKit
import Hero
class presentImageViewController: UIViewController {
    
    
    var img: UIImage! = nil {
        didSet{
            self.image.image = img
        }
    }
    
    var imgId: String! = nil {
        didSet{
            self.image.hero.id = imgId
        }
    }
    
    let image: UIImageView = {
        let image = UIImage(named: "")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hero.isEnabled = true
        view.addSubview(image)
        addConstraints()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(dismissView))
        view.addGestureRecognizer(panGesture)
        
    }
    
    func addConstraints(){
        NSLayoutConstraint.activate([
                image.leftAnchor.constraint(equalTo: view.leftAnchor),
                image.rightAnchor.constraint(equalTo: view.rightAnchor),
                image.topAnchor.constraint(equalTo: view.topAnchor),
                image.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
    }
    
    @objc func dismissView(sender: UIPanGestureRecognizer){
        let transation = sender.translation(in: nil)
        let progress = transation.y / 2 / view.frame.height
        switch sender.state {
        case .began:
            hero.dismissViewController()
        case .changed:
            Hero.shared.update(progress)
            
            let currentPos = CGPoint(x: transation.x + image.center.x, y: transation.y + image.center.y)
            Hero.shared.apply(modifiers: [.position(currentPos)], to: image)
            
        default:
            if progress + sender.velocity(in: nil).y / view.bounds.height > 0.2{
                Hero.shared.finish()
            }else{
                Hero.shared.cancel()
            }
        }
    }
    
}
