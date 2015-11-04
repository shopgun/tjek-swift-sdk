//
//  ETA_APIClient.h
//  ETA-SDK
//
//  Created by Laurie Hufford on 7/8/13.
//  Copyright (c) 2013 eTilbudsavis. All rights reserved.
//

#import "ETA.h"

#import "AFHTTPRequestOperationManager.h"

@class ETA_Session;
@interface ETA_APIClient : AFHTTPRequestOperationManager

// Create the ETA_APIClient with these methods. Do not use init as apiKey/Secret must be set before further session can be started.
+ (instancetype)clientWithApiKey:(NSString*)apiKey apiSecret:(NSString*)apiSecret appVersion:(NSString*)appVersion; // using the production base URL
+ (instancetype)clientWithBaseURL:(NSURL *)url apiKey:(NSString*)apiKey apiSecret:(NSString*)apiSecret appVersion:(NSString*)appVersion;


#pragma mark - API Requests

// send a request to the server. This will start a session if not already started
- (void) makeRequest:(NSString*)requestPath type:(ETARequestType)type parameters:(NSDictionary*)parameters completion:(void (^)(id response, NSError* error))completionHandler;


#pragma mark - Session

// The current session. nil until connected. Do not modify directly.
@property (nonatomic, readonly, strong) ETA_Session* session;

// use this method to update the session
- (void) setIfSameOrNewerSession:(ETA_Session *)session;
- (void) setIfNewerSession:(ETA_Session *)session;


// Whether we should read and save the session to UserDefaults. Defaults to YES.
@property (nonatomic, readwrite, assign) BOOL storageEnabled;

// try to start a session. This must be performed before any requests can be made.
- (void) startSessionWithCompletion:(void (^)(NSError* error))completionHandler;


#pragma mark - User Management
// try to add a user to the session.
- (void) attachUser:(NSDictionary*)userCredentials withCompletion:(void (^)(NSError* error))completionHandler;

// try to remove the user from the session
- (void) detachUserWithCompletion:(void (^)(NSError* error))completionHandler;

// does the current session allow the specified action
- (BOOL) allowsPermission:(NSString*)actionPermission;


@end