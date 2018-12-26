//
//  Functions.swift
//  Virtual Tourist
//
//  Created by Malik Basalamah on 14/04/1440 AH.
//  Copyright © 1440 Malik Basalamah. All rights reserved.
//

import UIKit

extension Client{
    
    func callImageFlicker(_ lat:Double,_ lon:Double, completion: @escaping (_ success:Bool,[LocationInformation]?, _ errorString: String?)->Void) {
        
        let parameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.Flicker_AUTH.APIKEY,
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(longitude: lon, latitude: lat),
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.perPage: Constants.FlickrParameterValues.perPage,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
            ] as [String : Any]
        
        let _ = taskForGETMethod(parameters as [String : AnyObject]) { (results, error) in
            
            guard (error == nil) else{
                print(error!)
                completion(false ,nil,error?.localizedDescription)
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = results?[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                print("Flickr API returned an error. See error code and message in \(results!)")
                completion(false,nil,error?.localizedDescription)
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = results?[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                print("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(results!)")
                completion(false,nil,error?.localizedDescription)
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]], photosArray.count != 0 else {
                print("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                completion(false,nil,"Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            
            let pageLimit = min(totalPages, 10)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            
            self.displayImageFromFlickr(parameters as [String : AnyObject], withPageNumber: randomPage, completion: { (success, results, errorString) in
                if success{
                    if errorString == "No Image Found" {
                        completion(true ,nil ,errorString)
                    }else{
                    completion(true,results,nil)
                }
                }else{
                    print(error?.localizedDescription ?? "Something Went Wrong")
                }
            })

        }
    }

    func displayImageFromFlickr(_ methodParameters: [String: AnyObject], withPageNumber: Int, completion: @escaping (_ success:Bool,[LocationInformation]?, _ errorString: String?)->Void) {
    
    // add the page to the method's parameters
    var methodParametersWithPageNumber = methodParameters
    methodParametersWithPageNumber[Constants.FlickrParameterKeys.Page] = withPageNumber as AnyObject?
    
    // create session and request
    let _ = taskForGETMethod(methodParametersWithPageNumber as [String : AnyObject]) { (results, error) in
        
        guard (error == nil) else{
            print(error!)
            completion(false ,nil,error?.localizedDescription)
            return
        }
        
        /* GUARD: Did Flickr return an error (stat != ok)? */
        guard let stat = results?[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
            print("Flickr API returned an error. See error code and message in \(results!)")
            completion(false,nil,error?.localizedDescription)
            return
        }
        
        /* GUARD: Is "photos" key in our result? */
        guard let photosDictionary = results?[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
            print("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(results!)")
            completion(false,nil,error?.localizedDescription)
            return
        }
        
        /* GUARD: Is the "photo" key in photosDictionary? */
        guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]], photosArray.count != 0 else {
            print("Cannot find key '\(Constants.FlickrResponseKeys.Photo)' in \(photosDictionary)")
            return
        }
        
        if photosArray.isEmpty {
            let stringError = "No Image Found"
            completion(true ,nil ,stringError)
        }
        
        let informations = LocationInformation.LocationsFromResults(photosArray)
        
        completion(true,informations,nil)
    }
}


    func downloadImages(imageUrl: String, complietion: @escaping (_ success:Bool, _ result: Data?, _ error: NSError?) -> Void) {

        guard let url = URL(string: imageUrl) else {
            return
        }
        
        let _ = download(url) { (data, error) in
            
            guard (error == nil) else{
                print(error!)
                complietion(false,nil,error)
                return
            }
            complietion(true,data,nil)
        }
    }
    private func bboxString(longitude:Double,latitude:Double) -> String {
        // ensure bbox is bounded by minimum and maximums
            let minimumLon = max(longitude - Constants.FlickerBBOX.SearchBBoxHalfWidth, Constants.FlickerBBOX.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.FlickerBBOX.SearchBBoxHalfHeight, Constants.FlickerBBOX.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.FlickerBBOX.SearchBBoxHalfWidth, Constants.FlickerBBOX.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.FlickerBBOX.SearchBBoxHalfHeight, Constants.FlickerBBOX.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
}


    

