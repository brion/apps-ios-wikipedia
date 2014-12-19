//
//  MWKImage.h
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "UIKit/UIKit.h"

#import "MWKSiteDataObject.h"

@class MWKTitle;
@class MWKArticle;

@interface MWKImage : MWKSiteDataObject

// Identifiers
@property (readonly) MWKSite *site;
@property (readonly) MWKArticle *article;

// Metadata, static
@property (readonly) NSString *sourceURL;
@property (readonly) NSString *extension;
@property (readonly) NSString *fileName;
@property (readonly) NSString *fileNameNoSizePrefix;

// Metadata, variable
@property (copy) NSDate *dateLastAccessed;
@property (copy) NSDate  *dateRetrieved;
@property (copy) NSString *mimeType;
@property (copy) NSNumber *width;
@property (copy) NSNumber *height;

-(instancetype)initWithArticle:(MWKArticle *)article sourceURL:(NSString *)url;
-(instancetype)initWithArticle:(MWKArticle *)article dict:(NSDictionary *)dict;

-(void)updateWithData:(NSData *)data mimeType:(NSString *)mimeType;
-(void)updateLastAccessed;
-(void)save;

-(UIImage *)asUIImage;

+(NSString *)fileNameNoSizePrefix:(NSString *)sourceURL;
+(int)fileSizePrefix:(NSString *)sourceURL;

@end
