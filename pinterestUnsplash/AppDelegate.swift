//
//  AppDelegate.swift
//  pinterestUnsplash
//
//  Created by Andrew on 4/27/18.
//  Copyright © 2018 Andrew. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let client_id = "86e8aae4ffa01d902628937eb1d491a2d4175419c51f7c116ad8bf148c5df831"
    let client_secret = "e56338cb38aff2c6f98a190152c7746bd4d0c591bef7541179d8af749d2f84b8"
    let redirect_uri = "pinterestUnsplash://returnAfterLogin"
    typealias JSONStandard = [String: AnyObject]
    let userDefault = UserDefaults()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        
        if !userDefault.bool(forKey: "isLogged"){
            window?.rootViewController = ViewController()
        }else{
            let mainPageNav = UINavigationController(rootViewController: mainPage())
            window?.rootViewController = mainPageNav
        }
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        debugPrint(url.absoluteString)
        let urlComponents = NSURLComponents(url: url as URL, resolvingAgainstBaseURL: false)
        let items = (urlComponents?.queryItems)! as [NSURLQueryItem]
        if url.scheme == "pinterestunsplash"{
            if let propertyName = items.first?.name, let propertyValue = items.first?.value{
                if propertyName == "code"{
                    let url = "https://unsplash.com/oauth/token"
                    let param: Parameters = [
                        "client_id" : client_id,
                        "client_secret": client_secret,
                        "redirect_uri": redirect_uri,
                        "code": propertyValue,
                        "grant_type": "authorization_code"
                    ]
                    Alamofire.request(url, method: .post, parameters: param, headers: nil).responseJSON { (response) in
                        guard let data = response.data else {
                            debugPrint("Unsuccessful to get the user data")
                            return
                        }
                        self.parseData(data: data)
                    }
                }
            }
        }
        return true
    }
    
    func parseData(data: Data){
        do{
            guard let myData = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? JSONStandard else { return }
            if let accesToken = myData["access_token"] as? String{
                print(accesToken)
                
                userDefault.set(true, forKey: "isLogged")
                userDefault.set(accesToken, forKey: "access_token")
                userDefault.synchronize()
                let mainPageNav = UINavigationController(rootViewController: mainPage())
                window?.rootViewController = mainPageNav
            }
        }catch let err{
            print(err.localizedDescription)
            return
        }
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "pinterestUnsplash")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

