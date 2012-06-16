//
//  PNBNodeEntry.m
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PNBNoteEntry.h"

@implementation PNBNoteEntry

@synthesize fileUrl = _fileUrl;
@synthesize title = _title;
@synthesize thumbnail = _thumbnail;
@synthesize state = _state;
@synthesize fileVersion = _fileVersion;

- (NSString *)description
{
    return [self.fileUrl lastPathComponent];
}

@end
