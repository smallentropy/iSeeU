//
//  ViewController.h
//  iSeeU
//
//  Created by Krzysztof Szczepaniak on 23/05/2013.
//  Copyright (c) 2013 Roche. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>

@interface ViewController : UIViewController <CvVideoCameraDelegate, UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIImageView *faceVisibilityIndicator;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIButton *saveButton;
@property (nonatomic, weak) IBOutlet UILabel *matchLabel;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, weak) IBOutlet UIProgressView *progressBar;

- (IBAction)saveTapped:(id)sender;
- (IBAction)segmentedValueChanged:(id)sender;

@end
