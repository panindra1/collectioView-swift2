//
//  FlickrSearcher.swift
//  flickrSearch
//
//  Created by Richard Turton on 31/07/2014.
//  Copyright (c) 2014 Razeware. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

let apiKey = "411cfe05ba5d89e54df0e2b2088efc9c"

struct FlickrSearchResults {
  let searchTerm : String
  let searchResults : [FlickrPhoto]
}

class FlickrPhoto : Equatable {
    
  var thumbnail : UIImage?
  var largeImage : UIImage?
  let photoID : String
  let farm : Int
  let server : String
  let secret : String
  
  init (photoID:String,farm:Int, server:String, secret:String) {
    self.photoID = photoID
    self.farm = farm
    self.server = server
    self.secret = secret
  }
  
   
  func flickrImageURL(size:String = "m") -> NSURL {
    return NSURL(string: "http://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_\(size).jpg")!
  }
  
  func loadLargeImage(completion: (flickrPhoto:FlickrPhoto, error: NSError?) -> Void) {
    let loadURL = flickrImageURL("b")
//    let loadRequest = NSURLRequest(URL:loadURL)
    print(loadURL.URLString)
    Alamofire.request(.GET, loadURL)
        .response { request, response, data, error in
            if error != nil {
                completion(flickrPhoto: self, error: nil)
                return
            }
            
            if let returnData = data {
                let returnedImage = UIImage(data: returnData)
                self.largeImage = returnedImage
                completion(flickrPhoto: self, error: nil)
                return
            }
            completion(flickrPhoto: self, error: nil)
    }
  }
  
  func sizeToFillWidthOfSize(size:CGSize) -> CGSize {
    if thumbnail == nil {
      return size
    }
    
    let imageSize = thumbnail!.size
    var returnSize = size
    
    let aspectRatio = imageSize.width / imageSize.height
    
    returnSize.height = returnSize.width / aspectRatio
    
    if returnSize.height > size.height {
      returnSize.height = size.height
      returnSize.width = size.height * aspectRatio
    }
    
    return returnSize
  }
  
}

func == (lhs: FlickrPhoto, rhs: FlickrPhoto) -> Bool {
  return lhs.photoID == rhs.photoID
}

class Flickr {
  
  let processingQueue = NSOperationQueue()
  
  func searchFlickrForTerm(searchTerm: String, completion : (results: FlickrSearchResults?, error : NSError?) -> Void){
    
    let searchURL = flickrSearchURLForSearchTerm(searchTerm)
    print(searchURL.URLString)
//    let searchRequest = NSURLRequest(URL: searchURL)
    Alamofire.request(.GET, searchURL)
        .response { request, response, data, error in
            if let returnData = data {
                let jsonData = JSON(data: returnData)
                switch (jsonData["stat"].string!) {
                case "ok":
                    print("Results processed OK")
                case "fail":
                    let APIError = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:jsonData["message"].string!])
                    completion(results: nil, error: APIError)
                    return
                default:
                    let APIError = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:"Uknown API response"])
                    completion(results: nil, error: APIError)
                    return
                }
                
                let photosContainer = jsonData["photos"]
                let photosReceived = photosContainer["photo"]
                
                let flickrPhotos : [FlickrPhoto] = photosReceived.map {
                    photoDictionary in
                    
                    let photoID = photoDictionary.1["id"] .string

                    let farm = photoDictionary.1["farm"] .number as! Int
                    let server = photoDictionary.1["server"]  .string
                    let secret = photoDictionary.1["secret"]  .string
                    
                    let flickrPhoto = FlickrPhoto(photoID: photoID!, farm: farm, server: server!, secret: secret!)
                    
                    let imageData = NSData(contentsOfURL: flickrPhoto.flickrImageURL())

                    flickrPhoto.thumbnail = UIImage(data: imageData!)
                    
                    return flickrPhoto
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    completion(results:FlickrSearchResults(searchTerm: searchTerm, searchResults: flickrPhotos), error: nil)
                })
            }
            //completionHandler(result: response, data: data, error: nil)
    }
  }
    
    
  private func flickrSearchURLForSearchTerm(searchTerm:String) -> NSURL {
    
    let escapedTerm = searchTerm.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    let URLString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&text=\(escapedTerm)&per_page=20&format=json&nojsoncallback=1"
    return NSURL(string: URLString)!
  }
  
  
}
