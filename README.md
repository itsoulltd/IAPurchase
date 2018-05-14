# IAPurchase
On AppDelegate : application didFinishLunching

        #if DEBUG
            IAPurchaseManager.shared.startTransactionObserver(sharedSecrate: "eea3614d1e324465927dc21cde51a60c", debug: true)
        #else
            IAPurchaseManager.shared.startTransactionObserver(sharedSecrate: "eea3614d1e324465927dc21cde51a60c")
        #endif
        
        //Make this call to make sure, if there is any purchase happen on last app session, then those purchase information will retain automatically.
        IAPurchaseManager.shared.uploadReceipt(offline: true, completion: { (success) in
                    //
                })
        
On AppDelegate : applicationWillTerminate
        
        IAPurchaseManager.shared.stopTransactionObserver()
        
Now IAPurchase is initiated for use.

#To fetch InApp Products from Apple Server.

    IAPurchaseManager.shared.loadIAProducts(productIDs: ["com.xxxx.app.onetimepurchase", "com.xxxx.app.subscription.yearly"], onCompletion: { (items: [IAProduct]?) in
            guard let items = items else{
                return
            }
            for iapProduct in items{
                print("\(iapProduct.product.productIdentifier) : \(iapProduct.formattedPrice)")
                print("\(iapProduct.product.localizedDescription)")
            }
        })
        
#To fetch already fetched items

    IAPurchaseManager.shared.loadIAProducts(productIDs: [], onCompletion: { (items: [IAProduct]?) in
            guard let items = items else{
                return
            }
            for iapProduct in items{
                print("\(iapProduct.product.productIdentifier) : \(iapProduct.formattedPrice)")
                print("\(iapProduct.product.localizedDescription)")
            }
        })
        
#To make a purchase

    IAPurchaseManager.shared.purchase(iapID: "com.xxxx.app.onetimepurchase", onCompletion: { (isInitiated) in
            print("Purchase Initialized \(isInitiated)")
        })
        
#To Check an item is Purchased of Not

    IAPurchaseManager.shared.isPurchased(iapID: "com.xxxx.app.onetimepurchase") will return true or false
    
#To check purchased products info,

                        let type = IAPurchaseManager.shared.productType(by: "com.xxxx.app.onetimepurchase")
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
                        
#Finally Observe Purchase Success-failed-restored call back

NotificationCenter.default.addObserver(self, selector: #selector(restoreFailed(notification:)), name: IAPurchaseManager.restoreFailureNotification, object: nil)
        
NotificationCenter.default.addObserver(self, selector: #selector(restoreSuscess(note:)), name: IAPurchaseManager.restoreSuccessfulNotification, object: nil)
        
NotificationCenter.default.addObserver(self, selector: #selector(purchaseSuscess(note:)), name: IAPurchaseManager.purchaseSuccessfulNotification, object: nil)
        
NotificationCenter.default.addObserver(self, selector: #selector(purchaseFailed(notification:)), name: IAPurchaseManager.purchaseFailureNotification, object: nil)
