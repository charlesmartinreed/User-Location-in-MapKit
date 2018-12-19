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
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    //@IBOutlet weak var goButtonTrailingConstraint: NSLayoutConstraint!
    
    
    //MARK:- Instance properties
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 10000
    var previousLocation: CLLocation?
    var buttonConstraint = NSLayoutConstraint()
    let geoCoder = CLGeocoder()
    var directionsArray = [MKDirections]()
    //var goButtonIsVisible = false
    
    
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
            startTrackingUserLocation()
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
    
    func startTrackingUserLocation() {
        mapView.showsUserLocation = true //this gives our blue location dot
        centerViewOnUserLocation()
        //update when user moves - fires off didUpdateLocations() protocol method
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
    }
    
    //MARK:- Center view methods
    func getCenterLocation(for mapview: MKMapView) -> CLLocation {
        //grab the coordinates for the point at the center of the mapView
        let latitude = mapview.centerCoordinate.latitude
        let longitude = mapview.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func centerViewOnUserLocation() {
        //location returns optionally
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters) //6 mile radius
            mapView.setRegion(region, animated: true)
        }
    }
    
    //MARK:- Methods for getting directions
    func getDirections() {
        //from current location to selected
        guard let location = locationManager.location?.coordinate else { return }
        
        //using a helper function for the request due to length
        let request = createDirectionsRequest(from: location)
        
        //now, let's use our directions
        let directions = MKDirections(request: request)
        
        //this is called when this method is, which is called when the Go button is tapped
        resetMapView(withNew: directions)
        
        //calculate the directions
        directions.calculate { (response, error) in
            if let err = error {
                //obviously not production level error handling haha
                print("Unable to calculate directions", err.localizedDescription)
            }
            
            guard let response = response else { return } //create an alert if not
            
            //show the route geometry by animating transition to new map rect - boundingMapRect means the map rect displays entire rect
            for route in response.routes {
                //let steps = route.steps //these are the building blocks we use to do step by step directions
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        //MKDirections.Request needs a source and destination
        
        //destination is the point the user dragged to, which we're placing at center of map
        let destinationCoordinate = getCenterLocation(for: mapView).coordinate
        //the location we passed in when calling the method
        let startingLocation = MKPlacemark(coordinate: coordinate)
        //the location we just created
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile //optional, but we're using this for testing
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    func resetMapView(withNew directions: MKDirections) {
        //add directions to array, use map() to run the cancel() on the item
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map {
            for (index, value) in directionsArray.enumerated() {
                $0.cancel() //cancels PENDING requests, won't return diretions we want
                directionsArray.remove(at: index)
            }
        }
    }
    
    //MARK:- @IBActions
    @IBAction func goButtonTapped(_ sender: UIButton) {
        getDirections()
    }
    
//    func animateGoButton() {
//
//        if goButtonIsVisible {
//            goButtonTrailingConstraint.constant = 0
//        } else {
//            goButtonTrailingConstraint.constant = -80
//        }
//
//        UIView.animate(withDuration: 0.5) {
//            self.view.layoutIfNeeded()
//        }
//    }
    

}

//MARK:- Delegate methods implemented vai extensions
extension MapScreen: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
//        guard let locations = locations.last else { return } //again, locations return optionally
//
//        let center = CLLocationCoordinate2D(latitude: locations.coordinate.latitude, longitude: locations.coordinate.longitude)
//        let region = MKCoordinateRegion(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
//        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        checkLocationAuthorization()
    }
}

extension MapScreen: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //center of map is where the pin exists, when it changes, use the new coordinate to reverse geolocate an address and then put that onto labels
        let center = getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        //there's a max call limit for geolocation, so we need to only need to update when significant movement occurs; over 50 meters
        guard let previousLocation = self.previousLocation else { return }
        
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        geocoder.reverseGeocodeLocation(center) { [weak self] (placemarks, error) in
            guard let self = self else { return } //weak self to avoid strong reference cycles
            
            if let _ = error {
                //show alert informing user of the error
                return
            }
            
            guard let placemark = placemarks?.first else {
                //show alert for error
                return
            }
            
            //setup address - using nil coalescing sine this can return nil
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
                self.addressLabel.text = "\(streetNumber) \(streetName)"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
    }
}
