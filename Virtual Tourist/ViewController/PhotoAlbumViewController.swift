//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Malik Basalamah on 12/04/1440 AH.
//  Copyright © 1440 Malik Basalamah. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var barButton: UIButton!
    @IBOutlet weak var noImage: UILabel!
    
    var selectedPin: Pin!
    
    var locations = LocationDataSource.sharedInstance.Locations
    var selectedPhotos = [IndexPath]()
    var arrayURL = [String]()
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<Photo>!

    
    fileprivate func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", self.selectedPin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "CASH_PHOTO_DATA")
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        }catch{
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        mapView.delegate = self
        collectionView.allowsMultipleSelection = true
        barButton.isEnabled = false
        noImage.isHidden = true
        
        setUpFetchedResultsController()
        zoomPin()
        flowLayoutConfig()
        
        if self.fetchedResultsController.fetchedObjects?.count == 0 {
            loadImageFromFlicker()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidLoad()
        collectionView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }


    func flowLayoutConfig(){
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    
    func loadImageFromFlicker(){
        Client.sharedInstance().callImageFlicker((selectedPin?.latitude)!, (selectedPin?.longitude)!) { (success, locationInformation, errorString) in
            if success{
                if errorString == "No Image Found"{
                    performUIUpdatesOnMain {
                    self.noImage.isHidden = false
                    self.noImage.text = "No Image Found"
                    }
                }else{
                if let info = locationInformation{
                    for i in info {
                        self.arrayURL.append(i.url_m!)
                    }
                }
                    self.downloadImages()
                }
            }else{
                print(errorString!)
            }
        }
    }
    
    func downloadImages(){
        
        if ((fetchedResultsController.fetchedObjects?.isEmpty)!) {
            
            for imageURL in arrayURL {
                Client.sharedInstance().downloadImages(imageUrl: imageURL) { (success, results, error) in
                    if success{
                        self.saveData(results!,imageURL)
                    }else{
                        print("Error: \(String(describing: error?.localizedDescription))")

                    }
                }
            }
        }
    }
        func saveData(_ results:Data,_ imageURL:String){
            let photo = Photo(context: self.dataController.viewContext)
            photo.imageURL = imageURL
            photo.imageData = results
            photo.creationDate = Date()
            photo.pin = self.selectedPin
            do{
                try self.dataController.viewContext.save()
            }catch{
                print(error)
            }
        }
    
    func zoomPin(){
        //zoom to location
        let span = MKCoordinateSpan(latitudeDelta: 3.0, longitudeDelta: 3.0)
        let coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(selectedPin.latitude, selectedPin.longitude)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        self.mapView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    @IBAction func barButtonAction(_ sender: Any) {
        if barButton.title(for: .normal) == "Remove"{
            removeData()
            barButton.setTitle("New Collection", for: .normal)
        }else{
            
            arrayURL.removeAll()

            guard let fetchedResults = self.fetchedResultsController.fetchedObjects else {
                print("Something went wrong")
                return
            }
            
            for i in fetchedResults {
                dataController.viewContext.delete(i)
                do{
                    try dataController.viewContext.save()
                }catch{
                print(error)
                }
            }

           loadImageFromFlicker()
        }
    }
    
    func removeData(){
        
        var photos: [Photo] = [Photo]()
        
        for i in selectedPhotos {
            photos.append(fetchedResultsController.object(at: i))
        }
        
        for i in photos {
            dataController.viewContext.delete(i)
            do{
                try dataController.viewContext.save()
            }catch{
                print(error)
            }
        }
        
        selectedPhotos.removeAll()
        collectionView.reloadData()

    }


}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sectionInformation = self.fetchedResultsController.sections?[section] {
            return sectionInformation.numberOfObjects
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell" , for: indexPath) as! CollectionViewCell
        
        cell.selectView.isHidden = true
        cell.indicator.isHidden = false
        cell.indicator.startAnimating()
        
        let arrayData = self.fetchedResultsController.fetchedObjects!
        
        self.barButton.isEnabled = true
        cell.indicator.stopAnimating()
        cell.indicator.isHidden=true
        cell.imageViewCell.image =  UIImage(data: arrayData[indexPath.row].imageData!)

        return cell
    }
  
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionViewCell
        cell.selectView.isHidden = false
        barButton.setTitle("Remove", for: .normal)
        selectedPhotos.append(indexPath)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CollectionViewCell
        
        cell.selectView.isHidden = true
        
        barButton.setTitle("Remove", for: .normal)
        
        selectedPhotos.remove(at: indexPath.startIndex)

        if selectedPhotos.count == 0 {
            barButton.setTitle("New Collection", for: .normal)
        }
    }
    
}

extension PhotoAlbumViewController:MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
}

//Mark : CoreData FetchedResultsController
extension PhotoAlbumViewController:NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            self.collectionView.insertItems(at: [newIndexPath!])
            
        case .delete:
            self.collectionView.deleteItems(at: [indexPath!])
        case .move:
            self.collectionView.moveItem(at: indexPath!, to: newIndexPath!)
        case .update:
            self.collectionView.reloadItems(at: [indexPath!])
        }
}


}
