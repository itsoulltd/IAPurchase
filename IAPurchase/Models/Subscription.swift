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

@objc(NonConsumable)
@objcMembers
public class NonConsumable: NSObject {
    
    public var productIdentifier: String
    public var purchaseDate: Date
    public var transactionId: String
    
    public init?(json: [String: Any]) {
        guard
            let productId = json["product_id"] as? String,
            let purchaseDateString = json["purchase_date"] as? String,
            let purchaseDate = dateFormatter.date(from: purchaseDateString),
            let transaction_id = json["transaction_id"] as? String
            else {
                return nil
        }
        
        self.productIdentifier = productId
        self.purchaseDate = purchaseDate
        self.transactionId = transaction_id
        
    }
    
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    return formatter
}()

@objc(Subscription)
@objcMembers
public class Subscription: NonConsumable {
    
    public var expiresDate: Date
    public var cancellationDate: Date?
    public var isTrialPeriod: Bool
    
    public var isActive: Bool {
        if isCancelled{
            return false
        }
        // is current date between purchaseDate and expiresDate?
        let dateStr = dateFormatter.string(from: Date())
        let nowDate = dateFormatter.date(from: dateStr)
        let active = (purchaseDate...expiresDate).contains(nowDate!)
        return active
    }
    
    public var isCancelled: Bool{
        return (cancellationDate != nil)
    }
    
    public override init?(json: [String: Any]) {
        guard
            let _ = json["product_id"] as? String,
            let purchaseDateString = json["purchase_date"] as? String,
            let _ = dateFormatter.date(from: purchaseDateString),
            let _ = json["transaction_id"] as? String,
            let expiresDateString = json["expires_date"] as? String,
            let expiresDate = dateFormatter.date(from: expiresDateString),
            let is_trial_period = json["is_trial_period"] as? String
            else {
                return nil
        }
        self.expiresDate = expiresDate
        self.isTrialPeriod = (is_trial_period == "true") ? true : false;
        super.init(json: json)
        
        if let cancellationDateStr = json["cancellation-date"] as? String{
            cancellationDate = dateFormatter.date(from: cancellationDateStr)
        }
    }
}
