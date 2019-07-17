//
//  json.swift
//  obopaypayments
//
//  Created by Shubham Bhiwaniwala on 24/06/19.
//  Copyright © 2019 Obopay. All rights reserved.
//

import Foundation

class JSON {
  
  static func stringifyJSONObject(jsonObject: [String : Any], prettyPrinted: Bool = false) -> String {
    var options: JSONSerialization.WritingOptions = []
    if prettyPrinted { options     = JSONSerialization.WritingOptions.prettyPrinted }
    do {
      let data    = try JSONSerialization.data(withJSONObject  : jsonObject,
                                               options        : options)
      if let string = String(data: data, encoding: String.Encoding.utf8) { return string }
    } catch { print(error) }
    
    return ""
  }
  
  static func stringifyJSONObjectArray(jsonObjectArray: [[String : Any]], prettyPrinted: Bool = false) -> String {
    var jsonObjectString : [String] = []
    for jsonObject in jsonObjectArray {
      if (jsonObject.count != 0) {
        jsonObjectString.append(stringifyJSONObject(jsonObject    : jsonObject,
                                                    prettyPrinted  : prettyPrinted))
      }
    }
    return "[\(jsonObjectString.joined(separator: ", "))]"
  }
  
  static func objectifyJSONObjectString(jsonObjectString : String) -> [String : Any] {
    let data = jsonObjectString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
    do {
      return try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    } catch let error as NSError {
      print("Failed to load: \(error.localizedDescription)")
    }
    return [:]
  }
  
}
