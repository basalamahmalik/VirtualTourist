//
//  LocationInformation.swift
//  Virtual Tourist
//
//  Created by Malik Basalamah on 12/04/1440 AH.
//  Copyright © 1440 Malik Basalamah. All rights reserved.
//

struct LocationInformation{
    
    
    let url_m:String?
    
    
    
    init(locationDictionary: [String:AnyObject])
    {
        // Check & Set the most important properties
        if let url_m = locationDictionary[Constants.FlickrParameterValues.MediumURL] as? String {
            self.url_m = url_m
        } else {
            self.url_m = ""
        }
    }
    
    static func LocationsFromResults(_ results: [[String:AnyObject]]) -> [LocationInformation] {
        
        var location = [LocationInformation]()
        
        // iterate through array of dictionaries, each Movie is a dictionary
        for result in results {
            location.append(LocationInformation(locationDictionary: result))
        }
        return location
    }
}

