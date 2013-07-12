//
//  ETA.h
//  ETA-SDK
//
//  Created by Laurie Hufford on 7/8/13.
//  Copyright (c) 2013 eTilbudsAvis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "ETA_APIClient.h"


@interface ETA : NSObject

@property (nonatomic, readonly, assign, getter=isConnected) BOOL connected;


// Construct an ETA object. Must use this method otherwise you wont have an API Key, and nothing will work
+ (instancetype) etaWithAPIKey:(NSString *)apiKey apiSecret:(NSString *)apiSecret;



#pragma mark - Connecting

// start a session. This is not required, as any API/user requests that you make will create the session automatically
- (void) connect:(void (^)(NSError* error))completionHandler;
// start a session and attach a user
- (void) connectWithUserEmail:(NSString*)email password:(NSString*)password completion:(void (^)(BOOL connected, NSError* error))completionHandler;


#pragma mark - User Management

// Try to set the current user of the session to be that with the specified email/pass
// Creates a session if one doesnt exist already.
- (void) attachUserEmail:(NSString*)email password:(NSString*)password completion:(void (^)(NSError* error))completionHandler;
// remove the user from the current session
- (void) detachUserWithCompletion:(void (^)(NSError* error))completionHandler;


#pragma mark - Sending API Requests

// Send a request to the serever.
// Creates a session if one doesnt exist already, blocking all future api requests until created.
- (void) api:(NSString*)requestPath type:(ETARequestType)type parameters:(NSDictionary*)parameters completion:(void (^)(id response, NSError* error, BOOL fromCache))completionHandler;


// If looking for items it will first check the cache for them. If found it will first send the item from the cache, and ALSO send the request to the server (expect 1 or 2 completionHandler events)
- (void) api:(NSString*)requestPath type:(ETARequestType)type parameters:(NSDictionary*)parameters useCache:(BOOL)useCache completion:(void (^)(id response, NSError* error, BOOL fromCache))completionHandler;


#pragma - Geolocation

// Any changes to location will be applied to all future requests.
// There will be no location info sent by default.
// Distance will only be sent if there is also a location to send.
@property (nonatomic, readwrite, strong) CLLocation* location;
@property (nonatomic, readwrite, strong) NSNumber* distance; // meters

// 'isLocationFromSensor' is currently just metadata for the server.
// Set to YES if the location property comes from the device's sensor.
@property (nonatomic, readwrite, assign) BOOL isLocationFromSensor;

// A utility geolocation setter method
- (void) setLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude distance:(CLLocationDistance)distance isFromSensor:(BOOL)isFromSensor;

// A list of the distances that we prefer to use.
// The 'distance' property will be clamped to within these numbers before being sent
+ (NSArray*) preferredDistances;


@end

@interface ETA (Catalogs)

- (void) getCatalogsWithCatalogIDs:(NSArray*)catalogIDs
                         dealerIDs:(NSArray*)dealerIDs
                          storeIDs:(NSArray*)storeIDs
                           orderBy:(NSArray*)sortKeys
                             limit:(NSUInteger)limit offset:(NSUInteger)offset
                        completion:(void (^)(NSArray* catalogs, NSError* error))completionHandler;

@end


@interface ETA (ShoppingList)

- (BOOL) canGetShoppingList;
- (BOOL) canUpdateShoppingList;
- (BOOL) canDeleteShoppingList;

- (void) getShoppingLists:(void (^)(NSArray* shoppingLists, NSError* error))completionHandler;

@end