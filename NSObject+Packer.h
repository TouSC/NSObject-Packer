//
//  SCPacker.h
//
//  Created by 唐绍成 on 2017/4/2.
//  Copyright © 2017年 唐绍成. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Packer)

- (id)setup;
- (id)setup:(BOOL)isMock groupHandle:(id(^)(NSString *key))handle;
- (id)unpack:(NSDictionary*)dic;
- (id)unpack:(NSDictionary*)dic groupHandle:(id(^)(NSString *key, id value))handle;
- (id)setup:(BOOL)isMock listCount:(NSInteger)listCount groupHandle:(id(^)(NSString *key))handle;

@end
