//
//  MWKSavedPageList.h
//  MediaWikiKit
//
//  Created by Brion on 11/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataObject.h"

@class MWKTitle;
@class MWKSavedPageEntry;

@interface MWKSavedPageList : MWKDataObject

@property (readonly) NSUInteger length;
@property (readonly) BOOL dirty;

-(MWKSavedPageEntry *)entryAtIndex:(NSUInteger)index;
-(NSUInteger)indexForEntry:(MWKSavedPageEntry *)entry;

-(MWKSavedPageEntry *)entryForTitle:(MWKTitle *)title;
-(BOOL)isSaved:(MWKTitle *)title;

/// Add a new entry to the saved page list!
-(void)addEntry:(MWKSavedPageEntry *)entry;
/// Remove one.
-(void)removeEntry:(MWKSavedPageEntry *)entry;

-(instancetype)initWithDict:(NSDictionary *)dict;

@end
