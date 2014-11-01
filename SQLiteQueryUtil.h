//
// SQLiteQueryUtil.h
// https://github.com/DietCoder/SQLiteQueryUtil
//
// Set of utility functions for accessing and manipulating a sqlite database
//
// License: The MIT License (MIT)
//
// Copyright (c) 2014 DietCoder
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface SQLiteQueryUtil : NSObject

-(id)initWithDBPath:(NSString*)dbPath;

/**
 read query on db
 
 @param query sqlite query
 @param bindParamsCallback optional block for binding query '?' to values
 @param onNextRowCallback optional block called for every row in query resultset
 @param onQueryCompleteCallack optional block called when the query completes
 */
-(void)queryDB:(NSString*)query withBindParamsCallback:(void (^)(sqlite3_stmt *queryStatement))bindParamsCallback onNextRowCallback:(void (^)(sqlite3_stmt *queryStatement, NSUInteger currentRow))onNextRowCallback onQueryCompleteCallack:(void(^)())onQueryCompleteCallack;

/**
 read|write query on db
 
 @param query sqlite query
 @param bindParamsCallback optional block for binding query '?' to values
 @param onNextRowCallback optional block called for every row in query resultset
 @param onQueryCompleteCallack optional block called when the query completes
 */
-(void)writeQueryInDB:(NSString*)query withBindParamsCallback:(void (^)(sqlite3_stmt *queryStatement))bindParamsCallback onNextRowCallback:(void (^)(sqlite3_stmt *queryStatement, NSUInteger currentRow))onNextRowCallback onQueryCompleteCallack:(void(^)())onQueryCompleteCallack;


/**
 returns the db user_version
 */
-(int32_t)dbVersion;

/**
 sets the db user_version
 
 @param updatedVersion user_version to set
 */
-(void)setdbVersion:(int32_t)updatedVersion;


/**
 opens a read only db connection. returns the sqlite result
 
 @param db database reference to assign the connection
 */
-(int)openDBReadOnly:(sqlite3**)db;

/**
 opens a read|write db connection. returns the sqlite result
 
 @param db database reference to assign the connection
 */
-(int)openDBReadWrite:(sqlite3**)db;

/**
 opens a db connection for creating tables. returns the sqlite result
 
 @param db database reference to assign the connection
 */
-(int)openForCreateDB:(sqlite3**)db;

/**
 uses sqlite limit and offset to iterate over a query's result set
 
 @param query sqlite query. must not contain a trailing ;
 @param countQuery query which should return a result count
 @param bufferSize number of results to retrieve per pass
 @param dbToUse database reference
 @param bindParamsCallback optional block for binding query '?' to values
 @param onNextRowCallback optional block called for every row in query resultset
 @param onQueryCompleteCallack optional block called when the query completes
 */
-(void)enumerateObjectsMatchingQuery:(NSString*)query countQuery:(NSString*)countQuery bufferSize:(NSUInteger)bufferSize withDB:(sqlite3**)dbToUse withBindParamsCallback:(void (^)(sqlite3_stmt *queryStatement))bindParamsCallback onNextRowCallback:(void (^)(sqlite3_stmt *queryStatement, NSUInteger currentRow))onNextRowCallback onQueryCompleteCallack:(void(^)())onQueryCompleteCallack;

/**
 workflow for migrations
 
 @param testConditionsExistToMigrate block to execute to execute preconditions before migrating. return true if the migration should proceed
 @param migrate block to perform the migration
 @param didMigrationSucceed block to test if the migration succeeded
 @param rollback block to execute if didMigrationSucceed returns false
 @param onMigrationComplete block always executed when the migration is complete- success or fail
 */
-(void)migrate:(BOOL (^)())testConditionsExistToMigrate migrate:(void (^)())migrate didMigrationSucceed:(BOOL (^)())didMigrationSucceed rollback:(void (^)())rollback onMigrationComplete:(void (^)(BOOL didComplete))onMigrationComplete;


// identical functions with db passed in for transactions

/**
 read query on db
 
 @param query sqlite query
 @param dbToUse database reference
 @param bindParamsCallback optional block for binding query '?' to values
 @param onNextRowCallback optional block called for every row in query resultset
 @param onQueryCompleteCallack optional block called when the query completes
 */
-(void)queryDB:(NSString*)query withDB:(sqlite3**)dbToUse withBindParamsCallback:(void (^)(sqlite3_stmt *queryStatement))bindParamsCallback onNextRowCallback:(void (^)(sqlite3_stmt *queryStatement, NSUInteger currentRow))onNextRowCallback onQueryCompleteCallack:(void(^)())onQueryCompleteCallack;

/**
 read|write query on db
 
 @param query sqlite query
 @param dbToUse database reference
 @param bindParamsCallback optional block for binding query '?' to values
 @param onNextRowCallback optional block called for every row in query resultset
 @param onQueryCompleteCallack optional block called when the query completes
 */
-(void)writeQueryInDB:(NSString*)query withDB:(sqlite3**)dbToUse withBindParamsCallback:(void (^)(sqlite3_stmt *queryStatement))bindParamsCallback onNextRowCallback:(void (^)(sqlite3_stmt *queryStatement, NSUInteger currentRow))onNextRowCallback onQueryCompleteCallack:(void(^)())onQueryCompleteCallack;

/**
 returns the db user_version
 
 @param db database reference
 */
-(int32_t)dbVersionWithDB:(sqlite3**)db;

/**
 sets the db user_version
 
 @param updatedVersion user_version to set
 @param db database reference
 */
-(void)setdbVersion:(int32_t)updatedVersion withDB:(sqlite3**)db;
@end
