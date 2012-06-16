//
//  PNBDetailViewController.m
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PNBDetailViewController.h"

@interface PNBDetailViewController () < UIScrollViewDelegate >

@end

@implementation PNBDetailViewController
@synthesize image = _image;
@synthesize imageView = _imageView;

#pragma mark - Managing the detail item

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.imageView.image = self.image;
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.image = nil;
}

#pragma mark - UIScrollViewDelegate handler

//
// UIScrollView를 이용해서 Pinch/Zoom을 위한 설정
// 
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

@end
