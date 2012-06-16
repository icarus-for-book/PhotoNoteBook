//
//  PNBPageViewController.h
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PNBNote;

@interface PNBPageViewController : UITableViewController

// 표시할 Document 파일
@property (nonatomic, strong) PNBNote *document;


- (IBAction)onAddPage:(id)sender;

@end
