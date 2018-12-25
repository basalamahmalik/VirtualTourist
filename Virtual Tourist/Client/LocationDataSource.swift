//
//  LocationDataSource.swift
//  Virtual Tourist
//
//  Created by Malik Basalamah on 12/04/1440 AH.
//  Copyright © 1440 Malik Basalamah. All rights reserved.
//

import Foundation

class LocationDataSource{
    
    var Locations = [LocationInformation]()
    
    // MARK: Singleton    
    static let sharedInstance = LocationDataSource()
    private init() {}
}
