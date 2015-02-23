SQLiteQueryUtil
===============

Set of utility functions for accessing and manipulating a sqlite database on iOS in objective-c

Dependencies: libsqlite3.dylib

(libsqlite3 is included in Xcode's iOS distribution. Select this lib from Xcode Project->Build Phases->Link Binary With Libraries)

example: init
```
NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString *docsDir = [dirPaths objectAtIndex:0];
NSString *databasePath = [[docsDir stringByAppendingPathComponent:@"database"] stringByAppendingPathExtension:@"sqlite"];

SQLiteQueryUtil *queryUtil = [[SQLiteQueryUtil alloc] initWithDBPath:databasePath];
```

example: select

```
/* init SQLiteQueryUtil queryUtil instance with database path */

sqlite3_int64 fooIdToQuery = 100;
__block NSMutableArray *foos = nil;

NSString *query = @"select id,name from foo where id=?;";

[queryUtil queryDB:query withBindParamsCallback:^(sqlite3_stmt *queryStatement) {

    sqlite3_bind_int64(queryStatement, 1, fooIdToQuery); // bind params start at 1

} onNextRowCallback:^(sqlite3_stmt *queryStatement, NSUInteger currentRow) {
    if(currentRow == 0) {
        foos = [[NSMutableArray alloc] init];
    }

    sqlite_int64 fooId = sqlite3_column_int64(queryStatement, 0); // column results start at 0
    const unsigned char *fooNameChars = sqlite3_column_text(queryStatement, 1);

    NSString *fooName = fooNameChars != NULL ? [[NSString alloc] initWithUTF8String:fooNameChars] : nil;

    Foo *nextFoo = [[Foo alloc] init];
    nextFoo.id = fooId;
    nextFoo.name = fooName;

    [foos addObject:nextFoo];

} onQueryCompleteCallack:^{ }];
```

example: insert

```
/* init SQLiteQueryUtil queryUtil instance with database path */

__block sqlite3_int64 insertResultId = -1;
NSString *nameToInsert = "mike";

NSString *query = @"insert into foo (name) values(?);";

[queryUtil writeQueryInDB:insertSQL withBindParamsCallback:^(sqlite3_stmt *queryStatement) {
    sqlite3_bind_text(queryStatement, 1, [nameToInsert UTF8String], -1, SQLITE_TRANSIENT); // bind params start at 1
} onNextRowCallback:^(sqlite3_stmt *queryStatement, NSUInteger currentRow) {
    insertResultId = sqlite3_last_insert_rowid(database);
} onQueryCompleteCallack:^{ }];
```

example: delete

```
/* init SQLiteQueryUtil queryUtil instance with database path */

__block BOOL success = NO;
sqlite3_int64 idToDelete = 100;

NSString *query = @"delete from foo where id=?;";

[queryUtil writeQueryInDB:insertSQL withBindParamsCallback:^(sqlite3_stmt *queryStatement) {
    sqlite3_bind_int64(queryStatement, 1, idToDelete); // bind params start at 1
} onNextRowCallback:^(sqlite3_stmt *queryStatement, NSUInteger currentRow) {
    success = YES;
} onQueryCompleteCallack:^{ }];
```

example: migration (add an index)

```
/* init SQLiteQueryUtil queryUtil instance with database path */

int32_t currentdbVersion = [queryUtil dbVersion];

int32_t rollbackDBVersion = 1;
int32_t targetDBVersion = 2;

__block sqlite3 *transactionDBConn = nil;
int openResult = [queryUtil openDBReadWrite:&transactionDBConn];

NSString *foo_name_index_create_sql_stmtString = "create index if not exists foo_name_index on foo(name);"
NSString *foo_name_index_drop_sql_stmtString = "drop index if exists foo.foo_name_index;"

[queryUtil migrate:^BOOL{
    return currentdbVersion == 1 && openResult == SQLITE_OK;
} migrate:^{
    NSLog(@"[SQLITE_MIGRATOR] Migration from v%d to v%d", currentdbVersion, targetDBVersion);
    [queryUtil writeQueryInDB:foo_name_index_create_sql_stmtString withDB:&transactionDBConn withBindParamsCallback:nil onNextRowCallback:nil onQueryCompleteCallack:nil];
    
    // update the db user version so we know migration was successful going forward
    [queryUtil setdbVersion:targetDBVersion withDB:&transactionDBConn];
    
} didMigrationSucceed:^BOOL{
    return YES;
} rollback:^{
    NSLog(@"[SQLITE_MIGRATOR] Migration Rollback to v%d", rollbackDBVersion);
    
    if (sqlite3_exec(transactionDBConn, "ROLLBACK;", 0, 0, 0) != SQLITE_OK) {
        NSLog(@"[SQLITE_MIGRATOR] SQL Error: %s",sqlite3_errmsg(transactionDBConn));
    }
    [queryUtil setdbVersion:rollbackDBVersion withDB:&transactionDBConn];
} onMigrationComplete:^(BOOL didComplete) {
    int closeResult = sqlite3_close(transactionDBConn);
    if(closeResult != SQLITE_OK) {
        NSLog(@"[SQLITE] Error failed to close db %d %s", closeResult, sqlite3_errmsg(transactionDBConn));
    }
    NSLog(@"[SQLITE_MIGRATOR] Migration from v%d to v%d %@",currentdbVersion, targetDBVersion, didComplete ? @"SUCCESS" : @"FAIL");
}
```
