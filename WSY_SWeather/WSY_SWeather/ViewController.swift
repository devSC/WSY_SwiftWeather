//
//  ViewController.swift
//  WSY_SWeather
//
//  Created by 袁仕崇 on 15/4/19.
//  Copyright (c) 2015年 wilson-yuan. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON



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
    
    func updateWeatherInfo(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let url = "http://api.openweathermap.org/data/2.5/forecast"
        let params = ["lat": latitude, "lon": longitude]
        
        println(params)
        
        Alamofire.request(.GET, url, parameters: params).responseJSON() {
            (resquest, response, json, error) in
            if error == nil {
                println("successRequest: \(url)")
                var json = JSON(json!)
                self.updateUISuccess(json)
            } else {
                self.loading.text = "Internet appears down! \n error: \(error?.description)"
//                assert(error != nil, "request error \(error?.description)")
            }
        }
        
    }
    
    func updateUISuccess(json: JSON) {
        self.loading.text = nil
        self.loadingIndicator.hidden = true
        self.loadingIndicator.stopAnimating()
        
        let service = WeatherService()
        if let tempResult = json["list"][0]["main"]["temp"].double {
            //get country
            let country = json["city"]["country"].stringValue
            //get and convert temperature
            var temperature = service.convertTemperature(country, temperature: tempResult)
            self.temperature.text = "\(temperature)"

            //get city name
            self.location.text = json["city"]["name"].stringValue
            
            //get and set icon
            
            let weather = json["list"][0]["weather"][0]
            let condition = weather["id"].intValue
            var icon = weather["icon"].stringValue
            var nightTime = service.isNightTime(icon)
            
            service.updateWeatherIcon(condition, nightTime: nightTime, index: 0, callBack: self.updatePictures)
            
            //Get forecast
            for index in 1...4 {
                if let tempResult = json["list"][index]["main"]["temp"].double {
                    //Get and convert temperature
                    var temperature = service.convertTemperature(country, temperature: tempResult)
                    if (index==1) {
                        self.temp1.text = "\(temperature)°"
                    }
                    else if (index==2) {
                        self.temp2.text = "\(temperature)°"
                    }
                    else if (index==3) {
                        self.temp3.text = "\(temperature)°"
                    }
                    else if (index==4) {
                        self.temp4.text = "\(temperature)°"
                    }
                    
                    // Get forecast time
                    var dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "HH:mm"
                    let rawDate = json["list"][index]["dt"].doubleValue
                    let date = NSDate(timeIntervalSince1970: rawDate)
                    let forecastTime = dateFormatter.stringFromDate(date)
                    if (index==1) {
                        self.time1.text = forecastTime
                    }
                    else if (index==2) {
                        self.time2.text = forecastTime
                    }
                    else if (index==3) {
                        self.time3.text = forecastTime
                    }
                    else if (index==4) {
                        self.time4.text = forecastTime
                    }
                    
                    // Get and set icon
                    let weather = json["list"][index]["weather"][0]
                    let condition = weather["id"].intValue
                    var icon = weather["icon"].stringValue
                    var nightTime = service.isNightTime(icon)
                    service.updateWeatherIcon(condition, nightTime: nightTime, index: index, callBack: self.updatePictures)
                    
                } else {
                    continue
                }
            }
        } else {
            self.loading.text = "Weather info is not available!"
        }
        
//        let service = swiff
    }
    
    func updatePictures(index: Int, name: String) {
        if (index==0) {
            self.icon.image = UIImage(named: name)
        }
        if (index==1) {
            self.image1.image = UIImage(named: name)
        }
        if (index==2) {
            self.image2.image = UIImage(named: name)
        }
        if (index==3) {
            self.image3.image = UIImage(named: name)
        }
        if (index==4) {
            self.image4.image = UIImage(named: name)
        }

    }
    
    //MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        var location: CLLocation = locations[locations.count - 1] as! CLLocation
        if location.horizontalAccuracy > 0 {
            self.locationManager.stopUpdatingLocation()
            println(location.coordinate)
            
            updateWeatherInfo(location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
    }


}

