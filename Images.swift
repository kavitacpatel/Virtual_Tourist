//
//  Images.swift
//  Virtual-Tourist
//
//  Created by kavita patel on 5/5/16.
//  Copyright © 2016 kavita patel. All rights reserved.
//

import Foundation
import CoreData
import MapKit
import UIKit

class Images: NSManagedObject
{
    
    static var imagesInstance = Images()
    var cachedImagesIndex = [Int]()
    var imageList = [NSManagedObject]()
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    func saveImages(location: CLLocationCoordinate2D,img: UIImage, imgName : String,completion:(error: String)-> Void)
    {
        let request = NSFetchRequest(entityName: "Pin")
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appdelegate.managedObjectContext
        let lati = location.latitude as NSNumber
        let long = location.longitude as NSNumber
        
        request.predicate = NSPredicate(format: "latitude = %@ AND longitude = %@", lati, long)
        do{
            let results = try context.executeFetchRequest(request)
            if results.count > 0 {
                for result in results
                {
                    let pin = result as! Pin
                    let imagesEntity = NSEntityDescription.insertNewObjectForEntityForName("Images", inManagedObjectContext: context) as! Images
                    //let imgData = NSData(data: UIImageJPEGRepresentation(img, 1.0)!)
                    if let data = UIImageJPEGRepresentation(img, 0.8) {
                        let filename = getDocumentsDirectory().stringByAppendingPathComponent("img\(imgName).png")
                        data.writeToFile(filename, atomically: true)
                        imagesEntity.imagesData = filename 
                        pin.addImageObject(imagesEntity)
                        imagesEntity.pin = pin
                    }
                    
                    do{
                        try context.save()
                        completion(error: "")
                    }catch
                    {
                        completion(error:  "Can not Save Images")
                    }
                }
            }
        }
        catch
        {
            completion(error:  "Can not Save Images")
        }
    }
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    // Get images of selected location
    func getImages(location: CLLocationCoordinate2D, completion:(error: String)-> Void)
    {
        
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appdelegate.managedObjectContext
        let lati = location.latitude as NSNumber
        let long = location.longitude as NSNumber
        let pageRequest = NSFetchRequest(entityName: "Pin")
        pageRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", lati, long)
        
        //Get Page no of current location URL
        do{
            let pages = try context.executeFetchRequest(pageRequest)
            for pageno in pages
            {
                Pin.pinInstance.pageno = pageno.valueForKey("page") as! Int
            }
        }
        catch
        {
            completion(error: "Can not Load Photos")
        }
        let request = NSFetchRequest(entityName: "Images")
        request.predicate = NSPredicate(format: "pin.latitude == %@ AND pin.longitude == %@", lati, long)
        //get Images of current location
        do{
            imageList = try context.executeFetchRequest(request) as! [NSManagedObject]
            completion(error: "")
        }
        catch
        {
            completion(error: "Can not Load Photos")
        }
    }
    func removeImages(location: CLLocationCoordinate2D,completion:(error: String)-> Void)
    {
        let fileManager:NSFileManager = NSFileManager.defaultManager()
        let request = NSFetchRequest(entityName: "Images")
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appdelegate.managedObjectContext
        let lati = location.latitude as NSNumber
        let long = location.longitude as NSNumber
        request.predicate = NSPredicate(format: "pin.latitude == %@ AND pin.longitude == %@", lati, long)
        do
        {
            imageList = try context.executeFetchRequest(request) as! [NSManagedObject]
            for img in imageList
            {
                context.deleteObject(img)
                do
                {
                     try context.save()
                }
                catch
                {
                    completion(error: "Can not remove from Core data")
                }
                do{
                    //remove from directory
                    try fileManager.removeItemAtPath(img.valueForKey("imagesData")as! String)
                    
                }
                catch
                {
                    completion(error: "Can not remove from document directory")
                }
                
                }
            completion(error: "")
        }
    catch
    {
        completion(error: "Can not fetch image for deletion")
    }

    }
    func removeSelectedImages(location: CLLocationCoordinate2D,completion:(error: String)-> Void)
    {
        let fileManager:NSFileManager = NSFileManager.defaultManager()
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appdelegate.managedObjectContext
        let request = NSFetchRequest(entityName: "Images")
        let lati = location.latitude as NSNumber
        let long = location.longitude as NSNumber
        request.predicate = NSPredicate(format: "pin.latitude == %@ AND pin.longitude == %@", lati, long)
        
        do{
            imageList = try context.executeFetchRequest(request) as! [NSManagedObject]
            if cachedImagesIndex.count == 0
            {
                completion(error: "No photo selectd to Remove")
            }
            else
            {
                cachedImagesIndex = cachedImagesIndex.sort { $0 > $1 }
                for i in 0...cachedImagesIndex.count-1
                {
                    do{
                        //remove from directory
                        try fileManager.removeItemAtPath(imageList[cachedImagesIndex[i]].valueForKey("imagesData")as! String)
                    }
                    catch
                    {
                        completion(error: "Can not remove from document directory")
                    }

                    do
                    {
                        context.deleteObject(imageList.removeAtIndex(cachedImagesIndex[i]))
                        try context.save()
                    }
                    catch
                    {
                        cachedImagesIndex.removeAll()
                        completion(error: "Photo Deletion Error")
                    }
                }
                cachedImagesIndex.removeAll()
                completion(error: "")
            }
        }
        catch
        {
            cachedImagesIndex.removeAll()
            completion(error: "Photo is Not Deleted")
        }
    }    
}
