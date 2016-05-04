//
//  CoreData.swift
//  Virtual-Tourist
//
//  Created by kavita patel on 5/1/16.
//  Copyright © 2016 kavita patel. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit

class LocationClass: AnyObject
{
    static let sharedInstance = LocationClass()
    var locations: [NSManagedObject]
    private init()
    {
        locations = [NSManagedObject]()
    }
    
    //coreData: delete location
    func deleteLocation(lati: Double, long: Double, completion: (error: String)-> Void)
    {
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
                    if newCoordination.latitude == lati && newCoordination.longitude == long
                    {
                        context.deleteObject(pin)
                        do{
                            try context.save()
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
    
    //coreData: save location
    func saveLocation(loc: CLLocationCoordinate2D, span: MKCoordinateSpan, completion: (error: String)-> Void)
    {
        let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appdelegate.managedObjectContext
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        let location = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: context)
        location.setValue(loc.latitude, forKey: "latitude")
        location.setValue(loc.longitude, forKey: "longitude")
        location.setValue(span.latitudeDelta, forKey: "latitudeDelta")
        location.setValue(span.longitudeDelta, forKey: "longitudeDelta")
        do{
            try context.save()
            completion(error: "")
        }catch
        {
            completion(error: "Can not Save Location")
        }
        
        
    }
    
    //coreData: get location
    func getLocation(completion: (locations: [NSManagedObject] ,error: String)-> Void)
    {
        do{
            let appdelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let context = appdelegate.managedObjectContext
            let request = NSFetchRequest(entityName: "Pin")
            let result = try context.executeFetchRequest(request)
            locations = result as! [NSManagedObject]
            completion(locations: locations, error: "")
        }catch
        {
            completion(locations: locations, error: "Can not Load Locations")
        }
    }
}
