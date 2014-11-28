//
// SQLiteQueryUtil.m
// https://github.com/DietCoder/SQLiteQueryUtil
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

#import "SQLiteQueryUtil.h"

@interface SQLiteQueryUtil()
@property (nonatomic, copy) NSString *dbPath;
@end

@implementation SQLiteQueryUtil

-(id)initWithDBPath:(NSString*)dbPath {
    if(self = [super init]) {
        if([dbPath isKindOfClass:[NSString class]]) {
            self.dbPath = dbPath;
        }
    }
    return self;
}

-(int)openDBReadOnly:(sqlite3**)db {
    
    // db exists open it
    return sqlite3_open_v2([self.dbPath UTF8String], db, SQLITE_OPEN_READONLY|SQLITE_OPEN_NOMUTEX, NULL);
}

-(int)openDBReadWrite:(sqlite3**)db {
    
    // db exists open it
    return sqlite3_open_v2([self.dbPath UTF8String], db, SQLITE_OPEN_READWRITE, NULL);
}

-(int)openForCreateDB:(sqlite3**)db {
    //db does not exist create it
    return sqlite3_open_v2([self.dbPath UTF8String], db, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE, NULL);
}

-(int32_t)dbVersionWithDB:(sqlite3**)db {
    __block int32_t version = 0;
    
    NSString *query = @"PRAGMA user_version;";
    
    [self queryDB:query withDB:db withBindParamsCallback:^(sqlite3_stmt *queryStatement) {
        
        
    } onNextRowCallback:^(sqlite3_stmt *queryStatement, NSUInteger currentRow) {
        
        version = sqlite3_column_int(queryStatement, 0);
        
    } onQueryCompleteCallack:^{
        
    }];
    
    return version;
}

-(int32_t)dbVersion {
    __block int32_t version = 0;
    
    NSString *query = @"PRAGMA user_version;";
    
    [self queryDB:query withBindParamsCallback:^(sqlite3_stmt *queryStatement) {
        
        
    } onNextRowCallback:^(sqlite3_stmt *queryStatement, NSUInteger currentRow) {
        
        version = sqlite3_column_int(queryStatement, 0);
        
    } onQueryCompleteCallack:^{
        
    }];
    
    return version;
}

-(void)setdbVersion:(int32_t)updatedVersion withDB:(sqlite3**)db {
    if(updatedVersion < INT32_MIN || updatedVersion > INT32_MAX) {
        NSLog(@"[SQLITE] Invalid version args");
        return;
    }
    
    NSString *query = [NSString stringWithFormat:@"PRAGMA user_version=%d;", updatedVersion];
    
    [self writeQueryInDB:query withDB:db withBindParamsCallback:^(sqlite3_stmt *queryStatement) {
        
    } onNextRowCallback:^(sqlite3_stmt *queryStatement, NSUInteger currentRow) {
        
    } onQueryCompleteCallack:^{
        
    }];
}

-(void)setdbVersion:(int32_t)updatedVersion {
    if(updatedVersion < INT32_MIN || updatedVersion > INT32_MAX) {
        NSLog(@"[SQLITE] Invalid version args");
        return;
    }
    
    
    NSString *query = [NSString stringWithFormat:@"PRAGMA user_version=%d;", updatedVersion];
    
    [self writeQueryInDB:query withBindParamsCallback:^(sqlite3_stmt *queryStatement) {
        
    } onNextRowCallback:^(sqlite3_stmt *queryStatement, NSUInteger currentRow) {
        
    } onQueryCompleteCallack:^{
        
    }];
}

// capture the workflow open, exc, close with error handling
-(void)openDB:(int (^)(sqlite3** db))opendb closedb:(int (^)(sqlite3*db))closedb andExecuteSQL:(NSString*)query isWriteQuery:(BOOL)isWriteQuery withBindParamsCallback:(void (^)(sqlite3_stmt *queryStatement))bindParamsCallback onNextRowCallback:(void (^)(sqlite3_stmt *queryStatement, NSUInteger currentRow))onNextRowCallback onQueryCompleteCallack:(void(^)())onQueryCompleteCallack {
    
    if(![query isKindOfClass:[NSString class]]) {
        NSLog(@"[SQLITE] Invalid query object type");
        
        // end here, callback or not
        if(onQueryCompleteCallack) {
            onQueryCompleteCallack();
        }
        return;
    }
    if(!opendb) {
        NSLog(@"[SQLITE] Invalid args");
        
        // end here, callback or not
        if(onQueryCompleteCallack) {
            onQueryCompleteCallack();
        }
        return;
    }
    
    sqlite3 *db = NULL;
    int dbOpenResult = opendb(&db);
    if (dbOpenResult != SQLITE_OK) {
        
        NSLog(@"[SQLITE] Failed to open database %d %s", dbOpenResult, sqlite3_errmsg(db));
        
        // properly close
        int closeResult = 0;
        
        bool callCloseBlock = closedb != nil;
        if(callCloseBlock) {
            closeResult = closedb(db);
        }
        else {
            closeResult = sqlite3_close(db);
        }
        
        if(closeResult != SQLITE_OK) {
            NSLog(@"[SQLITE] Error failed to close db %d %s", closeResult, sqlite3_errmsg(db));
        }
        
        // end here, callback or not
        if(onQueryCompleteCallack) {
            onQueryCompleteCallack();
        }
        return;
    }
    
    /*
     int enableExtendedResultCode = sqlite3_extended_result_codes(db, 1);
     if(enableExtendedResultCode != 0) {
     NSLog(@"[SQLITE] Error Failed to enable extended result codes: %d", enableExtendedResultCode);
     }
     */
    
    sqlite3_stmt *statement = NULL;
    const char *sql = [query UTF8String];
    int prepareResponse = sqlite3_prepare_v2(db, sql, -1, &statement, NULL);
    if (prepareResponse != SQLITE_OK) {
        NSLog(@"[SQLITE] Error preparing query %s", sqlite3_errmsg(db));
    } else {
        
        if(bindParamsCallback) {
            bindParamsCallback(statement);
        }
        
        NSUInteger currentRow = 0;
        
        int rowResult = sqlite3_step(statement);
        while(rowResult == SQLITE_ROW) {
            if(onNextRowCallback) {
                onNextRowCallback(statement, currentRow);
            }
            ++currentRow;
            
            rowResult = sqlite3_step(statement);
        }
        
        if(rowResult == SQLITE_DONE) {
            // for insert execute onNextRowCallback once for caller to retrieve row id via
            // execute sqlite3_last_insert_rowid
            if(isWriteQuery && currentRow == 0 && onNextRowCallback) {
                onNextRowCallback(statement, currentRow);
            }
        }
        else {
            NSLog(@"[SQLITE] Error unexpected last row result %d %s", rowResult, sqlite3_errmsg(db));
        }
    }
    
    int finalizeResult = sqlite3_finalize(statement);
    if(finalizeResult != SQLITE_OK) {
        NSLog(@"[SQLITE] Error failed to finalize prepare statement %d", finalizeResult);
    }
    else {
        statement = nil;
    }
    
    int closeResult = 0;
    
    bool callCloseBlock = closedb != nil;
    if(callCloseBlock) {
        closeResult = closedb(db);
    }
    else {
        closeResult = sqlite3_close(db);
    }
    
    if(closeResult != SQLITE_OK) {
        NSLog(@"[SQLITE] Error failed to close db %d", closeResult);
    }
    
    if(onQueryCompleteCallack) {
        onQueryCompleteCallack();
    }
}

-(void)queryDB:(NSString*)query withBindParamsCallback:(void (^)(sqlite3_stmt *queryStatement))bindParamsCallback onNextRowCallback:(void (^)(sqlite3_stmt *queryStatement, NSUInteger currentRow))onNextRowCallback onQueryCompleteCallack:(void(^)())onQueryCompleteCallack {
    
    [self openDB:^int(sqlite3 **db) {
        
        return [self openDBReadOnly:db];
        
    } closedb:nil andExecuteSQL:query isWriteQuery:NO withBindParamsCallback:bindParamsCallback onNextRowCallback:onNextRowCallback onQueryCompleteCallack:onQueryCompleteCallack];
}

-(void)queryDB:(NSString*)query withDB:(sqlite3**)dbToUse withBindParamsCallback:(void (^)(sqlite3_stmt *queryStatement))bindParamsCallback onNextRowCallback:(void (^)(sqlite3_stmt *queryStatement, NSUInteger currentRow))onNextRowCallback onQueryCompleteCallack:(void(^)())onQueryCompleteCallack {
    
    [self openDB:^int(sqlite3 **db) {
        
        *(db) = *dbToUse;
        return SQLITE_OK;
        
    } closedb:^int(sqlite3 *db) {
        
        // if db is passed caller must close
        return SQLITE_OK;
        
    } andExecuteSQL:query isWriteQuery:NO withBindParamsCallback:bindParamsCallback onNextRowCallback:onNextRowCallback onQueryCompleteCallack:onQueryCompleteCallack];
}

-(void)writeQueryInDB:(NSString*)query withDB:(sqlite3**)dbToUse withBindParamsCallback:(void (^)(sqlite3_stmt *queryStatement))bindParamsCallback onNextRowCallback:(void (^)(sqlite3_stmt *queryStatement, NSUInteger currentRow))onNextRowCallback onQueryCompleteCallack:(void(^)())onQueryCompleteCallack {
    
    [self openDB:^int(sqlite3 **db) {
        
        *(db) = *dbToUse;
        return SQLITE_OK;
        
    } closedb:^int(sqlite3 *db) {
        
        // if db is passed caller must close
        return SQLITE_OK;
        
    } andExecuteSQL:query isWriteQuery:YES withBindParamsCallback:bindParamsCallback onNextRowCallback:onNextRowCallback onQueryCompleteCallack:onQueryCompleteCallack];
}

-(void)writeQueryInDB:(NSString*)query withBindParamsCallback:(void (^)(sqlite3_stmt *queryStatement))bindParamsCallback onNextRowCallback:(void (^)(sqlite3_stmt *queryStatement, NSUInteger currentRow))onNextRowCallback onQueryCompleteCallack:(void(^)())onQueryCompleteCallack {
    
    [self openDB:^int(sqlite3 **db) {
        
        return [self openDBReadWrite:db];
        
    } closedb:nil andExecuteSQL:query isWriteQuery:YES withBindParamsCallback:bindParamsCallback onNextRowCallback:onNextRowCallback onQueryCompleteCallack:onQueryCompleteCallack];
}

// query should not include ;, limit will be inserted at the end
-(void)enumerateObjectsMatchingQuery:(NSString*)query countQuery:(NSString*)countQuery bufferSize:(NSUInteger)bufferSize withDB:(sqlite3**)dbToUse withBindParamsCallback:(void (^)(sqlite3_stmt *queryStatement))bindParamsCallback onNextRowCallback:(void (^)(sqlite3_stmt *queryStatement, NSUInteger currentRow))onNextRowCallback onQueryCompleteCallack:(void(^)())onQueryCompleteCallack {
    if(!([query isKindOfClass:[NSString class]] && [countQuery isKindOfClass:[NSString class]] && bufferSize > 0)) {
        NSLog(@"[SQLITE] Invalid query usage");
        return;
    }
    
    sqlite_int64 currentOffset = 0;
    __block sqlite_int64 count = 0;
    
    [self queryDB:countQuery withDB:dbToUse withBindParamsCallback:^(sqlite3_stmt *queryStatement) {
        
    } onNextRowCallback:^(sqlite3_stmt *queryStatement, NSUInteger currentRow) {
        
        // todo int or int64
        count = sqlite3_column_int(queryStatement, 0);
        
    } onQueryCompleteCallack:^{
        
    }];
    
    if(((sqlite_int64)bufferSize) >= count) {
        bufferSize = ((NSUInteger)count)-1;
    }
    
    for(; (bufferSize+currentOffset >= count ? (count-currentOffset) : bufferSize+currentOffset) < count; currentOffset += bufferSize) {
        
        NSString *nextQuery = [[NSString alloc] initWithFormat:@"%@ LIMIT %lu OFFSET %lld", query, (unsigned long)bufferSize, currentOffset];
        
        [self queryDB:nextQuery withDB:dbToUse withBindParamsCallback:bindParamsCallback onNextRowCallback:onNextRowCallback onQueryCompleteCallack:onQueryCompleteCallack];
    }
    
}

-(void)migrate:(BOOL (^)())testConditionsExistToMigrate migrate:(void (^)())migrate didMigrationSucceed:(BOOL (^)())didMigrationSucceed rollback:(void (^)())rollback onMigrationComplete:(void (^)(BOOL didComplete))onMigrationComplete {
    
    BOOL migrationSucceeded = NO;
    
    BOOL shouldMigrate = testConditionsExistToMigrate();
    
    if(shouldMigrate) {
        
        migrate();
        
        migrationSucceeded = didMigrationSucceed();
        
        if(!migrationSucceeded) {
            rollback();
        }
    }
    
    onMigrationComplete(migrationSucceeded);
}

-(BOOL)transaction:(BOOL (^)(sqlite3 **db))beginTransaction operationsInTransaction:(NSArray*)operationsInTransaction endTransaction:(BOOL (^)(BOOL transactionSucceeded, sqlite3 *db))endTransaction {
    
    sqlite3 *db = nil;
    
    // beginTransaction opens the db and executes begin transaction
    BOOL transactionSucceess = beginTransaction(&db);
    
    if(transactionSucceess) {
        
        // allows results to be passed between operations
        // ie insert row id result used as a foreign key in another statement
        NSMutableDictionary *contextData = [[NSMutableDictionary alloc] init];
        
        for(SQLiteQueryUtilTransactionOperation nextOperation in operationsInTransaction) {
            // TODO typecheck nextOperation | use wrapper object
            transactionSucceess &= nextOperation(db, contextData);
            
            if(!transactionSucceess) {
                break;
            }
        }
    }
    
    // endTransaction executes commit/rollback and closes the db
    transactionSucceess &= endTransaction(transactionSucceess, db);
    
    return transactionSucceess;
}

-(BOOL)writeTransactionWithOperations:(NSArray*)operationsInTransaction {
    BOOL(^closedb)(sqlite3*) = ^BOOL(sqlite3 *db) {
        int closeResult = closeResult = sqlite3_close(db);
        BOOL closeSuccess = closeResult == SQLITE_OK;
        if(closeResult != SQLITE_OK) {
            NSLog(@"[SQLITE] Error failed to close db %d %s", closeResult, sqlite3_errmsg(db));
        }
        return closeSuccess;
    };
    
    
    return [self transaction:^BOOL(sqlite3 **dbPtr){
        sqlite3 *db = NULL;
        int dbOpenResult = [self openDBReadWrite:&db];
        *dbPtr = db;
        
        BOOL beginTransactionSuccess = dbOpenResult == SQLITE_OK;
        
        if (beginTransactionSuccess) {
            // http://sqlite.org/lang_transaction.html
            // IMMEDIATE (Rather than exclusive) allows readonly queries inside the transaction
            // without error but changes (insert, update, delete) executed within the
            // transaction are  not visible
            int beginResponse = sqlite3_exec(db, "BEGIN IMMEDIATE TRANSACTION", 0, 0, 0);
            beginTransactionSuccess &= beginResponse == SQLITE_OK;
            if(beginResponse != SQLITE_OK) {
                NSLog(@"[SQLITE] Begin Transaction Error: %d %s",beginResponse, sqlite3_errmsg(db));
            }
        }
        
        return beginTransactionSuccess;
        
    } operationsInTransaction:operationsInTransaction endTransaction:^BOOL(BOOL transactionSucceeded, sqlite3 *db) {
        BOOL wholeTransactionSucceeded = transactionSucceeded;
        
        if(!transactionSucceeded) {
            int rollbackResponse = sqlite3_exec(db, "ROLLBACK", 0, 0, 0);
            if (rollbackResponse != SQLITE_OK) {
                NSLog(@"[SQLITE] Rollback Error: %d %s",rollbackResponse, sqlite3_errmsg(db));
            }
        }
        else {
            int commitResponse = sqlite3_exec(db, "COMMIT TRANSACTION", 0, 0, 0);
            wholeTransactionSucceeded &= commitResponse == SQLITE_OK;
            if (commitResponse != SQLITE_OK) {
                NSLog(@"[SQLITE] Commit Transaction Error: %d %s",commitResponse, sqlite3_errmsg(db));
            }
        }
        
        wholeTransactionSucceeded &= closedb(db);
        
        return wholeTransactionSucceeded;
    }];
}

@end
