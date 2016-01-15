//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jonathan Chou on 1/14/16.
//  Copyright © 2016 Jonathan Chou. All rights reserved.
//

import CoreData
import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var pin: MKPointAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeMapView()
        initializePin()
    }
    
    // disables user interaction with the map view
    func initializeMapView() {
        mapView.zoomEnabled = false;
        mapView.scrollEnabled = false;
        mapView.userInteractionEnabled = false;
    }
    
    func initializePin() {
        mapView.addAnnotation(pin)
        // center the mapView on the pin and set viewing region
        mapView.centerCoordinate = pin.coordinate
        let span = MKCoordinateSpanMake(0.045, 0.075)
        let region = MKCoordinateRegion(center: pin.coordinate, span: span)
        mapView.setRegion(region, animated: false)
    }
    
}
