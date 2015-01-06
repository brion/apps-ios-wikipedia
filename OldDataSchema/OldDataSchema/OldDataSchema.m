//
//  OldDataSchema.m
//  OldDataSchema
//
//  Created by Brion on 12/22/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "OldDataSchema.h"

#import "ArticleDataContextSingleton.h"
#import "ArticleCoreDataObjects.h"
#import "NSManagedObjectContext+SimpleFetch.h"

@implementation OldDataSchema {
    ArticleDataContextSingleton *context;
    NSMutableSet *savedTitles;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        savedTitles = [[NSMutableSet alloc] init];
        if (self.exists) {
            context = [ArticleDataContextSingleton sharedInstance];
        } else {
            context = nil;
        }
    }
    return self;
}

-(BOOL)exists
{
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentRootPath = [documentPaths objectAtIndex:0];
    NSString *filePath = [documentRootPath stringByAppendingPathComponent:@"articleData6.sqlite"];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

-(void)migrateData
{
    // TODO
    // 1) Go through saved article list, saving entries and (articles and images)
    // 2) Go through page reading history, saving entries and (articles and images) when not already transferred
    
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Saved"];
    NSError *err;
    NSArray *savedEntries = [context.mainContext executeFetchRequest:req error:&err];
    if (err) {
        NSLog(@"Error reading old Saved entries: %@", err);
    }
    for (Saved *saved in savedEntries) {
        [self migrateSaved:saved];
        [self migrateArticle:saved.article];
    }
    
    NSFetchRequest *req2 = [NSFetchRequest fetchRequestWithEntityName:@"History"];
    NSError *err2;
    NSArray *historyEntries = [context.mainContext executeFetchRequest:req2 error:&err2];
    if (err2) {
        NSLog(@"Error reading old Saved entries: %@", err2);
    }
    for (History *history in historyEntries) {
        [self migrateHistory:history];
        [self migrateArticle:history.article];
    }
}

-(void)migrateSaved:(Saved *)saved
{
    NSDictionary *dict = [self exportSaved:saved];
    [self.delegate oldDataSchema:self migrateSavedEntry:dict];
}

-(void)migrateHistory:(History *)history
{
    NSDictionary *dict = [self exportHistory:history];
    [self.delegate oldDataSchema:self migrateHistoryEntry:dict];
}

-(void)migrateArticle:(Article *)article
{
    NSString *key = [NSString stringWithFormat:@"%@:%@", article.domain, article.title];
    if ([savedTitles containsObject:key]) {
        // already imported this article
    } else {
        // Record for later to avoid dupe imports
        [savedTitles addObject:key];

        NSDictionary *dict = [self exportArticle:article];
        [self.delegate oldDataSchema:self migrateArticle:dict];
        
        // Find its images...
        for (Section *section in article.section) {
            for (SectionImage *sectionImage in section.sectionImage) {
                [self migrateImage:sectionImage];
            }
        }
    }
}

-(void)migrateImage:(SectionImage *)sectionImage
{
    NSDictionary *dict = [self exportImage:sectionImage];
    [self.delegate oldDataSchema:self migrateImage:dict];
}

-(NSDictionary *)exportSaved:(Saved *)saved
{
    return @{
             @"domain": @"wikipedia.org",
             @"language": saved.article.domain,
             @"title": saved.article.title,
             @"date": [self stringWithDate:saved.dateSaved]
             };
}

-(NSDictionary *)exportHistory:(History *)history
{
    return @{
             @"domain": @"wikipedia.org",
             @"language": history.article.domain,
             @"title": history.article.title,
             @"date": [self stringWithDate:history.dateVisited],
             @"discoveryMethod": history.discoveryMethod,
             @"scrollPosition": history.article.lastScrollY
             };
}

-(NSDictionary *)exportArticle:(Article *)article
{
    NSMutableDictionary *dict = [@{} mutableCopy];
    
    dict[@"redirected"] = // optional
    dict[@"lastmodified"] = // date
    dict[@"lastmodifiedby"] = // dict structure for user or empty
    dict[@"id"] = // number
    dict[@"languagecount"] = // number
    dict[@"displaytitle"] = // optional
    dict[@"protection"] = // struct
    dict[@"editable"] = // boolean
    
    // sections!
    dict[@"sections"] = [@[] mutableCopy];
    for (Section *section in article.section) {
        int sectionId = [section.sectionId intValue];
        dict[@"sections"][sectionId] = [self exportSection:section];
    }
    
    return @{
             @"language": article.domain,
             @"title": article.title,
             @"dict": dict
             };
}

-(NSDictionary *)exportSection:(Section *)section
{
    NSMutableDictionary *dict = [@{} mutableCopy];
    
    if (section.tocLevel) {
        dict[@"toclevel"] = section.tocLevel;
    }
    if (section.level) {
        dict[@"level"] = section.level;
    }
    if (section.title) {
        dict[@"line"] = section.title;
    }
    if (section.fromTitle) {
        dict[@"fromtitle"] = section.fromTitle;
    }
    if (section.anchor) {
        dict[@"anchor"] = section.anchor;
    }
    dict[@"id"] = section.sectionId;
    if (section.html) {
        dict[@"text"] = section.html;
    }
    
    return dict;
}

-(NSDictionary *)exportImage:(SectionImage *)sectionImage
{
    Section *section = sectionImage.section;
    Article *article = section.article;
    Image *image = sectionImage.image;
    ImageData *imageData = image.imageData;

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[@"domain"] = @"wikipedia.org";
    dict[@"language"] = article.domain;
    dict[@"title"] = article.title;

    dict[@"sectionId"] = section.sectionId;

    dict[@"sourceURL"] = image.sourceUrl;
    if (imageData.data) {
        dict[@"data"] = imageData.data;
    }
    
    return dict;
}

#pragma mark - date methods

- (NSDateFormatter *)iso8601Formatter
{
    // See: https://www.mediawiki.org/wiki/Manual:WfTimestamp
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    return formatter;
}

- (NSDate *)dateWithString:(NSString *)string
{
    return  [[self iso8601Formatter] dateFromString:string];
}

- (NSString *)stringWithDate:(NSDate *)date
{
    return [[self iso8601Formatter] stringFromDate:date];
}

@end
