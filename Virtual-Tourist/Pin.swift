//
//  Pin.swift
//  Virtual-Tourist
//
//  Created by kavita patel on 5/5/16.
//  Copyright © 2016 kavita patel. All rights reserved.
//

import Foundation
import CoreData
import MapKit
import UIKit

class Pin: NSManagedObject {
    
    static var pinInstance = Pin()
    var pageno: Int = 1
    var locations = [NSManagedObject]()
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
    }
   //set New Page no.
   /* func setNewPage(location: CLLocationCoordinate2D)
    {
        pageno = pageno + 1
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appdelegate.managedObjectContext
        let lati = location.latitude as NSNumber
        let long = location.longitude as NSNumber
        let pageRequest = NSFetchRequest(entityName: "Pin")
        pageRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", lati, long)
        
        //Get Page no of current location URL
        do{
            let pages = try context.executeFetchRequest(pageRequest)
            for page_no in pages
            {
                page_no.setValue(pageno, forKey: "page")
            }
        }
        catch
        {
            print( "Can not set new page")
        }
    }*/

  /*  func saveLocation(loc: CLLocationCoordinate2D, span: MKCoordinateSpan?, completion: (error: String)-> Void)
    {
        let lati = loc.latitude as NSNumber
        let long = loc.longitude as NSNumber
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appdelegate.managedObjectContext
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        
        let request = NSFetchRequest(entityName: "Pin")
        request.predicate = NSPredicate(format: "latitude = %@ AND longitude = %@", lati, long)
        do{
            let results = try context.executeFetchRequest(request)
            if results.count == 0
            {
                //if location is not saved than save it
                
                let location = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: context)
                location.setValue(lati , forKey: "latitude")
                location.setValue(long, forKey: "longitude")
                location.setValue(span!.latitudeDelta, forKey: "latitudeDelta")
                location.setValue(span!.longitudeDelta, forKey: "longitudeDelta")
                //initially set page to no 1 to get images
                location.setValue(1, forKey: "page")
                do{
                    
                    try context.save()
                    dispatch_async(dispatch_get_main_queue())
                    {
                        print("location is saved")
                        completion(error: "")
                    }
                }
                catch
                {
                    dispatch_async(dispatch_get_main_queue())
                    {
                        completion(error: "Can not Save Location")
                    }
                }
            }
        }
        catch
        {
            completion(error: "Can not Save Location")
        }
    }*/
    //CoreData: when Map Controller loads, get saved location from coredata
  /*  func getLocation(completion: (locations: [NSManagedObject] ,error: String)-> Void)
    {
        let request = NSFetchRequest(entityName: "Pin")
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appdelegate.managedObjectContext
        
        do{
            let results = try context.executeFetchRequest(request)
            locations = results as! [NSManagedObject]
            completion(locations: locations, error: "")
        }catch
        {
            completion(locations: locations, error: "Can not Load Locations")
        }
    }
    */
    
    //CoreData: Delete Pin and Related Images
   /* func deleteLocation(loc: CLLocationCoordinate2D, completion: (error: String)-> Void)
    {
        //remove images from document directory
        Images.imagesInstance.removeImages(loc.latitude, long: loc.longitude)
                let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                let context = appdelegate.managedObjectContext
                let request = NSFetchRequest(entityName: "Pin")
        
                do{
                    let pinList = try context.executeFetchRequest(request) as! [NSManagedObject]
                    if pinList.count > 0
                    {
                        for pin in pinList
                        {
                            let newCoordination = CLLocationCoordinate2D(latitude: pin.valueForKey("latitude") as! CLLocationDegrees, longitude: pin.valueForKey("longitude") as! CLLocationDegrees)
                            if newCoordination.latitude == loc.latitude && newCoordination.longitude == loc.longitude
                            {
                                do{
                                    context.deleteObject(pin)
                                    try context.save()
                                    print("location is deleted")
                                    completion(error: "")
                                }
                                catch
                                {
                                    completion(error: "Deletion is not Completed")
                                }
                            }
                        }
                        completion(error: "")
                    }
                    else
                    {
                        completion(error: "Can not Find Location")
                    }
                }
                catch
                {
                    completion(error: "Can Not Fetch Location")
                }
    }
 */   
}
