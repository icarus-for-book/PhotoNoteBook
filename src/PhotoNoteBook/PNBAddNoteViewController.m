//
//  PNBAddNoteViewController.m
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PNBAddNoteViewController.h"
#import "NSFileManager+Dir.h"
#import "PNBNote.h"

@interface PNBAddNoteViewController ()

@end

@implementation PNBAddNoteViewController
@synthesize textField = _textField;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDone:)];
    
}

- (void)viewDidUnload
{
    [self setTextField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.textField becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)onDone:(id)sender 
{
    // check parameter
    if ( [self.textField.text length] == 0 )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" 
                                                        message:@"제목을 넣어주세요." 
                                                       delegate:nil 
                                              cancelButtonTitle:@"확인" 
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    

    
    if (self.delegate) {
        [self.delegate addNoteViewController:self didFinishAdding:self.textField.text];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}
@end
