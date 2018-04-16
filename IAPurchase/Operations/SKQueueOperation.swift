//
//  SKQueueOperation.swift
//  IAPurchase
//
//  Created by Towhidul Islam on 4/16/18.
//  Copyright © 2018 Towhid Islam. All rights reserved.
//

import Foundation
import StoreKit

protocol SKQueueOperationDelegate: NSObjectProtocol {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse, onCompletion: OnProductsLoadCompletion?) -> Void
    func request(_ request: SKRequest, didFailWithError error: Error, onCompletion: OnProductsLoadCompletion?) -> Void
}

class SKQueueOperation: IAOperation, SKProductsRequestDelegate{
    
    var debugMode: Bool = false
    private weak var delegate: SKQueueOperationDelegate?
    var onLoadCompletionBlock: OnProductsLoadCompletion?
    private var productIds: [String]!
    
    init(_ productIds: [String], delegate: SKQueueOperationDelegate) {
        super.init()
        self.productIds = productIds
        self.delegate = delegate
    }
    
    override func execute() {
        let request = SKProductsRequest(productIdentifiers: Set(productIds))
        request.delegate = self
        request.start()
    }
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        delegate?.productsRequest(request, didReceive: response, onCompletion: onLoadCompletionBlock)
        super.finish()
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        delegate?.request(request, didFailWithError: error, onCompletion: onLoadCompletionBlock)
        super.finish()
    }
    
}
