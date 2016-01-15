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
    
}
