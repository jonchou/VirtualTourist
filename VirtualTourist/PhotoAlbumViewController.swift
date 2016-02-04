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
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var errorLabel: UILabel!
    
    private let reuseIdentifier = "FlickrCell"
    private var downloadCounter = 0

    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var pin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeMapView()
        initializePin()
        
        // Start the fetched results controller
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
        }
        
        if let error = error {
            print("Error performing initial fetch: \(error)")
        }

        // shows error label when no images are found
        if fetchedResultsController.fetchedObjects!.count == 0 {
            errorLabel.hidden = false
        } else {
            errorLabel.hidden = true
        }
        
        updateBottomButton()
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
        
        let width = floor(collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    // MARK: - Configure Cell
    
    func configureCell(cell: FlickrCell, atIndexPath indexPath: NSIndexPath) {
        
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // if the photo has been saved already, assign image from memory
        if let myImage = photo.image {
            cell.FlickrCellImage.image = myImage
            cell.activityIndicator.hidden = true
            cell.activityIndicator.stopAnimating()
        } else {
            // download the image
            cell.FlickrCellImage.image = UIImage(named: "placeholder")

            bottomButton.enabled = false
            self.downloadCounter += 1
            
            cell.activityIndicator.hidden = false
            cell.activityIndicator.startAnimating()

            let task = FlickrClient.sharedInstance().taskForImage(photo.imageUrl!) { (imageData, error) -> Void in

                if let data = imageData {
                    dispatch_async(dispatch_get_main_queue()) {
                        let image = UIImage(data: data)
                        
                        // stores photo into image cache
                        photo.image = image
                        cell.FlickrCellImage.image = image
                        cell.activityIndicator.hidden = true
                        cell.activityIndicator.stopAnimating()
                        
                        // used to determine when to enable the bottom button
                        self.downloadCounter -= 1
                        if self.downloadCounter == 0 {
                            self.bottomButton.enabled = true
                        }
                    }
                } else {
                    print(error)
                }
            }
            cell.taskToCancelifCellIsReused = task
        }
        
        // if the cell is "selected," it's color panel is grayed out
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.FlickrCellImage.alpha = 0.5
        } else {
            cell.FlickrCellImage.alpha = 1.0
        }
    }
  
    // Mark - UI Collection View Delegate
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCell", forIndexPath: indexPath) as! FlickrCell

        dispatch_async(dispatch_get_main_queue(), {
            self.configureCell(cell, atIndexPath: indexPath)
        })
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FlickrCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        configureCell(cell, atIndexPath: indexPath)
        
        // And update the buttom button
        updateBottomButton()
    }
    
    // MARK: - Shared Context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    
    // MARK: Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    
    // MARK: - Fetched Results Controller Delegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {

        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
        }, completion: nil)
    }
    
    @IBAction func bottomButtonClicked(sender: AnyObject) {
        // New collection
        if selectedIndexes.isEmpty {
            deleteAllImages()
            // Find new collection after, flickr max page number is 40
            let randomPage = String(arc4random_uniform(UInt32(pin.maxPages % 40)) + 1)
            FlickrClient.sharedInstance().searchImagesByLatLon(pin, pageNum: randomPage)
        } else {
            // Delete Selected Images
            deleteSelectedImages()
        }
    }
    
    func deleteAllImages() {
        for image in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(image)
            deleteFromDocDir(image)
        }
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func deleteSelectedImages() {
        var imagesToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            imagesToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for image in imagesToDelete {
            sharedContext.deleteObject(image)
            deleteFromDocDir(image)
        }
        
        CoreDataStackManager.sharedInstance().saveContext()

        selectedIndexes = [NSIndexPath]()
        // need to update title of button after we delete images
        updateBottomButton()
    }
    
    func deleteFromDocDir(image: Photo) {
        let path = FlickrClient.Caches.imageCache.pathForIdentifier(image.imagePath!)
        do {
            try NSFileManager.defaultManager().removeItemAtPath(path)
        } catch _ {}
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Photos"
        } else {
            bottomButton.title = "New Collection"
        }
    }
}
