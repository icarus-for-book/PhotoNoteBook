//
//  PNBMasterViewController.m
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PNBNoteListViewController.h"

// model classes
#import "PNBNote.h"
#import "PNBNoteEntry.h"
#import "PNBNoteMetadata.h"

// view controller classes
#import "PNBAddNoteViewController.h"
#import "PNBPageViewController.h"

// util
#import "NSFileManager+Dir.h"


@interface PNBNoteListViewController () < PNBAddNoteViewControllerDelegate, UIAlertViewDelegate >
{
    // UI상에서 추가를 한 것과 
    // 실제로 추가되고 NSMetadataQuery에 
    // 위해서 추가될때까지 데이터가 일치하지
    // 않을 수 있기 때문에 임시용 저장용으로 
    // 사용할 데이터
    NSMutableSet  *_deletedURLs;
    NSMutableSet  *_addedURLs;
    
    // 테이블 표시에 사용할 데이터 저장용
    // PBNNoteEntry 객체들.
    NSMutableArray  *_objects;
    
    // iCloud Root 디렉토리
    // ex) file://localhost/private/var/mobile/Library/Mobile%20Documents/<teamid~cloud~id>
    NSURL           *_iCloudRootURL;
    NSMetadataQuery * _query;
}
@end

@implementation PNBNoteListViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 화면 왼쪽 버튼에 "Edit Button" 추가
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    // 객체 초기화
    _objects = [[NSMutableArray alloc] initWithCapacity:10];
    _deletedURLs = [[NSMutableSet alloc] initWithCapacity:10];
    _addedURLs = [[NSMutableSet alloc] initWithCapacity:10];
    
    // 화면이 로드될 때 Cloud 폴더 검색한다.
    [self refresh];
}

- (void)viewWillAppear:(BOOL)animated {
    // 조회 가능하게 화면이 보이면 조회가 가능하도록
    // 설정하고 화면이 닫히면 클라우드 폴더를 조회
    // 하지 않는다.
    [_query enableUpdates];
}

- (void)viewWillDisappear:(BOOL)animated {
    // 클라우드 폴더 조회 종료
    [_query disableUpdates];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Portrait만 허용
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma Cloud Directory Query


// 주어진 경로 |fileURL|의 Document를 열어서 필요한 정보를 조회하고 
// 테이블 뷰에 셀을 추가한다.
- (void)loadDocAtURL:(NSURL *)fileURL {
    
    // Document파일을 분석할 객체(PNBNote*)를 생성한다.
    PNBNote * doc = [[PNBNote alloc] initWithFileURL:fileURL];
    
    // 정보를 조화하기 위해서 파일을 열어 본다.
    [doc openWithCompletionHandler:^(BOOL success) {

        // 파일을 열 수 없다면 에러 메시지 출력한다.
        if (!success) {
            NSLog(@"[ERROR] Failed to open %@", fileURL);
            return;
        }

        // Document 파일에서 필요한 파일을 조회한다. 
        // 제목, 위치, 썸네일 등등..
        NSString *title = [doc title];
        NSURL * fileURL = doc.fileURL;
        UIImage *thumbnail = doc.thumbnail;
        UIDocumentState state = doc.documentState;
        NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
        
        NSLog(@"Loaded : %@", [doc.fileURL lastPathComponent]);

        // 정보를 조회 했다면 파일을 닫는다.
        [doc closeWithCompletionHandler:^(BOOL success) {
            
            // 성공 했는지 확인
            if (!success) {
                NSLog(@"Failed to close %@", fileURL);
                // 실패를 하여도 일단 목록에는 넣도록 하자.
            }
            
            // 테이블에 표시한다. 
            [self addOrUpdateEntryWithURL:fileURL 
                                    title:title 
                                thumbnail:thumbnail 
                                    state:state 
                                  version:version];
        }];             
    }];    
}

- (void) refresh {
    
    // 데이터를 초기화 한다.
    [_objects removeAllObjects];
    [self.tableView reloadData];
    
    // 새로운 Note를 추가하지 못하도록 중지
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    // 클라우드 초기화 실행 
    [self initializeiCloudAccessWithCompletion:^(BOOL available) {
        
        if (!available) {
            //
            // 이 앱은 iCloud 전용 앱으로 만들것 이므로 클라우드를 사용할 수 없다면 
            // 경고를 보내고 앱을 종료시킨다. 
            //
            // @ref alertView:clickedButtonAtIndex:
            //
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Cannot using iCloud" 
                                                                 message:@"This app is designed in iCloud. Please Turn on iCloud in Setting"
                                                                delegate:self
                                                       cancelButtonTitle:nil 
                                                       otherButtonTitles:@"OK", nil];
            [alertView show];
        } else {
            // iCloud 디렉토리에서 조회 시작
            [self startQuery];
        }
    }];
}

// 클라우드를 사용할 수 없을때 에러 화면 처리
// 앱을 종료시킨다.
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    exit(0);
}

// Metadata Query객체를 생성한다. 
// 클라우드 디렉토리는 다수의 프로세스 혹은 쓰레드에서 수시로
// 추가, 삭제, 변경될 수 있기 때문에 디렉토리의 파일 조회를 
// 위해서 Metadata Query 객체가 있다.
- (NSMetadataQuery *)metadataQuery {
    NSMetadataQuery * query = [[NSMetadataQuery alloc] init];

    // 파일을 조회할 영역을 설정
    // 선택가능한 영역은 
    // 
    // - Documents 디렉토리q
    // - 그 이외
    //
    // 여기서는 Documents 이하 파일 혹은 폴더만 조회한다.
    [query setSearchScopes:[NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope]];

    // 파일명에 .note가 포함된 것만 검색
    NSString * filePattern = [NSString stringWithFormat:@"*.*", kNoteExtension];
    [query setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE %@",
                         NSMetadataItemFSNameKey, filePattern]];        
        
    return query;
    
}

// 클라우드 디렉토리 조회 중지
- (void)stopQuery {
    
    if (_query) {
        NSLog(@"Stop quering Cloud Directory...");
        
        // Metaquery Notification 제거
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                        name:NSMetadataQueryDidFinishGatheringNotification 
                                                      object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                        name:NSMetadataQueryDidUpdateNotification 
                                                      object:nil];
        // Query 중지
        [_query stopQuery];
        _query = nil;
    }
    
}

// 클라우드 디렉토리 조회 시작
- (void)startQuery {

    // 기존에 동작중인 것 중지
    // 혹시하는 마음에 추가
    [self stopQuery];
    
    NSLog(@"Start quering Cloud Directory...");
    
    _query = [self metadataQuery];
    
    // MedataQuery에 의해서 정보가 조회되면 조회 
    // 결과가 Notification을 통해서 전달된다. 
    // 따라서 결과를 받을 핸들러를 미리 설정해 둔다.
    
    // 첫번째 조회가 완료 되었을때
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processiCloudFiles:)
                                                 name:NSMetadataQueryDidFinishGatheringNotification
                                               object:nil];
    // 첫번째 이후 조회된 결과가 변경되었을 때 호출됨
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processiCloudFiles:)
                                                 name:NSMetadataQueryDidUpdateNotification
                                               object:nil];
    
    // 조회 시작
    [_query startQuery];
}

// 아이클라우드 디렉토리가 조회 완료되거나 변경되었을때 호출되는 콜백 메소드
- (void)processiCloudFiles:(NSNotification *)notification 
{
    // 업데이트 중지
    [_query disableUpdates];

    
    NSMutableArray *queriedURLs = [[NSMutableArray alloc] initWithCapacity:10];
    
    // The query reports all files found, every time.
    NSArray * queryResults = [_query results];
    for (NSMetadataItem * result in queryResults) {
        NSURL * fileURL = [result valueForAttribute:NSMetadataItemURLKey];
        
        NSNumber * aBool = nil;
        [fileURL getResourceValue:&aBool forKey:NSURLIsHiddenKey error:nil];
        if (aBool && ![aBool boolValue]) {
            // 정상적으로 보이는 파일만 추가
            [queriedURLs addObject:fileURL];
        }        
    }
    
    // UI에서 삭제했는데 실제로 삭제되는 시간이 걸리기 때문에
    // 조회를 해보면 아직 삭제간 안된 것으로 나온다. 혹은 
    // 추가를 했는데 추가한 것이 반영이 되지 않았다. 따라서 
    // 임시변수에 저장된 것으로 검색 결과를 보정한다.
    
    
    // 먼저 임시 변수들을 정리한다.
    // 1. UI에서 추가한 파일이 파일 목록에 있으면 _addedURLs에서 삭제
    [queriedURLs enumerateObjectsUsingBlock:^(NSURL *obj, NSUInteger idx, BOOL *stop) {
        if( [_addedURLs containsObject:obj] ) {
            [_addedURLs removeObject:obj];
        }
    }];
     
    // 2. UI에서 삭제 후 실제 목록에서 없으면 _deletedURLs에서도 삭제
    [queriedURLs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if( _deletedURLs.count >0 && ![_deletedURLs containsObject:obj] ) {
            [_deletedURLs removeObject:obj];
        }
    }];

    // 3. UI에서 삭제되어지만 목록에 있으면 목록에서 해당 URL을 제거한다.
    [_deletedURLs enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSURL *obj, BOOL *stop) {
        if( [queriedURLs containsObject:obj] ) {
            [queriedURLs removeObject:obj];
        }
    }];
    
    // 4. UI에서 추가되어지만 목록에 없으면 목록에서 해당 URL을 추가한다.
    [_addedURLs enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSURL *obj, BOOL *stop) {
        if( ! [queriedURLs containsObject:obj] ) {
            [queriedURLs addObject:obj];
        }
    }];
    
    //
    // 기존의 목록(_object)만 있고 실제 조회결과에 없는 것은
    // 외부에서 삭제된 것이므로 제거한다.
    // 다른 기기에서 제거하면 디렉토리에서 자동 제거되므로
    for (int i = _objects.count -1; i >= 0; --i) {
        PNBNoteEntry * entry = [_objects objectAtIndex:i];
        if (![queriedURLs containsObject:entry.fileUrl]) {
            [self removeEntryWithURL:entry.fileUrl];
        }
    }
    
    // 정보를 갱신한다.
    for (NSURL * fileURL in queriedURLs) {                
        [self loadDocAtURL:fileURL];        
    }
    
    // 추가 버튼 사용가능하도록 후 계속 조회
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [_query enableUpdates];
    
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 테이블 셀 생성
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    // 테이블 셀 설정
    PNBNoteEntry *entry = [_objects objectAtIndex:indexPath.row];
    cell.textLabel.text = entry.title;
    cell.detailTextLabel.text = [entry.fileVersion.modificationDate description];
    
    if( entry.thumbnail ) {
        cell.imageView.image = entry.thumbnail;
    } else {
        cell.imageView.image = [UIImage imageNamed:@"note-icon.png"];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // 삭제
        PNBNoteEntry *entry = [_objects objectAtIndex:indexPath.row];
        [self deleteEntry:entry]; 
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showPages"]) {
        //
        // Note에 기록되어 있는 사진 목록 화면으로..
        //
        PNBNoteEntry * entry = [_objects objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        PNBNote* note = [[PNBNote alloc] initWithFileURL:entry.fileUrl];    
        [[segue destinationViewController] setDocument:note];
         
    } else if( [[segue identifier] isEqualToString:@"addNote"] ) {
        //
        // add note
        //
        [[segue destinationViewController] setDelegate:self];
    }
}



#pragma mark Table Entry Helper Functions

// 주어진 |fileURL|에 해당하는 셀 인덱스를 조회한다.
- (int)indexOfEntryWithFileURL:(NSURL *)fileURL {
    
    __block int retval = -1;
    [_objects enumerateObjectsUsingBlock:^(PNBNoteEntry * entry, NSUInteger idx, BOOL *stop) {
        if ([entry.fileUrl isEqual:fileURL]) {
            retval = idx;
            *stop = YES;
        }
    }];
    
    return retval;    
}

// 테이블에 표시할 정보를 받아서 테이블셀을 추가하거나 갱신시킨다.
//
// |fileURL|을 기준으로 기본 셀이 있는지 확인후 없으면 셀슬 추가
// 있으면 새롭게 갱신된 정보로 변경한다.
- (void)addOrUpdateEntryWithURL:(NSURL *)fileURL 
                          title:(NSString *)title 
                      thumbnail:(UIImage*) thumb 
                          state:(UIDocumentState)state 
                        version:(NSFileVersion *)version {
    
    // Index를 제외한다.
    int index = [self indexOfEntryWithFileURL:fileURL];
    
    if (index == -1) {    
        // 
        // 기존 셀이 없다면 셀정보를 생성해 셀에 추가한다.
        //

        PNBNoteEntry * entry = [[PNBNoteEntry alloc] init];
        entry.fileUrl = fileURL;
        entry.title = title;
        entry.state = state;
        entry.thumbnail = thumb;
        entry.fileVersion = version;
        [_objects addObject:entry];

        // 셀에 추가
        NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:(_objects.count - 1) inSection:0];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:lastIndex] 
                              withRowAnimation:UITableViewRowAnimationRight];
        
    } else {
        //
        // 기존 셀이 있다면 정보 갱신후 셀로 다시 로드한다.
        //
        
        PNBNoteEntry * entry = [_objects objectAtIndex:index];
        entry.title = title;    
        entry.state = state;
        entry.thumbnail = thumb;
        entry.fileVersion = version;
        
        NSIndexPath *foundIndex = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:foundIndex]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
    
}

# pragma mark - PNBAddNoteViewController Delegate

// 파일명을 입력하는 화면에서 입력을 완료하면 호출되는 메소드
// 주어진 파일명 |title|로 파일을 생성한다.
// 만약 실패하면 다시 추가 화면으로 가고 성공하면 Note List화면으로 
// 넘어온다.
-(void)addNoteViewController:(PNBAddNoteViewController *)viewController didFinishAdding:(NSString *)title
{

    // 이중으로 추가되는 것을 막기위해서
    viewController.navigationItem.rightBarButtonItem.enabled = NO;
    
    // 추가할 URL를 하나 만든다.
    NSURL *noteUrl = [self docURL: [self uniqueDocFileName:title]];

    // PNBNote 객체 생성
    PNBNote *note = [[PNBNote alloc] initWithFileURL:noteUrl];
    [note setTitle:title];
    
    // 일단 저장하자. 그럼 파일이 생성된다.
    // 기존에 없던 파일이니 UIDocumentSaveForCreating 옵션을 주고
    // 저장한다.
    [note saveToURL:noteUrl forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        
        if (!success) {
            viewController.textField.text = @"";
            viewController.navigationItem.rightBarButtonItem.enabled = YES;
            NSLog(@"[ERROR] cannot create file : %@", noteUrl);
            return;
        } 

        [self.navigationController popViewControllerAnimated:YES];

        // 정보 조회후 테이블에 추가
        NSLog(@"File created : %@", noteUrl);        
        NSURL * fileURL = note.fileURL;
        UIImage *thumbnail = [note thumbnail];
        UIDocumentState state = note.documentState;
        NSFileVersion * version = [NSFileVersion currentVersionOfItemAtURL:fileURL];
        
        [_addedURLs addObject:fileURL];
        [self addOrUpdateEntryWithURL:fileURL title:title thumbnail:thumbnail state:state version:version];

        // Document 닫기
        [note closeWithCompletionHandler:^(BOOL success) {
        }];
        

        
    }];     
}

#pragma mark - cloud helper functions

// 클라우드 초기화
// Documents-base Cloud를 사용하기 위해서는 클라우드 디렉토리를 
// 조회하여 초기화를 해야 한다. 이렇게 초회를 하면 클라우드를 
// 사용할 수 있는 확인 할 수 있다.

- (void)initializeiCloudAccessWithCompletion:(void (^)(BOOL available)) completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _iCloudRootURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        if (_iCloudRootURL != nil) {
            // 클라우드 사용가능
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"iCloud URL : %@", _iCloudRootURL);
                completion(TRUE);
            });            
        }            
        else {
            // 클라우드 사용 불가
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"iCloud is not available");
                completion(FALSE);
            });
        }
    });
}

// 클라우드 디렉토리에 저장할 파일의 URL를 계산해서 반환한다.
// 클라우드 디렉토리의 Documents 폴더에 저장한다.
// Documents 디렉토리는 아이폰의 Settins앱에서 파일명로
// 삭제가 가능한다.
- (NSURL *)docURL:(NSString *)filename {    
    // iCloude URL
    NSURL * docsDir = [_iCloudRootURL URLByAppendingPathComponent:@"Documents" isDirectory:YES];
    return [docsDir URLByAppendingPathComponent:filename];
}



// 해당 URL를 가지는 셀을 테이블에서 삭제 한다.
- (void)removeEntryWithURL:(NSURL *)fileURL {
    // URL를 가지고 있는 셀의 인덱스를 찾는다.
    int index = [self indexOfEntryWithFileURL:fileURL];
    
    // 테이블에 표시할 데이터 목록에서 삭제후 테이블에도 삭제
    [_objects removeObjectAtIndex:index];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
}

// 주어진 |entry|를 삭제
- (void)deleteEntry:(PNBNoteEntry *)entry {
    
    //
    // 클라우드 파일을 삭제하기 위해서는 비동기로 NSFileCoordinator를 통해서 삭제한다.
    // NSFileCoordinator 파일은 특정 경로에 다른 프로세스 혹은 다른 쓰레드에서 해당파일에 
    // 접근하지 않음을 보장한다. 
    //
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateWritingItemAtURL:entry.fileUrl 
                                            options:NSFileCoordinatorWritingForDeleting
                                              error:nil 
                                         byAccessor:^(NSURL* writingURL) {                                                   
                                             
                                             // 여기서 지운다.
                                             // 이 코드가 실행될때 파일에 접근하는 다른 프로세스 혹은 
                                             // 쓰레드는 없다. 안심하고 삭제..
                                             NSFileManager* fileManager = [[NSFileManager alloc] init];
                                             [fileManager removeItemAtURL:entry.fileUrl error:nil];
                                         }];
    });    
    
    // 테이블에서 삭제
    [_deletedURLs addObject:entry.fileUrl];
    [self removeEntryWithURL:entry.fileUrl];
    
}

// 이미 |_objects|에 있는 파일명인지 조회한다.
- (BOOL)existDocumentNameInObjects:(NSString *)filename {
    __block BOOL existed = NO;
    [_objects enumerateObjectsUsingBlock:^(PNBNoteEntry *entry, NSUInteger idx, BOOL *stop) {
        if ([[entry.fileUrl lastPathComponent] isEqualToString:filename]) {
            existed = YES;
            *stop = YES;
        }
    }];
    return existed;
}

// 유일한 파일명을 찾는다.
- (NSString*) uniqueDocFileName:(NSString *)prefix {
    
    // 다른 기기와도 이름이 겹치지 않도록
    // 파일이름에 time을 추가함
    prefix = [NSString stringWithFormat:@"%@-%d", prefix, [[NSDate date] timeIntervalSinceReferenceDate]];
    
    NSInteger count = 0;
    NSString* docname = nil;
    
    // At this point, the document list should be up-to-date.
    BOOL done = NO;
    BOOL first = YES;
    while (!done) {
        if (first) {
            first = NO;
            docname = [NSString stringWithFormat:@"%@.%@",
                       prefix, kNoteExtension];
        } else {
            docname = [NSString stringWithFormat:@"%@_%d.%@",
                       prefix, count, kNoteExtension];
        }
        
        // 이미 있는 파일인지 확인한다.
        BOOL nameExists = [self existDocumentNameInObjects:docname]; 
        if (!nameExists) {            
            break;
        } else {
            count++;         
        }
    }
    
    return docname;
}


@end
