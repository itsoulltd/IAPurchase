//
//  AsynchOperation.h
//  KitePhotoLocker
//
//  Created by Towhid Islam on 6/7/17.
//  Copyright © 2017 Kite Games Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IAOperation : NSOperation

- (void) execute;
- (void) finish;

@end
