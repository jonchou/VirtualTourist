//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Jonathan Chou on 12/11/15.
//  Copyright © 2015 Jonathan Chou. All rights reserved.
//

import CoreData
import UIKit
import MapKit

class TravelLocationMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    private var editMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try fetchedResultsController.performFetch()
        } catch {}
    
        // restore state
        restoreMap()
        restorePins()
        enableGesture()
        mapView.delegate = self
    }
    
    func restorePins() {
        let pinArray = fetchedResultsController.fetchedObjects as! [Pin]
        for pin in pinArray {
            mapView.addAnnotation(pin)
        }
    }
    
    // MARK: - Core Data Convenience.

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        fetchedResultsController.delegate = self
        return fetchedResultsController
        
        }()
    
    func addPin(sender: UIGestureRecognizer) {
        let point = sender.locationInView(mapView)
        let coordinates = mapView.convertPoint(point, toCoordinateFromView: mapView)
        
        // beginning of gesture recognition
        if sender.state == UIGestureRecognizerState.Began {

            let dictionary: [String: AnyObject] = [
                Pin.Keys.Latitude : coordinates.latitude,
                Pin.Keys.Longitude : coordinates.longitude,
            ]
            
            let newPin = Pin(dictionary: dictionary, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            FlickrClient.sharedInstance().searchImagesByLatLon(newPin)
        }
        
    }
    
    func restoreMap() {
        if let savedMap = NSUserDefaults.standardUserDefaults().objectForKey("mapData") as? [String: AnyObject] {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2DMake(savedMap["latitude"] as! CLLocationDegrees,
                                                   savedMap["longitude"] as! CLLocationDegrees),
                // multiplying by this constant allows the span to stop growing larger and larger with each run
                span: MKCoordinateSpanMake((savedMap["latDelta"] as! CLLocationDegrees) * 0.882,
                                           (savedMap["longDelta"] as! CLLocationDegrees) * 0.882)
            )
            mapView.setRegion(region, animated: false)
        }
    }

    func saveMap() {
        let map: [String: AnyObject] = [
            "latitude": mapView.region.center.latitude,
            "longitude": mapView.region.center.longitude,
            "latDelta": mapView.region.span.latitudeDelta,
            "longDelta": mapView.region.span.longitudeDelta
        ]
        NSUserDefaults.standardUserDefaults().setObject(map, forKey: "mapData")
    }
    
    @IBAction func beginEditMode(sender: AnyObject) {
        if editMode {
            editMode = false
            editButton.title = "Edit"
            // remove "Tap pins to delete"
            view.frame.origin.y += 50
            // reenable gesture recognizer
            enableGesture()

        } else {
          // if we touch Edit
            editMode = true
            editButton.title = "Done"
            // raise "Tap pins to delete"
            view.frame.origin.y -= 50
            disableGesture()
        }
        
    }
    
    func enableGesture() {
        let pinDropGesture = UILongPressGestureRecognizer(target: self, action: "addPin:")
        mapView.addGestureRecognizer(pinDropGesture)
    }
    
    func disableGesture() {
        if mapView.gestureRecognizers != nil {
            for gesture in mapView.gestureRecognizers! {
                if let recognizer = gesture as? UILongPressGestureRecognizer {
                    mapView.removeGestureRecognizer(recognizer)
                }
            }
        }
        
    }
    
    // MARK: - Fetched Results Controller Delegate - Need to have this or else NSFetchedResultsController won't update
  
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            print("Insert an item")
            mapView.addAnnotation(anObject as! Pin)
            break
        case .Delete:
            print("Delete an item")
            mapView.removeAnnotation(anObject as! Pin)
            break
        default:
            break
        }
    }
    
    
    // MARK: mapView
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMap()
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        // if we are in edit mode when touching a pin
        if editMode {
            let touchedPin = view.annotation as! Pin
            let pinArray = fetchedResultsController.fetchedObjects as! [Pin]

            // iterate through fetchedResultsController to find the touched pin then delete it
            for pin in pinArray {
                if pin.longitude == touchedPin.longitude && pin.latitude == touchedPin.latitude {
                    sharedContext.deleteObject(pin)
                }
            }
            CoreDataStackManager.sharedInstance().saveContext()
        } else {
            // Go to the next view controller
            let viewController = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
            viewController.pin = view.annotation as! Pin
            
            // need to deselect pin or else when coming back to vc can't reselect pin
            mapView.deselectAnnotation(view.annotation, animated: false)
            
            // push next vc onto nav controller so that it transitions from the right and we can move back
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
}
