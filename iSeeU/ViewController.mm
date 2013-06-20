//
//  ViewController.m
//  iSeeU
//
//  Created by Krzysztof Szczepaniak on 23/05/2013.
//  Copyright (c) 2013 Roche. All rights reserved.
//

#import "ViewController.h"
#import "FaceDetector.h"
#import "CustomFaceRecognizer.h"
#import "OpenCVData.h"
#import <QuartzCore/QuartzCore.h>
#import "NSString+Addons.h"
#import "MyCvVideoCamera.h"
#import "NSString+Addons.h"

#define CAPTURE_FPS 30
#define LEARN_FPS 30
#define RADIANS(degrees) ((degrees * M_PI) / 180.0)

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) NSMutableArray *photoArray;
@property (nonatomic, strong) UIImage *faceImage;

@property (nonatomic, strong) UIImageView *leftUpper;
@property (nonatomic, strong) UIImageView *rightUpper;

//@property (nonatomic, strong) CALayer *featureLayer;

@property (nonatomic, strong) FaceDetector *faceDetector;
@property (nonatomic, strong) CustomFaceRecognizer *faceRecognizer;
@property (nonatomic, strong) MyCvVideoCamera* videoCamera;
@property (nonatomic, assign) BOOL modelAvailable;
@property (nonatomic, assign) BOOL learn;
@property (nonatomic, assign) BOOL recognize;
@property (nonatomic) NSInteger frameNum;
@property (nonatomic, assign) CGRect faceVisibilityRect;
@property (nonatomic, assign) BOOL indicatorVisible;
@property (nonatomic, strong) CALayer *featureLayer;

@property (nonatomic, assign) NSInteger picsTaken;
@property (nonatomic, assign) NSInteger personId;

@end

@implementation ViewController

#pragma mark - Image Processing

- (void)setFaceVisible:(BOOL)visible {
    if (visible != self.indicatorVisible) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //self.featureLayer.hidden = !visible;
            self.indicatorVisible = visible;
            CGRect rect = self.faceVisibilityIndicator.frame;
            rect.origin.y += visible ? rect.size.height : -rect.size.height;
            [UIView animateWithDuration:0.3 animations:^{
                self.faceVisibilityIndicator.frame = rect;
                self.faceVisibilityIndicator.alpha = visible ? 1.0 : 0.0f;
            }];
        });
    }
}

- (void)setMatchLabelText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.matchLabel.text = text;
    });
}

- (void)parseFaces:(const std::vector<cv::Rect> &)faces forImage:(cv::Mat&)image {
    // No faces found
    if (faces.size() != 1) {
        [self setFaceVisible:NO];
        [self setMatchLabelText:@""];
        return;
    }
    
    // We only care about the first face
    cv::Rect face = faces[0];
       
    // Unless the database is empty, try a match
    if (self.modelAvailable && self.recognize) {
        NSDictionary *match = [self.faceRecognizer recognizeFace:face inImage:image];
        
        // Match found
        if ([match objectForKey:@"personID"] != [NSNumber numberWithInt:-1]) {
            NSString *message = [match objectForKey:@"personName"];
            //highlightColor = [[UIColor greenColor] CGColor];
            
            NSNumberFormatter *confidenceFormatter = [[NSNumberFormatter alloc] init];
            [confidenceFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
            confidenceFormatter.maximumFractionDigits = 2;
            
            [self setMatchLabelText:[NSString stringWithFormat:@"You are %@ and i'm %@ confident about that :)", message,
                                     [confidenceFormatter stringFromNumber:[match objectForKey:@"confidence"]]]];
        } else {
            [self setMatchLabelText:@"Sorry, i don't know who you are :("];
        }
    } else {
        [self setMatchLabelText:@"Sorry, i don't know who you are :("];
    }
    
    // All changes to the UI have to happen on the main thread
    dispatch_sync(dispatch_get_main_queue(), ^{        
        [self setFaceVisible:YES];
    });
}

- (void)highlightFace:(CGRect)faceRect withColor:(CGColor *)color {
    if (self.featureLayer == nil) {
        self.featureLayer = [[CALayer alloc] init];
        self.featureLayer.borderWidth = 2.0;
    }
    
    [self.imageView.layer addSublayer:self.featureLayer];
    
    self.featureLayer.hidden = NO;
    self.featureLayer.borderColor = color;
    self.featureLayer.frame = faceRect;
}

- (void)processImage:(cv::Mat&)image {
    // Only process every CAPTURE_FPS'th frame (every 1s)
    if (self.frameNum % CAPTURE_FPS == 0) {
        [self parseFaces:[self.faceDetector facesFromImage:image] forImage:image];
    }
    
    if (self.indicatorVisible && self.learn && self.frameNum % LEARN_FPS == 0) {
        const std::vector<cv::Rect> &faces = [self.faceDetector facesFromImage:image];
        
        if (faces.size() == 1 && ![self.textField.text isEmpty]) {
            [self.faceRecognizer learnFace:faces[0] ofPersonID:self.personId fromImage:image];
            self.picsTaken++;
            self.frameNum = 0;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressBar.progress = self.picsTaken / 30.0f;
            });
            
            if (self.picsTaken == 30) {
                self.learn = NO;
                self.picsTaken = 0;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.modelAvailable = [self.faceRecognizer trainModel];
                    [self showProgressView:NO];
                    self.segmentedControl.selectedSegmentIndex = 0;
                    [self.segmentedControl sendActionsForControlEvents:UIControlEventValueChanged];
                    [self recognize:YES];
                });
            }
        }
    }
    
    self.frameNum++;
}

- (void)setupCamera {
    self.videoCamera = [[MyCvVideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = CAPTURE_FPS;
    self.videoCamera.grayscaleMode = NO;
}

#pragma mark - ViewController Lifecycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _photoArray = [[NSMutableArray alloc] init];
        _faceImage = [UIImage imageNamed:@"face"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupCamera];
    
    self.faceDetector = [[FaceDetector alloc] init];
    self.faceRecognizer = [[CustomFaceRecognizer alloc] initWithEigenFaceRecognizer];
    self.modelAvailable = [self.faceRecognizer trainModel];
    self.faceVisibilityRect = self.faceVisibilityIndicator.frame;
    self.recognize = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [self becomeFirstResponder];
    [self.videoCamera start];
    //[self setFaceVisible:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.videoCamera stop];
}

#pragma mark - UI Setup
- (void)setupUI {
    UIImage *hand = [UIImage imageNamed:@"hand-pointing"];
    self.leftUpper = [[UIImageView alloc] initWithImage:hand];
    self.rightUpper = [[UIImageView alloc] initWithImage:hand];
    
    CGRect rect = self.imageView.frame;
    
    self.leftUpper.frame = CGRectMake(rect.origin.x - 65, rect.origin.y + 100, 100, 51);
    self.rightUpper.frame = CGRectMake(rect.origin.x + rect.size.width - 36, rect.origin.y + 100, 100, 51);

    self.rightUpper.transform = CGAffineTransformMakeScale(-1, 1);
    
    [self.view addSubview:self.leftUpper];
    [self.view addSubview:self.rightUpper];
    
    UIEdgeInsets insets = UIEdgeInsetsMake(18, 18, 18, 18);    
    UIImage *normalImage = [UIImage imageNamed:@"blueButton"];
    [self.saveButton setBackgroundImage:[normalImage resizableImageWithCapInsets:insets] forState:UIControlStateNormal];
    UIImage *highlightedImage = [UIImage imageNamed:@"blueButtonHighlight"];
    [self.saveButton setBackgroundImage:[highlightedImage resizableImageWithCapInsets:insets] forState:UIControlStateNormal];
    
    rect = self.textField.frame;
    rect.size = CGSizeMake(rect.size.width, 44.0f);
    self.textField.frame = rect;
    
    self.saveButton.alpha = 0.0f;
    self.textField.alpha = 0.0f;
    self.faceVisibilityIndicator.alpha = 0.0f;
    self.progressBar.alpha = 0.0f;
    self.indicatorVisible = NO;
    
    self.imageView.image = self.faceImage;
    
//    self.learningSwitch = [[RCSwitch alloc] initWithFrame:CGRectMake(self.imageView.frame.size.width + self.imageView.frame.size.width / 2, self.imageView.frame.origin.y - 32, 64, 54)];
//    [self.view addSubview:self.learningSwitch];
}

- (void)showInputField:(BOOL)show {
    [UIView animateWithDuration:0.3f animations:^{
        CGFloat alpha = show ? 1.0f : 0.0f;
        self.textField.alpha = alpha;
        self.saveButton.alpha = alpha;
        self.matchLabel.alpha = show ? 0.0 : 1.0f;
    }];
}

- (void)showProgressView:(BOOL)show {    
    [UIView animateWithDuration:0.3 animations:^{
        self.progressBar.alpha = show ? 1.0f : 0.0f;
    } completion:^(BOOL finished) {
        self.progressBar.progress = 0.0;
    }];
}

#pragma mark - IBActions
- (void)saveTapped:(id)sender {
    if (![self.textField.text isEmpty]) {
        self.personId = [self.faceRecognizer newPersonWithName:self.textField.text];
        [self showProgressView:YES];
        [self.videoCamera start];
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [self saveTapped:textField];
    return YES;
}

- (void)recognize:(BOOL)recognize {
    self.textField.text = @"";
    [self.textField resignFirstResponder];
    if (recognize) {
        [self.videoCamera start];
        self.learn = NO;
        self.recognize = YES;
        [self showInputField:NO];
    } else {
        [self.videoCamera stop];
        self.learn = YES;
        self.recognize = NO;
        [self showInputField:YES];
        [self setFaceVisible:NO];
    }
}

- (void)segmentedValueChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) { //recognize
        [self recognize:YES];
    } else { //learn
        [self recognize:NO];
    }
}

@end
