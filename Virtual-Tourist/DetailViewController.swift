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
    var imageArray:[UIImage] = [UIImage]()
    let flickrObj = FlickrApi()
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    let refreshControl = UIRefreshControl()
    var cache: NSCache?
    var cachedImagesIndex = [String]()
    var managedObjectContext: NSManagedObjectContext!
    
    //Fetch record
    lazy var fetchedResultsController: NSFetchedResultsController = {
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
        let lati = annotation.coordinate.latitude as NSNumber
        let long = annotation.coordinate.longitude as NSNumber
        let predicate = NSPredicate(format: "pin.latitude == %@ AND pin.longitude == %@", lati, long) as NSPredicate
        self.fetchedResultsController.fetchRequest.predicate = predicate
            do
            {
                    try self.fetchedResultsController.performFetch()
                    newCollectionBtn.enabled = true
                    self.photoCollectionView.reloadData()
            }
            catch
            {
                    let fetchError = error as NSError
                     newCollectionBtn.enabled = false
                    print("\(fetchError), \(fetchError.userInfo)")
            }
        mapView.addAnnotation(annotation)
        coordinate = annotation.coordinate
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
        self.configureCell(cell, atIndexPath: indexPath) { (cell) in
            return cell
        }
        showActivityInd(false)
        return cell
    }
    func configureCell(cell: imageCellCollectionViewCell, atIndexPath indexPath: NSIndexPath, completion: (cell: imageCellCollectionViewCell)-> Void)
    {
        // Fetch Record
        let record = fetchedResultsController.objectAtIndexPath(indexPath)
        
        // Update Cell
            if let imgName = record.valueForKey("imagesData") as? String
            {
                let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                let fileURL = documentsURL.URLByAppendingPathComponent(imgName)
                let img = UIImage(contentsOfFile: fileURL.path!)
                    cell.albumImage.image = img
                    completion(cell: cell)
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
            let record = fetchedResultsController.objectAtIndexPath(indexPath)
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
            let record = fetchedResultsController.objectAtIndexPath(indexPath)
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
       //return Images.imagesInstance.imageList.count
        if let sections = fetchedResultsController.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        
        return 0
        
    }
    
    @IBAction func newCollectionBtnPressed(sender: AnyObject)
    {
        showActivityInd(true)
        newCollectionBtn.enabled = false
        cache?.removeAllObjects()
        //remove old images
        removeAllImages()
        //first set new pageno than get images
        setNewPage()
        MapController.instance.getFlickrData(coordinate,context: managedObjectContext) { (error) in
            if error == ""
            {
                self.photoCollectionView.reloadData()
                self.newCollectionBtn.enabled = true
            }
            else
            {
                self.newCollectionBtn.enabled = false
            }
        }
    }

    @IBAction func removePictureBtnPressed(sender: AnyObject)
    {
            let fileManager:NSFileManager = NSFileManager.defaultManager()
            let request = NSFetchRequest(entityName: "Images")
            let lati = coordinate.latitude as NSNumber
            let long = coordinate.longitude as NSNumber
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
                                    print( "Can not remove from document directory")
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
    func removeAllImages()
    {
        let fileManager:NSFileManager = NSFileManager.defaultManager()
        let request = NSFetchRequest(entityName: "Images")
        let lati = coordinate.latitude as NSNumber
        let long = coordinate.longitude as NSNumber
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
                                print( "Can not remove from document directory")
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
        MapController.instance.pageno = MapController.instance.pageno + 1
        let lati = coordinate.latitude as NSNumber
        let long = coordinate.longitude as NSNumber
        let pageRequest = NSFetchRequest(entityName: "Pin")
        pageRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", lati, long)
        
        //Get Page no of current location URL
        do{
            let pages = try managedObjectContext.executeFetchRequest(pageRequest)
            for page_no in pages
            {
                page_no.setValue(MapController.instance.pageno, forKey: "page")
            }
        }
        catch
        {
            print( "Can not set new page")
        }
    }

    func mapViewDidFinishLoadingMap(mapView: MKMapView)
    {
        showActivityInd(false)
    }
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
     
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
