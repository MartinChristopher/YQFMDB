//
//  AVFMDBUtil.m
//  AVFMDB
//
//  Created by Apple on 2021/7/23.
//

#import "AVFMDBUtil.h"
#import "AVMacros.h"
#import <objc/runtime.h>

@implementation AVFMDBUtil

+ (NSString *)dbPathForName:(NSString *)name {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *dbPath = [documentDirectory stringByAppendingPathComponent:name];
    return dbPath;
}

#pragma mark - <存储类型转为字典>

+ (NSDictionary *)storageTypeTodictionary:(id)parameters {
    NSDictionary *dic;
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        dic = parameters;
    }
    else {
        Class CLS = [AVFMDBUtil getModelClass:parameters];
        dic = [AVFMDBUtil modelToDictionary:CLS];
    }
    return dic;
}

#pragma mark - <获取模型类>

+ (Class)getModelClass:(id)parameters {
    Class CLS;
    if ([parameters isKindOfClass:[NSString class]]) {
        if (!NSClassFromString(parameters)) {
            CLS = nil;
        } else {
            CLS = NSClassFromString(parameters);
        }
    } else if ([parameters isKindOfClass:[NSObject class]]) {
        CLS = [parameters class];
    } else {
        CLS = parameters;
    }
    return CLS;
}

#pragma mark - <模型转字典>

+ (NSDictionary *)modelToDictionary:(Class)cls {
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:0];
    
    unsigned int outCount = 0;
    objc_property_t * properties = class_copyPropertyList(cls, &outCount);
    for (unsigned int i = 0; i < outCount; i++) {
        //属性名
        NSString *name = [NSString stringWithCString:property_getName(properties[i]) encoding:NSUTF8StringEncoding];
        //属性类型
        NSString *type = [NSString stringWithCString:property_getAttributes(properties[i]) encoding:NSUTF8StringEncoding];
        //属性的类型换为数据库类型
        id value = [AVFMDBUtil propertTypeConvert:type];
        if (value) {
            [dic setObject:value forKey:name];
        }
    }
    free(properties);
    
    return dic;
}

#pragma mark - <属性类型转数据库类型>

+ (NSString *)propertTypeConvert:(NSString *)typeStr {
    NSString *resultStr = nil;
    if ([typeStr hasPrefix:@"T@\"NSArray\""]) {
        resultStr = SQL_ARRAY;
    } else if ([typeStr hasPrefix:@"T@\"NSString\""]) {
        resultStr = SQL_TEXT;
    } else if ([typeStr hasPrefix:@"T@\"NSData\""]) {
        resultStr = SQL_BLOB;
    } else if ([typeStr hasPrefix:@"Ti"]||[typeStr hasPrefix:@"TI"]||[typeStr hasPrefix:@"Ts"]||[typeStr hasPrefix:@"TS"]||[typeStr hasPrefix:@"T@\"NSNumber\""]||[typeStr hasPrefix:@"TB"]||[typeStr hasPrefix:@"Tq"]||[typeStr hasPrefix:@"TQ"]) {
        resultStr = SQL_INTEGER;
    } else if ([typeStr hasPrefix:@"T@"]){
        resultStr = SQL_MODEL;
    } else if ([typeStr hasPrefix:@"Tf"] || [typeStr hasPrefix:@"Td"]){
        resultStr= SQL_REAL;
    }
    
    return resultStr;
}

#pragma mark - <获取model属性的key和value>

+ (NSDictionary *)getModelPropertyKeyValue:(id)model
                                  clomnArr:(NSArray *)clomnArr {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:0];
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList([model class], &outCount);
    for (unsigned int i = 0; i < outCount; i++) {
        NSString *name = [NSString stringWithCString:property_getName(properties[i]) encoding:NSUTF8StringEncoding];
        
        //特殊判断，如果数据库表中不存这个字段 则跳过。
        if (![clomnArr containsObject:name]) {
            continue;
        }
        
        id value = [model valueForKey:name];
        if (value) {
            [result setObject:value forKey:name];
        }
    }
    free(properties);
    return result;
}

+ (NSString *)getFileName:(NSString *)filePath {
    return [[filePath lastPathComponent] stringByDeletingPathExtension];
}

@end
