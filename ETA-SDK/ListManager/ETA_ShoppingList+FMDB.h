//
//  ETA_ShoppingList+FMDB.h
//  ETA-SDK
//
//  Created by Laurie Hufford on 7/17/13.
//  Copyright (c) 2013 eTilbudsavis. All rights reserved.
//

#import "ETA_ShoppingList.h"

@class FMResultSet, FMDatabase;

// This category adds a lot of handy methods for talking to an FMDB database.
// It contains the table definition for an object of this type.

@interface ETA_ShoppingList (FMDB)

// create the shopping list table with the specified name in the db
+ (BOOL) createTable:(NSString*)tableName inDB:(FMDatabase*)db;

// empty the table specified with the name in the db
+ (BOOL) clearTable:(NSString*)tableName inDB:(FMDatabase*)db;

#pragma mark - Converters

// convert a resultSet into a shopping list
+ (ETA_ShoppingList*) shoppingListFromResultSet:(FMResultSet*)res;

// get the parameters & values of the list in a form that can be added to the DB
- (NSDictionary*) dbParameterDictionary;



#pragma mark - Getters

+ (NSArray*) getAllListsWithSyncStates:(NSArray*)syncStates andUserID:(id)userID fromTable:(NSString*)tableName inDB:(FMDatabase*)db;

// get the shopping list with the specified ID
+ (ETA_ShoppingList*) getListWithID:(NSString*)listID fromTable:(NSString*)tableName inDB:(FMDatabase*)db;



#pragma mark - Setters

// replace or insert a list in the db with 'list'. returns success or failure.
+ (BOOL) insertOrReplaceList:(ETA_ShoppingList*)list intoTable:(NSString*)tableName inDB:(FMDatabase*)db error:(NSError * __autoreleasing *)error;

// remove the list from the table/db.  returns success or failure.
+ (BOOL) deleteList:(NSString*)listID fromTable:(NSString*)tableName inDB:(FMDatabase*)db error:(NSError * __autoreleasing *)error;



@end