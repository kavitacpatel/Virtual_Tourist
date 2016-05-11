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

class DetailViewController: UIViewController , MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{

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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        photoCollectionView.allowsMultipleSelection = true
        showActivityInd(true)
        screenSize = UIScreen.mainScreen().bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        refreshControl.addTarget(self, action: #selector(DetailViewController.refreshController), forControlEvents: .ValueChanged)
        photoCollectionView.addSubview(refreshControl)
       photoCollectionView.sendSubviewToBack(refreshControl)
        cache = NSCache()
    }
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        mapView.addAnnotation(annotation)
        coordinate = annotation.coordinate
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 4000, 4000)
        self.mapView.setRegion(region, animated: true)
        newCollectionBtn.enabled = false
        //Clear cachedindex
        Images.imagesInstance.cachedImagesIndex.removeAll()
        //Get images of location from coreData
        self.refreshController()
        
    }
    func refreshController()
    {
        Images.imagesInstance.getImages(coordinate.latitude,long: coordinate.longitude) { (error) in
            dispatch_async(dispatch_get_main_queue())
            {
                if error != ""
                {
                    self.alertMsg("Error: Images", msg: error)
                }
                else
                {
                    if Images.imagesInstance.imageList.count == 0
                    {
                        self.newCollectionBtn.enabled = false
                    }
                    else
                    {
                        self.newCollectionBtn.enabled = true
                    }
                self.showActivityInd(false)
                self.photoCollectionView.reloadData()
                self.refreshControl.endRefreshing()
                }
            }
            
        }

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
        cell.albumImage?.image = UIImage(named: "placeholder")
        if (self.cache?.objectForKey(indexPath.row) != nil){
            cell.albumImage?.image = self.cache?.objectForKey(indexPath.row) as? UIImage
        }
        else{
           if Images.imagesInstance.imageList.count != 0
           {
                if let imageName = Images.imagesInstance.imageList[indexPath.row].valueForKey("imagesData") as? String
                {
                    let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                    let fileURL = documentsURL.URLByAppendingPathComponent(imageName)
                    let img = UIImage(contentsOfFile: fileURL.path!)
                    cell.albumImage.image = img
                }
            }
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath)
        {
         cell.alpha = 0.3
         // show Remove Selected Pictures button
         removePicture.hidden = false
         newCollectionBtn.hidden = true
         Images.imagesInstance.cachedImagesIndex.append(indexPath.row)
        }
    }
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
    {
        //remove deselected images from cached images
        if let cell = collectionView.cellForItemAtIndexPath(indexPath)
        {
            cell.alpha = 1.0
            let cnt = Images.imagesInstance.cachedImagesIndex.count - 1
            for index in 0...cnt
            {
                if index < Images.imagesInstance.cachedImagesIndex.count
                {
                    if Images.imagesInstance.cachedImagesIndex[index] == indexPath.row
                    {
                        Images.imagesInstance.cachedImagesIndex.removeAtIndex(index)
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
       return Images.imagesInstance.imageList.count
    }
    @IBAction func removePictureBtnPressed(sender: AnyObject)
    {
        Images.imagesInstance.removeSelectedImages(coordinate.latitude, long: coordinate.longitude)
        Images.imagesInstance.getImages(coordinate.latitude, long: coordinate.longitude, completion: { (error) in
         if error != ""
            {
                self.alertMsg("Error: Photos", msg: error)
            }
        })
        // Hide Remove Selected Pictures button
        removePicture.hidden = true
        newCollectionBtn.hidden = false
        photoCollectionView.reloadData()
    }
    @IBAction func newCollectionBtnPressed(sender: AnyObject)
    {
        showActivityInd(true)
        newCollectionBtn.enabled = false
        getNewPhotos()
        
    }
    
    func getNewPhotos()
    {
        cache?.removeAllObjects()
        self.flickrObj.updateImages(self.coordinate) { (error) in
           dispatch_async(dispatch_get_main_queue(), self.refreshController)
        }
    }

    func mapViewDidFinishLoadingMap(mapView: MKMapView)
    {
        showActivityInd(false)
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
