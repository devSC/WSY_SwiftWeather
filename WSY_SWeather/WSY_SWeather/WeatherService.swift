//
//  WeatherService.swift
//  WSY_SWeather
//
//  Created by YSC on 15/4/23.
//  Copyright (c) 2015年 wilson-yuan. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import SwiftyJSON

enum Status {
    case success
    case failure
}
class Response {
    var status: Status = .failure
    var object: JSON? = nil
    var error: NSError? = nil
}
class WeatherService {
    init() {
    
    }
    
    func retrieveForecast (latitude: CLLocationDegrees, longitude: CLLocationDegrees, success: (response: Response) ->(), failure: (response: Response)->()) {
        let url = "http://api.openweathermap.org/data/2.5/forecast"
        
        let params = ["lat": latitude, "lon": longitude]
        println("params: \(params)")
        
        Alamofire.request( .GET, url, parameters: params).responseJSON() {
            (request, response, json, error) in
            if (error != nil) {
                println("error: \(error)")
                var response = Response()
                response.status = .failure
                response.error = error
                failure(response: response)
            } else {
                println("success: \(url)")
                var json = JSON(json!)
                var response = Response()
                response.status = .success
                response.object = json
                success(response: response)
            }
        }
    }
    
    func convertTemperature(country: String, temperature: Double) -> Double {
        if (country == "US") {
            return round(((temperature - 273.15) * 1.8) + 32)
        } else {
            return round(temperature - 273.15)
        }
    }
    
    func isNightTime(icon: String) -> Bool {
        return icon.rangeOfString("n") != nil
    }
    
    func updateWeatherIcon(condition: Int, nightTime: Bool, index: Int, callBack: (index: Int, name: String) -> ()) {
    
        //ThunderStorm
        if condition < 300 {
            if nightTime {
                callBack(index: index, name: "tstorm1_night")
            } else {
                callBack(index: index, name: "tstorm1")
            }
        }
        
        //Drizzle
        else if condition < 500 {
            callBack(index: index, name: "light_rain")
        }
        //Rain / Freezing rain /Shower rain
        else if condition < 600 {
            callBack(index: index, name: "shower3")
        }
        //snow
        else if condition < 700 {
            callBack(index: index, name: "snow4")
        }
        // Fog / Mist / Haze / etc.
        else if (condition < 771) {
            if nightTime {
                callBack(index: index, name: "fog_night")
            } else {
                callBack(index: index, name: "fog")
            }
        }
            // Tornado / Squalls
        else if (condition < 800) {
            callBack(index: index, name: "tstorm3")
        }
            // Sky is clear
        else if (condition == 800) {
            if (nightTime){
                callBack(index: index, name: "sunny_night")
            }
            else {
                callBack(index: index, name: "sunny")
            }
        }
            // few / scattered / broken clouds
        else if (condition < 804) {
            if (nightTime){
                callBack(index: index, name: "cloudy2_night")
            }
            else{
                callBack(index: index, name: "cloudy2")
            }
        }
            // overcast clouds
        else if (condition == 804) {
            callBack(index: index, name: "overcast")
        }
            // Extreme
        else if ((condition >= 900 && condition < 903) || (condition > 904 && condition < 1000)) {
            callBack(index: index, name: "tstorm3")
        }
            // Cold
        else if (condition == 903) {
            callBack(index: index, name: "snow5")
        }
            // Hot
        else if (condition == 904) {
            callBack(index: index, name: "sunny")
        }
            // Weather condition is not available
        else {
            callBack(index: index, name: "dunno")
        }
    }
    
    
}
