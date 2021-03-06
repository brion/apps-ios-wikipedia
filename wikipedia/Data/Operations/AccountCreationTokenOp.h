//  Created by Monte Hurd on 1/16/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "MWNetworkOp.h"

@interface AccountCreationTokenOp : MWNetworkOp

- (id)initWithDomain: (NSString *) domain
            userName: (NSString *) userName
            password: (NSString *) password
     completionBlock: (void (^)(NSString *))completionBlock
      cancelledBlock: (void (^)(NSError *))cancelledBlock
          errorBlock: (void (^)(NSError *))errorBlock
;

@end
