//
//  YQFMDB.m
//  YQFMDB
//
//  Created by Apple on 2021/7/23.
//

#import "YQFMDB.h"
#import "YQFMDBUtil.h"
#import "YQMacros.h"

@interface YQFMDB ()

@property (nonatomic, strong) NSString *dbPath;
@property (nonatomic, strong) FMDatabase *db;

@end

@implementation YQFMDB

#pragma mark - <创建数据库>

static YQFMDB *lcdb = nil;

+ (instancetype)shared {
    return [YQFMDB sharedDbName:@""];
}

+ (instancetype)sharedDbName:(NSString *)dbName {
    if (!lcdb) {
        if (!dbName || dbName.length < 1) {
            dbName = kDataBaseName;
        }
        NSString *path = [YQFMDBUtil dbPathForName:dbName];
        NSLog(@"%@", path);
        FMDatabase *fmdb = [FMDatabase databaseWithPath:path];
        if ([fmdb open]) {
            lcdb = YQFMDB.new;
            lcdb.db = fmdb;
            lcdb.dbPath = path;
        }
    }
    if (![lcdb.db open]) {
        NSLog(@"数据库打开失败");
        return nil;
    };
    return lcdb;
}

#pragma mark - <判断表>

- (BOOL)isExistTable:(NSString *)tableName {
    FMResultSet *set = [_db executeQuery:@"SELECT count(*) as 'count' FROM sqlite_master WHERE type ='table' and name = ?", tableName];
    while ([set next]) {
        NSInteger count = [set intForColumn:@"count"];
        if (count == 0) {
            return NO;
        } else {
            return YES;
        }
    }
    return NO;
}

#pragma mark - <获取表字段>

- (NSArray *)getColumnArr:(NSString *)tableName {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:0];
    FMResultSet *resultSet = [_db getTableSchema:[NSString stringWithFormat:@"%@",tableName]];
    while ([resultSet next]) {
        [arr addObject:[resultSet stringForColumn:@"name"]];
    }
    return arr;
}

#pragma mark - <创建表>

- (BOOL)createWithTable:(NSString *)tableName
             dicOrModel:(id)parameters
            excludeName:(NSArray * _Nullable)nameArr {
    return [self createWithTable:tableName dicOrModel:parameters excludeName:nameArr primaryKeyDic:nil];
}

- (BOOL)createWithTable:(NSString *)tableName
             dicOrModel:(id)parameters
            excludeName:(NSArray * _Nullable)nameArr
          primaryKeyDic:(NSDictionary * _Nullable)primaryKeyDic {
    BOOL result = NO;
    
    NSDictionary *dic = [YQFMDBUtil storageTypeTodictionary:parameters];
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *propertyTypeDic = [NSMutableDictionary dictionaryWithDictionary:[userDefault dictionaryForKey:@"propertyTypeDic"]];
    NSMutableDictionary *dbDic = [NSMutableDictionary dictionaryWithDictionary:[propertyTypeDic valueForKey:[YQFMDBUtil getFileName:_db.databasePath]]];
    [dbDic setObject:dic forKey:tableName];
    
    [propertyTypeDic setValue:dbDic forKey:[YQFMDBUtil getFileName:_db.databasePath]];
    [userDefault setObject:propertyTypeDic forKey:@"propertyTypeDic"];
    [userDefault synchronize];
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (",tableName];

    //把模型中不保存的属性去除
    int keyCount = 0;
    for (NSString *key in dic) {
        keyCount++;
        if (primaryKeyDic && [key isEqualToString:primaryKeyDic[kPrimaryKeyName]]) {
            //最后一个 没有最后的逗号
            if (keyCount == dic.count) {
                [sql appendFormat:@"%@ %@ PRIMARY KEY)",primaryKeyDic[kPrimaryKeyName],primaryKeyDic[kPrimaryKeyType]];
                break;
            } else {
                [sql appendFormat:@"%@ %@ PRIMARY KEY,",primaryKeyDic[kPrimaryKeyName],primaryKeyDic[kPrimaryKeyType]];
                continue;
            }
        }
        //不需要保存的字段
        if (nameArr && [nameArr containsObject:key]) {
            if (keyCount == dic.count) {
                [sql deleteCharactersInRange:NSMakeRange(sql.length - 1, 1)];
                [sql appendFormat:@")"];
                break;
            }
            continue;
        }
        if (keyCount == dic.count) {
            [sql appendFormat:@" %@ %@)",key,dic[key]];
            break;
        }
        [sql appendFormat:@" %@ %@,",key,dic[key]];
    }
    
    result = [_db executeUpdate:sql];

    return result;
}

#pragma mark - <插入多条数据>

- (void)insertWithTable:(NSString *)tableName
             dataSource:(id)dataSource {
    NSArray *columnArr = [self getColumnArr:tableName];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *propertyTypeDic = [NSMutableDictionary dictionaryWithDictionary:[userDefault dictionaryForKey:@"propertyTypeDic"]];
    NSDictionary *dbDic = [propertyTypeDic valueForKey:[YQFMDBUtil getFileName:_db.databasePath]][tableName];
    //多条数据
    if ([dataSource isKindOfClass:[NSArray class]]) {
        for (int i = 0; i < [dataSource count]; i++) {
            [self insertWithTable:tableName dataSource:dataSource[i] columnArr:columnArr propertyTypeDic:dbDic];
        }
    }
    //一条数据
    else {
        [self insertWithTable:tableName dataSource:dataSource columnArr:columnArr propertyTypeDic:dbDic];
    }
}

#pragma mark - <插入数据>

- (BOOL)insertWithTable:(NSString *)tableName
             parameters:(id)parameters {
    NSArray *columnArr = [self getColumnArr:tableName];
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *propertyTypeDic = [NSMutableDictionary dictionaryWithDictionary:[userDefault dictionaryForKey:@"propertyTypeDic"]];
    NSDictionary *dbDic = [propertyTypeDic valueForKey:[YQFMDBUtil getFileName:_db.databasePath]][tableName];
    return [self insertWithTable:tableName dataSource:parameters columnArr:columnArr propertyTypeDic:dbDic];;
}

- (BOOL)insertWithTable:(NSString *)tableName
             dataSource:(id)dataSource
              columnArr:(NSArray *)columnArr
        propertyTypeDic:(NSDictionary *)propertyTypeDic {
    
    NSDictionary *dic;
    if ([dataSource isKindOfClass:[NSDictionary class]]) {
        dic = dataSource;
    } else {
        dic = [YQFMDBUtil getModelPropertyKeyValue:dataSource clomnArr:columnArr];
    }

    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"INSERT INTO %@ (",tableName];
    NSMutableString *tempStr = [NSMutableString stringWithCapacity:0];
    NSMutableArray *argumentsArr = [NSMutableArray arrayWithCapacity:0];
    
    for (NSString *key in dic) {
        if (![columnArr containsObject:key]) {
            continue;
        }
        [sql appendFormat:@"%@,",key];
        [tempStr appendString:@"?,"];
        
        if ([propertyTypeDic[key] isEqualToString:SQL_ARRAY]) {//数组存储前先反序列化为二进制数据
            [argumentsArr addObject:[NSKeyedArchiver archivedDataWithRootObject:dic[key]]];
        }else if([propertyTypeDic[key] isEqualToString:SQL_MODEL]){//模型存储前先反序列化为二进制数据
            [argumentsArr addObject:[NSKeyedArchiver archivedDataWithRootObject:dic[key]]];
        }else {
            [argumentsArr addObject:dic[key]];
        }
        
    }
    
    //删除最后一个符号
    [sql deleteCharactersInRange:NSMakeRange(sql.length - 1, 1)];
    //删除最后一个符号
    if (tempStr.length) {
        [tempStr deleteCharactersInRange:NSMakeRange(tempStr.length - 1, 1)];
    }
    
    [sql appendFormat:@") VALUES (%@)",tempStr];
    
    BOOL result = [_db executeUpdate:sql withArgumentsInArray:argumentsArr];
    if (result) {
        NSLog(@"插入成功");
    } else {
        NSLog(@"插入失败");
    }
    return result;
}

#pragma mark - <删除数据>

- (BOOL)deleteWithTable:(NSString *)tableName
            whereFormat:(NSString *)whereFormat {
    BOOL result = NO;
    NSMutableString *sqlString = [[NSMutableString alloc] initWithFormat:@"DELETE FROM %@ %@",tableName,whereFormat];
    result = [_db executeUpdate:sqlString];
    if (result) {
        NSLog(@"删除成功");
    } else {
        NSLog(@"删除失败");
    }
    return result;
}

#pragma mark - <修改数据>

- (BOOL)updateWithTable:(NSString *)tableName
             dataSource:(id)dataSource
            whereFormat:(NSString *)format {
    BOOL result = NO;
    NSMutableString *sqlString;
    NSMutableString *whereString;
    
    whereString = [[NSMutableString alloc] initWithFormat:@"%@",format];
    sqlString = [[NSMutableString alloc] initWithFormat:@"UPDATE %@ SET ",tableName];
    
    NSDictionary *dic;
    NSArray *clomnArr = [self getColumnArr:tableName];
    if ([dataSource isKindOfClass:[NSDictionary class]]) {
        dic = dataSource;
    } else {
        dic = [YQFMDBUtil getModelPropertyKeyValue:dataSource clomnArr:clomnArr];
    }
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *propertyTypeDic = [NSMutableDictionary dictionaryWithDictionary:[userDefault dictionaryForKey:@"propertyTypeDic"]];
    NSDictionary *dbDic = [propertyTypeDic valueForKey:[YQFMDBUtil getFileName:_db.databasePath]][tableName];
    
    NSMutableArray *argumentsArr = [NSMutableArray arrayWithCapacity:0];
    
    for (NSString *key in dic) {
        if (![clomnArr containsObject:key]) {
            continue;
        }
        [sqlString appendFormat:@"%@ = %@,",key,@"?"];
        
        if ([dbDic[key] isEqualToString:SQL_ARRAY]) {//数组存储前先反序列化为二进制数据
            [argumentsArr addObject:[NSKeyedArchiver archivedDataWithRootObject:dic[key]]];
        }else if([dbDic[key] isEqualToString:SQL_MODEL]){//模型存储前先反序列化为二进制数据
            [argumentsArr addObject:[NSKeyedArchiver archivedDataWithRootObject:dic[key]]];
        }else {
            [argumentsArr addObject:dic[key]];
        }
    }
    
    [sqlString deleteCharactersInRange:NSMakeRange(sqlString.length - 1, 1)];
    
    if (whereString.length) {
        [sqlString appendFormat:@" %@",whereString];
    }
    
    result = [_db executeUpdate:sqlString withArgumentsInArray:argumentsArr];
    if (result) {
        NSLog(@"修改成功");
    } else {
        NSLog(@"修改失败");
    }
    
    return result;
}

#pragma mark - <查询数据>

- (NSArray *)selectWithTable:(NSString *)tableName
                  dicOrModel:(id)parameters
                 whereFormat:(NSString * _Nullable)format {
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"SELECT * FROM %@ %@", tableName, format ? format : @""];
    FMResultSet *set = [_db executeQuery:sql];
    
    NSMutableArray *resultArr = [NSMutableArray arrayWithCapacity:0];
    NSDictionary *dbDic = [NSDictionary dictionary];
    NSArray *clomnArr = [NSArray array];
    Class CLS;
    
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        CLS = [NSMutableDictionary class];
        //查找结果 转为字典
        dbDic = parameters;
        clomnArr = dbDic.allKeys;
    }
    else {
        CLS = [YQFMDBUtil getModelClass:parameters];
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *propertyTypeDic = [NSMutableDictionary dictionaryWithDictionary:[userDefault dictionaryForKey:@"propertyTypeDic"]];
        dbDic = [propertyTypeDic valueForKey:[YQFMDBUtil getFileName:_db.databasePath]][tableName];
        clomnArr = [self getColumnArr:tableName];
    }
    if (CLS) {
        while ([set next]) {
            id resultObj = CLS.new;
            
            for (NSString *name in clomnArr) {
                if ([dbDic[name] isEqualToString:SQL_TEXT]) {
                    id value = [set stringForColumn:name];
                    if (value) {
                        [resultObj setValue:value forKey:name];
                    }
                } else if ([dbDic[name] isEqualToString:SQL_INTEGER]) {
                    [resultObj setValue:@([set longLongIntForColumn:name]) forKey:name];
                } else if ([dbDic[name] isEqualToString:SQL_REAL]) {
                    [resultObj setValue:[NSNumber numberWithDouble:[set doubleForColumn:name]] forKey:name];
                } else if ([dbDic[name] isEqualToString:SQL_BLOB]) {
                    id value = [set dataForColumn:name];
                    if (value) {
                        [resultObj setValue:value forKey:name];
                    }
                } else if ([dbDic[name] isEqualToString:SQL_ARRAY]) {
                    NSData *data = [set dataForColumn:name];
                    NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                    [resultObj setValue:array forKey:name];
                } else if ([dbDic[name] isEqualToString:SQL_MODEL]) {
                    NSData *data = [set dataForColumn:name];
                    id model = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                    [resultObj setValue:model forKey:name];
                }
            }
            
            if (resultObj) {
                [resultArr addObject:resultObj];
            }
        }
    }
    return resultArr;
}

#pragma mark - <清空表>

- (BOOL)deleteAllDataFromTable:(NSString *)tableName {
    NSString *sqlstr = [NSString stringWithFormat:@"DELETE FROM %@", tableName];
    if (![_db executeUpdate:sqlstr]) {
        return NO;
    }
    return YES;
}

@end
