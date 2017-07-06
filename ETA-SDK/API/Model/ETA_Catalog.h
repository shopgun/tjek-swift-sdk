//
//  ETA_Catalog.h
//  ETA-SDKExample
//
//  Created by Laurie Hufford on 7/29/13.
//  Copyright (c) 2013 eTilbudsavis. All rights reserved.
//

#import "ETA_ModelObject.h"
#import "ETA_Branding.h"
#import "ETA_Store.h"

typedef enum {
    ETA_Catalog_ImageSize_Thumb = 0,
    ETA_Catalog_ImageSize_View = 1,
    ETA_Catalog_ImageSize_Zoom = 2,
} ETA_Catalog_ImageSize;


@interface ETA_Catalog : ETA_ModelObject

@property (nonatomic, readwrite, strong, nullable) NSString* label;
@property (nonatomic, readwrite, strong, nullable) UIColor* backgroundColor;
@property (nonatomic, readwrite, strong, nullable) NSDate* runFromDate;
@property (nonatomic, readwrite, strong, nullable) NSDate* runTillDate;
@property (nonatomic, readwrite, assign) NSInteger pageCount;
@property (nonatomic, readwrite, assign) NSInteger offerCount;

@property (nonatomic, readwrite, strong, nullable) ETA_Branding* branding;

@property (nonatomic, readwrite, strong, nullable) NSString* dealerID;
@property (nonatomic, readwrite, strong, nullable) NSURL* dealerURL;
@property (nonatomic, readwrite, strong, nullable) NSString* storeID;
@property (nonatomic, readwrite, strong, nullable) NSURL* storeURL;

@property (nonatomic, readwrite, assign) CGSize dimensions;

@property (nonatomic, readwrite, strong, nullable) NSDictionary* imageURLBySize;
@property (nonatomic, readwrite, strong, nullable) NSDictionary* pageImageURLsBySize;


- (nullable NSURL*) imageURLForSize:(ETA_Catalog_ImageSize)imageSize;
- (nullable NSArray*) pageImageURLsForSize:(ETA_Catalog_ImageSize)pageSize;

/**
 *	You need to fetch/assign the Store property yourself using the storeID property - it will be nil until populated.
 */
@property (nonatomic, readwrite, strong, nullable) ETA_Store* store;

@end