//
//  Photo+Extentions.swift
//  Virtual Tourist
//
//  Created by Malik Basalamah on 17/04/1440 AH.
//  Copyright © 1440 Malik Basalamah. All rights reserved.
//

import Foundation
import CoreData

extension Photo{
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
