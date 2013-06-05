//
//  NSString+Addons.m
//  iSeeU
//
//  Created by Krzysztof Szczepaniak on 03/06/2013.
//  Copyright (c) 2013 Roche. All rights reserved.
//

#import "NSString+Addons.h"

@implementation NSString (Addons)

- (BOOL)isEmpty {
    if([self length] == 0) { //string is empty or nil
        return YES;
    }
    
    if(![[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        //string is all whitespace
        return YES;
    }
    
    return NO;
}

@end
