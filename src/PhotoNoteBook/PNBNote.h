//
//  PNBNote.h
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kNoteExtension @"note"

@interface PNBNote : UIDocument

// 노트의 타이틀 조회
- (NSString *) title;
// 타이틀 변경
- (void) setTitle:(NSString*) title;
// 노트 썸네일 이미지 조회
- (UIImage *)thumbnail;


// 노트에 포함된 페이지 수 조회
- (NSInteger) countOfPages;
// 주어진 사진과 타이틀로 페이지 생성
- (void) addPageWithPhoto:(UIImage*) photo withTitle:(NSString*) title;
// 페이지 삭제
- (void) removePageAtIndex:(NSInteger)index;
// 주어진 인덱스의 페이지 사진 조회
- (UIImage*) pagePhotoAtIndex:(NSInteger)index;
// 주어진 인덱스의 페이지 썸네일 조회
- (UIImage*) pageThumbAtIndex:(NSInteger)index;
// 주어진 인덱스의 페이지 타이틀 조회
- (NSString*) pageTitleAtIndex:(NSInteger)index;
// 주어진 인덱스의 페이지 생성 시간 조회
- (NSDate*) pageCtimeAtIndex:(NSInteger)index;

@end
