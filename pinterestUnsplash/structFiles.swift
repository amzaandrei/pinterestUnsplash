//
//  structFiles.swift
//  pinterestUnsplash
//
//  Created by Andrew on 4/27/18.
//  Copyright © 2018 Andrew. All rights reserved.
//

import Foundation


struct UserStruct{
    
    var id: String?
    var username: String?
    var name: String?
    var links: UserLinks?
    var width: Int?
    var profileImages: UserProfileImage?
    var photos: [UserPhotos]?
    init(dict: [String: Any],dictLinks: UserLinks?,dictImages: UserProfileImage?,dictPhotoInfos: [UserPhotos]? ) {
        self.id = dict["id"] as? String
        self.username = dict["username"] as? String
        self.name = dict["name"] as? String
        self.width = dict["width"] as? Int
        links = dictLinks
        profileImages = dictImages
        photos = dictPhotoInfos
    }
}

struct UserLinks {
    var me: String?
    var photos: String?
    var likes: String?
    var following: String?
    var followers: String?
    init(dict: [String: Any]) {
        self.me = dict["self"] as? String
        self.likes = dict["likes"] as? String
        self.photos = dict["photos"] as? String
        self.following = dict["following"] as? String
        self.followers = dict["followers"] as? String
    }
}

struct UserProfileImage {
    var small: String?
    var medium: String?
    var large: String?
    init(dict: [String: Any]) {
        self.small = dict["small"] as? String
        self.medium = dict["medium"] as? String
        self.large = dict["large"] as? String
    }
}


struct UserPhotos {
    var id: String?
    var width: Int?
    var height: Int?
    var likes: Int?
    var imagesUrls: PhotosDimensions
    init(dict: [String: Any],dictImagesUrl: PhotosDimensions) {
        self.id = dict["id"] as? String
        self.width = dict["width"] as? Int
        self.height = dict["height"] as? Int
        self.likes = dict["likes"] as? Int
        self.imagesUrls = dictImagesUrl
    }
}

struct PhotosDimensions {
    var raw: String?
    var full: String?
    var regular: String?
    var small: String?
    var thumb: String?
    init(dict: [String: Any]) {
        self.raw = dict["raw"] as? String
        self.regular = dict["regular"] as? String
        self.small = dict["small"] as? String
        self.thumb = dict["thumb"] as? String
        self.full = dict["full"] as? String
    }
}


struct Photo{
    var id: String?
    var width: Int?
    var height: Int?
    var likes: Int?
    var imagesUrls: PhotosDimensions
    var producer: UserStruct
    init(dict: [String: Any],dictImagesUrl: PhotosDimensions,dictProducer: UserStruct) {
        self.id = dict["id"] as? String
        self.width = dict["width"] as? Int
        self.height = dict["height"] as? Int
        self.likes = dict["likes"] as? Int
        self.imagesUrls = dictImagesUrl
        self.producer = dictProducer
    }
}













