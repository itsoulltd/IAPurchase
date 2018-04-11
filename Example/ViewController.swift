//
//  ViewController.swift
//  Example
//
//  Created by Towhid Islam on 10/21/17.
//  Copyright © 2017 Towhid Islam. All rights reserved.
//

import UIKit
import IAPurchase

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(restoreFailed(notification:)), name: PurchaseManager.restoreFailureNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(restoreSuscess(note:)), name: PurchaseManager.restoreSuccessfulNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseSuscess(note:)), name: PurchaseManager.purchaseSuccessfulNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseFailed(notification:)), name: PurchaseManager.purchaseFailureNotification, object: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
        PurchaseManager.shared.loadSubscription(productIDs: ["com.tasnim.kitemakeup.subscription.yearly"]) { (items: [IAProduct]?) in
            
            guard let xsubs = items else{
                PurchaseManager.shared.uploadReceipt(completion: { (success) in
                    guard let paidSubs = PurchaseManager.shared.currentSubscription else{
                        return
                    }
                    print("isActive : \(paidSubs.isActive)")
                    print("\(paidSubs.productIdentifier) : \(paidSubs.expiresDate)")
                    print("isCanceled : \(paidSubs.isCancelled)")
                    print("Receipt Status : \(PurchaseManager.shared.currentSessionStatus.toString())")
                })
                return
            }
            for subscription in xsubs{
                print("\(subscription.product.productIdentifier) : \(subscription.formattedPrice)")
                print("\(subscription.product.localizedDescription)")
            }
            //How to purchase, for testing first one is purchased.
            if let subscriptionToBuy = xsubs.first{
                PurchaseManager.shared.purchase(inAppProduct: subscriptionToBuy)
                //PurchaseManager.shared.restorePurchases()
            }
            //
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func purchaseSuscess(note: Notification) -> Void {
        //For Test Load the receipt
        guard let paidSubs = PurchaseManager.shared.currentSubscription else{
            return
        }
        print("isActive : \(paidSubs.isActive)")
        print("\(paidSubs.productIdentifier) : \(paidSubs.expiresDate)")
        print("isCanceled : \(paidSubs.isCancelled)")
        print("Receipt Status : \(PurchaseManager.shared.currentSessionStatus.toString())")
    }
    
    @objc func restoreSuscess(note: Notification) -> Void {
        //For Test Load the receipt
        guard let restoredIds = note.userInfo?["ids"] as? [String] else{
            print("no items to restore")
            return
        }
        print(restoredIds)
    }
    
    @objc func purchaseFailed(notification: Notification) -> Void {
        print(notification.userInfo as Any)
    }
    
    @objc func restoreFailed(notification: Notification) -> Void {
        print(notification.userInfo as Any)
    }


}

