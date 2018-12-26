//
//  TravelLocationMapViewController.swift
//  Virtual Tourist
//
//  Created by Malik Basalamah on 12/04/1440 AH.
//  Copyright © 1440 Malik Basalamah. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var dataController:DataController!
    var pin: Pin!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    var annotations = [MKPointAnnotation]()

    fileprivate func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "CASH_PIN_DATA")
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        }catch{
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        setUpFetchedResultsController()
        addPin()
        loadPin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    func loadPin(){
        for location in fetchedResultsController.fetchedObjects! {
            let latitude = location.latitude
            let longitude = location.longitude
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }
        performUIUpdatesOnMain {
            self.mapView.addAnnotations(self.annotations)

        }

    }
    
    func addPin(){
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleTap(gestureReconizer:)))
        
        gestureRecognizer.delegate = self as? UIGestureRecognizerDelegate
            mapView.addGestureRecognizer(gestureRecognizer)

    }
    
    @objc func handleTap(gestureReconizer: UILongPressGestureRecognizer) {
        let location = gestureReconizer.location(in: mapView)
        let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
        
        // Add annotation:
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        if gestureReconizer.state == UIGestureRecognizer.State.began {
        mapView.addAnnotation(annotation)
        }
        savePin(lat: coordinate.latitude,lon: coordinate.longitude)
        
        
    }

    func savePin(lat:Double,lon:Double){
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = lat
        pin.longitude = lon
        pin.creationDate = Date()
        do{
            try dataController.viewContext.save()
        }catch{
            print(error)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toCollection" ) {
            if let nextVC = segue.destination as? PhotoAlbumViewController {
                nextVC.selectedPin = pin
                nextVC.dataController = dataController
            }
        }
    }
}

extension TravelLocationMapViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let annotation = view.annotation
        let lat = annotation!.coordinate.latitude
        let lon = annotation!.coordinate.longitude
        if let data = fetchedResultsController.fetchedObjects{
            for i in data{
                if i.latitude == lat && i.longitude == lon{
                    self.pin = i
                    performSegue(withIdentifier: "toCollection", sender: self)
                    break
                }else{
                    print("something went wrong # SEGUE")
                }
            }
        }
    }
}
extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        let lat = CLLocationDegrees(latitude)
        let lon = CLLocationDegrees(longitude)
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
    }
}


extension TravelLocationMapViewController: NSFetchedResultsControllerDelegate {
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        guard let pin = anObject as? Pin else {
            fatalError("An Error Occourd")
        }
        
        switch type {
        case .insert:
        mapView.addAnnotation(pin)
        case .delete:
        mapView.removeAnnotation(pin)

        case .update:
        mapView.removeAnnotation(pin)
        mapView.addAnnotation(pin)
    
        case .move:
            break

        }
    }
}
