//
//  MyCvVideoCamera.h
//  iSeeU
//
//  Created by Krzysztof Szczepaniak on 04/06/2013.
//  Copyright (c) 2013 Roche. All rights reserved.
//

#import <opencv2/highgui/cap_ios.h>

@interface MyCvVideoCamera : CvVideoCamera

- (void)updateOrientation;

@end
