//
//  CustomFaceRecognizer.h
//  iSeeU
//
//  Created by Krzysztof Szczepaniak on 03/06/2013.
//  Copyright (c) 2013 Roche. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>
#import "/usr/include/sqlite3.h"

@interface CustomFaceRecognizer : NSObject {
    sqlite3 *_db;
    cv::Ptr<cv::FaceRecognizer> _model;
}

- (id)initWithEigenFaceRecognizer;
- (id)initWithFisherFaceRecognizer;
- (id)initWithLBPHFaceRecognizer;
- (int)newPersonWithName:(NSString *)name;
- (NSMutableArray *)getAllPeople;
- (BOOL)trainModel;
- (void)forgetAllFacesForPersonID:(int)personID;
- (void)learnFace:(cv::Rect)face ofPersonID:(int)personID fromImage:(cv::Mat&)image;
- (cv::Mat)pullStandardizedFace:(cv::Rect)face fromImage:(cv::Mat&)image;
- (NSDictionary *)recognizeFace:(cv::Rect)face inImage:(cv::Mat&)image;

@end
