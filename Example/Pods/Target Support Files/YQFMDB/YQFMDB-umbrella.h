#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AVFMDB.h"
#import "AVFMDBHeader.h"
#import "AVFMDBUtil.h"
#import "AVMacros.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabasePool.h"
#import "FMDatabaseQueue.h"
#import "FMDB.h"
#import "FMResultSet.h"

FOUNDATION_EXPORT double YQFMDBVersionNumber;
FOUNDATION_EXPORT const unsigned char YQFMDBVersionString[];

