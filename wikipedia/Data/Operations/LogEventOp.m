//  Created by Monte Hurd on 4/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "LogEventOp.h"
#import "NSURLRequest+DictionaryRequest.h"
#import "NSString+Extras.h"
#import "SessionSingleton.h"
#import "WikipediaAppUtils.h"

#define LOG_ENDPOINT @"https://bits.wikimedia.org/event.gif"

//#define LOG_ENDPOINT @"http://localhost:8000/event.gif"

@implementation LogEventOp

- (id)initWithSchema: (NSString *)schema
            revision: (int)revision
               event: (NSDictionary *)event
                wiki: (NSString *)wiki
{
    self = [super init];
    if (self) {

        NSDictionary *payload =
        @{
          @"event"    : event,
          @"revision" : @(revision),
          @"schema"   : schema,
          @"wiki"     : wiki
          };

        NSData *payloadJsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
        NSString *payloadJsonString = [[NSString alloc] initWithData:payloadJsonData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", payloadJsonString);
        NSString *encodedPayloadJsonString = [payloadJsonString urlEncodedUTF8String];
        NSString *urlString = [NSString stringWithFormat:@"%@?%@;", LOG_ENDPOINT, encodedPayloadJsonString];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
        [request addValue:[WikipediaAppUtils versionedUserAgent] forHTTPHeaderField:@"User-Agent"];
        self.request = request;
        
        self.completionBlock = ^(){
            //NSLog(@"EVENT LOGGING COMPLETED");
        };
    }
    return self;
}

@end
