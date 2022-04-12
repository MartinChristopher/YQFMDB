//
//  AVFMDB.h
//  AVFMDB
//
//  Created by Apple on 2021/7/23.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVFMDB : NSObject

+ (instancetype)shared;

+ (instancetype)sharedDbName:(NSString *)dbName;


/**
 判断表
 
 @param tableName 表名
 @return 是否存在
 */
- (BOOL)isExistTable:(NSString *)tableName;

/**
 获取表字段
 
 @param tableName 表名
 @return 表字段
 */
- (NSArray *)getColumnArr:(NSString *)tableName;

/**
 创建表

 @param tableName 表名
 @param parameters 存储的model或字典类型
 @param nameArr 不保存到数据库 model中的属性或者字典的键值对
 @return 是否创建成功
 */
- (BOOL)createWithTable:(NSString *)tableName
            dicOrModel:(id)parameters
            excludeName:(NSArray * _Nullable)nameArr;

- (BOOL)createWithTable:(NSString *)tableName
             dicOrModel:(id)parameters
            excludeName:(NSArray * _Nullable)nameArr
          primaryKeyDic:(NSDictionary * _Nullable)primaryKeyDic;

/**
 插入数据（支持插入一个数据或者一个数组）
 
 @param tableName 表名
 @param dataSource 插入数据
 */
- (void)insertWithTable:(NSString *)tableName
             dataSource:(id)dataSource;

/**
 插入数据
 
 @param tableName 表名
 @param parameters 插入数据
 */
- (BOOL)insertWithTable:(NSString *)tableName
             parameters:(id)parameters;

/**
 删除数据
 
 @param tableName 表名
 @param whereFormat 删除的条件
 @return 是否删除成功
 */
- (BOOL)deleteWithTable:(NSString *)tableName
            whereFormat:(NSString *)whereFormat;

/**
 更新数据
 
 @param tableName 表名
 @param dataSource 更新数据
 @param format 更新的条件
 @return 是否更新成功
 */
- (BOOL)updateWithTable:(NSString *)tableName
             dataSource:(id)dataSource
            whereFormat:(NSString *)format;

/**
 查找数据
 
 @param tableName 表名
 @param parameters 数据类型model或字典
 @param format 查找的条件 注：默认不带WHERE关键字，需要手动添加
 @return 查询结果
 */
- (NSArray *_Nullable)selectWithTable:(NSString *)tableName
                           dicOrModel:(id)parameters
                          whereFormat:(NSString * _Nullable)format;

/**
 清空表
 
 @param tableName  表名
 @return 是否清空成功
 */
- (BOOL)deleteAllDataFromTable:(NSString *)tableName;

@end

NS_ASSUME_NONNULL_END
