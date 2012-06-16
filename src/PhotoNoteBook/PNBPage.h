//
//  PNBPage.h
//  PhotoNoteBook
//
//  Created by 안 진섭 on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// 페이지 정보를 보관한 클래스
@interface PNBPage : NSObject < NSCoding >

// 페이지 제목
@property (nonatomic, strong) NSString *title;

// 페이지 생성 시간
@property (nonatomic, strong) NSDate *ctime;

// Note에 그림 페이지
@property (nonatomic, strong) UIImage *photo;
// photo의 썸네임
@property (nonatomic, strong) UIImage *thumbnail;


// 이미지로 객체 초기화
- (id) initWithImage:(UIImage *)image;


@end
