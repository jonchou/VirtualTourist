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

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let reuseIdentifier = "FlickrCell"
    
    var pin: MKPointAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeMapView()
        initializePin()
        
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "text": "baby asian elephant",
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        
        FlickrClient.sharedInstance().getImageFromFlickrBySearch(methodArguments)
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
    
    
    // Layout the collection view
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    // Mark - UI Collection View
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // TODO: Change count of pictures returned
        return 5
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCell", forIndexPath: indexPath) as! FlickrCell
        //let meme = memes[indexPath.item]
        //cell.setText(meme.topText!, botText: meme.botText!)
        //cell.setAttributes(meme.topText!, botText: meme.botText!, memeAttribText: memeTextAttributes)
        //cell.imageView.image = meme.image
        //TODO: set image of cell from search
        return cell
    }
    
    
}
