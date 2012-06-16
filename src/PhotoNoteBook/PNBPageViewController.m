//
//  PNBPageViewController.m
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PNBPageViewController.h"
#import "PNBDetailViewController.h"
#import "PNBNote.h"
#import "LoadingView.h"


// for private methods.
@interface PNBPageViewController () <UIImagePickerControllerDelegate,
                                     UIActionSheetDelegate, 
                                     UINavigationControllerDelegate>

@end

@implementation PNBPageViewController

@synthesize document = _document;


// 객체가 종료될때 호출되는 메소스
// 여기서는 로드면서 생성된 PBNNote 객체를 닫는 기능을 함.
// 이 화면에서 상위로 올라면 객체가 제거되면서 dealloc이 
// 호출되므로 여기서 PBNNote를 닫는 것이 적당함.
- (void)dealloc
{
    if( self.document.documentState == UIDocumentStateNormal ) {
        [self.document closeWithCompletionHandler:^(BOOL success) {
        }];
    }
}

// PBNNote 객체를 염.
- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.document.documentState != UIDocumentStateNormal ) {
        [self.document openWithCompletionHandler:^(BOOL success) {
        }];
    }
    

}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(updatedDocumentState:) 
                                                 name:UIDocumentStateChangedNotification 
                                               object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIDocumentStateChangedNotification
                                                  object:nil];
    
}

- (void) updatedDocumentState:(NSNotification *)noti
{
    NSLog(@"changed : %@", self.document);
    if( self.document.documentState == UIDocumentStateNormal ) {
        [self.tableView reloadData];
    } else if (self.document.documentState == UIDocumentStateInConflict ) {

        NSURL *fileURL = self.document.fileURL;
        
        NSMutableArray *fileVersions = [[NSMutableArray alloc] initWithCapacity:4];
        [fileVersions addObject:[NSFileVersion currentVersionOfItemAtURL:fileURL]];
        [fileVersions addObjectsFromArray:[NSFileVersion otherVersionsOfItemAtURL:fileURL]];
        
        // 버전들의 최종 변경 시간을 확인한다.
        __block NSFileVersion *recentVersion = [NSFileVersion currentVersionOfItemAtURL:fileURL];
        [fileVersions enumerateObjectsUsingBlock:^(NSFileVersion *obj, NSUInteger idx, BOOL *stop) {
            if( [recentVersion.modificationDate compare:obj.modificationDate] == NSOrderedAscending )
            {
                recentVersion = obj;
            }
        }];
        
        // 버전을 확정한다.
        if (![recentVersion isEqual:[NSFileVersion currentVersionOfItemAtURL:fileURL]]) {
            [recentVersion replaceItemAtURL:fileURL options:0 error:nil];    
        }

        // 다른 버전들 삭제
        [NSFileVersion removeOtherVersionsOfItemAtURL:fileURL error:nil];
        
        // 충돌되었다고 표시된 파일들을 해결되었다고 설정
        // 나머지는 시스템이 알아서 진행한다.
        NSArray* conflictVersions = [NSFileVersion unresolvedConflictVersionsOfItemAtURL:self.document.fileURL];
        for (NSFileVersion* fileVersion in conflictVersions) {
            fileVersion.resolved = YES;
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.document.documentState == UIDocumentStateNormal ) {
        return [self.document countOfPages];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    
    cell.textLabel.text = [self.document pageTitleAtIndex:indexPath.row];
    cell.detailTextLabel.text = [[self.document pageCtimeAtIndex:indexPath.row] description];
    cell.imageView.image = [self.document pageThumbAtIndex:indexPath.row];
    
    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.document removePageAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.document saveToURL:self.document.fileURL 
                forSaveOperation:UIDocumentSaveForOverwriting 
               completionHandler:^(BOOL success) {
            
        }];
        
    }   
}

#pragma mark - segue handler

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [[segue identifier] isEqualToString:@"showImage"] )
    {
        // 특정 이미지만 보고 싶을때
        
        // 선택한 이미지를 가져옴
        NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
        UIImage *image = [self.document pagePhotoAtIndex:selected.row];
        
        // 설정후 넘김
        [[segue destinationViewController] setTitle:[self.document pageTitleAtIndex:selected.row]];
        [[segue destinationViewController] setImage:image];
    }
}

#pragma mark - Table view delegate


- (IBAction)onAddPage:(id)sender {
    
    //
    // Note에 추가할 그림을 얻는 방식을 선택하는 UIActionSheet 생성후 보여줌
    //
    
    NSMutableArray *photoSources = [[NSMutableArray alloc] initWithCapacity:3];
    
    // 가능한 Options들 찾기
    if( [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] )
    {
        [photoSources addObject:@"Camera"];
    }
    
    if( [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary] )
    {
        [photoSources addObject:@"Photo Library"];
    }
    
    if( [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum] )
    {
        [photoSources addObject:@"Albums"];
    }
    
    // 사용 가능한 것이 없다면 추가 못하도록 설정후 리턴.
    // 이런 경우가 있을까??
    if ([photoSources count] == 0) {
        NSLog(@"There is no way to add page..");
        self.navigationItem.rightBarButtonItem.enabled = NO;
        return;
    }

    // UIActionSheet로 표시
    UIActionSheet * actionSheet = [[UIActionSheet alloc] init];
    actionSheet.delegate = self;
    for (NSString *title in photoSources){
        [actionSheet addButtonWithTitle:title];
    }
    [actionSheet addButtonWithTitle:@"Cancel"];
    actionSheet.destructiveButtonIndex = 0;
    actionSheet.cancelButtonIndex = photoSources.count;
    
    [actionSheet showInView:self.view];
}

#pragma mark - UIImagePickerDelegate handler
- (void) imagePickerController:(UIImagePickerController *)picker 
 didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    //
    // 찍은 사진을 가져옴
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (! image) {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    [picker dismissModalViewControllerAnimated:YES];
    
    // 사진을 Note에 추가
    // 타이틀은 파일이름으로 한다.
    NSString *title = [[info objectForKey:UIImagePickerControllerReferenceURL]lastPathComponent ];
    [self.document addPageWithPhoto:image 
                          withTitle:title];
    
    // 테이블 갱신
    [self.tableView reloadData];
    
    // 파일 저장 ( 확실하게 )
    [self.document saveToURL:self.document.fileURL forSaveOperation:UIDocumentStateInConflict completionHandler:^(BOOL success) {
        NSLog(@"Save complete");
    }];


}

#pragma mark - UIActionSheetDelegate handler


//
// 사용자가 선택한 방법으로 그림 추가
//
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"button index = %d", buttonIndex);
    
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"Cancel"]) {
        // Noting..
        return;
    } else if ([title isEqualToString:@"Photo Library"]) {
        sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    } else if ([title isEqualToString:@"Albums"]) {
        sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    } else if ([title isEqualToString:@"Camera"]) {
        sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        return;
    }
                
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType =sourceType;
    imagePicker.delegate = self;
    imagePicker.allowsEditing = YES;
    [self presentModalViewController:imagePicker animated:YES];

}


@end
