//
//  userProfilePage.swift
//  pinterestUnsplash
//
//  Created by Andrew on 4/27/18.
//  Copyright © 2018 Andrew. All rights reserved.
//

import UIKit
import Alamofire
import Hero
import CoreData

class userProfilePage: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,CellDelegate {
    
    
    let cellId = "cellId"
    let cellId2 = "cellId2"
    typealias JSONStandard = [String: AnyObject]
    let tabValArr = ["Photos","Likes","Collections"]
    let userDefaults = UserDefaults()
    var allDataLikes = [UserPhotoLikes]()
    var allDataForFollowings = [UserFollowers](){
        didSet{
            DispatchQueue.main.async {
                self.myColl2.reloadData()
            }
        }
    }
    var managedObjectContext: NSManagedObjectContext! = nil
    var myPhotosArr = [UIImage]()
    var profileImg: UIImage! = nil {
        didSet{
            self.profileImage.image = profileImg
        }
    }
    
    var profileImgID: String! = nil{
        didSet{
            self.profileImage.hero.id = profileImgID
        }
    }
    
    
    lazy var myColl: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let myColll = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        myColll.delegate = self
        myColll.alwaysBounceVertical = false
        myColll.contentInset = UIEdgeInsets(top: 0, left: self.view.frame.width / 2 - 30, bottom: 0, right: 0)
        myColll.showsHorizontalScrollIndicator = false
        myColll.dataSource = self
        myColll.register(cellCustomTabs.self, forCellWithReuseIdentifier: cellId)
        myColll.translatesAutoresizingMaskIntoConstraints = false
        myColll.backgroundColor = .white
        return myColll
    }()
    
    lazy var myColl2: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let myColll = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        myColll.alwaysBounceVertical = false
        myColll.delegate = self
        myColll.showsHorizontalScrollIndicator = false
        myColll.dataSource = self
        myColll.register(cellCustomUserProfilePage.self, forCellWithReuseIdentifier: cellId2)
        myColll.translatesAutoresizingMaskIntoConstraints = false
        myColll.backgroundColor = .white
        return myColll
    }()
    
    let profileImage: UIImageView = {
        let image = UIImage(named: "")
        let imageVIew = UIImageView(image: image)
        imageVIew.contentMode = .scaleAspectFill
        imageVIew.isUserInteractionEnabled = true
        imageVIew.translatesAutoresizingMaskIntoConstraints = false
        imageVIew.layer.cornerRadius = 20
        imageVIew.layer.masksToBounds = true
        return imageVIew
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hero.isEnabled = true
        self.edgesForExtendedLayout = []
        view.backgroundColor = .white
        view.addSubview(profileImage)
        view.addSubview(myColl)
        view.addSubview(myColl2)
        addConstraints()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log out", style: .done, target: self, action: #selector(logOut))
        let handlePanGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesureToDismissView))
        view.addGestureRecognizer(handlePanGesture)
        
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        retrieveCoreData()
    }
    
    @objc func logOut(){
        /// TODO: uncompleted delete Core Data
        let photosFetch: NSFetchRequest<UserPhotosEntity> = UserPhotosEntity.fetchRequest()
        let userFetch: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        let userFollowers: NSFetchRequest<UserFollowers> = UserFollowers.fetchRequest()
        let userProfileImageDataFetch: NSFetchRequest<UserProfileImageEntity> = UserProfileImageEntity.fetchRequest()
        let deleteRequestPhotos = NSBatchDeleteRequest(fetchRequest: photosFetch as! NSFetchRequest<NSFetchRequestResult>)
        let deleteRequestUser = NSBatchDeleteRequest(fetchRequest: userFetch as! NSFetchRequest<NSFetchRequestResult>)
        let deleteRequestFollowers = NSBatchDeleteRequest(fetchRequest: userFollowers as! NSFetchRequest<NSFetchRequestResult>)
        let deleteRequestImages = NSBatchDeleteRequest(fetchRequest: userProfileImageDataFetch as! NSFetchRequest<NSFetchRequestResult>)
        do{
            try managedObjectContext.execute(deleteRequestPhotos)
            try managedObjectContext.execute(deleteRequestUser)
            try managedObjectContext.execute(deleteRequestFollowers)
            try managedObjectContext.execute(deleteRequestImages)
            try managedObjectContext.save()
            userDefaults.set(false, forKey: "isLogged")
            userDefaults.synchronize()
            self.present(ViewController(), animated: true, completion: nil)
        }catch let err{
            print(err.localizedDescription)
            return
        }
    }
    
    func retrieveCoreData(){
        let photosFetch: NSFetchRequest<UserPhotosEntity> = UserPhotosEntity.fetchRequest()
        let userFetch: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        let userFollowers: NSFetchRequest<UserFollowers> = UserFollowers.fetchRequest()
        do{
            let myPhotosObject = try managedObjectContext.fetch(photosFetch)
            let userObjects = try managedObjectContext.fetch(userFetch)
            allDataForFollowings = try managedObjectContext.fetch(userFollowers)
            for myPhotoObject in myPhotosObject{
                myPhotosArr = myPhotoObject.images as! [UIImage]
            }
            for userObj in userObjects{
                let objs = userObj.userPhotoLikes?.allObjects as! [UserPhotoLikes]
                for obj in objs{
                    self.allDataLikes.append(obj)
                }
            }
        }catch let err{
            print(err.localizedDescription)
            return
        }
    }
    
    @objc func panGesureToDismissView(sender: UIPanGestureRecognizer){
        let transation = sender.translation(in: nil)
        let progress = transation.y / 2 / view.frame.height
        switch sender.state {
        case .began:
            hero.dismissViewController()
        case .changed:
            Hero.shared.update(progress)
            
            let currentPos = CGPoint(x: transation.x + profileImage.center.x, y: transation.y + profileImage.center.y)
            Hero.shared.apply(modifiers: [.position(currentPos)], to: profileImage)
            
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
            profileImage.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            profileImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImage.heightAnchor.constraint(equalToConstant: 40),
            profileImage.widthAnchor.constraint(equalToConstant: 40),
            myColl.rightAnchor.constraint(equalTo: view.rightAnchor),
            myColl.leftAnchor.constraint(equalTo: view.leftAnchor),
            myColl.heightAnchor.constraint(equalToConstant: 31),
            myColl.topAnchor.constraint(equalTo: profileImage.bottomAnchor,constant: 30),
            myColl2.rightAnchor.constraint(equalTo: view.rightAnchor),
            myColl2.leftAnchor.constraint(equalTo: view.leftAnchor),
            myColl2.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            myColl2.topAnchor.constraint(equalTo: myColl.bottomAnchor,constant: 40)
            ])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count: Int! = nil
        if collectionView == self.myColl{
            count = tabValArr.count
        }else{
            count = 3
        }
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell! = nil
        if collectionView == self.myColl{
            let mycell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! cellCustomTabs
            let values = tabValArr[indexPath.row]
            mycell.labels.text = values
            cell = mycell
        }
        if collectionView == self.myColl2{
            let mycell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId2, for: indexPath) as! cellCustomUserProfilePage
            mycell.delegate = self
            if indexPath.row == 0{
                mycell.currentIndex = indexPath.row
                mycell.myPhotosArr = myPhotosArr
            }
            if indexPath.row == 1{
                mycell.currentIndex = indexPath.row
                mycell.allDataLikes = allDataLikes
            }
            if indexPath.row == 2{
                mycell.currentIndex = indexPath.row
                mycell.followingUserData = allDataForFollowings
            }
            cell = mycell
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size: CGSize! = nil
        if collectionView == self.myColl{
           size = CGSize(width: view.frame.size.width - self.view.frame.width / 2 + 30, height: 30)
        }
        if collectionView == self.myColl2{
            size = CGSize(width: view.frame.size.width, height: view.frame.size.height)
        }
        return size
    }
    
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//        let x = targetContentOffset.pointee.x
//        pageController.currentPage = Int(x / view.frame.width)
//        print(x)
//        let offSet = CGPoint(x: self.myColl1.center.x + x, y: 0)
//        myColl1.setContentOffset(offSet, animated: true)
        
    }
    
    
    func colCategorySelected(_ indexPath: IndexPath,currentIndex: Int) {
        let presentImagePage = presentImageViewController()
        if currentIndex == 0{
            let img = myPhotosArr[indexPath.row]
            presentImagePage.img = img
            presentImagePage.imgId = "image" + String(describing: indexPath.row)
        }else if currentIndex == 1{
            let allDataLikesVal = allDataLikes[indexPath.row]
//            let returneData = self.downloadImage(url: allDataLikesVal.imagesUrls.full!)
//            let img = UIImage(data: returneData)
            presentImagePage.img = UIImage(data: allDataLikesVal.image!)
            presentImagePage.imgId = "image1" + String(describing: indexPath.row)
        }
        self.present(presentImagePage, animated: true, completion: nil)
        self.hero.isEnabled = true
    }
    
}

protocol CellDelegate {
    func colCategorySelected(_ indexPath : IndexPath,currentIndex: Int)
}



class cellCustomUserProfilePage: UICollectionViewCell,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,PinterestLayoutDelegate,
UITableViewDelegate, UITableViewDataSource ,UICollectionViewDragDelegate,UIDropInteractionDelegate{
    
    
    
    
    
    let cellId3 = "cellId3"
    let tableCell = "cellId4"
    var followingUserData = [UserFollowers](){
        didSet{
            self.myTable.reloadData()
        }
    }
    
    var myPhotosArr = [UIImage](){
        didSet{
            self.myColl3.reloadData()
        }
    }
    var allImageLikes = [UIImage]()
    var allDataLikes = [UserPhotoLikes](){
        didSet{
            DispatchQueue.main.async {
                self.myColl3.reloadData()
            }
        }
    }
    
    let longPressedImage: UIImageView = {
        let image = UIImage()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    
    var currentIndex: Int! = nil{
        didSet{
            if currentIndex == 0 || currentIndex == 1{
                self.myTable.alpha = 0
            }else{
                self.myTable.alpha = 1
            }
        }
    }
    var currentView: UIView! = nil
    var delegate : CellDelegate?
    
    lazy var myColl3: UICollectionView = {
        let layout = PinterestLayout()
        let myColll = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        myColll.delegate = self
        myColll.bounces = false
        myColll.showsVerticalScrollIndicator = false
        myColll.dataSource = self
        myColll.dragDelegate = self
        myColll.dragInteractionEnabled = true
        myColll.register(cellCustomUserProfilePageForImage.self, forCellWithReuseIdentifier: cellId3)
        myColll.translatesAutoresizingMaskIntoConstraints = false
        myColll.backgroundColor = .white
        return myColll
    }()
    
    lazy var myTable: UITableView = {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.register(followingUserTableCell.self, forCellReuseIdentifier: tableCell)
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    var imageDragged: UIImage! = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(myColl3)
        addSubview(myTable)
        if let layout = myColl3.collectionViewLayout as? PinterestLayout{
            layout.delegate = self
        }
        addConstraints()
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(longGestureCell))
//        myColl3.addGestureRecognizer(longGesture)
    }
    
    
    
    func addConstraints(){
        NSLayoutConstraint.activate([
            myColl3.rightAnchor.constraint(equalTo: self.rightAnchor),
            myColl3.leftAnchor.constraint(equalTo: self.leftAnchor),
            myColl3.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            myColl3.topAnchor.constraint(equalTo: self.topAnchor),
            
            myTable.rightAnchor.constraint(equalTo: self.rightAnchor),
            myTable.leftAnchor.constraint(equalTo: self.leftAnchor),
            myTable.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            myTable.topAnchor.constraint(equalTo: self.topAnchor)
            ])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count: Int! = 3
        if currentIndex == 0{
            count = self.myPhotosArr.count
        }
        if currentIndex == 1{
            count =  self.allDataLikes.count
        }
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId3, for: indexPath) as! cellCustomUserProfilePageForImage
        if currentIndex == 0{
            let img = myPhotosArr[indexPath.row]
            cell.myImage.image = img
            cell.myImage.hero.id = "image" + String(describing: indexPath.row)
        }
        if currentIndex == 1{
            let imgData = allDataLikes[indexPath.row]
            if let image = imgData.image{
                cell.myImage.image = UIImage(data: image)
                cell.myImage.hero.id = "image1" + String(describing: indexPath.row)
            }
            if let userImage = imgData.thumbImage{
                cell.userPhotoTaken.image = UIImage(data: userImage)
            }
        }
        if currentIndex == 2{
            cell.backgroundColor = .red
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
        var height: CGFloat! = 0
//        if let imageExist = allDataLikes[indexPath.row].image{
            let image = UIImage(named: "photo")
            height = image?.size.height
//        }
        return height!
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.colCategorySelected(indexPath,currentIndex: currentIndex)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId3, for: indexPath) as! cellCustomUserProfilePageForImage
        
        guard let image = cell.myImage.image else { return [] }
        imageDragged = image
        let provider = NSItemProvider(object: image)
        let item = UIDragItem(itemProvider: provider)
        item.localObject = image
        item.previewProvider = {
            let frame: CGRect
            if image.size.width > image.size.height {
                let multiplier = cell.frame.width / image.size.width
                frame = CGRect(x: 0, y: 0, width: cell.frame.width, height: image.size.height * multiplier)
            } else {
                let multiplier = cell.frame.height / image.size.height
                frame = CGRect(x: 0, y: 0, width: image.size.width * multiplier, height: cell.frame.height)
            }
            
            let previewImageView = UIImageView(image: image)
            
            previewImageView.contentMode = .scaleAspectFit
            previewImageView.frame = frame
            
            
            return UIDragPreview(view: previewImageView, parameters: UIDragPreviewParameters())
            
//            let center = CGPoint(x: cell.bounds.midX, y: cell.bounds.midY)
//            let target = UIDragPreviewTarget(container: cell, center: center)
//            return UITargetedDragPreview(view: previewImageView, parameters: UIDragPreviewParameters(), target: target)
        }
        
        
        return [item]
    }
    
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return followingUserData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableCell, for: indexPath) as! followingUserTableCell
        let followerData = followingUserData[indexPath.row]
        if let imageDataExist = followerData.profileImaes{
            cell.userImage.image = UIImage(data: imageDataExist)
        }
        cell.userLabelName.text = followerData.name
        return cell
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func longGestureCell(gesture: UILongPressGestureRecognizer){

        if gesture.state != .ended {
            let position = gesture.location(in: self.myColl3)
            if let indexPath = myColl3.indexPathForItem(at: position){
                let attributes = myColl3.layoutAttributesForItem(at: indexPath)
                let cellRect = attributes?.frame
                let cellFrameInSuperview = myColl3.convert(cellRect!, to: superview)
                var height: CGFloat! = 0
                var width: CGFloat! = 0
                if let imageExist = allDataLikes[indexPath.row].image{
                    let image = UIImage(named: "photo")
                    height = image?.size.height
                    width = 197
                    longPressedImage.image = UIImage(data: imageExist)
                }
                self.addSubview(longPressedImage)
                NSLayoutConstraint.activate([
                    longPressedImage.heightAnchor.constraint(equalToConstant: height),
                    longPressedImage.widthAnchor.constraint(equalToConstant: width),
                    longPressedImage.topAnchor.constraint(equalTo: self.topAnchor, constant: cellFrameInSuperview.origin.y + 80),
                    longPressedImage.leftAnchor.constraint(equalTo: self.leftAnchor, constant: cellFrameInSuperview.origin.x - myColl3.frame.width)
                    ])
                let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesturePressedImage))
                longPressedImage.addGestureRecognizer(panGesture)
                debugPrint(cellFrameInSuperview.origin.x)
                debugPrint(cellFrameInSuperview.origin.y)
                debugPrint(height)
            }
        }
        if  gesture.state == .ended{
            longPressedImage.removeFromSuperview()
        }
        
    }
    
    
    
    
    
    
    @objc func panGesturePressedImage(sender: UIPanGestureRecognizer){
        let image = sender.view
        let translation = sender.translation(in: superview)
        image?.center = CGPoint(x: (image?.center.x)! + translation.x, y: (image?.center.y)! + translation.y)
        sender.setTranslation(CGPoint.zero, in: superview)
//        gestureRecognizer.view!.center = CGPoint(x: gestureRecognizer.view!.center.x + translation.x, y: gestureRecognizer.view!.center.y + translation.y)
        
    }
    
    
    
}


class cellCustomUserProfilePageForImage: UICollectionViewCell{
    
    let myImage: UIImageView = {
        let image = UIImage()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false;
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    let userPhotoTaken: UIImageView = {
        let image = UIImage()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false;
        return imageView
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(myImage)
        myImage.addSubview(userPhotoTaken)
        addConstraints()
    }
    
    func addConstraints(){
        NSLayoutConstraint.activate([
            myImage.rightAnchor.constraint(equalTo: self.rightAnchor),
            myImage.leftAnchor.constraint(equalTo: self.leftAnchor),
            myImage.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            myImage.topAnchor.constraint(equalTo: self.topAnchor),
            userPhotoTaken.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10),
            userPhotoTaken.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10),
            userPhotoTaken.heightAnchor.constraint(equalToConstant: 40),
            userPhotoTaken.widthAnchor.constraint(equalToConstant: 40)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}



class cellCustomTabs: UICollectionViewCell{
    
    let labels: UILabel = {
        let label = UILabel()
        label.text = "AMZA"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(labels)
        addConstraints()
    }
    
    
    
    func addConstraints(){
        NSLayoutConstraint.activate([
            labels.leftAnchor.constraint(equalTo: self.leftAnchor),
            labels.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

class followingUserTableCell: UITableViewCell {
    
    let tableCell = "cellId4"
    
    let userImage: UIImageView = {
        let image = UIImage()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false;
        return imageView
    }()
    
    let userLabelName: UILabel = {
        let label = UILabel()
        label.text = "AMza"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: tableCell)
        addSubview(userImage)
        addSubview(userLabelName)
        addConstraints()
    }
    
    func addConstraints(){
        NSLayoutConstraint.activate([
            
                userImage.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                userImage.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15),
                userImage.heightAnchor.constraint(equalToConstant: 40),
                userImage.widthAnchor.constraint(equalToConstant: 40),
                userLabelName.leftAnchor.constraint(equalTo: userImage.rightAnchor, constant: 15),
                userLabelName.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
}

