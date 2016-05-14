//
//  DetailViewController.swift
//  Virtual-Tourist
//
//  Created by kavita patel on 4/29/16.
//  Copyright © 2016 kavita patel. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class DetailViewController: UIViewController , MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate{

    @IBOutlet weak var removePicture: UIButton!
    @IBOutlet weak var newCollectionBtn: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var activityInd: UIActivityIndicatorView!
    var annotation = MKPointAnnotation()
    var coordinate = CLLocationCoordinate2D()
    var lati : NSNumber = 0.0
    var long: NSNumber = 0.0
    var currentPageNo: Int = 1
    // if location is loading first time than download images from API
    var currentPinFlag = false
    var imageArray:[UIImage] = [UIImage]()
    let flickrObj = FlickrApi()
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    let refreshControl = UIRefreshControl()
    var cache: NSCache?
    var cachedImagesIndex = [String]()
    var managedObjectContext: NSManagedObjectContext!
    var photoDictionary = [AnyObject]()
    var updateStatus = false
    var numberOfCell = 10
    
    //Fetch record
    lazy var fetchedResultsController: NSFetchedResultsController? = {
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Images")
        // Add Sort Descriptors
        let sortDescriptor = NSSortDescriptor(key: "imagesData", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Initialize Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    override func viewDidLoad()
    {
        super.viewDidLoad()
        coordinate = annotation.coordinate
        lati = annotation.coordinate.latitude as NSNumber
        long = annotation.coordinate.longitude as NSNumber
        print(currentPinFlag)
        if currentPinFlag
        {
            // location is coming first time, download images from api
            updateStatus = true
            getFlickrData()
        }

        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        photoCollectionView.allowsMultipleSelection = true
        photoCollectionView.alwaysBounceVertical = true
        showActivityInd(true)
        screenSize = UIScreen.mainScreen().bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        cache = NSCache()
    }
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        coordinate = annotation.coordinate
        lati = annotation.coordinate.latitude as NSNumber
        long = annotation.coordinate.longitude as NSNumber
        // already images are dowanloaded, fetch from coredata
    
            let predicate = NSPredicate(format: "pin.latitude == %@ AND pin.longitude == %@", lati, long) as NSPredicate
            self.fetchedResultsController!.fetchRequest.predicate = predicate
            do
            {
                    try self.fetchedResultsController!.performFetch()
                    newCollectionBtn.enabled = true
                    //self.photoCollectionView.reloadData()
            }
            catch
            {
                    let fetchError = error as NSError
                     newCollectionBtn.enabled = false
                    print("\(fetchError), \(fetchError.userInfo)")
            }
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 4000, 4000)
        self.mapView.setRegion(region, animated: true)
        //Clear cachedindex
        cachedImagesIndex.removeAll()

    }
    
    //To reduce cell gaps
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return CGSize(width: (collectionView.frame.size.width - 3)/3, height: 110)
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return 1
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCell", forIndexPath: indexPath) as! imageCellCollectionViewCell
        cell.backgroundColor = UIColor.blackColor()
        cell.albumImage.image = UIImage(named: "placeholder")
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    func configureCell(cell: imageCellCollectionViewCell, atIndexPath indexPath: NSIndexPath)
    {
        
        if updateStatus
        {
           if photoDictionary.count != 0
           {
            getFlickrImage(photoDictionary[indexPath.row].valueForKey("farm") as! Int, serverid: photoDictionary[indexPath.row].valueForKey("server") as! String, photoid: photoDictionary[indexPath.row].valueForKey("id") as! String, secret: photoDictionary[indexPath.row].valueForKey("secret") as! String ,completion: { (img) in
                dispatch_async(dispatch_get_main_queue())
                {
                      cell.albumImage.image = img
                }
                if indexPath.row == self.photoDictionary.count-1
                {
                    self.updateStatus = false
                    self.showActivityInd(false)
                }
            })
        }
        }
        else
        {
            // Fetch Record
            if fetchedResultsController?.objectAtIndexPath(indexPath).count != 0
            {
                if let record: NSManagedObject? = self.fetchedResultsController!.objectAtIndexPath(indexPath) as? NSManagedObject
                {
                    if let imgName = record!.valueForKey("imagesData") as? String
                    {
                        self.newCollectionBtn.enabled = true
                        self.showActivityInd(false)
                        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                        let fileURL = documentsURL.URLByAppendingPathComponent(imgName)
                        dispatch_async(dispatch_get_main_queue())
                        {
                            let img = UIImage(contentsOfFile: fileURL.path!)
                            cell.albumImage.image = img
                        }
                    }
                }
            }
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath)
        {
         cell.alpha = 0.3
         // show Remove Selected Pictures button
         removePicture.hidden = false
         newCollectionBtn.hidden = true
            let record = fetchedResultsController!.objectAtIndexPath(indexPath)
            if let imgName = record.valueForKey("imagesData") as? String
            {
               cachedImagesIndex.append(imgName)
            }
        }
    }
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
    {
        //remove deselected images from cached images
        if let cell = collectionView.cellForItemAtIndexPath(indexPath)
        {
            cell.alpha = 1.0
            let cnt = cachedImagesIndex.count - 1
            let record = fetchedResultsController!.objectAtIndexPath(indexPath)
            let imgName = record.valueForKey("imagesData") as? String
            for index in 0...cnt
            {
                if index < cachedImagesIndex.count
                {
                    if cachedImagesIndex[index] == imgName
                    {
                        cachedImagesIndex.removeAtIndex(index)
                    }
                }
            }
        }
    }
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
      /*  if photoDictionary.count != 0
        {
            return self.photoDictionary.count
        }
        else
        {
            if let sections = fetchedResultsController!.sections
            {
                let sectionInfo = sections[section]
                return sectionInfo.numberOfObjects
            }
        }*/
        return numberOfCell
    }
    
    @IBAction func newCollectionBtnPressed(sender: AnyObject)
    {
        showActivityInd(true)
        cache?.removeAllObjects()
        photoDictionary.removeAll()
        //remove old images
        removeAllImages()
        getFlickrData()
        self.updateStatus = true
    }
    
    func getFlickrData()
    {
        
         // set page if called new button or set flag after first time location downloaded
        currentPageNo = currentPageNo + 1
         setNewPage()
        // get data of dropped pin location
        let flickrObj = FlickrApi()
        flickrObj.getFlickrData(currentPageNo, coordinate: coordinate, completion: { (photoDict, error) in
            if photoDict != nil
                {
                    dispatch_async(dispatch_get_main_queue())
                    {
                            self.photoDictionary = photoDict! as [AnyObject]
                           if self.photoDictionary.count == 0
                           {
                             self.newCollectionBtn.enabled = false
                             self.showActivityInd(false)
                           }
                        self.numberOfCell = self.photoDictionary.count
                            self.photoCollectionView.reloadData()
                    }
                }
                else
                {
                    self.alertMsg("Error: SaveImages", msg: "Can not save images")
                    self.newCollectionBtn.enabled = false
                }
        })
       
    }
    func getFlickrImage(farmid: NSNumber, serverid: String,photoid: String, secret: String,completion:(img: UIImage?)-> Void)
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
                        self.saveImages(img!, imgName: photoid, completion: { (error) in
                        if error != ""
                        {
                            print(error)
                        }
                        else{
                            completion(img: img!)
                        }
                    })
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
    func saveImages(img: UIImage, imgName : String,completion:(error: String?) -> Void)
    {
        let request = NSFetchRequest(entityName: "Pin")
        request.predicate = NSPredicate(format: "latitude = %@ AND longitude = %@", lati, long)
        do{
            let results = try managedObjectContext.executeFetchRequest(request)
            if results.count > 0
            {
                for result in results
                {
                    let pin = result as! Pin
                    let imagesEntity = NSEntityDescription.insertNewObjectForEntityForName("Images", inManagedObjectContext: managedObjectContext) as! Images
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
                                try self.managedObjectContext.save()
                                completion(error: "")
                            }
                            catch
                            {
                                completion(error: "Can not Save Images")
                            }
                        }
                    }
                    else
                    {
                        completion(error: "Can not save images to document directory")
                    }
                }
            }
        }
        catch
        {
            completion(error: "Can not Save Images")
        }
    }
    func removeAllImages()
    {
        let fileManager:NSFileManager = NSFileManager.defaultManager()
        let request = NSFetchRequest(entityName: "Images")
        request.predicate = NSPredicate(format: "pin.latitude == %@ AND pin.longitude == %@", lati, long)
        do{
            let imageList = try managedObjectContext.executeFetchRequest(request) as! [NSManagedObject]
            for img in imageList
            {
                do{
                    //remove from directory
                    let imageName = img.valueForKey("imagesData")as! String
                    let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                    let fileURL = documentsURL.URLByAppendingPathComponent(imageName)
                    try fileManager.removeItemAtPath(fileURL.path!)
                }
                catch
                {
                    //print( "Can not remove from document directory")
                }
                do
                {
                    managedObjectContext.deleteObject(img)
                    try managedObjectContext.save()
                    //first set new pageno than get images
                    
                }
                catch
                {
                    print( "Photo Deletion Error")
                }
            }
        }
        catch
        {
            cachedImagesIndex.removeAll()
            print( "Photo is Not Deleted")
        }
       
    }
    //remove selected images
    @IBAction func removePictureBtnPressed(sender: AnyObject)
    {
        let fileManager:NSFileManager = NSFileManager.defaultManager()
        let request = NSFetchRequest(entityName: "Images")
        request.predicate = NSPredicate(format: "pin.latitude == %@ AND pin.longitude == %@", lati, long)
        do{
            let imageList = try managedObjectContext.executeFetchRequest(request) as! [NSManagedObject]
            if cachedImagesIndex.count > 0
            {
                for index in 0...cachedImagesIndex.count-1
                {
                    for img in imageList
                    {
                        if cachedImagesIndex[index] == img.valueForKey("imagesData") as! String
                        {
                            do{
                                //remove from directory
                                let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                                let fileURL = documentsURL.URLByAppendingPathComponent(cachedImagesIndex[index])
                                try fileManager.removeItemAtPath(fileURL.path!)
                            }
                            catch
                            {
                                //print( "Can not remove from document directory")
                            }
                            do
                            {
                                managedObjectContext.deleteObject(img)
                                try managedObjectContext.save()
                            }
                            catch
                            {
                                print( "Photo Deletion Error")
                            }
                        }
                    }
                }
            }
        }
        catch
        {
            cachedImagesIndex.removeAll()
            print( "Photo is Not Deleted")
        }
        removePicture.hidden = true
        newCollectionBtn.hidden = false
        photoCollectionView.reloadData()
    }

    func setNewPage()
    {
        let pageRequest = NSFetchRequest(entityName: "Pin")
        pageRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", lati, long)
        
        //Get Page no of current location URL
        do{
            let pages = try managedObjectContext.executeFetchRequest(pageRequest)
            for page_no in pages
            {
                page_no.setValue(currentPageNo, forKey: "page")
                page_no.setValue(false, forKey: "firstTimeFlag")
            }
        }
        catch
        {
            print( "Can not set new page")
        }
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        photoCollectionView.reloadData()
    }
    
    func alertMsg(title: String, msg: String)
    {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        showActivityInd(false)
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
