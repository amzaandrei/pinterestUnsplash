//
//  File.swift
//  pinterestUnsplash
//
//  Created by Andrew on 4/27/18.
//  Copyright © 2018 Andrew. All rights reserved.
//

import UIKit
import Hero
import Alamofire
import CoreData

class mainPage: UIViewController,UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PinterestLayoutDelegate,UISearchBarDelegate {
    
    
    let userDefaults = UserDefaults()
    let cellId = "cellId"
    let cellId2 = "cellId2"
    let cellId3 = "cellId3"
    typealias JSONStandard = [String: AnyObject]
    var managedObjectContext: NSManagedObjectContext! = nil
    var userInfoData: UserStruct! = nil
    var myProfileImg: UIImage! = nil
    var allPhotos = [Photo]()
    var allUsers = [UserStruct]()
    var userName: String! = nil
    var allDataUserLikes = [Photo]()
    var allDataForFollowings = [UserStruct]()
    var allPhotosImg = [UIImage]()
    var searchBar = UISearchBar()
    var trendsArr: [String] = ["random","users"] {
        didSet{
            self.userDefaults.set(self.trendsArr, forKey: "trendsArr")
            self.userDefaults.synchronize()
        }
    }
    var trendTapped: String = ""
    
    
    
    lazy var myCollPhotos: UICollectionView = {
        let layout = PinterestLayout()
        let myColll = UICollectionView(frame: .zero, collectionViewLayout: layout)
        myColll.delegate = self
        myColll.alwaysBounceVertical = false
        myColll.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        myColll.alwaysBounceVertical = false
        myColll.dataSource = self
        myColll.register(myCell.self, forCellWithReuseIdentifier: cellId)
        myColll.translatesAutoresizingMaskIntoConstraints = false
        myColll.backgroundColor = .white
        return myColll
    }()
    
    lazy var myCollUsers: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let myColll = UICollectionView(frame: .zero, collectionViewLayout: layout)
        myColll.delegate = self
        myColll.alwaysBounceVertical = false
        myColll.dataSource = self
        myColll.register(myCellUser.self, forCellWithReuseIdentifier: cellId3)
        myColll.translatesAutoresizingMaskIntoConstraints = false
        myColll.backgroundColor = .white
        return myColll
    }()
    
    lazy var trendsColl: UICollectionView = {
        let myLayout = UICollectionViewFlowLayout()
        myLayout.scrollDirection = .horizontal
        let myColll = UICollectionView(frame: CGRect.zero, collectionViewLayout: myLayout)
        myColll.delegate = self
        myColll.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        myColll.dataSource = self
        myColll.register(myCellTrends.self, forCellWithReuseIdentifier: cellId2)
        myColll.translatesAutoresizingMaskIntoConstraints = false
        myColll.backgroundColor = nil
        myColll.showsHorizontalScrollIndicator = false
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
        let userDefaultsArr = self.userDefaults.array(forKey: "trendsArr")
        if userDefaultsArr != nil{
            trendsArr = userDefaultsArr as! [String]
        }
        self.edgesForExtendedLayout = []
        view.addSubview(myCollPhotos)
        view.addSubview(myCollUsers)
        view.addSubview(trendsColl)
        trendsColl.alpha = 0
        view.addSubview(profileImage)
        addConstraints()
        if let layout = myCollPhotos.collectionViewLayout as? PinterestLayout{
            layout.delegate = self
        }
        self.hero.isEnabled = true
        profileImage.hero.id = "myProfileImg"
        
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let profileImageTapped = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        profileImage.addGestureRecognizer(profileImageTapped)
        
        findConnectionInternetStatus()
        fetchCoreData()
        
        searchBar.delegate = self
        searchBar.searchBarStyle = UISearchBarStyle.minimal
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Search", style: .plain, target: self, action: #selector(showSearchBar))
    }
    
    @objc func showSearchBar() {
        searchBar.alpha = 0
        navigationItem.titleView = searchBar
        navigationItem.setLeftBarButton(nil, animated: true)
        UIView.animate(withDuration: 0.5, animations: {
            self.trendsColl.alpha = 1
            self.searchBar.alpha = 1
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.hideSearchBar))
        }, completion: { finished in
            self.searchBar.becomeFirstResponder()
        })
    }
    
    @objc func hideSearchBar() {
        UIView.animate(withDuration: 0.5, animations: {
            self.trendsColl.alpha = 0
            self.searchBar.alpha = 0
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Search", style: .plain, target: self, action: #selector(self.showSearchBar))
        }, completion: { finished in
            /// TODO: nu se face dismiss la tastatura :/
            DispatchQueue.main.async(execute: {
                self.view.endEditing(true)
                self.resignFirstResponder()
            })
        })
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let queryText = searchBar.text else { return }
        let userBool = trendTapped == "users" ? true : false
        trendTapped = ""
        if searchBar.text == "" && self.trendTapped == "" {
            let actionController = UIAlertController(title: "Important", message: "Add something in the search box or choose something from the trends list cells", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            actionController.addAction(action)
            self.present(actionController, animated: true, completion: nil)
        }
        let page = String(2)
        let perPage = String(10)
        self.parseDataPhotosRequest(query: queryText, page: page, perPage: perPage, user: userBool)
        //// mai pot ca params "collections", "orientation"
        
        DispatchQueue.main.async {
            self.trendsArr.append(queryText)
            self.trendsColl.reloadData()
        }
    }
    
    func parseDataPhotosRequest(query: String, page: String, perPage: String, user: Bool){
        self.allPhotos.removeAll()
        self.allPhotosImg.removeAll()
        var url: String! = nil
        if user{
            url = "https://api.unsplash.com/search/users"
        }else{
            url = "https://api.unsplash.com/search/photos"
        }
        guard let accesToken = userDefaults.string(forKey: "access_token") else { return }
        let params: Parameters = [
            "query": query,
            "page": page,
            "per_page": perPage
        ]
        let headers: HTTPHeaders = [
            "Authorization": "Bearer " + accesToken
        ]
        Alamofire.request(url, method: .get, parameters: params, headers: headers).responseJSON { (response) in
            guard let data = response.data else { return }
            self.parseAllPhotos(data: data,user: user)
        }
    }
    
    func parseAllPhotos(data: Data,user: Bool){
        var photoUrls: PhotosDimensions! = nil
        var userData: UserStruct! = nil
        var userImagesData: UserProfileImage! = nil
        var userDataLinks: UserLinks! = nil
        var userDataProfileImages: UserProfileImage! = nil
        do{
            guard let allPhotosDict = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? JSONStandard else { return }
            if let results = allPhotosDict["results"] as? [JSONStandard]{
                if !user{
                    for result in results{
                        if let urls = result["urls"] as? JSONStandard {
                            photoUrls = PhotosDimensions(dict: urls)
                        }
                        if let user = result["user"] as? JSONStandard{
                            if let profile_image = user["profile_image"] as? JSONStandard{
                                userImagesData = UserProfileImage(dict: profile_image)
                            }
                            userData = UserStruct(dict: user, dictLinks: nil, dictImages: userImagesData, dictPhotoInfos: nil)
                        }
                        let photoData = Photo(dict: result, dictImagesUrl: photoUrls, dictProducer: userData)
                        self.allPhotos.append(photoData)
                        
                    }
                    for photoIndex in allPhotos{
                        guard let imgString = photoIndex.imagesUrls.small else { return }
                        let returnData = self.downloadImage(url: imgString)
                        let img = UIImage(data: returnData)
                        self.allPhotosImg.append(img!)
                    }
                    DispatchQueue.main.async {
                        self.myCollPhotos.alpha = 1
                        self.myCollUsers.alpha = 0
                        self.myCollPhotos.reloadData()
                    }
                }else{
                    var photosArr = [UserPhotos]()
                    for result in results{
                        if let links = result["links"] as? JSONStandard{
                            userDataLinks = UserLinks(dict: links)
                        }
                        if let profileImages = result["profile_image"] as? JSONStandard{
                            userDataProfileImages = UserProfileImage(dict: profileImages)
                        }
                        
                        if let photos = result["photos"] as? [JSONStandard]{
                            for photo in photos{
                                var userPhotoUrls: PhotosDimensions! = nil
                                if let photoUrl = photo["urls"] as? JSONStandard{
                                    userPhotoUrls = PhotosDimensions(dict: photoUrl)
                                }
                                let userPhotosInfos = UserPhotos(dict: photo,dictImagesUrl: userPhotoUrls)
                                photosArr.append(userPhotosInfos)
                            }
                        }
                        userInfoData = UserStruct(dict: result, dictLinks: userDataLinks, dictImages: userDataProfileImages, dictPhotoInfos: photosArr)
                        self.allUsers.append(userInfoData)
                        photosArr.removeAll()
                    }
                    DispatchQueue.main.async {
                        self.myCollUsers.alpha = 1
                        self.myCollPhotos.alpha = 0
                        self.myCollUsers.reloadData()
                    }
                }
            }
        }catch let err{
            print(err.localizedDescription)
            return
        }
    }
    
    func findConnectionInternetStatus(){
        let reachiability = Reachability()!
        NotificationCenter.default.addObserver(self, selector: #selector(internetConnectionHasChanged), name: ReachabilityChangedNotification, object: reachiability)
        do{
            try reachiability.startNotifier()
        }catch{
            print("could not start notifier")
        }
    }
    
    @objc func internetConnectionHasChanged(note: Notification){
        let reachiability = note.object as! Reachability
        
        if reachiability.isReachable{
            if reachiability.isReachableViaWiFi{
                debugPrint("via WIFI")
            }else{
                debugPrint("via LTE")
            }
        }else{
            debugPrint("unreachable")
        }
        
    }
    
    func fetchCoreData(){
        
        let userProfileImageDataFetch: NSFetchRequest<UserProfileImageEntity> = UserProfileImageEntity.fetchRequest()
        
        do{
            let obj = try managedObjectContext.fetch(userProfileImageDataFetch)
            if obj.count == 0{
                fetchAllDataFromUser()
            }else{
                myProfileImg = UIImage(data: obj[0].large!)
                DispatchQueue.main.async {
                    self.profileImage.image = self.myProfileImg
                }
            }
        }catch let err{
            print(err.localizedDescription)
            return
        }
        
    }
    
    func fetchAllDataFromUser(){
        guard let accesToken = userDefaults.string(forKey: "access_token") else { return }
        let url = URL(string: "https://api.unsplash.com/me")
        let header: HTTPHeaders = [
            "Authorization": "Bearer " + accesToken
        ]
        Alamofire.request(url!, method: .get, parameters: nil, headers: header).responseJSON { (response) in
            guard let data = response.data else { return }
            self.parseUserData(data: data)
        }
    }
    
    func parseUserData(data: Data){
        var userDataLinks: UserLinks! = nil
        var userDataProfileImages: UserProfileImage! = nil
        do{
            guard let allDict = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? JSONStandard else  { return }
            
            if let links = allDict["links"] as? JSONStandard{
                userDataLinks = UserLinks(dict: links)
            }
            if let profileImages = allDict["profile_image"] as? JSONStandard{
                userDataProfileImages = UserProfileImage(dict: profileImages)
            }
            var photosArr = [UserPhotos]()
            if let photos = allDict["photos"] as? [JSONStandard]{
                for photo in photos{
                    var userPhotoUrls: PhotosDimensions! = nil
                    if let photoUrl = photo["urls"] as? JSONStandard{
                        userPhotoUrls = PhotosDimensions(dict: photoUrl)
                    }
                    let userPhotosInfos = UserPhotos(dict: photo,dictImagesUrl: userPhotoUrls)
                    photosArr.append(userPhotosInfos)
                }
            }
            userInfoData = UserStruct(dict: allDict, dictLinks: userDataLinks, dictImages: userDataProfileImages, dictPhotoInfos: photosArr)
            photosArr.removeAll()
            userName = userInfoData.username
            getUser()
            
        }catch let err{
            print(err.localizedDescription)
            return
        }
    }
    
    
    func getUser(){
        let urlsArr = ["https://api.unsplash.com/users/" + userName + "/likes", "https://api.unsplash.com/users/" + userName + "/following"]
        guard let accesToken = userDefaults.string(forKey: "access_token") else { return }
        for (index,_) in urlsArr.enumerated(){
            let url = URL(string: urlsArr[index])
            let header: HTTPHeaders = [
                "Authorization": "Bearer " + accesToken
            ]
            Alamofire.request(url!, method: .get, parameters: nil, headers: header).responseJSON { (response) in
                guard let data = response.data else { return }
                self.parseData(data: data,index: index)
            }
        }
        
    }
    
    func parseData(data: Data,index: Int){
        var photoUrls: PhotosDimensions! = nil
        var userData: UserStruct! = nil
        var userImagesData: UserProfileImage! = nil
        do{
            guard let allDict = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [JSONStandard] else {
                print("Impossible to parse JSON")
                return
            }
            if index == 0{
                for dict in allDict{
                    if let urls = dict["urls"] as? JSONStandard {
                        photoUrls = PhotosDimensions(dict: urls)
                    }
                    if let user = dict["user"] as? JSONStandard{
                        if let profile_image = user["profile_image"] as? JSONStandard{
                            userImagesData = UserProfileImage(dict: profile_image)
                        }
                        userData = UserStruct(dict: user, dictLinks: nil, dictImages: userImagesData, dictPhotoInfos: nil)
                    }
                    let photoData = Photo(dict: dict, dictImagesUrl: photoUrls, dictProducer: userData)
                    self.allDataUserLikes.append(photoData)
                }
            }
            if index == 1{
                for dict in allDict{
                    if let profileUrls = dict["profile_image"] as? JSONStandard{
                        userImagesData = UserProfileImage(dict: profileUrls)
                    }
                    userData = UserStruct(dict: dict, dictLinks: nil, dictImages: userImagesData, dictPhotoInfos: nil)
                    self.allDataForFollowings.append(userData)
                }
            }
            self.addDataToCoreData()
        }catch let err{
            print(err.localizedDescription)
            return
        }
    }
    
    
    func addDataToCoreData(){
        
        let userEntity = UserEntity(context: self.managedObjectContext)
        userEntity.id = userInfoData.id
        userEntity.name = userInfoData.name
        userEntity.username = userInfoData.username
        
        let userLinksEntity = UserLinksEntity(context: self.managedObjectContext)
        userLinksEntity.me = userInfoData.links?.me
        userLinksEntity.followers = userInfoData.links?.followers
        userLinksEntity.following = userInfoData.links?.following
        userLinksEntity.likes = userInfoData.links?.likes
        userLinksEntity.photos = userInfoData.links?.photos
        
        userLinksEntity.user = userEntity
        
        let userProfileImageEntity = UserProfileImageEntity(context: self.managedObjectContext)
        guard let small = userInfoData.profileImages?.small, let medium = userInfoData.profileImages?.medium, let large = userInfoData.profileImages?.large else { return }
        userProfileImageEntity.small = self.downloadImage(url: small)
        userProfileImageEntity.medium = self.downloadImage(url: medium)
        userProfileImageEntity.large = self.downloadImage(url: large)
        
        userProfileImageEntity.userLinks = userLinksEntity
        
        var photosData = [UIImage]()
        for myPhoto in userInfoData.photos!{
            guard let fullImgUrl = myPhoto.imagesUrls.full else {return}
            let returnedData = self.downloadImage(url: fullImgUrl)
            let img = UIImage(data: returnedData)
            photosData.append(img!)
        }
        
        let userPhotos = UserPhotosEntity(context: self.managedObjectContext)
        userPhotos.images = photosData as NSObject
        photosData.removeAll()
        
        for allDataUserLike in allDataUserLikes{
            let userLikes = UserPhotoLikes(context: self.managedObjectContext)
            userLikes.height = Float(allDataUserLike.height!)
            userLikes.width = Float(allDataUserLike.width!)
            userLikes.id = allDataUserLike.id
            userLikes.likes = Float(allDataUserLike.likes!)
            if let thumgImage = allDataUserLike.producer.profileImages?.medium{
                let returnedDataThumbImage = self.downloadImage(url: thumgImage)
                userLikes.thumbImage = returnedDataThumbImage
            }
            let returnedDataImage = self.downloadImage(url: allDataUserLike.imagesUrls.regular!)
            userLikes.image = returnedDataImage
            userLikes.userRel = userEntity
        }
        
        for userFol in self.allDataForFollowings{
            let userFollowers = UserFollowers(context: self.managedObjectContext)
            userFollowers.id = userFol.id
            userFollowers.name = userFol.name
            if let imageExist = userFol.profileImages?.medium{
                let returnedDataThumbImage = self.downloadImage(url: imageExist)
                userFollowers.profileImaes = returnedDataThumbImage
            }
            userFollowers.userName = userFol.username
        }
        
        DispatchQueue.main.async {
            let actionController = UIAlertController(title: "Important", message: "Do you want to save into your library your liked photos from your account?", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "OK", style: .default) { (_) in
                self.saveToLibraries()
            }
            let noAction = UIAlertAction(title: "No", style: .default, handler: nil)
            actionController.addAction(yesAction)
            actionController.addAction(noAction)
            self.present(actionController, animated: true, completion: nil)
            
            
            self.profileImage.image = UIImage(data: userProfileImageEntity.medium!)
        }
        
        do {
            try self.managedObjectContext.save()
        } catch let error as NSError{
            print("Could not save. \(error), \(error.userInfo)")
        }
        
    }
    
    func saveToLibraries(){
        for allDataUserLike in allDataUserLikes{
            let returnedDataImage = self.downloadImage(url: allDataUserLike.imagesUrls.regular!)
            if let image = UIImage(data: returnedDataImage){
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
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
    
    var bottomConstraint: NSLayoutConstraint! = nil
    
    func addConstraints(){
        
        bottomConstraint = profileImage.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant: -20)
        bottomConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            myCollPhotos.rightAnchor.constraint(equalTo: view.rightAnchor),
            myCollPhotos.leftAnchor.constraint(equalTo: view.leftAnchor),
            myCollPhotos.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            myCollPhotos.topAnchor.constraint(equalTo: view.topAnchor),
            
            myCollUsers.rightAnchor.constraint(equalTo: view.rightAnchor),
            myCollUsers.leftAnchor.constraint(equalTo: view.leftAnchor),
            myCollUsers.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            myCollUsers.topAnchor.constraint(equalTo: view.topAnchor),
            
            trendsColl.rightAnchor.constraint(equalTo: view.rightAnchor),
            trendsColl.leftAnchor.constraint(equalTo: view.leftAnchor),
            trendsColl.topAnchor.constraint(equalTo: view.topAnchor),
            trendsColl.heightAnchor.constraint(equalToConstant: 40),
            
            profileImage.rightAnchor.constraint(equalTo: view.rightAnchor,constant: -20),
            profileImage.heightAnchor.constraint(equalToConstant: 40),
            profileImage.widthAnchor.constraint(equalToConstant: 40)
            ])
    }
    
    @objc func imageTapped(){
        let page = userProfilePage()
        let navPage = UINavigationController(rootViewController: page)
        page.profileImg = myProfileImg
        page.profileImgID = "myProfileImg"
        present(navPage, animated: true, completion: nil)
        self.hero.isEnabled = true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count: Int! = nil
        if collectionView == myCollPhotos{
            count = self.allPhotos.count
        }
        if collectionView == myCollUsers{
            count = self.allUsers.count
        }
        if collectionView == trendsColl{
            count = self.trendsArr.count
        }
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell! = nil
        if collectionView == self.myCollPhotos{
            let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! myCell
            let photoValue = allPhotosImg[indexPath.row]
            myCell.myImage.image = photoValue
            myCell.myImage.hero.id = "image" + String(describing: indexPath.row)
            cell = myCell
        }
        if collectionView == self.myCollUsers{
            let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId3, for: indexPath) as! myCellUser
            let userData = allUsers[indexPath.row]
            if let profileImageExist = userData.profileImages?.small{
                myCell.userImage.loadImageUsingCacheString(urlString: profileImageExist)
            }
            if let firstPortofolioImage = userData.photos![0].imagesUrls.regular{
                myCell.firstImage.loadImageUsingCacheString(urlString: firstPortofolioImage)
            }
            myCell.userNameLabel.text = userData.name
            cell = myCell
        }
        if collectionView == self.trendsColl{
            let myCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId2, for: indexPath) as! myCellTrends
            let trendsValues = trendsArr[indexPath.row]
            myCell.backgroundColor = .red
            myCell.labelTrends.text = trendsValues
            myCell.color = false
            cell = myCell
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
        var height: CGFloat! = nil
        if collectionView == self.myCollPhotos{
            let image = allPhotosImg[indexPath.row]
             height = image.size.height
        }
        return height
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == myCollPhotos{
            let presentImage = allPhotos[indexPath.row].imagesUrls
            let presentImagePage = presentImageViewController()
            if let imageExist = presentImage.full{
                let returnedData = self.downloadImage(url: imageExist)
                let image = UIImage(data: returnedData)
                presentImagePage.img = image
            }
            presentImagePage.imgId = "image" + String(describing: indexPath.row)
            present(presentImagePage, animated: true, completion: nil)
            self.hero.isEnabled = true
        }
        if collectionView == trendsColl{
            let trendsValues = trendsArr[indexPath.row]
            let cell = trendsColl.cellForItem(at: indexPath) as! myCellTrends
            if !cell.color{
                cell.backgroundColor = .blue
                cell.color = true
            }else{
                cell.backgroundColor = .red
                cell.color = false
            }
            trendTapped = trendsValues
            if trendTapped != "users"{
                searchBar.text = trendsValues
            }
        }
        if collectionView == myCollUsers{
            let userData = allUsers[indexPath.row]
            let presentUserPage = userPage()
            let navPage = UINavigationController(rootViewController: presentUserPage)
            presentUserPage.idName = userData.username
            present(navPage, animated: true, completion: nil)
            self.hero.isEnabled = true
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size: CGSize! = nil
        if collectionView == self.trendsColl{
            let trendsValues = trendsArr[indexPath.row]
            let width = (trendsValues).size(withAttributes: nil).width + 40
            let height = (trendsValues).size(withAttributes: nil).height + 10
            size = CGSize(width: width, height: height)
        }
        if collectionView == self.myCollUsers{
            size = CGSize(width: self.view.frame.width / 2 + 100, height: self.view.frame.height / 2 + 1.00)
        }
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        var insetEdge: UIEdgeInsets! = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let defaultSize = (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize
        if collectionView == self.myCollUsers{
            /// TODO: ceva neinregula cu padding top hardcodat 300 si cel de la minimumLineSpacingForSectionAt
            let paddingTop = self.view.frame.height / 2 - (defaultSize?.height)! / 2 - 200
            insetEdge = UIEdgeInsets(top: paddingTop, left: 0, bottom: 0, right: 0)
        }
        return insetEdge
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        var padding: CGFloat! = 0
        if collectionView == self.myCollUsers{
            let defaultSize = (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize
            if collectionView == self.myCollUsers{
                padding = self.view.frame.height / 2 - (defaultSize?.height)! / 2 - 100
            }
        }
        return padding
    }
    
    var scrollValues: CGFloat = 0


    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = scrollView.contentOffset.y
        if y >= -20 && y <= 120{
            if y > scrollValues {
                scrollValues = y
                DispatchQueue.main.async {
                    self.bottomConstraint.constant = y
                    self.view.layoutIfNeeded()
                }
            }
            if scrollValues > y {
                scrollValues = y
                DispatchQueue.main.async {
                    self.bottomConstraint.constant = y
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
}


class myCell: UICollectionViewCell{
    
    let myImage: UIImageView = {
        let image = UIImage()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false;
        return imageView
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(myImage)
        addConstraints()
    }
    
    func addConstraints(){
        NSLayoutConstraint.activate([
            myImage.rightAnchor.constraint(equalTo: self.rightAnchor),
            myImage.leftAnchor.constraint(equalTo: self.leftAnchor),
            myImage.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            myImage.topAnchor.constraint(equalTo: self.topAnchor),
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


class myCellTrends: UICollectionViewCell{
    
    var color: Bool = false
    let labelTrends: UILabel = {
        let label = UILabel()
        label.text = "TEXT"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.layer.cornerRadius = 10.0
        self.contentView.layer.masksToBounds = true
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 0.5
        self.layer.masksToBounds = false
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.contentView.layer.cornerRadius).cgPath
        self.addSubview(labelTrends)
        addConstraints()
    }
    
    func addConstraints(){
        NSLayoutConstraint.activate([
                labelTrends.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                labelTrends.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


class myCellUser: UICollectionViewCell{
    
    let firstImage: UIImageView = {
        let image = UIImage()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false;
        return imageView
    }()
    
    let userImage: UIImageView = {
        let image = UIImage()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false;
        return imageView
    }()
    
    let userNameLabel: UILabel = {
        let label = UILabel()
        label.text = "TEXT"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(firstImage)
        addSubview(userImage)
        addSubview(userNameLabel)
        addConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addConstraints(){
        NSLayoutConstraint.activate([
                firstImage.leftAnchor.constraint(equalTo: self.leftAnchor),
                firstImage.rightAnchor.constraint(equalTo: self.rightAnchor),
                firstImage.topAnchor.constraint(equalTo: self.topAnchor),
                firstImage.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                userImage.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 15),
                userImage.heightAnchor.constraint(equalToConstant: 40),
                userImage.widthAnchor.constraint(equalToConstant: 40),
                userImage.bottomAnchor.constraint(equalTo: self.bottomAnchor,constant: -10),
                userNameLabel.leftAnchor.constraint(equalTo: userImage.rightAnchor, constant: 15),
                userNameLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor,constant: -10),
            ])
    }
    
}



