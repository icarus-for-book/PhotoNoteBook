//
//  NSFileManager+Dir.m
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSFileManager+Dir.h"

@implementation NSFileManager(FindDirs)

// document url for the app
+ (NSURL*) docURL
{
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    
    return  url;
}


@end
