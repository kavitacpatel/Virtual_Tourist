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
    var pointAnnotation = MKPointAnnotation()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        gestureRecognize.minimumPressDuration = 1.0
        showActivityInd(true)
    }
    override func viewDidAppear(animated: Bool)
    {
        editBtn.title = "Edit"
        
        getLocation()
    }
    func getLocation()
    {
        var span = MKCoordinateSpan()
        Pin.pinInstance.getLocation { (locations, error) in
            if error != ""
            {
                self.alertMsg("Location Error", msg: error)
            }
            else
            {
                for location in locations
                {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate.latitude = location.valueForKey("latitude") as! CLLocationDegrees
                    annotation.coordinate.longitude = location.valueForKey("longitude") as! CLLocationDegrees
                    self.pointAnnotation.coordinate.latitude = annotation.coordinate.latitude
                    self.pointAnnotation.coordinate.longitude = annotation.coordinate.longitude
                    span.latitudeDelta = location.valueForKey("latitudeDelta") as! CLLocationDegrees
                    span.longitudeDelta = location.valueForKey("longitudeDelta") as! CLLocationDegrees
                    self.mapView.addAnnotation(annotation)
                }
                if locations.count > 0
                {
                // the map should return to the same state when it is turned on again
                  self.mapView.region.span = span
                  let region: MKCoordinateRegion = MKCoordinateRegionMake(self.pointAnnotation.coordinate, span)
                  self.mapView.region = region
                }
            }
        }
        
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
          Pin.pinInstance.deleteLocation(newcoordinate, completion: { (error) in
            if error != ""
            {
                self.alertMsg("Delete Location", msg: error)
            }
            else
            {
                self.alertMsg("Delete Location", msg: "Location is Deleted")
            }
        })
        }
        else
        {
            pointAnnotation.coordinate = newcoordinate
            performSegueWithIdentifier("detailSegue", sender: self)
        }
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        let secondVC: DetailViewController = segue.destinationViewController as! DetailViewController
        secondVC.annotation = pointAnnotation
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
      if sender.state == UIGestureRecognizerState.Ended
      {
         let touchPoint = gestureRecognize.locationInView(mapView)
         let points = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
         let coordinate = CLLocationCoordinate2D(latitude: points.latitude, longitude: points.longitude)
         let annotation = MKPointAnnotation()
         var mapSpan = MKCoordinateSpan()
         annotation.coordinate = coordinate
         mapView.addAnnotation(annotation)
         mapSpan = mapView.region.span
         // get data of dropped pin location
         let flickrObj = FlickrApi()
        flickrObj.getFlickrData(1, coordinate: coordinate,span: mapSpan, completion: { (error) in
            if error != ""
            {
                self.alertMsg("Error: SaveImages", msg: error!)
            }
        })
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

