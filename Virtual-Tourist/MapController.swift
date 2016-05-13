//
//  ViewController.swift
//  Virtual-Tourist
//
//  Created by kavita patel on 4/29/16.
//  Copyright © 2016 kavita patel. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapController: UIViewController, MKMapViewDelegate
{
    @IBOutlet var gestureRecognize: UILongPressGestureRecognizer!
    @IBOutlet weak var activityInd: UIActivityIndicatorView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editBtn: UIBarButtonItem!
    @IBOutlet weak var deleteLbl: UILabel!
    var editState = false
    static var instance = MapController()
    var pageno: Int = 1
    var pointAnnotation = MKPointAnnotation()
    var managedObjectContext: NSManagedObjectContext!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        print(managedObjectContext)
        gestureRecognize.minimumPressDuration = 1.0
        showActivityInd(true)
    }
    override func viewDidAppear(animated: Bool)
    {
        editBtn.title = "Edit"
        if mapView.annotations.count != 0
        {
            let ex = mapView.annotations
            mapView.removeAnnotations(ex)
        }
        getLocation()
    }
    func mapViewDidFailLoadingMap(mapView: MKMapView, withError error: NSError)
    {
        showActivityInd(false)
        alertMsg("Network Error", msg: "Can not Load Map")
    }
    func mapViewDidFinishLoadingMap(mapView: MKMapView)
    {
        showActivityInd(false)
    }
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        
        let newcoordinate = CLLocationCoordinate2D(latitude: (view.annotation?.coordinate.latitude)!, longitude: (view.annotation?.coordinate.longitude)!)
        if editState
        {
            //Delete selected pin
           self.mapView.removeAnnotation(view.annotation!)
           // Delete from Coredata
            removeImages(newcoordinate.latitude, long: newcoordinate.longitude)
            deleteLocation(newcoordinate)
        }
        else
        {
            getPageofSelectedPin(newcoordinate.latitude, long: newcoordinate.longitude)
            self.pointAnnotation.coordinate = newcoordinate
            self.performSegueWithIdentifier("detailSegue", sender: self)
        }
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        let secondVC: DetailViewController = segue.destinationViewController as! DetailViewController
        secondVC.annotation = pointAnnotation
        secondVC.managedObjectContext = managedObjectContext
    }
    @IBAction func editBtnPressed(sender: AnyObject)
    {
        if editBtn.title == "Edit"
        {
            editState = true
            showLabel(false)
        }
        else
        {
            editState = false
            showLabel(true)
        }
    }
    
    @IBAction func addPinWithGesture(sender: UILongPressGestureRecognizer)
    {
      if gestureRecognize.state == .Began
      {
         let touchPoint = gestureRecognize.locationInView(mapView)
         let points = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
         let coordinate = CLLocationCoordinate2D(latitude: points.latitude, longitude: points.longitude)
         let annotation = MKPointAnnotation()
         var mapSpan = MKCoordinateSpan()
         annotation.coordinate = coordinate
         mapView.addAnnotation(annotation)
         mapSpan = mapView.region.span
         saveLocation(coordinate, span: mapSpan)
         getFlickrData(coordinate,context: managedObjectContext, completion: { (error) in
            if error != ""
            {
                self.alertMsg("Error: SaveImages", msg: error)
            }
            self.showActivityInd(false)
         })
      }
    }
    func getFlickrData(coordinate: CLLocationCoordinate2D,context: NSManagedObjectContext,completion: (error: String)-> Void)
    {
        // get data of dropped pin location
        let flickrObj = FlickrApi()
        flickrObj.getFlickrData(pageno, coordinate: coordinate, completion: { (photoDict, error) in
            dispatch_async(dispatch_get_main_queue())
            {
                if photoDict != nil
                {
                    //get photos
                    for photo in photoDict!
                    {
                        let farmId = photo.valueForKey("farm") as! NSNumber
                        let serverId = photo.valueForKey("server") as! String
                        let photoId = photo.valueForKey("id") as! String
                        let secret = photo.valueForKey("secret") as! String
                        
                        //Get Flickr Images
                        self.getFlickrImage(farmId, serverid: serverId, photoid: photoId, secret: secret, coordinate: coordinate, context: context)
                        completion(error: "")
                    }
                }
                else
                {
                    self.alertMsg("Error: SaveImages", msg: "Can not save images")
                    
                }
            }
        })
        
    }
    func getFlickrImage(farmid: NSNumber, serverid: String,photoid: String, secret: String ,coordinate: CLLocationCoordinate2D,context: NSManagedObjectContext)
    {
        let size = "z"
        let photoURL = "https://farm\(farmid).staticflickr.com/\(serverid)/\(photoid)_\(secret)_\(size).jpg"
        if let url = NSURL(string: photoURL)
        {
            // Download Image
            if let data = NSData(contentsOfURL: url)
            {
                //Save Photos to CoreData
                let img = UIImage(data: data)
                dispatch_async(dispatch_get_main_queue())
                {
                    self.saveImages(coordinate,context: context, img: img!, imgName: photoid)
                }
            }
            else
            {
                self.alertMsg("Loading Images", msg:"Error in Loading Photos")
            }
        }
        else
        {
                self.alertMsg("Loading Images", msg:"Error in URL")
        }
    }
    func saveImages(coordinate:CLLocationCoordinate2D,context: NSManagedObjectContext,img: UIImage, imgName : String)
    {
        let lati = coordinate.latitude as NSNumber
        let long = coordinate.longitude as NSNumber
        let request = NSFetchRequest(entityName: "Pin")
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
                    let result = pngImageData!.writeToFile(fileURL.path!, atomically: true)
                    if result
                    {
                        imagesEntity.setValue("img\(imgName).png", forKey: "imagesData")
                        pin.addImageObject(imagesEntity)
                        imagesEntity.pin = pin
                        dispatch_async(dispatch_get_main_queue())
                        {
                            do
                            {
                                try context.save()
                            }
                            catch
                            {
                                print("Can not Save Images")
                            }
                        }
                    }
                    else
                    {
                        print( "Can not save images to document directory")
                    }
                }
            }
        }
        catch
        {
            print( "Can not Save Images")
        }
    }

    func removeImages(lati: NSNumber, long: NSNumber)
    {
        //cascade relationship automatically delete images from table
        //only delete fron document directory
        let fileManager:NSFileManager = NSFileManager.defaultManager()
        let request = NSFetchRequest(entityName: "Images")
        request.predicate = NSPredicate(format: "pin.latitude == %@ AND pin.longitude == %@", lati ,long)
        do
        {
            if let imageList = try managedObjectContext?.executeFetchRequest(request)
            {
                for img in imageList
                {
                    //remove path from coredata
                    do{
                        //remove from directory
                        let imageName = img.valueForKey("imagesData")as! String
                        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                        let fileURL = documentsURL.URLByAppendingPathComponent(imageName)
                        try fileManager.removeItemAtPath(fileURL.path!)
                    }
                    catch
                    {
                        print( "Can not remove from document directory")
                    }
              }

            }
        }
        catch
        {
            print( "Can not fetch image for deletion")
        }
    }
    func getPageofSelectedPin(lati: NSNumber, long: NSNumber)
    {
        let request = NSFetchRequest(entityName: "Pin")
        request.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", lati, long)
            do{
                let results = try managedObjectContext.executeFetchRequest(request)
                let locations = results as! [NSManagedObject]
                for location in locations
                {
                    pageno = location.valueForKey("page") as! Int
                }
            }
            catch
            {
                print("Can not Load Locations")
            }
    }
    
    func getLocation()
    {
        let request = NSFetchRequest(entityName: "Pin")
        do{
            let results = try managedObjectContext.executeFetchRequest(request)
            let locations = results as! [NSManagedObject]
            for location in locations
            {
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = location.valueForKey("latitude") as! CLLocationDegrees
                annotation.coordinate.longitude = location.valueForKey("longitude") as! CLLocationDegrees
                self.pointAnnotation.coordinate.latitude = annotation.coordinate.latitude
                self.pointAnnotation.coordinate.longitude = annotation.coordinate.longitude
                let span = MKCoordinateSpanMake(location.valueForKey("latitudeDelta") as! CLLocationDegrees, location.valueForKey("longitudeDelta") as! CLLocationDegrees)
                self.mapView.addAnnotation(annotation)
                let region = MKCoordinateRegionMake(self.pointAnnotation.coordinate, span)
                // the map should return to the same state when it is turned on again
                self.mapView.region = region
            }
            
        }
        catch
        {
            print("Can not Load Locations")
        }
        
    }

    func saveLocation(loc: CLLocationCoordinate2D, span: MKCoordinateSpan?)
    {
        let lati = loc.latitude as NSNumber
        let long = loc.longitude as NSNumber
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: managedObjectContext)
        let request = NSFetchRequest(entityName: "Pin")
        request.predicate = NSPredicate(format: "latitude = %@ AND longitude = %@", loc.latitude, loc.longitude)
        let location = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
        do{
            let results = try managedObjectContext.executeFetchRequest(request)
            if results.count == 0
            {
                //if location is not saved than save it
                
                location.setValue(lati , forKey: "latitude")
                location.setValue(long, forKey: "longitude")
                location.setValue(span!.latitudeDelta, forKey: "latitudeDelta")
                location.setValue(span!.longitudeDelta, forKey: "longitudeDelta")
                //initially set page to no 1 to get images
                location.setValue(1, forKey: "page")
                do{
                    
                    try managedObjectContext.save()
                }
                catch
                {
                    print("Can not Save Location")
                }
            }
          }
        catch
        {
            print( "Can not Save Location")
        }
    }
    func deleteLocation(loc: CLLocationCoordinate2D)
    {
        let request = NSFetchRequest(entityName: "Pin")
        do{
            let pinList = try managedObjectContext.executeFetchRequest(request) as! [NSManagedObject]
            if pinList.count > 0
            {
                for pin in pinList
                {
                    let newCoordination = CLLocationCoordinate2D(latitude: pin.valueForKey("latitude") as! CLLocationDegrees, longitude: pin.valueForKey("longitude") as! CLLocationDegrees)
                    if newCoordination.latitude == loc.latitude && newCoordination.longitude == loc.longitude
                    {
                        do{
                            managedObjectContext.deleteObject(pin)
                            try managedObjectContext.save()
                            print("location is deleted")
                            return
                        }
                        catch
                        {
                            print("Deletion is not Completed")
                        }
                    }
                }
            }
            else
            {
                print("Can not Find Location")
            }
        }
        catch
        {
            print("Can Not Fetch Location")
        }

    }
    func alertMsg(title: String, msg: String)
    {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        showActivityInd(false)
    }

    func showLabel(show: Bool)
    {
        if show
        {
            deleteLbl.hidden = true
            editBtn.title = "Edit"
        }
        else
        {
            deleteLbl.hidden = false
            editBtn.title = "Done"
        }
    }
    
    func showActivityInd(show: Bool)
    {
        activityInd.hidden = !show
        if show
        {
            activityInd.startAnimating()
        }
        else
        {
            activityInd.stopAnimating()
        }
    }
}

