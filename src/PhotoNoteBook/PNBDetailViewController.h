//
//  PNBDetailViewController.h
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// 그림을 보여주는 화면
// 간단하게...
@interface PNBDetailViewController : UIViewController

@property (strong, nonatomic) UIImage *image;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end
