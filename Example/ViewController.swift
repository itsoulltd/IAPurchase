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
        // Do any additional setup after loading the view, typically from a nib.
        PurchaseManager.shared.loadSubscription(productIDs: ["com.hoxro.iap.test.nonconsumable.a"
            ,"com.hoxro.iap.test.subscription.monthly"
            ,"com.hoxro.iap.test.subscription.yearly"]) { (items: [IAProduct]?) in
            //
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

