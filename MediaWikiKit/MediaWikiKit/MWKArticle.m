//
//  MWKArticle.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKArticle

-(instancetype)initWithTitle:(MWKTitle *)title dict:(NSDictionary *)dict
{
    self = [self initWithSite:title.site];
    if (self) {
        _title = title;

        _redirected     =  [self optionalTitle:     @"redirected"     dict:dict];
        _lastmodified   =  [self requiredDate:      @"lastmodified"   dict:dict];
        _lastmodifiedby =  [self requiredUser:      @"lastmodifiedby" dict:dict];
        _articleId      = [[self requiredNumber:    @"id"             dict:dict] intValue];
        _languagecount  = [[self requiredNumber:    @"languagecount"  dict:dict] intValue];
        _displaytitle   =  [self optionalString:    @"displaytitle"   dict:dict];
        _protection     =  [self requiredDictionary:@"protection"     dict:dict];
        _editable       = [[self requiredNumber:    @"editable"       dict:dict] boolValue];
    }
    return self;
}

-(id)dataExport
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];

    if (self.redirected) {
        dict[@"redirected"] = self.redirected.prefixedText;
    }
    dict[@"lastmodified"] = [self iso8601DateString:self.lastmodified];
    dict[@"lastmodifiedby"] = [self.lastmodifiedby dataExport];
    dict[@"id"] = @(self.articleId);
    dict[@"languagecount"] = @(self.languagecount);
    if (self.displaytitle) {
        dict[@"displaytitle"] = self.displaytitle;
    }
    dict[@"protection"] = self.protection;
    dict[@"editable"] = @(self.editable);

    return [NSDictionary dictionaryWithDictionary:dict];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@", [self dataExport]];
}

- (BOOL)isEqual:(id)object
{
    if (object == nil) {
        return NO;
    } else if (![object isKindOfClass:[MWKArticle class]]) {
        return NO;
    } else {
        MWKArticle *other = object;
        return [self.site isEqual:other.site] &&
            [self.redirected isEqual:other.redirected] &&
            [self.lastmodified isEqual:other.lastmodified] &&
            [self.lastmodifiedby isEqual:other.lastmodifiedby] &&
            self.articleId == other.articleId &&
            self.languagecount == other.languagecount &&
            [self.displaytitle isEqualToString:other.displaytitle] &&
            [self.protection isEqualToDictionary:other.protection] &&
            self.editable == other.editable;
        
    }
}
@end
