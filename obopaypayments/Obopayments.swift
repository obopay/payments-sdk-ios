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
  
  init(businessRegId : String, mobileNo : String, authKey : String) {
    
    self.mobileNo         = mobileNo
    self.authKey          = authKey
    self.businessRegId    = businessRegId
    
  }
  
  func toJSONObject() -> [String : Any] {
    
    var jsonObj : [String : Any] = [:]
        jsonObj["businessRegId"]    = self.businessRegId
        jsonObj["mobileNo"]         = self.mobileNo
        jsonObj["authKey"]          = self.authKey
    
    return jsonObj
  }
  
}

enum SdkErrorCode : String {
  case INITIALIZATION_PENDING = "INITIALIZATION_PENDING"
  case OPERATION_IN_PROGRESS  = "OPERATION_IN_PROGRESS"
}

public class Obopayments : NSObject, SFSafariViewControllerDelegate {
  
  private var businessVC          : UIViewController?
  private var currSessionRequest  : SessionRequest?
  private var sdkInitPending      : Bool                = true
  private var requestInProgress   : Bool                = false
  
  private let scheme      : String    = "https"
  private let host        : String    = "192.168.216.141"
  private let port        : String    = "443"
  private var reqId       : Int       = 0
  private let DIRECT_LINK : String    = "DIRECT_LINK"
  
  private var bgColor     : UIColor?
  private var fgColor     : UIColor?
  private var callback    : (([String : Any]) -> Void)?
  
  private var userCloseCallback : (() -> ())?
  
  
  
  public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    self.businessVC?.dismiss(animated: false, completion: nil)
    self.requestInProgress = false
    self.userCloseCallback!()
  }
  
  /*============================================================================
                                 BUSINESS APIS
    ============================================================================*/
  
  public func initialize(uiViewController : UIViewController, businessRegId : String,
                         mobileNo : String, authKey : String, fgColor : UIColor?,
                         bgColor : UIColor?) {
  
    self.businessVC = uiViewController
  
    self.currSessionRequest =
        SessionRequest(businessRegId: businessRegId, mobileNo: mobileNo,
                       authKey: authKey)
    
    self.bgColor = bgColor
    self.fgColor = fgColor
      
    self.sdkInitPending     = false
  }
  
  public func setUserCloseCallback(cb : (() -> ())?) {
    self.userCloseCallback = cb
  }
  
  public func setResponse(url : URL) {
    
    self.requestInProgress = false
    
    let responseMsg : [String : Any]  =
      JSON.fromJSON(jsonObjectString: url.getValue(queryKey: "response")!)
    
    let response  : [String : Any]              = responseMsg["response"] as! [String : Any]
    let cb        : (([String : Any]) -> Void)? = self.callback
    
    if ( (response["code"] as! String) == "FAILURE" ) {
      self.businessVC!.dismiss(animated: false, completion: nil)
    }
    
    cb!(response)
    return
  }
  
  
  public func activateUser(data : [String : Any],
                           cb : @escaping (([String : Any]) -> Void?)) -> [String : Any]? {
    
    let initRes = self.validateCall()
    if (initRes != nil) {
      return initRes!
    }
    
    var userData  : [String : Any]  = [:]
        userData["userDetails"]     = data
    
    self.callback = self.createCallback(cb: cb)
    self.openSafari(request : self.createRequest(directLink: "sdkRoot/sdkRegistration",
                                                 dlParam: userData))
    return nil
  }
  
  
  public func loginUser(cb : @escaping (([String : Any]) -> Void?)) -> [String : Any]? {
    
    let initRes = self.validateCall()
    if (initRes != nil) {
      return initRes!
    }
    
    self.callback = self.createCallback(cb: cb)
    self.openSafari(request : self.createRequest(directLink: "sdkRoot/sdkLogin",
                                                 dlParam: nil))
    return nil
  }
  
  
  public func viewTransactionHistory(data : [String : Any],
                                     cb : @escaping (([String : Any]) -> Void?)) -> [String : Any]? {
    
    let initRes = self.validateCall()
    if (initRes != nil) {
      return initRes!
    }
    
    self.callback = self.createCallback(cb: cb)
    self.openSafari(request : self.createRequest(directLink: "walletMgmt/walletHistory",
                                                 dlParam: data))
    return nil
  }
  
  
  public func selectTransactionHistory(data : [String : Any],
                                       cb : @escaping (([String : Any]) -> Void?)) -> [String : Any]? {
    
    let initRes = self.validateCall()
    if (initRes != nil) {
      return initRes!
    }
    
    var dlParams  : [String : Any]  = [:]
        dlParams["walletType"]      = data["walletType"]
        dlParams["selectable"]      = true
    
    self.callback = self.createCallback(cb: cb)
    self.openSafari(request : self.createRequest(directLink: "walletMgmt/walletHistory",
                                                 dlParam: dlParams))
    return nil
  }
  
  
  public func addMoney(data : [String : Any],
                              cb : @escaping (([String : Any]) -> Void?)) -> [String : Any]? {
    
    let initRes = self.validateCall()
    if (initRes != nil) {
      return initRes!
    }
    
    self.callback = self.createCallback(cb: cb)
    self.openSafari(request : self.createRequest(directLink: "loadMoney/selectPg",
                                                 dlParam: data))
    return nil
  }
  
  
  public func sendMoney(data : [String : Any],
                        cb : @escaping (([String : Any]) -> Void?)) -> [String : Any]? {
    
    let initRes = self.validateCall()
    if (initRes != nil) {
      return initRes!
    }
    
    self.callback = self.createCallback(cb: cb)
    self.openSafari(request : self.createRequest(directLink: "sendMoney/transMoney",
                                                 dlParam: data))
    return nil
  }
  
  
  public func collectRequest(data : [String : Any],
                             cb : @escaping (([String : Any]) -> Void?)) -> [String : Any]? {
    
    let initRes = self.validateCall()
    if (initRes != nil) {
      return initRes!
    }
    
    self.callback = self.createCallback(cb: cb)
    self.openSafari(request : self.createRequest(directLink: "sendMoney/collectRequest",
                                                 dlParam: data))
    return nil
  }
  
  
  public func lockCard(cb : @escaping (([String : Any]) -> Void?)) -> [String : Any]? {
    
    var data : [String : Any] = [:]
        data["action"]        = "LOCK"
    
    let initRes = self.validateCall()
    if (initRes != nil) {
      return initRes!
    }
    
    self.callback = self.createCallback(cb: cb)
    self.openSafari(request : self.createRequest(directLink: "cardMgmt/changeCardStatus",
                                                 dlParam: data))
    return nil
  }
  
  public func blockCard(cb : @escaping (([String : Any]) -> Void?)) -> [String : Any]? {
    
    var data : [String : Any] = [:]
        data["action"]        = "BLOCK"
    
    let initRes = self.validateCall()
    if (initRes != nil) {
      return initRes!
    }
    
    self.callback = self.createCallback(cb: cb)
    self.openSafari(request : self.createRequest(directLink: "cardMgmt/changeCardStatus",
                                                 dlParam: data))
    return nil
  }
  
  public func requestMoney(data : [String : Any],
                           cb : @escaping (([String : Any]) -> Void?)) -> [String : Any]? {
    
    let initRes = self.validateCall()
    if (initRes != nil) {
      return initRes!
    }
    
    self.callback = self.createCallback(cb: cb)
    self.openSafari(request : self.createRequest(directLink: "reqMoney/selectSender",
                                                 dlParam: data))
    return nil
  }
  
  /*============================================================================
                                PRIVATE METHODS
    ============================================================================*/
  
  private  func getUserObject(session : SessionRequest) -> [String : Any] {
    
    var userObj : [String : Any]    = [:]
        userObj["businessRegId"]    = session.businessRegId
        userObj["authKey"]          = session.authKey
        userObj["mobileNo"]         = session.mobileNo
    
    return userObj
  }
  
  private  func createInvokingUrl(request : [String : Any],
                                        context : [String : Any]) -> URL {
    
    var url = URL(string: "\(self.scheme)://\(self.host):\(self.port)/payments")
    
        url = url!.addQueryParam(key: "userAgent", value: "paymentsCordova")
        url = url!.addQueryParam(key: "request", value: JSON.toJSON(jsonObject: request))
        url = url!.addQueryParam(key: "context", value: JSON.toJSON(jsonObject: context))
    
    return url!
  }
  
  private  func createError(errorCode : SdkErrorCode,
                                  errorMessage : String) -> [String : Any] {
    
    var jsonObject : [String : Any] = [:]
        jsonObject["errorCode"]     = errorCode.rawValue
        jsonObject["errorMessage"]  = errorMessage
    
    return jsonObject
  }
  
  private  func createRequest(directLink : String,
                              dlParam : [String : Any]?) -> [String : Any] {
    
    let requestId : String          = "\(self.getNewReqId())"
    let messageId : String          =  DIRECT_LINK
    let data      : [String : Any]  = self.createData(directLink: directLink,
                                                      dlParam: dlParam)
    
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
  
  private func openSafari(request : [String : Any]) {
    
    let context : [String : Any]  = self.getUserObject(session: self.currSessionRequest!)
    let url     : URL             = self.createInvokingUrl(request: request, context: context)
    
    self.requestInProgress = true
    
    let sfViewController  = SFSafariViewController(url: url)
        sfViewController.delegate = self
    
    if (self.bgColor != nil) {
      sfViewController.preferredBarTintColor = self.bgColor!
    }
    
    if (self.fgColor != nil) {
      sfViewController.preferredControlTintColor = self.fgColor!
    }
    
    self.businessVC!.present(sfViewController, animated: false, completion: nil)
    
  }
  
  private func validateCall() -> [String : Any]? {
    if (self.sdkInitPending == true) {
      return createError(errorCode: .INITIALIZATION_PENDING,
                         errorMessage: "Obopayments SDK is not initialized")
    }
    
    if (self.requestInProgress == true) {
      return createError(errorCode: .OPERATION_IN_PROGRESS,
                         errorMessage: "An ongoing action has not yet completed. Another request cannot be made until it finishes")
    }
    
    return nil
  }
  
  private func createCallback(cb : @escaping ([String : Any]) -> Void?) -> (([String : Any]) -> Void) {
    let callback : (([String : Any]) -> Void) = {
      response in
      
      self.businessVC!.dismiss(animated: false, completion: nil)
      cb(response)
    }
    return callback
  }
  
  private func getNewReqId() -> Int {
    self.reqId = self.reqId + 1
    return self.reqId
  }
  
}
