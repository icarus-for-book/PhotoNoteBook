//
//  PNBNodeEntry.h
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PNBNoteEntry : NSObject

// 표시할 파일 URL
@property (nonatomic, strong) NSURL *fileUrl;
// 타이틀
@property (nonatomic, strong) NSString *title;
// 썸네일
@property (nonatomic, strong) UIImage *thumbnail;
// 도큐먼트 상태
@property (nonatomic, assign) UIDocumentState state;
// 파일 버전
@property (nonatomic, strong) NSFileVersion *fileVersion;

@end
