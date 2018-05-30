//
//  NSObject+Packer.m
//
//  Created by 唐绍成 on 2017/4/2.
//  Copyright © 2017年 唐绍成. All rights reserved.
//

#import "NSObject+Packer.h"
#import <objc/runtime.h>

@implementation NSObject (Packer)
- (id)setup{
    return [self setup:NO groupHandle:nil];
}

- (id)setup:(BOOL)isMock groupHandle:(id(^)(NSString *key))handle{
    return [self setup:isMock listCount:isMock ? 1 : 0 groupHandle:handle];
}

- (id)setup:(BOOL)isMock listCount:(NSInteger)listCount groupHandle:(id(^)(NSString *key))handle{
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (int i=0; i<count; i++)
    {
        objc_property_t property = properties[i];
        NSString *key = [NSString stringWithUTF8String:property_getName(property)];
        NSString *type = [NSString stringWithUTF8String:property_getAttributes(property)];
        NSArray *types = [type componentsSeparatedByString:@"\""];
        if (types.count==3)
        {
            if ([(NSString*)types.lastObject rangeOfString:@"R"].location!=NSNotFound)//readonly
            {
                continue;
            }
            type = types[1];
        }
        else
        {
			free(properties);
            return self;
        }
        if (![type isEqualToString:NSStringFromClass([self class])])//防止递归无限循环，当有子属性类型和自己相同时不init
        {
            id object = [NSClassFromString(type) new];
            if (isMock)
            {
                if ([object isKindOfClass:[NSString class]])
                {
                    if (handle)
                    {
                        object = handle(key);
                    }
                    if ([object length]==0)
                    {
                        object = @"this is a string";
                    }
                }
                else if ([object isKindOfClass:[NSNumber class]])
                {
                    if (handle)
                    {
                        object = handle(key);
                    }
                    if ([object length]==0)
                    {
                        object = @(9.9);
                    }
                }
                else if ([object isKindOfClass:[NSArray class]])
                {
                    if (handle)
                    {
                        NSMutableArray *array = @[].mutableCopy;
                        for (int i=0; i<listCount; i++)
                        {
                            id element = handle(key);
                            if (element)
                            {
                                [array addObject:element];
                            }
                        }
                        object = [array copy];
                    }
                }
                else if ([object isKindOfClass:[NSDictionary class]])
                {
                    id element;
                    if (handle)
                    {
                        element = handle(key);
                    }
                    if (element)
                    {
                        object = element;
                    }
                }
                else
                {
                    id element;
                    if (handle)
                    {
                        element = handle(key);
                    }
                    if (!element)
                    {
                        element = [object setup:YES listCount:listCount groupHandle:handle];
                    }
                    object = element;
                }
                [self setValue:object forKey:key];
            }
            else
            {
                if ([self valueForKey:key]==nil)
                {
                    [self setValue:object forKey:key];
                }
            }
        }
    }
    free(properties);
    return self;
}

- (id)unpack:(NSDictionary*)dic{
    return [self unpack:dic groupHandle:nil];
}

- (id)unpack:(NSDictionary*)dic groupHandle:(id(^)(NSString *key, id value))handle{

    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (int i=0; i<count; i++)
    {
        objc_property_t property = properties[i];
        NSString *key = [NSString stringWithUTF8String:property_getName(property)];
        NSString *type = [NSString stringWithUTF8String:property_getAttributes(property)];
        NSArray *types = [type componentsSeparatedByString:@"\""];
        if (types.count==3)
        {
            type = types[1];
        }
        else
        {
            continue;
        }
        
        NSString *realKey = key;
        if ([key isEqualToString:@"ID"])
        {
            realKey = @"id";
        }
        else if ([[key substringToIndex:key.length>=3 ? 3 : 0] isEqualToString:@"New"])
        {
            realKey = [key stringByReplacingOccurrencesOfString:@"New" withString:@"new"];
        }
        NSString *value = dic[realKey];

        if ([value isKindOfClass:[NSDictionary class]])
        {
            id object = [NSClassFromString(type) new];
            [object unpack:value groupHandle:handle];
            [self setValue:object forKey:key];
        }
        else if ([value isKindOfClass:[NSArray class]])
        {
            if (handle)
            {
                NSMutableArray *array = @[].mutableCopy;
                for (id element in value)
                {
                    [array addObject:handle(key,element)];
                }
                [self setValue:[array copy] forKey:key];
            }
            else
            {
                [self setValue:value forKey:key];
            }
        }
        else if ([value isKindOfClass:[NSNull class]])
        {
            [self setValue:value forKey:key];
        }
        else if ([value isKindOfClass:[NSString class]])
        {
            if ([value isEqualToString:@"N/A"] ||
                [value isEqualToString:@"n/a"] ||
                [value isEqualToString:@"NULL"] ||
                [value isEqualToString:@"Null"] ||
                [value isEqualToString:@"null"])
            {
                [self setValue:@"" forKey:key];
            }
            else
            {
                [self setValue:handle ? handle(key,value) : value forKey:key];
            }
        }
        else if (value==nil)
        {
            continue;
        }
        else
        {
            [self setValue:value forKey:key];
        }
    }
    free(properties);
    return self;
}

@end
