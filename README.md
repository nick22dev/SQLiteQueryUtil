SQLiteQueryUtil
===============

Set of utility functions for accessing and manipulating a sqlite database on iOS in objective-c

Dependencies: libsqlite3.dylib

(libsqlite3 is included in Xcode's iOS distribution. Select this lib from Xcode Project->Build Phases->Link Binary With Libraries)

example: select

```
NSString *databasePath = "";

sqlite3_int64 fooIdToQuery = 100;
__block NSMutableArray *foos = nil;

NSString *query = @"select id,name from foo where id=?;";

SQLiteQueryUtil *queryUtil = [[SQLiteQueryUtil alloc] initWithDBPath:databasePath];

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

sqlite3_int64 insertResultId = 100;
NSString *name = "mike";

NSString *query = @"insert into foo (name) values(?);";

[queryUtil writeQueryInDB:insertSQL withBindParamsCallback:^(sqlite3_stmt *queryStatement) {
    sqlite3_bind_text(queryStatement, 1, [name UTF8String], -1, SQLITE_TRANSIENT);
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
    sqlite3_bind_int64(queryStatement, 1, idToDelete);
} onNextRowCallback:^(sqlite3_stmt *queryStatement, NSUInteger currentRow) {
    success = YES;
} onQueryCompleteCallack:^{ }];
```
