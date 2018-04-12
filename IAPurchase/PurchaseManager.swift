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
import StoreKit

public typealias OnProductsLoadCompletion = ([IAProduct]?) -> Void

@objcMembers
public class PurchaseManager: NSObject {
    
    public static let restoreSuccessfulNotification = Notification.Name("SubscriptionServiceRestoreSuccessfulNotification")
    public static let restoreFailureNotification = Notification.Name("SubscriptionServiceRestoreFailureNotification")
    public static let purchaseSuccessfulNotification = Notification.Name("SubscriptionServicePurchaseSuccessfulNotification")
    public static let purchaseFailureNotification = Notification.Name("SubscriptionServicePurchaseFailureNotification")
    
    public static let shared = PurchaseManager()
    
    public let simulatedStartDate: Date
    private var savedSession: Session?
    private var sharedSecrate: String?
    private var paymentObserver: PaymentQueueObserver = PaymentQueueObserver()
    private var debugMode = false
    public var hasReceiptData: Bool {
        return loadReceipt() != nil
    }
    
    public var currentSessionStatus: ReceiptStatus {
        guard let session = savedSession else {
            return .Inactive
        }
        let status = session.receiptStatus()
        return status
    }
    
    public var currentSubscription: Subscription?
    
    fileprivate var onLoadCompletionBlock: OnProductsLoadCompletion?
    public var products: [IAProduct]? {
        didSet {
            if let block = onLoadCompletionBlock{
                block(products)
            }
        }
    }
    
    private override init() {
        let persistedDateKey = "SimulatedStartDate"
        if let persistedDate = UserDefaults.standard.object(forKey: persistedDateKey) as? Date {
            simulatedStartDate = persistedDate
        } else {
            let date = Date().addingTimeInterval(-30) // 30 second difference to account for server/client drift.
            UserDefaults.standard.set(date, forKey: "SimulatedStartDate")
            simulatedStartDate = date
        }
    }
    
    public func startTransactionObserver(sharedSecrate: String, debug:Bool = false){
        debugMode = debug
        self.sharedSecrate = sharedSecrate
        paymentObserver.startObserving(delegate: self)
    }
    
    public func stopTransactionObserver(){
        paymentObserver.removeObserver()
    }
    
    public func loadIAProducts(productIDs:[String], onCompletion:OnProductsLoadCompletion? = nil) {
        onLoadCompletionBlock = onCompletion
        let request = SKProductsRequest(productIdentifiers: Set(productIDs))
        request.delegate = self
        request.start()
    }
    
    public func purchase(inAppProduct: IAProduct) {
        let payment = SKPayment(product: inAppProduct.product)
        SKPaymentQueue.default().add(payment)
    }
    
    public func purchase(iapID: String) {
        let first = products?.first(where: { (item: IAProduct) -> Bool in
            return item.product.productIdentifier == iapID
        })
        guard let inAppProduct = first else { fatalError("IAP ID not given.") }
        purchase(inAppProduct: inAppProduct)
    }
    
    public func isPurchased(iapID: String) -> Bool{
        guard let session = savedSession else {
            return false
        }
        return session.isPurchased(iapID)
    }
    
    public func productType(by iapID: String) -> NonConsumable?{
        guard let session = savedSession else {
            return nil
        }
        return session.productType(by: iapID)
    }
    
    public func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    public func uploadReceipt(completion: @escaping ((_ success: Bool) -> Void)) {
        if let receiptData = loadReceipt() {
            upload(receipt: receiptData, onCompletion: { [weak self] (session, error) in
                guard let strongSelf = self else{
                    completion(false)
                    return
                }
                if let session = session{
                    strongSelf.savedSession = session
                    strongSelf.currentSubscription = session.currentSubscription
                    strongSelf.saveLastSession()
                    completion(true)
                }else{
                    //Try to load Last Saved Session
                    if let session = strongSelf.restoreLastSession(){
                        strongSelf.savedSession = session
                        strongSelf.currentSubscription = session.currentSubscription
                        completion(true)
                    }
                    else {
                        completion(false)
                    }
                }
            })
        }
        else{
            completion(false)
        }
    }
    
    private func upload(receipt data: Data, onCompletion: @escaping (Session?, Error?) -> Void) {
        let body = [
            "receipt-data": data.base64EncodedString(),
            "password": sharedSecrate!
        ]
        let bodyData = try! JSONSerialization.data(withJSONObject: body, options: [])
        
        let url = (debugMode == false)
            ? URL(string: "https://buy.itunes.apple.com/verifyReceipt")!
            : URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        //Create Task
        let isDebugMode = debugMode
        let task = URLSession.shared.dataTask(with: request) { (responseData, response, error) in
            if let res = response as? HTTPURLResponse {
                if (res.statusCode == 200 || res.statusCode == 201){
                    if let responseData = responseData {
                        let session = Session(decryptedData: responseData, debugMode: isDebugMode)
                        onCompletion(session, nil)
                    }
                    else{
                        onCompletion(nil, error)
                    }
                }else{
                    onCompletion(nil, error)
                }
            }
            else{
                onCompletion(nil, error)
            }
        }
        //Start Task
        task.resume()
    }
    
    private func saveLastSession(){
        guard let session = self.savedSession else {
            return
        }
        let archieved = NSKeyedArchiver.archivedData(withRootObject: session)
        UserDefaults.standard.set(archieved, forKey: "savedSession_key")
        UserDefaults.standard.synchronize()
    }
    
    private func restoreLastSession() -> Session?{
        guard let unarchived = UserDefaults.standard.data(forKey: "savedSession_key") else{
            return nil
        }
        let session = NSKeyedUnarchiver.unarchiveObject(with: unarchived) as? Session
        return session
    }
    
    private func loadReceipt() -> Data? {
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            if debugMode {print("Error loading receipt data: \(error.localizedDescription)")}
            return nil
        }
    }
    
}

// MARK: - SKProductsRequestDelegate

extension PurchaseManager: SKProductsRequestDelegate {
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products.map { IAProduct(product: $0) }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        if request is SKProductsRequest {
            if debugMode {print("Subscription Options Failed Loading: \(error.localizedDescription)")}
        }
        if let block = onLoadCompletionBlock {
            block(nil)
        }
    }
}

//MARK: 

extension PurchaseManager: PaymentQueueObserverDelegate{
    
    public func shouldHandleTransaction(forProductId: String) -> Bool{
        guard let optionItems = self.products else {
            return false;
        }
        var result = false;
        for subscrition in optionItems {
            if (subscrition.product.productIdentifier == forProductId){
                result = true
                break
            }
        }
        return result
    }
    
    public func shouldAddStorePayment(forProductId: String) -> Bool {
        guard let optionItems = self.products else {
            return false;
        }
        let find = optionItems.first { (item: IAProduct) -> Bool in
            return item.identifier == forProductId
        }
        guard let actItem = find else { return false }
        return actItem.shouldAddStorePayment
    }
    
}
