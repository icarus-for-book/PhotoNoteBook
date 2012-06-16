//
//  PNBNote.m
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PNBNote.h"
#import "PNBNoteMetadata.h"
#import "PNBPage.h"
#import "UIImage+Resize.h"

// Private methods for PNBNote
@interface PNBNote()

// 내부 데이터를 저장할 file wrapper
@property (nonatomic, strong) NSFileWrapper *fileWrapper;
// 노트의 메타 데이터
@property (nonatomic, strong) PNBNoteMetadata *metadata;
        
@end

@implementation PNBNote

@synthesize fileWrapper = _fileWrapper;
@synthesize metadata = _metadata;

- (id) initWithFileURL:(NSURL *)url
{
    self = [super initWithFileURL:url];
    if(self)
    {
        // 초기화
        self.fileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
        NSFileWrapper *photoDir = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
        photoDir.preferredFilename = @"photo";
        [self.fileWrapper addFileWrapper:photoDir];
        self.metadata = [[PNBNoteMetadata alloc] init];
    }
    
    return self;
}

//
// Note Meta Data
//

- (NSString *) title
{
    return self.metadata.title;
}

- (void) setTitle:(NSString*) title
{
    self.metadata.title = title;
}

- (UIImage *)thumbnail
{
    return self.metadata.thumbnail;
}

//
// Page Data inside Note
//

- (NSInteger) countOfPages
{
    return [[[self fileWrapperForPhotoDir] fileWrappers] count];
}

- (void) addPageWithPhoto:(UIImage*) photo  withTitle:(NSString*) title
{
    
    // 페이지 생성
    PNBPage *page = [[PNBPage alloc] initWithImage:photo];
    page.title = title;
    page.thumbnail = [photo imageByScalingAndCroppingForSize:CGSizeMake(145, 145)];
    
    if (! self.metadata.thumbnail) {
        self.metadata.thumbnail = page.thumbnail;
    }
    
    // FileWrapper를 만들어서 Photo 폴더에 추가
    [self encodeObject:page toWrappers:[self fileWrapperForPhotoDir] preferredFilename:[self uniqueFilename]];
}

- (void) removePageAtIndex:(NSInteger)index
{

    // 페이지 제거
    NSString *key = [[[self fileWrapperForPhotoDir].fileWrappers allKeys] objectAtIndex:index];
    NSFileWrapper *targetWrapper = [[self fileWrapperForPhotoDir].fileWrappers objectForKey:key];
    
    [[self fileWrapperForPhotoDir] removeFileWrapper:targetWrapper];
}

- (UIImage*) pagePhotoAtIndex:(NSInteger)index
{
    // 페이지의 사진 정보 찾아서 반환
    NSFileWrapper *dir = [self fileWrapperForPhotoDir];
    NSArray *keys = [[dir fileWrappers] allKeys];
    PNBPage *page = [self decodeObjectFromWrapper:dir WithPreferredFilename:[keys objectAtIndex:index]];
    return page.photo;
}

- (UIImage*) pageThumbAtIndex:(NSInteger)index
{
    // 페이지의 사진 정보 찾아서 반환
    NSFileWrapper *dir = [self fileWrapperForPhotoDir];
    NSArray *keys = [[dir fileWrappers] allKeys];
    PNBPage *page = [self decodeObjectFromWrapper:dir WithPreferredFilename:[keys objectAtIndex:index]];
    return page.thumbnail;
}

- (NSString*) pageTitleAtIndex:(NSInteger)index
{
    // 페이지의 사진 정보 찾아서 반환
    NSFileWrapper *dir = [self fileWrapperForPhotoDir];
    NSArray *keys = [[dir fileWrappers] allKeys];
    PNBPage *page = [self decodeObjectFromWrapper:dir WithPreferredFilename:[keys objectAtIndex:index]];
    return page.title;
}

- (NSDate*) pageCtimeAtIndex:(NSInteger)index
{
    // 페이지의 사진 정보 찾아서 반환
    NSFileWrapper *dir = [self fileWrapperForPhotoDir];
    NSArray *keys = [[dir fileWrappers] allKeys];
    PNBPage *page = [self decodeObjectFromWrapper:dir WithPreferredFilename:[keys objectAtIndex:index]];
    return page.ctime;
}

//
// Helper Function for adding or extracting data
//

#define kEncodeDecodeKey @"data"

// 주어진 파일 이름으로 fileWrapper에서 데이터를 찾아서 
// 객체화 시키는 메소드
- (id)decodeObjectFromWrapper:(NSFileWrapper*)fileWrappers 
        WithPreferredFilename:(NSString *)preferredFilename {
    
    // get filewrapper using |preferredFilename|
    NSFileWrapper * fileWrapper = [[fileWrappers fileWrappers] 
                                       objectForKey:preferredFilename];
    if (!fileWrapper) {
        NSLog(@"[ERROR] Cannot find file (%@) in file wrapper", preferredFilename);
        return nil;
    }
    
    // Extract Data
    NSData * data = [fileWrapper regularFileContents];    
    NSKeyedUnarchiver * unarchiver = [[NSKeyedUnarchiver alloc] 
                                         initForReadingWithData:data];
    return [unarchiver decodeObjectForKey:kEncodeDecodeKey];
    
}

// 데이터를 fileWrapper에 저장.
// 데이터는 NSFileWrapper로 만들어지고 이렇게 만들어진 NSFileWrapper는 최종 파일로 만들어진다.
// 파일로 만드는 것은 UIDocument의 다른 내부 메소드가 수행.
// 여기서는 fileWrapper를 만드는 것
- (void)encodeObject:(id<NSCoding>)object 
          toWrappers:(id)wrappers 
   preferredFilename:(NSString *)preferredFilename 
{
    NSMutableData * data = [NSMutableData data];
    NSKeyedArchiver * archiver = [[NSKeyedArchiver alloc] 
                                    initForWritingWithMutableData:data];
    [archiver encodeObject:object forKey:kEncodeDecodeKey];
    [archiver finishEncoding];
    
    // wrappers가 NSDictionary 혹은 NSFileWrapper가 될 수 있다.
    // 따라서 각기 다른 방법으로 추가
    BOOL isFileWrapper = [wrappers isKindOfClass:[NSFileWrapper class]];
    BOOL isDirectory = [wrappers isKindOfClass:[NSFileWrapper class]]; 
    
    if(isFileWrapper){
        [wrappers addRegularFileWithContents:data 
                           preferredFilename:preferredFilename];
    } else if( isDirectory ){
        NSFileWrapper * wrapper = [[NSFileWrapper alloc] 
                                        initRegularFileWithContents:data];
        [wrappers setObject:wrapper forKey:preferredFilename];
    }
}

#define kMetaFileName @"meta.plist"

- (NSString *) uniqueFilename
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    
    NSString *uuidString = [NSString stringWithString:(__bridge NSString *) uuidStringRef];
    CFRelease(uuidStringRef);
    return uuidString;
}

//
// main function for reading and saving.
//


// UIDocument의 saveToURL:xxx 함수를 통해서 파일을 저장하면 
// 저장할 데이터를 만들어야 한다. 이 함수는 그 데이터를 생성한다. 
// 이 메소드에서 반환할 데이터는 NSData 혹은 NSFileWrapper여야 
// 이 프로그램에서는 ** NSFileWrapper ** 를 사용한다.
- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    // NSFileWrapper에는 기존 파일을 수정할 수 방법이 없어서 기존 것이 있으면 삭제후 다시 추가한다.
    // 다른 방법이 있으면 jinniahn@gmail.com 으로 알려주세요.
    if( [[self.fileWrapper fileWrappers] objectForKey:@"meta.plist"] )
    {
        NSFileWrapper *oldWrapper = [[self.fileWrapper fileWrappers] objectForKey:@"meta.plist"];
        [self.fileWrapper removeFileWrapper:oldWrapper ];
    }
    [self encodeObject:self.metadata toWrappers:self.fileWrapper preferredFilename:@"meta.plist"];
    
    return self.fileWrapper;
}

// UIDocument의 openWithCompletionHandler: 로 파일을 읽으면 저장된
// 파일로 부터 데이터를 읽는다. 이쪽으로 넘어오는 데이터는 NSData 혹은 
// NSFileWrapper이다. contestForType:error:에서 반환하여 저장된 
// 데이터를 읽는 것이다.
// 이 프로그램에서는 ** NSFileWrapper ** 를 사용한다.
- (BOOL)loadFromContents:(id)contents 
                  ofType:(NSString *)typeName 
                   error:(NSError *__autoreleasing *)outError
{
    
    // NSFileWrapper 클래스인지 확인한다.
    if ( ! [contents isKindOfClass:[NSFileWrapper class]] ) {
        return FALSE;
    }
    
    // 데이터를 저장한다.
    self.fileWrapper = contents;
    self.metadata = [self decodeObjectFromWrapper:self.fileWrapper 
                            WithPreferredFilename:@"meta.plist"];
    
    return YES;
    
}

// NSFileWrapper를 통해서 만들어진 폴더 구조는 다음과 같다.
// ex)
//  
// xxxx.note
//   - meta.plist    :  Note 메타 정보
//   - photo         : 사진을 저장할 폴더
//       - xxxxxxxx1 : 사진 
//       - xxxxxxxx2 : 사진
//       -   ...
//
// photo 폴더에 해당하는 fileWrapper를 반환한다.
//
- (NSFileWrapper*) fileWrapperForPhotoDir
{
    return [[self.fileWrapper fileWrappers] objectForKey:@"photo"];
}


- (void)disableEditing
{
    NSLog(@"%s", __func__);
}
- (void)enableEditing
{
    NSLog(@"%s", __func__);
    
}


@end
