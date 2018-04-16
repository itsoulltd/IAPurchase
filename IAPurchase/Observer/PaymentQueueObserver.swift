//
//  PaymentQueueObserver.swift
//  SubscriptionExample
//
//  Created by Towhid Islam on 7/21/17.
//  Copyright © 2017 Towhid Islam. All rights reserved.
//

import Foundation
import StoreKit

@objc(PaymentQueueObserverDelegate)
public protocol PaymentQueueObserverDelegate: NSObjectProtocol{
    func shouldHandleTransaction(forProductId: String) -> Bool
    func shouldAddStorePayment(forProductId: String) -> Bool
}

public class PaymentQueueObserver: NSObject, SKPaymentTransactionObserver {
    
    fileprivate weak var _service: PaymentQueueObserverDelegate?
    
    public func startObserving(delegate: PaymentQueueObserverDelegate? = nil) -> Void {
        SKPaymentQueue.default().add(self)
        _service = delegate
    }
    
    public func removeObserver(){
        SKPaymentQueue.default().remove(self)
    }
    
    private func shouldHandle(productId: String) -> Bool{
        return (_service?.shouldHandleTransaction(forProductId: productId))!
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        
        let ids: [String] = queue.transactions.flatMap({ (transaction) -> String? in
            if (shouldHandle(productId: transaction.payment.productIdentifier) == false){
                return nil
            }else{
                return (transaction.transactionState == SKPaymentTransactionState.failed)
                    ? transaction.payment.productIdentifier
                    : nil
            }
        })
        //print("RestoreCompletedTransaction failed for product ids: \(ids)")
        DispatchQueue.main.async {
            let uniqueids = NSOrderedSet(array: ids).array
            NotificationCenter.default.post(name: IAPurchaseManager.restoreFailureNotification, object: nil, userInfo: ["ids":uniqueids,"error":error.localizedDescription])
        }
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        
        let ids: [String] = queue.transactions.flatMap({ (transaction) -> String? in
            if (shouldHandle(productId: transaction.payment.productIdentifier) == false){
                return nil
            }else{
                return (transaction.transactionState == SKPaymentTransactionState.failed
                    || transaction.transactionState == SKPaymentTransactionState.deferred
                    || transaction.transactionState == SKPaymentTransactionState.purchasing)
                    ? nil
                    : transaction.payment.productIdentifier
            }
        })
        //print("RestoreCompletedTransaction finished for product ids: \(ids)")
        if ids.count <= 0 {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: IAPurchaseManager.restoreFailureNotification, object: nil, userInfo: ["ids":ids])
            }
        }else{
            IAPurchaseManager.shared.uploadReceipt { (success) in
                guard success else{
                    DispatchQueue.main.async {
                        let uniqueids = NSOrderedSet(array: ids).array
                        NotificationCenter.default.post(name: IAPurchaseManager.restoreFailureNotification, object: nil, userInfo: ["ids":uniqueids,"error":"uploadReceipt failed!"])
                    }
                    return
                }
                DispatchQueue.main.async {
                    let uniqueids = NSOrderedSet(array: ids).array
                    NotificationCenter.default.post(name: IAPurchaseManager.restoreSuccessfulNotification, object: nil, userInfo: ["ids":uniqueids])
                }
            }
        }
    }

    public func paymentQueue(_ queue: SKPaymentQueue,
                      updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                handlePurchasingState(for: transaction, in: queue)
            case .purchased:
                handlePurchasedState(for: transaction, in: queue)
            case .restored:
                handleRestoredState(for: transaction, in: queue)
            case .failed:
                handleFailedState(for: transaction, in: queue)
            case .deferred:
                handleDeferredState(for: transaction, in: queue)
            }
        }
    }
    
    private func handlePurchasingState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        
        if(shouldHandle(productId: transaction.payment.productIdentifier) == false){
            return
        }
        //print("User is attempting to purchase product id: \(transaction.payment.productIdentifier)")
    }
    
    private func handlePurchasedState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        
        if(shouldHandle(productId: transaction.payment.productIdentifier) == false){
            return
        }
        //print("User purchased product id: \(transaction.payment.productIdentifier)")
        queue.finishTransaction(transaction)
        IAPurchaseManager.shared.uploadReceipt { (success) in
            guard success else{
                return
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: IAPurchaseManager.purchaseSuccessfulNotification, object: nil, userInfo: ["id":transaction.payment.productIdentifier,"status":NSNumber(value: success)])
            }
        }
    }
    
    private func handleRestoredState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        
        if(shouldHandle(productId: transaction.payment.productIdentifier) == false){
            return
        }
        //print("Purchase restored for product id: \(transaction.payment.productIdentifier)")
        queue.finishTransaction(transaction)
        
    }
    
    private func handleFailedState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        
        if(shouldHandle(productId: transaction.payment.productIdentifier) == false){
            //This is for re-settle the odd things
            //queue.finishTransaction(transaction)
            return
        }
        //print("Purchase failed for product id: \(transaction.payment.productIdentifier)")
        DispatchQueue.main.async {
            var info = ["id":transaction.payment.productIdentifier]
            if let err = transaction.error{
                info["error"] = err.localizedDescription
            }
            NotificationCenter.default.post(name: IAPurchaseManager.purchaseFailureNotification, object: nil, userInfo: info)
        }
    }
    
    private func handleDeferredState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        
        if(shouldHandle(productId: transaction.payment.productIdentifier) == false){
            return
        }
        //print("Purchase deferred for product id: \(transaction.payment.productIdentifier)")
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        guard let service = _service else { return false }
        return service.shouldAddStorePayment(forProductId: product.productIdentifier);
    }
    
}
