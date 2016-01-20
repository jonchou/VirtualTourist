//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by Jonathan Chou on 1/19/16.
//  Copyright © 2016 Jonathan Chou. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    struct Constants {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let API_KEY = "5196cb5448befb0611703b847aa9f893"
        static let EXTRAS = "url_m"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let SAFE_SEARCH = "1"
        static let PER_PAGE = "21"
    }
    
    struct Methods {
        static let PHOTO_SEARCH = "flickr.photos.search"
    }
    
    struct Keys {
        static let ErrorStatusMessage = "status_message"
    }
}