//
//  Utility.swift
//  WunderLINQ
//
//  Created by Keith Conger on 7/14/19.
//  Copyright © 2019 Black Box Embedded, LLC. All rights reserved.
//

import Foundation

class Utility {
    // MARK: - Utility Methods
    // Unit Conversion Functions
    // bar to psi
    class func barToPsi(_ bar:Double) -> Double {
        let psi = bar * 14.5037738
        return psi
    }
    // bar to kpa
    class func barTokPa(_ bar:Double) -> Double {
        let kpa = bar * 100.0
        return kpa
    }
    // bar to kg-f
    class func barTokgf(_ bar:Double) -> Double {
        let kgf = bar * 1.0197162129779
        return kgf
    }
    // kilometers to miles
    class func kmToMiles(_ kilometers:Double) -> Double {
        let miles = kilometers * 0.62137
        return miles
    }
    // Celsius to Fahrenheit
    class func celciusToFahrenheit(_ celcius:Double) -> Double {
        let fahrenheit = (celcius * 1.8) + Double(32)
        return fahrenheit
    }
    // L/100 to mpg
    class func l100ToMpg(_ l100:Double) -> Double {
        let mpg = 235.215 / l100
        return mpg
    }
    // meters to feet
    class func mtoFeet(_ meters:Double) -> Double {
        let meters = meters / 0.3048
        return meters
    }
    //radians to degrees
    class func degrees(radians:Double) -> Double {
        return 180 / Double.pi * radians
    }
    
    // Calculate time duration
    class func calculateDuration(start:String, end:String) -> String{
        var dateFormat = "yyyyMMdd-HH:mm:ss"
        var dateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = dateFormat
            formatter.locale = Locale.current
            formatter.timeZone = TimeZone.current
            return formatter
        }
        let startDate = dateFormatter.date(from:start)!
        let endDate = dateFormatter.date(from:end)!
        let difference = Calendar.current.dateComponents([.hour, .minute, .second], from: startDate, to: endDate)
        
        return "\(difference.hour!) \(NSLocalizedString("hours", comment: "")), \(difference.minute!) \(NSLocalizedString("minutes", comment: "")), \(difference.second!) \(NSLocalizedString("seconds", comment: ""))"
    }
}
