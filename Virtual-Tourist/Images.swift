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
            if results.count > 0
            {
                for result in results
                {
                    let pin = result as! Pin
                    let imagesEntity = NSEntityDescription.insertNewObjectForEntityForName("Images", inManagedObjectContext: context) as! Images
                    let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                    let fileURL = documentsURL.URLByAppendingPathComponent("img\(imgName).png")
                    let pngImageData = UIImagePNGRepresentation(img)
                    dispatch_async(dispatch_get_main_queue())
                    {
                      let result = pngImageData!.writeToFile(fileURL.path!, atomically: true)
                       if result
                        {
                            imagesEntity.setValue("img\(imgName).png", forKey: "imagesData")
                            pin.addImageObject(imagesEntity)
                            imagesEntity.pin = pin
                            do{
                               
                                try context.save()
                                completion(error: "")
                                }
                            catch
                            {
                                completion(error:  "Can not Save Images")
                            }
                        }
                        else
                        {
                            completion(error: "Can not save images to document directory")
                        }
                    }
                }
                
            }
        }
        
        catch
        {
            completion(error:  "Can not Save Images")
        }
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
                self.imageList = try context.executeFetchRequest(request) as! [NSManagedObject]
                completion(error: "")
            }
            catch
            {
                completion(error: "Can not Fetch Images from CoreData")
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
            self.imageList = try context.executeFetchRequest(request) as! [NSManagedObject]
            for img in self.imageList
            {
                do{
                    //remove from directory
                    let imageName = img.valueForKey("imagesData")as! String
                    let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                    let fileURL = documentsURL.URLByAppendingPathComponent(imageName)
                    try fileManager.removeItemAtPath(fileURL.path!)
                    //remove path from coredata
                    context.deleteObject(img)
                    do
                    {
                        try context.save()
                    }
                    catch
                    {
                        completion(error: "Can not remove from Core data")
                    }

                }
                catch let err as NSError
                {
                    completion(error: err.description)
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
                        let imageName = imageList[cachedImagesIndex[i]].valueForKey("imagesData")as! String
                        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                        let fileURL = documentsURL.URLByAppendingPathComponent(imageName)
                        try fileManager.removeItemAtPath(fileURL.path!)
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
