//
//  url.swift
//  obopaypayments
//
//  Created by Shubham Bhiwaniwala on 02/07/19.
//  Copyright © 2019 Obopay. All rights reserved.
//

import Foundation

extension URL {
  
  func getValue(queryKey : String) -> String? {
    let components = URLComponents(url: self, resolvingAgainstBaseURL: false)
    assert(components != nil)
    let queryItems = components!.queryItems
    if (queryItems == nil) {
      return nil
    }
    
    var returnVal : String? = ""
    
    queryItems!.forEach({
      item in
      if (item.name == queryKey) {
        returnVal = item.value
      }
    })
    
    return returnVal
  }
  
  func getAllQueryParams() -> [String : Any] {
    let components = URLComponents(url: self, resolvingAgainstBaseURL: false)
    assert(components != nil)
    let queryItems = components!.queryItems
    if (queryItems == nil) {
      return [:]
    }
    
    var qI : [String : Any] = [:]
    
    queryItems!.forEach({
      item in
      qI[item.name] = item.value
    })
    
    return qI
  }
  
  func addQueryParam(key : String, value : String) -> URL {
    
    guard var components = URLComponents(string: absoluteString) else { return absoluteURL }
    
    var queryItems : [URLQueryItem] = components.queryItems ?? []
    let newQueryItem = URLQueryItem(name: key, value: value)
    queryItems.append(newQueryItem)
    
    components.queryItems = queryItems
    return components.url!
    
  }
  
  func removeQueryParam(key : String) -> URLQueryItem? {
    guard var components = URLComponents(string: absoluteString) else { return nil }
    
    var queryItems : [URLQueryItem] = components.queryItems ?? []
    
    let pos = self.indexOf(key: key)
    if (pos == -1) {
      return nil
    }
    
    let removedQP = queryItems.remove(at: pos)
    
    components.queryItems = queryItems
    
    return removedQP
  }
  
  func indexOf(key : String) -> Int {
    guard var components = URLComponents(string: absoluteString) else { return -1 }
    
    var queryItems : [URLQueryItem] = components.queryItems ?? []
    let len                         = queryItems.count
    
    for i in 0..<len {
      if(queryItems[i].name == key) {
        return i
      }
    }
    
    return -1
    
  }
  
}

