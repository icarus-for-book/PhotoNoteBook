//
//  PNBNoteMetadata.m
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PNBNoteMetadata.h"

@implementation PNBNoteMetadata

@synthesize title = _title;
@synthesize thumbnail = _thumbnail;

- (id)initWithTitle:(NSString *)title
{
    self = [super init];
    if(self) {
        self.title = title;
    }
    
    return self;
}

#pragma mark - NSCoding 

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    self.title = [aDecoder decodeObjectForKey:@"title"];
    
    NSData *data = [aDecoder decodeObjectForKey:@"thumbnail"];
    UIImage *image = [UIImage imageWithData:data];
    self.thumbnail = image;
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.title forKey:@"title"];
    NSData *data = UIImagePNGRepresentation(self.thumbnail);
    [aCoder encodeObject:data forKey:@"thumbnail"];
}

@end
