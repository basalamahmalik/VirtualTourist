//
//  GCDBlackBox.swift
//  Virtual Tourist
//
//  Created by Malik Basalamah on 12/04/1440 AH.
//  Copyright © 1440 Malik Basalamah. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
