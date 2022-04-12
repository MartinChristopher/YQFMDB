//
//  AVMacros.h
//  AVFMDB
//
//  Created by Apple on 2021/7/23.
//

#ifndef AVMacros_h
#define AVMacros_h

///数据库中常见的几种类型
#define SQL_TEXT     @"TEXT"    //文本
#define SQL_INTEGER  @"INTEGER" //int long integer ...
#define SQL_REAL     @"REAL"    //浮点
#define SQL_BLOB     @"BLOB"    //data
#define SQL_MODEL    @"MODEL"   //sqlite没有model这个数据类型，这是自己添加的一种类型
#define SQL_ARRAY    @"ARRAY"   //sqlite没有数组这个数据类型，这是自己添加的一种类型

///主键
#define kPrimaryKeyName  @"primaryKeyName"
#define kPrimaryKeyType  @"primaryKeyType"

///数据库名
#define kDataBaseName   @"AVFMDB.sqlite"

#endif /* AVMacros_h */
