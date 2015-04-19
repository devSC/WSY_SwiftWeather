//
//  ViewController.swift
//  WSY_SWeather
//
//  Created by 袁仕崇 on 15/4/19.
//  Copyright (c) 2015年 wilson-yuan. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    let locationManager: CLLocationManager = CLLocationManager()
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var image4: UIImageView!
    @IBOutlet weak var image3: UIImageView!
    @IBOutlet weak var temp4: UILabel!
    @IBOutlet weak var temp3: UILabel!
    @IBOutlet weak var temp2: UILabel!
    @IBOutlet weak var temp1: UILabel!
    @IBOutlet weak var time4: UILabel!
    @IBOutlet weak var time3: UILabel!
    @IBOutlet weak var time2: UILabel!
    @IBOutlet weak var time1: UILabel!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var loading: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        loadingIndicator.startAnimating()
        
        let background = UIImage(named: "background.png")
        self.view.backgroundColor = UIColor(patternImage: background!)
        
        let singleFingerTap = UITapGestureRecognizer(target: self, action: "handleSingleTap:")

        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    func handleSingleTap(recognize: UITapGestureRecognizer) {
        locationManager.startUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

