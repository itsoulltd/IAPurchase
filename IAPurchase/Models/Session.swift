/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import CoreDataStack

@objc(ReceiptStatus)
public enum ReceiptStatus: Int{
    case Active = 0
    case BadJson = 21000
    case ServiceUnavailable = 21005
    case Inactive = 21006
    
    public func toString() -> String {
        switch self {
        case .Active:
            return "Active"
        case .BadJson:
            return "BadJson"
        case .ServiceUnavailable:
            return "ServiceUnavailable"
        case .Inactive:
            return "Inactive"
        }
    }
}

@objc(Session)
public class Session: NGObject {
    
    public var id: String?
    public var paidSubscriptions: [Subscription]?
    
    public var currentSubscription: Subscription? {
        let sortedByMostRecentPurchase = paidSubscriptions?.sorted { $0.purchaseDate > $1.purchaseDate }
        return sortedByMostRecentPurchase?.first
    }
    
    @objc public var receiptData: Data?
    public var parsedReceipt: [String: Any]?
    
    public func receiptStatus() -> ReceiptStatus{
        if let status = parsedReceipt!["status"] as? Int, let receiptStatus = ReceiptStatus(rawValue: status){
            return receiptStatus
        }
        return .Inactive
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public init(decryptedData: Data) {
        super.init()
        loader(decryptedData: decryptedData)
    }
    
    private func loader(decryptedData: Data){
        
        let json = try! JSONSerialization.jsonObject(with: decryptedData, options: []) as! Dictionary<String, Any>
        print(json)
        
        id = UUID().uuidString
        self.receiptData = decryptedData
        self.parsedReceipt = json
        
        if let latestPurchases = parsedReceipt!["latest_receipt_info"] as? Array<[String: Any]>{
            var subscriptions = [Subscription]()
            for purchase in latestPurchases {
                if let paidSubscription = Subscription(json: purchase) {
                    subscriptions.append(paidSubscription)
                }
            }
            paidSubscriptions = subscriptions
        } else {
            paidSubscriptions = []
        }
    }
    
    public override func updateValue(_ value: Any!, forKey key: String!) {
        if key == "receiptData" {
            receiptData = Data(base64Encoded: value as! String)
            if let data = receiptData{
                loader(decryptedData: data)
            }
        }
    }
    
}
