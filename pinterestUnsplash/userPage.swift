//
//  userPage.swift
//  pinterestUnsplash
//
//  Created by Andrew on 5/12/18.
//  Copyright © 2018 Andrew. All rights reserved.
//

import UIKit
import Alamofire
import CoreData
import Hero

class userPage: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UICollectionViewDataSource {
    
    let cellId = "cellId"
    let userDefaults = UserDefaults()
    typealias JSONStandard = [String: AnyObject]
    var allDataPhotos = [UserPhotos]()
    var myLikesID = [Int]()
    var managedObjectContext: NSManagedObjectContext! = nil
    var allPhotos = [UIImage](){
        didSet{
            DispatchQueue.main.async {
                self.myColl.reloadData()
            }
        }
    }
    var idName: String! = nil{
        didSet{
            self.parseUserPhotos(id: idName)
        }
    }
    
    lazy var myColl: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let myColll = UICollectionView(frame: .zero, collectionViewLayout: layout)
        myColll.delegate = self
        myColll.alwaysBounceVertical = false
        myColll.dataSource = self
        myColll.register(customCell.self, forCellWithReuseIdentifier: cellId)
        myColll.translatesAutoresizingMaskIntoConstraints = false
        myColll.backgroundColor = .white
        return myColll
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(myColl)
        self.edgesForExtendedLayout = []
        addConstraints()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissMe))
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//        let handlePanGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesureToDismissView))
//        myColl.addGestureRecognizer(handlePanGesture)
    }
    
    @objc func panGesureToDismissView(sender: UIPanGestureRecognizer){
        let transation = sender.translation(in: nil)
        let progress = transation.y / 2 / view.frame.height
        switch sender.state {
        case .began:
            hero.dismissViewController()
        default:
            if progress + sender.velocity(in: nil).y / view.bounds.height > 0.2{
                Hero.shared.finish()
            }else{
                Hero.shared.cancel()
            }
        }
    }
    
    func addConstraints(){
        NSLayoutConstraint.activate([
            myColl.rightAnchor.constraint(equalTo: view.rightAnchor),
            myColl.leftAnchor.constraint(equalTo: view.leftAnchor),
            myColl.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            myColl.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }
    
    @objc func dismissMe(){
        hero.dismissViewController()
    }
    
    func fetchMyPhotoLiked(){
        let fetch: NSFetchRequest<UserPhotoLikes> = UserPhotoLikes.fetchRequest()
        do{
            let myLikes = try managedObjectContext.fetch(fetch)
            for like in myLikes{
                for (index,dataPhoto) in allDataPhotos.enumerated(){
                    if like.id! == dataPhoto.id{
                        self.myLikesID.append(index)
                    }
                }
            }
            debugPrint(myLikesID)
        }catch let err{
            print(err.localizedDescription)
            return
        }
    }
    
    func parseUserPhotos(id: String){
        let url = "https://api.unsplash.com/users/" + id + "/photos"
        guard let accesToken = userDefaults.string(forKey: "access_token") else { return }
        let header: HTTPHeaders = [
            "Authorization": "Bearer " + accesToken,
            "page": "1",
//            "per_page"
        ]
        Alamofire.request(url, method: .get, headers: header).responseJSON { (response) in
            guard let data = response.data else { return }
            self.parseData(data: data)
        }
    }
    
    func parseData(data: Data){
        var photoDim: PhotosDimensions! = nil
        do{
            guard let userPhotos = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [JSONStandard] else { return }
            for photo in userPhotos{
                if let imageUrls = photo["urls"] as? JSONStandard{
                    photoDim = PhotosDimensions(dict: imageUrls)
                }
                let photoDict = UserPhotos(dict: photo, dictImagesUrl: photoDim)
                self.allDataPhotos.append(photoDict)
            }
            fetchMyPhotoLiked()
            for userPhoto in allDataPhotos{
                let returnData = self.downloadImage(url: userPhoto.imagesUrls.small!)
                let image = UIImage(data: returnData)
                self.allPhotos.append(image!)
            }
        }catch let err{
            print(err.localizedDescription)
            return
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allPhotos.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! customCell
        let dataForCell = allPhotos[indexPath.row]
        let dataLikes = allDataPhotos[indexPath.row].likes
//        for liked in myLikesID{
//            if indexPath.row == liked{
//                cell.likeBtt.backgroundColor = .red
//            }
//        }
        cell.image.image = dataForCell
        cell.backgroundColor = .red
        cell.likesLabel.text = String(dataLikes!)
        cell.likeBtt.tag = indexPath.row
        cell.likeBtt.addTarget(self, action: #selector(likeBttTapped), for: .touchUpInside)
        cell.downloadImageBTT.tag = indexPath.row
        cell.downloadImageBTT.addTarget(self, action: #selector(downloadimage), for: .touchUpInside)
        return cell
    }
    

    

    @objc func downloadimage(sender: UIButton){
        let image = allPhotos[sender.tag]
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        print("Done")
    }
    
    @objc func likeBttTapped(sender: UIButton){
        guard let photoId = allDataPhotos[sender.tag].id else { return }
//        self.likeOrUnlike()
        let url = "https://api.unsplash.com/photos/" + String(photoId) + "/like"
        guard let accesToken = userDefaults.string(forKey: "access_token") else { return }
        let header: HTTPHeaders = [
            "Authorization": "Bearer " + accesToken
        ]
        var method: HTTPMethod! = nil
        for myLike in myLikesID{
            if sender.tag == myLike{
                method = .delete
            }else{
                method = .post
            }
        }
        Alamofire.request(url, method: method, headers: header).responseJSON { (response) in
            guard let data = response.data else { return }
            do{
                if let dataJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? JSONStandard{
                    debugPrint(dataJSON)
                    if let photoDict = dataJSON["photo"] as? JSONStandard{
                        if let likedByMe = photoDict["liked_by_user"] as? Bool{
                            if likedByMe{
                                if method == .delete{
                                    debugPrint("Deleted")
                                }else{
                                    debugPrint("Liked")
                                }
                                self.myLikesID.append(sender.tag)
                            }else{
                                debugPrint("Don't liked :/")
                                self.myLikesID.remove(at: sender.tag)
                            }
                        }
                    }
                }
            }catch let err{
                print(err.localizedDescription)
                return
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.height)
    }
    
    
    
    func downloadImage(url: String) -> Data {
        let url = URL(string: url)
        let dispatchGroup = DispatchGroup()
        var finalData: Data! = nil
        dispatchGroup.enter()
        let task = URLSession.shared.dataTask(with: url!) { (data, res, err) in
            if err != nil{
                print(err?.localizedDescription)
                return
            }
            guard let data = data else { return }
            finalData = data
            dispatchGroup.leave()
        }
        task.resume()
        dispatchGroup.wait()
        return finalData
    }
    
    
}


class customCell: UICollectionViewCell {
    
    let image: UIImageView = {
        let image = UIImage()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false;
        return imageView
    }()
    
    
    let heartImage: UIImageView = {
        let image = UIImage(named: "emptyHeart")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false;
        return imageView
    }()
    
    let downloadImageBTT: UIButton = {
        let btt = UIButton(type: .system)
        btt.setImage(UIImage(named: "download"), for: .normal)
        btt.translatesAutoresizingMaskIntoConstraints = false
        return btt
    }()
    
    let likeBtt: UIButton = {
        let btt = UIButton(type: .system)
        btt.translatesAutoresizingMaskIntoConstraints = false
        btt.backgroundColor = UIColor.darkGray
        return btt
    }()
    
    let likesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(image)
        addSubview(likeBtt)
        likeBtt.addSubview(heartImage)
        likeBtt.addSubview(likesLabel)
        addSubview(downloadImageBTT)
        addConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addConstraints(){
        NSLayoutConstraint.activate([
            image.leftAnchor.constraint(equalTo: self.leftAnchor),
            image.rightAnchor.constraint(equalTo: self.rightAnchor),
            image.topAnchor.constraint(equalTo: self.topAnchor),
            image.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            likeBtt.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 20),
            likeBtt.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -30),
            likeBtt.heightAnchor.constraint(equalToConstant: 45),
            likeBtt.widthAnchor.constraint(equalToConstant: 70),
            heartImage.leftAnchor.constraint(equalTo: likeBtt.leftAnchor, constant: 5),
            heartImage.centerYAnchor.constraint(equalTo: likeBtt.centerYAnchor),
            heartImage.heightAnchor.constraint(equalToConstant: 30),
            heartImage.widthAnchor.constraint(equalToConstant: 30),
            likesLabel.leftAnchor.constraint(equalTo: heartImage.rightAnchor, constant: 5),
            likesLabel.centerYAnchor.constraint(equalTo: likeBtt.centerYAnchor),
            downloadImageBTT.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -20),
            downloadImageBTT.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -30),
            downloadImageBTT.heightAnchor.constraint(equalToConstant: 40),
            downloadImageBTT.widthAnchor.constraint(equalToConstant: 40),
            ])
    }
    
    
}








