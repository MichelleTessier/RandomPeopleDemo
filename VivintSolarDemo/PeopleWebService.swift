//
//  PeopleWebService.swift
//  VivintSolarDemo
//
//  Created by Michelle Tessier on 5/12/17.
//  Copyright © 2017 Michelle Tessier. All rights reserved.
//

import Foundation

class PeopleWebService: NSObject {
    
    class func getDataForRandomPeople(count : NSInteger, completion: @escaping (([WebPerson]?, WebError?) -> ())) {
        
        let resultsCountQueryItem = URLQueryItem(name: "results", value: count.description)
        
        let queryItems = [resultsCountQueryItem]
        
        guard var components = URLComponents(string: "https://randomuser.me/api/") else { return }
        
        components.queryItems = queryItems
        
        guard let constructedURL = components.url else { return }
   
        let task = dataTaskWithURL(constructedURL) { (data, error) in
            
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let webPeople = self.parseRandomPeopleData(data) else {
                completion(nil, WebError.unknownError)
                return
            }
            
            completion(webPeople, nil)
        }
        
        task.resume()
        
    }
    
    class func dataTaskWithURL(_ url : URL, completion : @escaping ((Data?, WebError?) -> ())) -> URLSessionDataTask {
        
        return URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            //Check for errors and response data
            if let error = error {
                let webError = WebError.webErrorFromDataTaskError(error: error)
                completion(nil, webError)
                return
            }
            
            if let httpError = self.parseURLResponseCode(urlResponse: response) {
                completion(nil, httpError)
                return
            }
            
            completion(data, nil)
            
        }
        
    }
    
    private class func parseURLResponseCode(urlResponse: URLResponse?) -> WebError? {
        guard let responseCode = (urlResponse as? HTTPURLResponse)?.statusCode else {
            //If we don't have a status code, something is wrong
            return WebError.unknownError
        }
        
        if let error = WebError.parseResponseCode(responseCode, message: HTTPURLResponse.localizedString(forStatusCode: responseCode)) {
            //We got something other than a 200 (expected), so return an error associated with the code.
            return error
        }
        
        //No errors, response was a success!
        return nil
    }
    
    private class func parseRandomPeopleData(_ data : Data?) -> [WebPerson]? {
        
        guard let data = data else { return nil }
       
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any] {
                return self.parseRandomPeopleJSON(jsonObject)
            }
            
        } catch {
            print("Error deserializing JSON response: \(error.localizedDescription)")
        }
        
        return nil
     
    }
    
    //For parsing larger amounts of JSON, I would rather use Mantle. https://github.com/Mantle/Mantle
    //But as this is a coding test, I thought it might be nice to show what I would do myself
    
    private class func parseRandomPeopleJSON(_ jsonDictionary : Dictionary<String, Any>) -> [WebPerson]? {
        
        guard let results = jsonDictionary["results"] as? Array<Dictionary<String, Any>> else { return nil }
        
        var webPeople : [WebPerson] = []
        
        for dictionary in results {
            
            let webPerson = WebPerson()
         
            if let nameDictionary = dictionary["name"] as? [String : String],
                let firstName = nameDictionary["first"],
                let lastName = nameDictionary["last"] {
                
                //It would be better to localize this so that for names where the last name is written first, it would be correct. One option could be to use a localized string, but that would make names always take the order of the locale of the users phone. I am interested to find a better solution.
                
                webPerson.name = "\(firstName.capitalized) \(lastName.capitalized)"
                
            }
            
            if let phone = dictionary["phone"] as? String {
                webPerson.phone = phone
            }
            
            if let email = dictionary["email"] as? String {
                webPerson.email = email
            }
            
            if let pictureDictionary = dictionary["picture"] as? [String : String],
                let thumbnailURL = pictureDictionary["thumbnail"] {
                webPerson.thumbnailURL = thumbnailURL
            }
            
            webPeople.append(webPerson)
            
        }
        
        return webPeople
        
    }
    
}

class WebPerson {
    
    var phone : String?
    var email : String?
    var thumbnailURL : String?
    var name : String?
    var id : String?
    
}

public enum WebError: Error {
    
    case unknownError
    case dataTaskError(reason: String)
    case clientError(reason : String)
    case serverError(reason : String)
    
    //Retruns nil if http status is 200 (No error)
    static func parseResponseCode(_ code: Int, message: String?) -> WebError? {
        
        var reason = "An unknown error occurred"
        
        if let message = message {
            reason = message
        }
        
        if code == 200 { return nil }
        if code >= 400 && code < 500 { return .clientError(reason: reason) }
        if code >= 500 { return .serverError(reason: reason) }
        return .unknownError
        
    }
    
    static func webErrorFromDataTaskError(error : Error) -> WebError {
        
        return .dataTaskError(reason: error.localizedDescription)
        
    }
    
    static func reasonForError(error : WebError) -> String {
        switch error {
        case .dataTaskError(let reason):
            return reason
        case .clientError(let reason):
            return reason
        case .serverError(let reason):
            return reason
        default:
            return "An unknown error occurred"
        }
    }
    
}


