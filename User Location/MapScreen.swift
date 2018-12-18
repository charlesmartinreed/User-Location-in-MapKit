//
//  ViewController.swift
//  User Location
//
//  Created by Charles Martin Reed on 12/18/18.
//  Copyright © 2018 Charles Martin Reed. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation //because we're using user location

class MapScreen: UIViewController {

    //MARK:- @IBOutlets
    @IBOutlet weak var mapView: MKMapView! //strong reference, private to this file
    
    //MARK:- Instance properties
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 10000
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()
        //mapView.delegate = self - we're doing this in IB, actually
    }
    
    //MARK:- Location management methods
    func checkLocationServices() {
        //1. make sure location services are not disabled
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            //2. Does OUR app have permission?
            checkLocationAuthorization()
        } else {
            //Show an alert letting the usr know they have to turn on location services
            let ac = UIAlertController(title: "Location services are disabled", message: "Please enable location tracking to continue", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(ac, animated: true, completion: nil)
        }
    }
    
    func setupLocationManager(){
        //setup the delegate, which is this view controller
        locationManager.delegate = self
        
        //determine the accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse: //when app open, in foreground
            mapView.showsUserLocation = true //this gives our blue location dot
            centerViewOnUserLocation()
            //update when user moves - fires off didUpdateLocations() protocol method
            locationManager.startUpdatingLocation()
            break
        case .denied: //user denied, show alert on how to turn on permissions
            break
        case .notDetermined: //user hasn't picked allow or not allowed
            locationManager.requestWhenInUseAuthorization()
        case .restricted: //app can't use location due to overriding circumnstances like parental controls - show an alert to let user know what's up
            break
        case .authorizedAlways: //even when app is in the background
            break
        }
    }
    
    //MARK:- Placing the user location region in center of view
    func centerViewOnUserLocation() {
        //location returns optionally
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters) //6 mile radius
            mapView.setRegion(region, animated: true)
        }
    }
    

}



//MARK:- Delegate conformation via extension
extension MapScreen: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let locations = locations.last else { return } //again, locations return optionally
        
        let center = CLLocationCoordinate2D(latitude: locations.coordinate.latitude, longitude: locations.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        checkLocationAuthorization()
    }
}
