SQLiteQueryUtil
===============

Set of utility functions for accessing and manipulating a sqlite database on iOS in objective-c

Dependencies: libsqlite3.dylib

(libsqlite3 is included in Xcode's iOS distribution. Select this lib from Xcode Project->Build Phases->Link Binary With Libraries)

example: select

```
NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
NSString *docsDir = [dirPaths objectAtIndex:0];
NSString *databasePath = [[docsDir stringByAppendingPathComponent:@"database"] stringByAppendingPathExtension:@"sqlite"];

sqlite3_int64 fooIdToQuery = 100;
__block NSMutableArray *foos = nil;

NSString *query = @"SELECT ID,fooName FROM fooTable WHERE ID=?;";

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
    nextFoo.foodId = fooId;
    nextFoo.fooName = fooName;

    [foos addObject:nextFoo];

} onQueryCompleteCallack:^{

}];
```
