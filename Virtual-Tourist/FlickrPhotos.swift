//
//  FlickrPhotos.swift
//  Virtual-Tourist
//
//  Created by kavita patel on 5/2/16.
//  Copyright © 2016 kavita patel. All rights reserved.
//

import Foundation
import UIKit
import CoreData
class FlickrPhotos: AnyObject
{
    static let sharedInstance = FlickrPhotos()
    var List: [NSManagedObject]
    
    private init()
    {
        List = [NSManagedObject]()
    }
    var cachedImagesIndex = [Int]()
    // coreData: save photos
    func saveImages(img: UIImage,completion:(error: String)-> Void)
    {
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appdelegate.managedObjectContext
        let entity = NSEntityDescription.entityForName("Images", inManagedObjectContext: context)
        let images = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: context)
        let imageData = NSData(data: UIImageJPEGRepresentation(img, 1.0)!)
        images.setValue(imageData, forKey: "imagesData")
        do{
            try context.save()
            completion(error: "")
        }catch
        {
            completion(error: "Can not Save Photos")
        }
        
    }
    
    //coreData: remove Photos
    func removeImages(completion:(error: String)-> Void)
    {
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appdelegate.managedObjectContext
        let request = NSFetchRequest(entityName: "Images")
        do{
            let imageList = try context.executeFetchRequest(request) as! [NSManagedObject]
            if imageList.count > 0
            {
                do{
                    for img in imageList
                    {
                        context.deleteObject(img)
                        try context.save()
                    }
                    completion(error: "")
                }
                catch
                {
                    completion(error: "Photo is Not Deleted")
                }
            }
        }
        catch
        {
            completion(error: "Photo Loading Error")
        }
    }
    
    //Remove Selected Photos
    func removeSelectedImages(completion:(error: String)-> Void)
    {
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appdelegate.managedObjectContext
        let request = NSFetchRequest(entityName: "Images")
        do{
            var imageList = try context.executeFetchRequest(request) as! [NSManagedObject]
            if cachedImagesIndex.count == 0
            {
                completion(error: "No photo selectd to Remove")
            }
            else
            {
                cachedImagesIndex = cachedImagesIndex.sort { $0 > $1 }
                
                for i in 0...cachedImagesIndex.count-1
                {
                    context.deleteObject(imageList.removeAtIndex(cachedImagesIndex[i]))
                    do
                    {
                        try context.save()
                    }
                    catch
                    {
                        completion(error: "Photo Deletion Error")
                    }
                }
            }
        }
        catch
        {
            completion(error: "Photo is Not Deleted")
        }
    }
    
    //coreData: get images
    func getImages(completion:(error: String)-> Void)
    {
        cachedImagesIndex.removeAll()
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appdelegate.managedObjectContext
        let request = NSFetchRequest(entityName: "Images")
        do{
            List = try context.executeFetchRequest(request) as! [NSManagedObject]
            print(List.count)
        }
        catch
        {
            completion(error: "Can not Load Photos")
        }
    }
    
    

}
