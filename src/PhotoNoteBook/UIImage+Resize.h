//
//  UIImage+Resize.h
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImage(ResizeImage)

- (UIImage*)imageByBestFitForSize:(CGSize)targetSize;
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;

@end
