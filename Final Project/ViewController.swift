//
//  ViewController.swift
//  Final Project
//
//  Created by David Feng on 12/8/21.
//

import MapKit
import UIKit
import Photos
import CoreLocation
import PhotosUI

class ViewController: UIViewController, MKMapViewDelegate, PHPickerViewControllerDelegate, CLLocationManagerDelegate {

    @IBOutlet var mapView: MKMapView!
        
    let manager = CLLocationManager()
    var images : [UIImage] = []
    var locations : [CLLocation?] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        // Do any additional setup after loading the view.
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        images = []
        locations = []
        
        dismiss(animated: true, completion: nil)
        
        let identifiers = results.compactMap(\.assetIdentifier)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        
        let imageManager = PHImageManager()
        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = PHImageRequestOptionsResizeMode.exact
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        // this one is key
        requestOptions.isSynchronous = true
        
        if (fetchResult.count > 0) {
            for index in 0...(fetchResult.count - 1) {
                if let loc = fetchResult.object(at: index).location {
                    self.locations.append(loc)
                    
                    imageManager.requestImage(for: fetchResult.object(at: index), targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: requestOptions, resultHandler: { (pickedImage, info) in
                        
                        self.images.append(pickedImage!)

                    })
                }
            }
            
            for loc in locations {
                if let l = loc {
                    render(l)
                }
            }
            
            print("num images")
            print(images.count)
            print("num locations")
            print(locations.count)
//
//            for item in results {
//
//                item.itemProvider.loadObject(ofClass: UIImage.self) {
//                    (image, error) in
//
//                    if let image = image as? UIImage {
//                        self.images.append(image)
//                    }
//                }
//            }
                        
        }
        
    }
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        images = []
        locations = []
        mapView.removeAnnotations(mapView.annotations)
        presentPickerView()
    }
    
    func presentPickerView() {
        images = []
        locations = []
        let photoLibrary = PHPhotoLibrary.shared()
        
        var configuration : PHPickerConfiguration = PHPickerConfiguration(photoLibrary: photoLibrary)
        
        configuration.filter = PHPickerFilter.images
        configuration.selectionLimit = 100
        
        let picker : PHPickerViewController = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()

        let handler: (PHAuthorizationStatus) -> Void = { status in
            print(status)
        }

        PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: handler)
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is MKUserLocation) {
            let pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: String(annotation.hash))

            let rightButton = UIButton(type: .contactAdd)
            let coord = annotation.coordinate
            
            var index = -1
            if (locations.count > 0) {
                for i in 0...locations.count-1 {
                    let lat = locations[i]?.coordinate.latitude
                    let long = locations[i]?.coordinate.longitude
                    if (lat == coord.latitude && long == coord.longitude) {
                        index = i
                    }
                }
            }

            rightButton.tag = index
            rightButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)

            pinView.canShowCallout = true
            let pinImage = UIImage(named: "pin")
            pinView.rightCalloutAccessoryView = rightButton
            let size = CGSize(width: 45, height: 50)
            UIGraphicsBeginImageContext(size)
            pinImage!.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()

            pinView.image = resizedImage

            return pinView
        }
        else {
            return nil
        }
    }
    
    @objc func buttonAction(sender:UIButton!)
    {
        if (sender.tag != -1) {
            let vc = storyboard?.instantiateViewController(identifier: "second_vc") as! SecondViewController
            print(sender.tag)
            print(images.count)
            print(images[sender.tag])
            vc.sentImage = images[sender.tag]
            present(vc, animated: true, completion: nil)
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.first != nil {
            manager.stopUpdatingLocation()
        }
    }
    
    func render(_ location: CLLocation) {
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        
        let region = MKCoordinateRegion(center: coordinate, span: span)

        mapView.setRegion(region, animated: true)
        
        let locPin = MKPointAnnotation()
        locPin.coordinate = coordinate
        locPin.title = "Photo"
        mapView.addAnnotation(locPin)
    }

}


extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerEditedImage")] as? UIImage {
            images.append(image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
