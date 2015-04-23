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
    
    
}
