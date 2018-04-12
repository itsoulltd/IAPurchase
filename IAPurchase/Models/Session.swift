/**
 * Copyright (c) 2017 Towhidul Islam
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
    private var paidSubscriptions: [Subscription]?
    private var paidSubscriptionsByGroup: [String:[Subscription]]?
    private var nonConsumptions: [NonConsumable]?
    
    public func isPurchased(_ iapID: String) -> Bool{
        //Pick from current Subscription
        if let cSub = currentSubscription, cSub.productIdentifier == iapID {
            return cSub.isActive
        }
        //Pick from Subscription Group
        if paidSubscriptionsByGroup == nil {
            paidSubscriptionsByGroup = subscriptionsByGroup
        }
        if let pSubs = paidSubscriptionsByGroup?[iapID]{
            let sortedByMostRecentPurchase = pSubs.sorted { $0.purchaseDate > $1.purchaseDate }
            guard let sub = sortedByMostRecentPurchase.first else{
                return false
            }
            return sub.isActive
        }
        //Pick from nonConsumed Items
        guard let nonConsumableItems = nonConsumptions else { return false }
        let isPurchased = nonConsumableItems.contains(where: { (item: NonConsumable) -> Bool in
            return item.productIdentifier == iapID
        })
        return isPurchased
    }
    
    public func productType(by iapID: String) -> NonConsumable?{
        //Pick from current Subscription
        if let cSub = currentSubscription, cSub.productIdentifier == iapID {
            return cSub
        }
        //Pick from Subscription Group
        if paidSubscriptionsByGroup == nil {
            paidSubscriptionsByGroup = subscriptionsByGroup
        }
        if let pSubs = paidSubscriptionsByGroup?[iapID]{
            let sortedByMostRecentPurchase = pSubs.sorted { $0.purchaseDate > $1.purchaseDate }
            guard let sub = sortedByMostRecentPurchase.first else{
                return nil
            }
            return sub
        }
        //Pick from nonConsumed Items
        guard let nonConsumableItems = nonConsumptions else { return nil }
        let filteredItems = nonConsumableItems.filter { (item: NonConsumable) -> Bool in
            return item.productIdentifier == iapID
        }
        return filteredItems.first
    }
    
    public var currentSubscription: Subscription? {
        let sortedByMostRecentPurchase = paidSubscriptions?.sorted { $0.purchaseDate > $1.purchaseDate }
        return sortedByMostRecentPurchase?.first
    }
    
    public var subscriptionsByGroup: [String:[Subscription]]?{
        guard let pSubs = paidSubscriptions else { return nil }
        //
        let container = pSubs.reduce(into: [String: [Subscription]]()) { (results, item: Subscription) in
            if(results.keys.contains(item.productIdentifier)){
                var items = results[item.productIdentifier]
                items?.append(item)
            }else{
                results[item.productIdentifier] = Array<Subscription>(arrayLiteral: item)
            }
        }
        return container
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
    
    public init(decryptedData: Data, debugMode: Bool = false) {
        super.init()
        loader(decryptedData: decryptedData)
    }
    
    private func loader(decryptedData: Data, debugMode: Bool = false){
        
        let json = try! JSONSerialization.jsonObject(with: decryptedData, options: []) as! Dictionary<String, Any>
        if debugMode { print(json) }
        
        id = UUID().uuidString
        self.receiptData = decryptedData
        self.parsedReceipt = json
        
        if let latestPurchases = parsedReceipt!["latest_receipt_info"] as? Array<[String: Any]>{
            paidSubscriptions = [Subscription]()
            nonConsumptions = [NonConsumable]()
            //
            for purchase in latestPurchases {
                if let paidSubscription = Subscription(json: purchase) {
                    paidSubscriptions?.append(paidSubscription)
                }
                else if let nonConsumable = NonConsumable(json: purchase){
                    nonConsumptions?.append(nonConsumable)
                }
            }
            //
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
