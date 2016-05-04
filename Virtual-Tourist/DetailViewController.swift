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
    var page: Int = 1
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    
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
    }
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        mapView.addAnnotation(annotation)
        coordinate = annotation.coordinate
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 4000, 4000)
        self.mapView.setRegion(region, animated: true)
        newCollectionBtn.enabled = false
        getPhotos(page)
        photoCollectionView.reloadData()
    }
    func getPhotos(pageno: Int)
    {
        flickrObj.getFlickrData(pageno, coordinate: coordinate) { (error) in
            dispatch_async(dispatch_get_main_queue())
            {
            if error != ""
            {
                self.alertMsg("Error", msg: error!)
                self.newCollectionBtn.enabled = false
            }
            else
            {
                FlickrPhotos.sharedInstance.getImages { (error) in
                    if error != ""
                    {
                        self.alertMsg("Error: CoreData", msg: error)
                    }
                }
                self.newCollectionBtn.enabled = true
                self.showActivityInd(false)
                self.photoCollectionView.reloadData()
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
        cell.backgroundColor = UIColor.whiteColor()
        if FlickrPhotos.sharedInstance.List.count > 0
        {
            let image = FlickrPhotos.sharedInstance.List[indexPath.row].valueForKey("imagesData") as! NSData
           cell.albumImage.image = UIImage(data: image)
        }
        else
        {
            alertMsg("Photo Album", msg: "No Photos")
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
         FlickrPhotos.sharedInstance.cachedImagesIndex.append(indexPath.row)
        }
    }
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
    {
        //remove deselected images from cached images
        if let cell = collectionView.cellForItemAtIndexPath(indexPath)
        {
            cell.alpha = 1.0
            let cnt = FlickrPhotos.sharedInstance.cachedImagesIndex.count
            for index in 0...cnt
            {
                if FlickrPhotos.sharedInstance.cachedImagesIndex.count < index
                {
                    if FlickrPhotos.sharedInstance.cachedImagesIndex[index] == indexPath.row
                    {
                        FlickrPhotos.sharedInstance.cachedImagesIndex.removeAtIndex(index)
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
       return FlickrPhotos.sharedInstance.List.count
    }
    @IBAction func removePictureBtnPressed(sender: AnyObject)
    {
     FlickrPhotos.sharedInstance.removeSelectedImages
        { (error) in
            if error != ""
            {
                self.alertMsg("Error: Deletion", msg: error)
            }
        }
        FlickrPhotos.sharedInstance.getImages { (error) in
            if error != ""
            {
                self.alertMsg("Error: Photos", msg: error)
            }
        }
        // Hide Remove Selected Pictures button
        removePicture.hidden = true
        newCollectionBtn.hidden = false
        photoCollectionView.reloadData()
    }
    @IBAction func newCollectionBtnPressed(sender: AnyObject)
    {
        page = page + 1
        getPhotos(page)
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
