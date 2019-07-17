//
//  Obopayments.swift
//  obopaypayments
//
//  Created by Shubham Bhiwaniwala on 25/06/19.
//  Copyright © 2019 Obopay. All rights reserved.
//

import Foundation
import WebKit
import UIKit
import SafariServices

class SessionRequest {
  var businessRegId     : String?
  var mobileNo          : String?
  var authKey           : String?
  var businessName      : String?
  var businessLogoUrl   : String?
  
  init(businessRegId : String, mobileNo : String, authKey : String,
       businessName : String, businessLogoUrl : String) {
    
    self.businessName     = businessName
    self.mobileNo         = mobileNo
    self.authKey          = authKey
    self.businessRegId    = businessRegId
    self.businessLogoUrl  = businessLogoUrl
    
  }
  
  func toJSONObject() -> [String : Any] {
    
    var jsonObj : [String : Any] = [:]
        jsonObj["businessRegId"]    = self.businessRegId
        jsonObj["mobileNo"]         = self.mobileNo
        jsonObj["authKey"]          = self.authKey
        jsonObj["businessName"]     = self.businessName
        jsonObj["businessLogoUrl"]  = self.businessLogoUrl
    
    return jsonObj
  }
  
}

enum SdkErrorCode : String {
  case INITIALIZATION_PENDING = "INITIALIZATION_PENDING"
  case ONGOING_REQUEST        = "ONGOING_REQUEST"
  case SUCCESS                = "SUCCESS"
  case REQUEST_FAILED         = "REQUEST_FAILED"
}

public class Obopayments : NSObject, SFSafariViewControllerDelegate {
  
  private var businessUIViewC     : UIViewController?
  private var currSessionRequest  : SessionRequest?
  
  private var sdkInitPending      : Bool                = true
  private var requestInProgress   : Bool                = false
  
  private let scheme  : String = "https"
  private let host    : String = "192.168.216.141"
  private let port    : String = "443"
  private var reqId   : Int    = 0
  
  private var requestMap       : [String : (([String : Any]) -> Void)?] = [:]
  private var userCloseCallback : (() -> ())?
  
  public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
//    self.businessUIViewC?.dismiss(animated: false, completion: nil)
    self.userCloseCallback!()
  }
  
  /*============================================================================
                                 BUSINESS APIS
    ============================================================================*/
  
  public func setUserCloseCallback(cb : (() -> ())?) {
    self.userCloseCallback = cb
  }
  
  public func initialize(uiViewController : UIViewController, businessRegId : String,
                mobileNo : String, authKey : String, businessName : String,
                businessLogoUrl : String) {
  
      self.businessUIViewC    = uiViewController
    
      self.currSessionRequest =
        SessionRequest(businessRegId: businessRegId, mobileNo: mobileNo,
                       authKey: authKey, businessName: businessName,
                       businessLogoUrl: businessLogoUrl)
      
      self.sdkInitPending     = false
  }
  
  
  public func setResponse(url : URL) {
    
    let responseMsg : [String : Any]  =
      JSON.objectifyJSONObjectString(jsonObjectString: url.getValue(queryKey: "response")!)
    
    let messageId   : String          = responseMsg["messageId"] as! String
    let response    : [String : Any]  = responseMsg["response"] as! [String : Any]
    var requestId   : Int?
    guard let requestI = responseMsg["requestId"] else { return }
    
    if let number = requestI as? Int {
      requestId = number
      self.businessUIViewC!.dismiss(animated: false, completion: nil)
    } else {
      requestId = Int(responseMsg["requestId"] as! String)!
    }
    
    let cb : (([String : Any]) -> Void)? =
      self.requestMap["\(requestId!)"]! as (([String : Any]) -> Void)?
    
    if ( (response["code"] as! String) == "FAILURE" ) {
      
      if (messageId == "ONGOING_ACTION") {
        cb!(response)
        return
      }
      
      self.businessUIViewC!.dismiss(animated: false, completion: nil)
    }
    
    cb!(response)
    return
  }
  
  
  public func activateUser(data : [String : Any], cb : @escaping (([String : Any]) -> Void?)) -> [String : Any] {
    
    if (self.sdkInitPending == true) {
      return createError(errorCode: .INITIALIZATION_PENDING,
                         errorMessage: "Initialize sdk before using this api")
    }
    self.requestInProgress = true
    
    self.reqId = self.reqId + 1
    
    let callback : (([String : Any]) -> Void)? = {
      response in
      
      if ((response["data"] != nil) &&
          (response["data"] as! [String : Any])["errorCode"] != nil &&
          ((response["data"] as! [String : Any])["errorCode"] as! String) == "OPERATION_IN_PROGRESS") {
        
        cb(response)
        return
      }
      
      self.businessUIViewC!.dismiss(animated: false, completion: nil)
      cb(response)
    }
    
    requestMap["\(self.reqId)"]     = callback
    let reqId     : String          = "\(self.reqId)"
    let messageId : String          = "DIRECT_LINK"
    
    var userData  : [String : Any]  = [:]
        userData["userDetails"]     = data
    
    let data    : [String : Any]  = self.createData(directLink: "sdkRoot/sdkRegistration",
                                                    dlParam: userData)
    
    let request : [String : Any]  = self.createRequest(requestId: reqId, messageId: messageId,
                                                       data: data)
    
    let context : [String : Any]  = self.getUserObject(session: self.currSessionRequest!)
    
    let url : URL         = self.createInvokingUrl(request: request, context: context)
    
    let sfViewController  = SFSafariViewController(url: url)
        sfViewController.delegate = self
    
    self.businessUIViewC!.present(sfViewController, animated: false, completion: nil)
    
    return createError(errorCode: .ONGOING_REQUEST, errorMessage: "request is started to process")
  }
  
  
  public func loginUser(cb : @escaping (([String : Any]) -> Void?)) -> [String : Any] {
    
    if (self.sdkInitPending == true) {
      return createError(errorCode: .INITIALIZATION_PENDING, errorMessage: "Initialize sdk before using this api")
    }
    
    self.requestInProgress = true
  
    self.reqId = self.reqId + 1
    
    let callback : (([String : Any]) -> Void) = {
      response in
      
      if ((response["data"] != nil) &&
        (response["data"] as! [String : Any])["errorCode"] != nil &&
        ((response["data"] as! [String : Any])["errorCode"] as! String) == "OPERATION_IN_PROGRESS") {
        
        cb(response)
        return
      }
      
      self.businessUIViewC!.dismiss(animated: false, completion: nil)
      cb(response)
    }
    
    requestMap["\(self.reqId)"] = callback
    
    let reqId     : String        = "\(self.reqId)"
    let messageId : String        = "DIRECT_LINK"
    
    let data1   : [String : Any]  = self.createData(directLink: "sdkRoot/sdkLogin", dlParam: nil)
    let request : [String : Any]  = self.createRequest(requestId: reqId, messageId: messageId, data: data1)
    let context : [String : Any]  = self.getUserObject(session: self.currSessionRequest!)
    
    let url : URL         = self.createInvokingUrl(request: request, context: context)
    
    let sfViewController  = SFSafariViewController(url: url)
        sfViewController.delegate = self
    
    self.businessUIViewC!.present(sfViewController, animated: false, completion: nil)
    
    return createError(errorCode: .ONGOING_REQUEST, errorMessage: "request is started to process")
  }
  
  
  public func viewTransactionHistory(data : [String : Any], cb : @escaping (([String : Any]) -> Void?)) -> [String : Any] {
    
    if (self.sdkInitPending == true) {
      return createError(errorCode: .INITIALIZATION_PENDING, errorMessage: "Initialize sdk before using this api")
    }
    
    self.requestInProgress = true
    
    self.reqId = self.reqId + 1
    
    let callback : (([String : Any]) -> Void) = {
      response in
      
      if ((response["data"] != nil) &&
        (response["data"] as! [String : Any])["errorCode"] != nil &&
        ((response["data"] as! [String : Any])["errorCode"] as! String) == "OPERATION_IN_PROGRESS") {
        
        cb(response)
        return
      }
      
      self.businessUIViewC!.dismiss(animated: false, completion: nil)
      cb(response)
    }
    
    requestMap["\(self.reqId)"] = callback
    
    let reqId     : String          = "\(self.reqId)"
    let messageId : String          = "DIRECT_LINK"
    
    let data1   : [String : Any]  = self.createData(directLink: "walletMgmt/walletHistory", dlParam: data)
    let request : [String : Any]  = self.createRequest(requestId: reqId, messageId: messageId, data: data1)
    let context : [String : Any]  = self.getUserObject(session: self.currSessionRequest!)
    
    let url : URL         = self.createInvokingUrl(request: request, context: context)
    
    let sfViewController  = SFSafariViewController(url: url)
        sfViewController.delegate = self
    
    self.businessUIViewC!.present(sfViewController, animated: false, completion: nil)
    
    return createError(errorCode: .ONGOING_REQUEST, errorMessage: "request is started to process")
  }
  
  
  public func selectTransactionHistory(data : [String : Any],
                                              cb : @escaping (([String : Any]) -> Void?)) -> [String : Any] {
    
    if (self.sdkInitPending == true) {
      return createError(errorCode: .INITIALIZATION_PENDING, errorMessage: "Initialize sdk before using this api")
    }
    
    self.requestInProgress = true
    
    self.reqId = self.reqId + 1
    
    let callback : (([String : Any]) -> Void) = {
      response in
      
      if ((response["data"] != nil) &&
        (response["data"] as! [String : Any])["errorCode"] != nil &&
        ((response["data"] as! [String : Any])["errorCode"] as! String) == "OPERATION_IN_PROGRESS") {
        cb(response)
        return
      }
      
      self.businessUIViewC!.dismiss(animated: false, completion: nil)
      cb(response)
    }
    
    requestMap["\(self.reqId)"] = callback
    
    let reqId     : String          = "\(self.reqId)"
    let messageId : String          = "DIRECT_LINK"
    
    var dlParams  : [String : Any]  = [:]
        dlParams["walletType"]      = data["walletType"]
        dlParams["selectable"]      = true
    
    let data1   : [String : Any]  = self.createData(directLink: "walletMgmt/walletHistory", dlParam: dlParams)
    let request : [String : Any]  = self.createRequest(requestId: reqId, messageId: messageId, data: data1)
    let context : [String : Any]  = self.getUserObject(session: self.currSessionRequest!)
    
    let url = self.createInvokingUrl(request: request, context: context)
    
    let sfViewController = SFSafariViewController(url: url)
        sfViewController.delegate = self
    
    self.businessUIViewC!.present(sfViewController, animated: false, completion: nil)
    
    return createError(errorCode: .ONGOING_REQUEST, errorMessage: "request is started to process")
  }
  
  
  public func addMoney(data : [String : Any],
                              cb : @escaping (([String : Any]) -> Void?)) -> [String : Any] {
    
    if (self.sdkInitPending == true) {
      return createError(errorCode: .INITIALIZATION_PENDING, errorMessage: "Initialize sdk before using this api")
    }
    
    self.requestInProgress = true
    
    self.reqId = self.reqId + 1
    
    let callback : (([String : Any]) -> Void) = {
      response in
      
      if ((response["data"] != nil) &&
        (response["data"] as! [String : Any])["errorCode"] != nil &&
        ((response["data"] as! [String : Any])["errorCode"] as! String) == "OPERATION_IN_PROGRESS") {
        cb(response)
        return
      }
      
      self.businessUIViewC!.dismiss(animated: false, completion: nil)
      cb(response)
    }
    
    requestMap["\(self.reqId)"] = callback
    
    let reqId     : String          = "\(self.reqId)"
    let messageId : String          = "DIRECT_LINK"
    
    let data1   : [String : Any]  = self.createData(directLink: "loadMoney/selectPg", dlParam: data)
    let request : [String : Any]  = self.createRequest(requestId: reqId, messageId: messageId, data: data1)
    let context : [String : Any]  = self.getUserObject(session: self.currSessionRequest!)
    
    let url = self.createInvokingUrl(request: request, context: context)
    
    let sfViewController = SFSafariViewController(url: url)
        sfViewController.delegate = self
    
    self.businessUIViewC!.present(sfViewController, animated: false, completion: nil)
    
    return createError(errorCode: .ONGOING_REQUEST, errorMessage: "request is started to process")
  }
  
  
  public func sendMoney(data : [String : Any],
                               cb : @escaping (([String : Any]) -> Void?)) -> [String : Any] {
    
    if (self.sdkInitPending == true) {
      return createError(errorCode: .INITIALIZATION_PENDING, errorMessage: "Initialize sdk before using this api")
    }
    
    self.requestInProgress = true
    
    self.reqId = self.reqId + 1
    
    let callback : (([String : Any]) -> Void) = {
      response in
      
      if ((response["data"] != nil) &&
        (response["data"] as! [String : Any])["errorCode"] != nil &&
        ((response["data"] as! [String : Any])["errorCode"] as! String) == "OPERATION_IN_PROGRESS") {
        cb(response)
        return
      }
      
      self.businessUIViewC!.dismiss(animated: false, completion: nil)
      cb(response)
    }
    
    requestMap["\(self.reqId)"] = callback
    
    let reqId     : String          = "\(self.reqId)"
    let messageId : String          = "DIRECT_LINK"
    
    let data1   : [String : Any]  = self.createData(directLink: "sendMoney/transMoney", dlParam: data)
    let request : [String : Any]  = self.createRequest(requestId: reqId, messageId: messageId, data: data1)
    let context : [String : Any]  = self.getUserObject(session: self.currSessionRequest!)
    
    let url = self.createInvokingUrl(request: request, context: context)
    
    let sfViewController = SFSafariViewController(url: url)
        sfViewController.delegate = self
    
    self.businessUIViewC!.present(sfViewController, animated: false, completion: nil)
    
    return createError(errorCode: .ONGOING_REQUEST, errorMessage: "request is started to process")
  }
  
  
  public func collectRequest(data : [String : Any],
                                    cb : @escaping (([String : Any]) -> Void?)) -> [String : Any] {
    
    if (self.sdkInitPending == true) {
      return createError(errorCode: .INITIALIZATION_PENDING, errorMessage: "Initialize sdk before using this api")
    }
    
    self.requestInProgress = true
    
    self.reqId = self.reqId + 1
    
    let callback : (([String : Any]) -> Void) = {
      response in
      
      if ((response["data"] != nil) &&
        (response["data"] as! [String : Any])["errorCode"] != nil &&
        ((response["data"] as! [String : Any])["errorCode"] as! String) == "OPERATION_IN_PROGRESS") {
        cb(response)
        return
      }
      
      self.businessUIViewC!.dismiss(animated: false, completion: nil)
      cb(response)
    }
    
    requestMap["\(self.reqId)"] = callback
    
    let reqId     : String          = "\(self.reqId)"
    let messageId : String          = "DIRECT_LINK"
    
    let data1   : [String : Any]  = self.createData(directLink: "sendMoney/collectRequest", dlParam: data)
    let request : [String : Any]  = self.createRequest(requestId: reqId, messageId: messageId, data: data1)
    let context : [String : Any]  = self.getUserObject(session: self.currSessionRequest!)
    
    let url = self.createInvokingUrl(request: request, context: context)
    
    let sfViewController = SFSafariViewController(url: url)
        sfViewController.delegate = self
    
    self.businessUIViewC!.present(sfViewController, animated: false, completion: nil)
    
    return createError(errorCode: .ONGOING_REQUEST, errorMessage: "request is started to process")
  }
  
  
  public func lockCard(cb : @escaping (([String : Any]) -> Void?)) -> [String : Any] {
    
    var data : [String : Any] = [:]
        data["action"]        = "LOCK"
    
    if (self.sdkInitPending == true) {
      return createError(errorCode: .INITIALIZATION_PENDING, errorMessage: "Initialize sdk before using this api")
    }
    
    self.requestInProgress = true
    
    self.reqId = self.reqId + 1
    
    let callback : (([String : Any]) -> Void) = {
      response in
      
      if ((response["data"] != nil) &&
        (response["data"] as! [String : Any])["errorCode"] != nil &&
        ((response["data"] as! [String : Any])["errorCode"] as! String) == "OPERATION_IN_PROGRESS") {
        cb(response)
        return
      }
      
      self.businessUIViewC!.dismiss(animated: false, completion: nil)
      cb(response)
    }
    
    requestMap["\(self.reqId)"] = callback
    
    let reqId     : String          = "\(self.reqId)"
    let messageId : String          = "DIRECT_LINK"
    
    let data1   : [String : Any]  = self.createData(directLink: "cardMgmt/changeCardStatus", dlParam: data)
    let request : [String : Any]  = self.createRequest(requestId: reqId, messageId: messageId, data: data1)
    let context : [String : Any]  = self.getUserObject(session: self.currSessionRequest!)
    
    let url = self.createInvokingUrl(request: request, context: context)
    
    let sfViewController = SFSafariViewController(url: url)
        sfViewController.delegate = self
    
    self.businessUIViewC!.present(sfViewController, animated: false, completion: nil)
    
    return createError(errorCode: .ONGOING_REQUEST, errorMessage: "request is started to process")
  }
  
  public func blockCard(cb : @escaping (([String : Any]) -> Void?)) -> [String : Any] {
    
    var data : [String : Any] = [:]
        data["action"]        = "BLOCK"
    
    if (self.sdkInitPending == true) {
      return createError(errorCode: .INITIALIZATION_PENDING, errorMessage: "Initialize sdk before using this api")
    }
    
    self.requestInProgress = true
    
    self.reqId = self.reqId + 1
    
    let callback : (([String : Any]) -> Void) = {
      response in
      
      if ((response["data"] != nil) &&
        (response["data"] as! [String : Any])["errorCode"] != nil &&
        ((response["data"] as! [String : Any])["errorCode"] as! String) == "OPERATION_IN_PROGRESS") {
        cb(response)
        return
      }
      
      self.businessUIViewC!.dismiss(animated: false, completion: nil)
      cb(response)
    }
    
    requestMap["\(self.reqId)"] = callback
    
    let reqId     : String          = "\(self.reqId)"
    let messageId : String          = "DIRECT_LINK"
    
    let data1   : [String : Any]  = self.createData(directLink: "cardMgmt/changeCardStatus", dlParam: data)
    let request : [String : Any]  = self.createRequest(requestId: reqId, messageId: messageId, data: data1)
    let context : [String : Any]  = self.getUserObject(session: self.currSessionRequest!)
    
    let url = self.createInvokingUrl(request: request, context: context)
    
    let sfViewController = SFSafariViewController(url: url)
        sfViewController.delegate = self
    
    self.businessUIViewC!.present(sfViewController, animated: false, completion: nil)
    
    return createError(errorCode: .ONGOING_REQUEST, errorMessage: "request is started to process")
  }
  
  public func requestMoney(data : [String : Any],
                                  cb : @escaping (([String : Any]) -> Void?)) -> [String : Any] {
    
    if (self.sdkInitPending == true) {
      return createError(errorCode: .INITIALIZATION_PENDING, errorMessage: "Initialize sdk before using this api")
    }
    
    self.requestInProgress = true
    
    self.reqId = self.reqId + 1
    
    let callback : (([String : Any]) -> Void) = {
      response in
      
      if ((response["data"] != nil) &&
        (response["data"] as! [String : Any])["errorCode"] != nil &&
        ((response["data"] as! [String : Any])["errorCode"] as! String) == "OPERATION_IN_PROGRESS") {
        cb(response)
        return
      }
      
      self.businessUIViewC!.dismiss(animated: false, completion: nil)
      cb(response)
    }
    
    requestMap["\(self.reqId)"] = callback
    
    let reqId     : String          = "\(self.reqId)"
    let messageId : String          = "DIRECT_LINK"
    
    let data1   : [String : Any]  = self.createData(directLink: "reqMoney/selectSender", dlParam: data)
    let request : [String : Any]  = self.createRequest(requestId: reqId, messageId: messageId, data: data1)
    let context : [String : Any]  = self.getUserObject(session: self.currSessionRequest!)
    
    let url = self.createInvokingUrl(request: request, context: context)
    
    let sfViewController = SFSafariViewController(url: url)
        sfViewController.delegate = self
    
    self.businessUIViewC!.present(sfViewController, animated: false, completion: nil)
    
    return createError(errorCode: .ONGOING_REQUEST, errorMessage: "request is started to process")
  }
  
  /*============================================================================
                                PRIVATE METHODS
    ============================================================================*/
  
  private  func getUserObject(session : SessionRequest) -> [String : Any] {
    
    var userObj : [String : Any]    = [:]
        userObj["businessRegId"]    = session.businessRegId
        userObj["businessName"]     = session.businessName
        userObj["authKey"]          = session.authKey
        userObj["businessLogoUrl"]  = session.businessLogoUrl
        userObj["mobileNo"]         = session.mobileNo
    
    return userObj
  }
  
  private  func createInvokingUrl(request : [String : Any],
                                        context : [String : Any]) -> URL {
    
    var url = URL(string: "\(self.scheme)://\(self.host):\(self.port)/payments")
    
        url = url!.addQueryParam(key: "userAgent", value: "cordova")
        url = url!.addQueryParam(key: "request", value: JSON.stringifyJSONObject(jsonObject: request))
        url = url!.addQueryParam(key: "context", value: JSON.stringifyJSONObject(jsonObject: context))
    
    return url!
  }
  
  private  func createError(errorCode : SdkErrorCode,
                                  errorMessage : String) -> [String : Any] {
    
    var jsonObject : [String : Any] = [:]
        jsonObject["errorCode"]     = errorCode.rawValue
        jsonObject["errorMessage"]  = errorMessage
    
    return jsonObject
  }
  
  private  func createRequest(requestId : String, messageId : String,
                                    data : [String : Any]) -> [String : Any] {
    
    var jsonObject : [String : Any] = [:]
        jsonObject["requestId"]     = requestId
        jsonObject["messageId"]     = messageId
        jsonObject["data"]          = data
    
    return jsonObject
  }
  
  private  func createData(directLink : String,
                                 dlParam : [String : Any]?) -> [String : Any] {
    
    var jsonObject : [String : Any] = [:]
        jsonObject["directLink"]    = directLink
        jsonObject["dlParams"]      = dlParam
    
    return jsonObject
  }
  
}
