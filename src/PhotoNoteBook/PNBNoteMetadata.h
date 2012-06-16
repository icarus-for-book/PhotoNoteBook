//
//  PNBNoteMetadata.h
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// Note 메타 정보 보관를 위한 클래스
@interface PNBNoteMetadata : NSObject < NSCoding >

// 제목으로 객체 초기화
- (id) initWithTitle:(NSString*) title;

// Note 제목
@property (nonatomic, strong) NSString *title;
// 노트 썸네일 이미지
@property (nonatomic, strong) UIImage *thumbnail;

#pragma mark - NSCoding 


@end
