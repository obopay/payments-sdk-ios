//
//  object.swift
//  obopaypayments
//
//  Created by Shubham Bhiwaniwala on 24/06/19.
//  Copyright © 2019 Obopay. All rights reserved.
//

import Foundation

class Object {
  static func stringifyObject(arg : Any) -> String {
    switch arg {
    case is String :
      return "'\(escapeSingleQuote(str: arg as! String))'"
    case is Int :
      return String(format: "%d", arg as! Int)
    case is Float :
      return String(format: "%d", arg as! Float)
    case is Double :
      return String(format: "%d", arg as! Double)
    case is Bool :
      return "\(arg as! Bool)"
    case nil :
      return "null"
    case is [String : Any] :
      return JSON.stringifyJSONObject(jsonObject: arg as! [String : Any], prettyPrinted: false)
    case is [[String : Any]] :
      return JSON.stringifyJSONObjectArray(jsonObjectArray: arg as! [[String : Any]], prettyPrinted: false)
    default:
      return  "\(arg) has invalid type"
    }
  }
  
  private static func escapeSingleQuote(str: String) -> String {
    return str.replacingOccurrences(of: "'", with: "\\'")
  }
  
}
