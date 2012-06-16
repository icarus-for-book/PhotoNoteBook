//
//  PNBPage.m
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PNBPage.h"

@implementation PNBPage

@synthesize title = _title;
@synthesize ctime = _ctime;
@synthesize photo = _photo;
@synthesize thumbnail = _thumbnail;

- (id) initWithImage:(UIImage *)image
{
    self.photo = image;
    self.thumbnail = nil;
    self.title = @"untitle";
    self.ctime = [NSDate date];
    return self;
}


#pragma mark - NSCoding 

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    NSData *data = [aDecoder decodeObjectForKey:@"thumbnail"];
    self.thumbnail = [UIImage imageWithData:data];

    data = [aDecoder decodeObjectForKey:@"photo"];
    self.photo = [UIImage imageWithData:data];
    self.ctime = [aDecoder decodeObjectForKey:@"ctime"];
    self.title = [aDecoder decodeObjectForKey:@"title"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    NSData *data = UIImagePNGRepresentation(self.thumbnail);
    [aCoder encodeObject:data forKey:@"thumbnail"];
    
    data = UIImagePNGRepresentation(self.photo);
    [aCoder encodeObject:data forKey:@"photo"];
    [aCoder encodeObject:self.ctime forKey:@"ctime"];
    [aCoder encodeObject:self.title forKey:@"title"];
}


@end
