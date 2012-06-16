//
//  PNBAddNoteViewController.h
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PNBAddNoteViewController;

@protocol PNBAddNoteViewControllerDelegate <NSObject>

// PNBAddNoteViewController에서 Note에 대한 자료를 입력하면 호출되는
// 메소드
- (void) addNoteViewController:(PNBAddNoteViewController*) viewController 
               didFinishAdding:(NSString *)title;

@end

@interface PNBAddNoteViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) id<PNBAddNoteViewControllerDelegate> delegate;

- (IBAction)onDone:(id)sender;

@end
