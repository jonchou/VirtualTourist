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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pinDropGesture = UILongPressGestureRecognizer(target: self, action: "addPin:")
        self.mapView.addGestureRecognizer(pinDropGesture)
        
        mapView.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {}
    
        fetchedResultsController.delegate = self
        
        // repopulate persisted pins
        restorePins()

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

    // TODO: change NSSortDescriptor?
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
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
            
            self.mapView.addAnnotation(newPin)
            
            CoreDataStackManager.sharedInstance().saveContext()
            
            FlickrClient.sharedInstance().searchImagesByLatLon(newPin)
        }
        
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        // Go to the next view controller
        let viewController = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        viewController.pin = view.annotation as! Pin
        
        // need to deselect pin or else when coming back to vc can't reselect pin
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        // push next vc onto nav controller so that it transitions from the right and we can move back
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    
}
