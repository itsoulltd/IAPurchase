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
        
        loadTest()
    }
    
    fileprivate func loadTest(){
        
        //IAPurchaseManager.shared.loadIAProducts(productIDs: [], onCompletion:nil)
        
        IAPurchaseManager.shared.loadIAProducts(productIDs: ["com.tasnim.kitemakeup.subscription.yearly","com.tasnim.kitemakeup.subscription.monthly"])
        { (items: [IAProduct]?) in
            guard let items = items else{
                return
            }
            for iapProduct in items{
                print("\(iapProduct.product.productIdentifier) : \(iapProduct.formattedPrice)")
                print("\(iapProduct.product.localizedDescription)")
            }
        }
        
        //Adding New Items
        IAPurchaseManager.shared.loadIAProducts(productIDs: ["com.tasnim.kitemakeup.onetimepurchase", "com.tasnim.kitemakeup.subscription.yearly"], onCompletion: { (items: [IAProduct]?) in
            guard let items = items else{
                return
            }
            for iapProduct in items{
                print("\(iapProduct.product.productIdentifier) : \(iapProduct.formattedPrice)")
                print("\(iapProduct.product.localizedDescription)")
            }
        })
        
        //Just Fetching existing items
        IAPurchaseManager.shared.loadIAProducts(productIDs: [], onCompletion: { (items: [IAProduct]?) in
            guard let items = items else{
                return
            }
            for iapProduct in items{
                print("\(iapProduct.product.productIdentifier) : \(iapProduct.formattedPrice)")
                print("\(iapProduct.product.localizedDescription)")
            }
            
            //Nothing Check
            DispatchQueue.main.async {
                IAPurchaseManager.shared.loadIAProducts(productIDs: [], onCompletion:nil)
            }
        })
        
    }
    
    fileprivate func purchaseTest() {
        // Do any additional setup after loading the view, typically from a nib.
        IAPurchaseManager.shared.loadIAProducts(productIDs: ["com.tasnim.kitemakeup.subscription.yearly","com.tasnim.kitemakeup.onetimepurchase"]) { (items: [IAProduct]?) in
            //
            guard let xsubs = items else{
                //If there is no internet and user ever had a purchse.
                IAPurchaseManager.shared.uploadReceipt(completion: { (success) in
                    //This is offline test.
                    let purchasedId = "com.tasnim.kitemakeup.subscription.yearly"
                    if IAPurchaseManager.shared.isPurchased(iapID: purchasedId){
                        
                        let type = IAPurchaseManager.shared.productType(by: purchasedId)
                        if type is Subscription{
                            guard let paidSubs = type as? Subscription else{
                                return
                            }
                            print("\(paidSubs.productIdentifier) : isActive : \(paidSubs.isActive) : \(paidSubs.expiresDate)")
                            print("isCanceled : \(paidSubs.isCancelled)")
                            print("TransactionID : \(paidSubs.transactionId)")
                            
                        }else{
                            guard let paidSubs = type else{
                                return
                            }
                            print("\(paidSubs.productIdentifier) : isActive : YES : \(paidSubs.purchaseDate)")
                            print("TransactionID : \(paidSubs.transactionId)")
                        }
                        
                        print("Receipt Status : \(IAPurchaseManager.shared.currentSessionStatus.toString())")
                        
                    }
                })
                return
            }
            //Print products info
            for iapProduct in xsubs{
                print("\(iapProduct.product.productIdentifier) : \(iapProduct.formattedPrice)")
                print("\(iapProduct.product.localizedDescription)")
                
                //How to purchase, for testing first one is purchased.
                if iapProduct.identifier == "com.tasnim.kitemakeup.onetimepurchase"{
                    //IAPurchaseManager.shared.restorePurchases()
                    IAPurchaseManager.shared.purchase(iapID: "com.tasnim.kitemakeup.onetimepurchase", onCompletion: { (isInitiated) in
                        print("Purchase Initiated \(isInitiated)")
                    })
                }
                //
            }
            //
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func purchaseSuscess(note: Notification) -> Void {
        
        guard let purchasedId = note.userInfo?["id"] as? String else { return }
        
        if IAPurchaseManager.shared.isPurchased(iapID: purchasedId){
            
            let type = IAPurchaseManager.shared.productType(by: purchasedId)
            if type is Subscription{
                guard let paidSubs = type as? Subscription else{
                    return
                }
                print("\(paidSubs.productIdentifier) : isActive : \(paidSubs.isActive) : \(paidSubs.expiresDate)")
                print("isCanceled : \(paidSubs.isCancelled)")
                print("TransactionID : \(paidSubs.transactionId)")
                
            }else{
                guard let paidSubs = type else{
                    return
                }
                print("\(paidSubs.productIdentifier) : isActive : YES : \(paidSubs.purchaseDate)")
                print("TransactionID : \(paidSubs.transactionId)")
            }
            
            print("Receipt Status : \(IAPurchaseManager.shared.currentSessionStatus.toString())")
            
        }else{
            print("Unsatisfied results")
        }
        
    }
    
    @objc func restoreSuscess(note: Notification) -> Void {
        //For Test Load the receipt
        guard let restoredIds = note.userInfo?["ids"] as? [String] else{ return }
        print(restoredIds)
    }
    
    @objc func purchaseFailed(notification: Notification) -> Void {
        guard let err = notification.userInfo?["error"] as? String else { return }
        print(err)
        guard let purchasedId = notification.userInfo?["id"] as? String else { return }
        print(purchasedId)
    }
    
    @objc func restoreFailed(notification: Notification) -> Void {
        guard let err = notification.userInfo?["error"] as? String else { return }
        print(err)
        guard let restoredIds = notification.userInfo?["ids"] as? [String] else { return }
        print(restoredIds)
    }


}

