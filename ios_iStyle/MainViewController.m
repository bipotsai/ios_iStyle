//
//  MainViewController.m
//  ios_iStyle
//
//  Created by Saker Lin on 2015/7/14.
//  Copyright (c) 2015年 Saker Lin. All rights reserved.
//

#import "MainViewController.h"
#import "CollageElementView.h"
#import "UIImage+CollagePreview.h"
#import "UIView+RelativeFrame.h"
#import <UIImageView+AFNetworking.h>
#import "UIView+ImageRender.h"
#import <QuartzCore/CALayer.h>
#import "SVProgressHUD.h"
#import "RootViewController.h"
#import "SearchViewController.h"
#import "SearchRecord.h"
@interface MainViewController ()<UIGestureRecognizerDelegate, SearchViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *centerView;
@property (weak, nonatomic) IBOutlet UIView *collageView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (nonatomic, strong) NSArray *collages;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property (nonatomic, strong) NSMutableArray *records;
@property (nonatomic, strong) NSString *lastsanp;
@property (nonatomic, weak) CollageElementView *currentCollageElementView;
@end

@implementation MainViewController
-(void)viewWillAppear:(BOOL)animated{
     self.collageView.center = CGPointMake(self.centerView.frame.size.width / 2., self.centerView.frame.size.height / 2.);
}
- (void)viewDidLoad {
    [super viewDidLoad];
     // Do any additional setup after loading the view from its nib.
     _collages = [Collage collages];
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Share"
                                                                    style:UIBarButtonItemStyleDone
                                                                    target:nil
                                                                   action:@selector(saveCollage)];
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Fav"
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:nil
                                                                  action:@selector(showFav)];
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@"iStyle"];
    
    item.rightBarButtonItem = rightButton;
    item.leftBarButtonItem = leftButton;
    item.hidesBackButton = YES;
    [self.navBar pushNavigationItem:item animated:NO];
    
    for (unsigned long i = 0; i < self.collages.count;  i++) {
        CGRect bottomViewBound = [self.bottomView bounds];
        CGSize bottomSize = bottomViewBound.size;
        CGFloat bWidth = bottomSize.width;
        CGFloat bHeight = bottomSize.height;
        NSLog(@"width=%f,height=%f",bWidth,bHeight);
        CGFloat gap = (bWidth - 80*self.collages.count )/5.0;
        NSLog(@"gap=%f",gap);
        CGFloat x = (i*(80+gap)) + gap;

        UIImageView  *result = [[UIImageView alloc] initWithFrame:CGRectMake(x,
                                                                             10.0,
                                                                             80.0,
                                                                             80.0)];
        
        result.image = [UIImage renderPreviewImageWithCollage:self.collages[i] ofSize:result.frame.size];
        result.tag = i;
        [result setUserInteractionEnabled:YES];
        
        UITapGestureRecognizer *singleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onExampleCollageTap:)];
        [singleTap setNumberOfTapsRequired:1];
        [result addGestureRecognizer:singleTap];
        
        [self.bottomView addSubview:result];
    }
    UIColor *blueColor = [UIColor  colorWithRed:85.0f/255.0f green:172.0f/255.0f blue:238.0f/255.0f alpha:1.0f];
    UIColor *centerColor = [UIColor colorWithRed:131.0f/255.0f green:168.0f/255.0f blue:222.0f/255.0f alpha:1.0];
    self.centerView.backgroundColor = centerColor;

    self.collageView.backgroundColor = blueColor;
    self.collageView.layer.cornerRadius = 5.;
    [self.collageView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    self.records = [NSMutableArray array];
    __weak __typeof(self) this = self;
    self.collage = self.collages[0];
    [self.collage enumerateRelativeFramesUsingBlock:^(CGRect relativeFrame, NSUInteger index) {
        [this createCollageElementViewWithRelativeFrame:relativeFrame index:(NSUInteger *)index ];
    }];
    //NSString * timestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970] * 1000];
   
}
- (NSString *)getTime{
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYY-MM-d_HHmmss"];
    NSString *correctDate = [formatter stringFromDate:date];
    NSLog(@"%@",correctDate);
    return correctDate;
}
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    const CGFloat kCollageViewPaddings = 5.;
    
    CGRect frame = self.collageView.frame;
    
    BOOL needUseWidth = YES;
    
    if (self.collage.ratio >= 1.) {
        if (self.view.frame.size.width < self.view.frame.size.height &&
            self.view.frame.size.height >= self.view.frame.size.width / self.collage.ratio) {
            needUseWidth = YES;
        } else {
            needUseWidth = NO;
        }
    } else {
        if (self.view.frame.size.height < self.view.frame.size.width &&
            self.view.frame.size.width >= self.view.frame.size.height / self.collage.ratio) {
            needUseWidth = YES;
        } else {
            needUseWidth = NO;
        }
    }
    
    
    if (needUseWidth) {
        frame.size.width = self.view.frame.size.width - kCollageViewPaddings * 2.;
        frame.size.height = frame.size.width / self.collage.ratio;
    } else {
        frame.size.height = self.view.frame.size.height - kCollageViewPaddings * 2.;
        frame.size.width = frame.size.height * self.collage.ratio;
    }
    
    self.collageView.frame = frame;
    
    //self.collageView.center = CGPointMake(self.view.frame.size.width / 2., self.view.frame.size.height / 2.);
    self.collageView.center = CGPointMake(self.centerView.frame.size.width / 2., self.centerView.frame.size.height / 2.);
         [self.collageView.subviews makeObjectsPerformSelector:@selector(refreshFrame)];
}

- (void)onExampleCollageTap:(UITapGestureRecognizer *)sender {
    
    [self.records removeAllObjects];
    [self.collageView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    __weak __typeof(self) this = self;
    self.collage = self.collages[sender.view.tag];
        [self.collage enumerateRelativeFramesUsingBlock:^(CGRect relativeFrame, NSUInteger index) {
            [this createCollageElementViewWithRelativeFrame:relativeFrame index:(NSUInteger *)index ];
    }];
    
}

- (void)createCollageElementViewWithRelativeFrame:(CGRect)relativeFrame index:(NSUInteger *)index{
    
    [self.records insertObject:[NSString stringWithFormat:@"%lu",(long)index]  atIndex:(long)index];
    CollageElementView *result = [CollageElementView new];
    result.tag = (int)index;
    result.relativeFrame = relativeFrame;
    [result addTarget:self action:@selector(onCollageElementTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.collageView addSubview:result];
    [self.collageView.subviews makeObjectsPerformSelector:@selector(refreshFrame)];
    
}

- (void)onCollageElementTap:(id)sender {
    self.currentCollageElementView = sender;
    SearchViewController *Svc = [[SearchViewController alloc] init];
    Svc.delegate = self;
    [self presentViewController:Svc animated:YES completion:nil];
}
-(void)getSelectedRecord:(SearchRecord *)record{
   
    [self.records replaceObjectAtIndex:self.currentCollageElementView.tag withObject:record];
   
    UIImage *Image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString: record.imageUrl]]];
    self.currentCollageElementView.image = Image;
}
- (void)showFav{
    
    RootViewController *Rvc = [[RootViewController alloc] init];
   
    [self presentViewController:Rvc animated:YES completion:nil];
}
- (void)saveCollage{
    NSArray *images = [[self.collageView.subviews valueForKey:@"image"] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isKindOfClass:[UIImage class]];
    }]];
    NSLog(@"count=%lu", [self.collage.relativeFrames count]);
    if( [self.collage.relativeFrames count] == [images count]){
        UIImage *snap = [self.collageView renderImage];
        NSData *imgData = UIImagePNGRepresentation(snap);
        NSString *time = [self getTime];
        NSString *newImageName=[self getImagePath:[NSString stringWithFormat:@"/screenshot/%@.png",time]];
        NSLog(@"%@", newImageName);
        if(imgData){
            self.lastsanp = newImageName;
            [imgData writeToFile:newImageName atomically:YES];
            NSLog(@"write success");
            [self shareContent];
        }else{
            NSLog(@"error while taking screenshot");
        }
    } else {
       [SVProgressHUD showErrorWithStatus: @"Please fill all images!"];
    }
 
}
- (NSString*)getImagePath:(NSString *)name {
    
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,  NSUserDomainMask, YES);
    
    NSString *docPath = [path objectAtIndex:0];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *finalPath = [docPath stringByAppendingPathComponent:name];
    
    // Remove the filename and create the remaining path
    [fileManager createDirectoryAtPath:[finalPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSLog(@"path=%@",finalPath);
    
    return finalPath;
    
}


-(void)shareContent{
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    for (SearchRecord *record in self.records) {
       [messages addObject:[NSString stringWithFormat:@"%@ %@", record.title, record.productUrl]];
        NSLog(@"%@",record.title);
         NSLog(@"%@",record.productUrl);
        
    }
    /*
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    for (SearchRecord *record in self.records) {
        [messages addObject:[NSString stringWithFormat:@"%@ %@", record.title, record.productUrl]];
    }
    
    UIImage * image = [UIImage imageNamed:@"screenShot"];
    NSArray * shareItems = @[message , image];
    */
   // UIActivityViewController * avc = [[UIActivityViewController alloc] init];
    NSString *message = [messages componentsJoinedByString:@"\n\r"];
    UIImage *happyImage = [UIImage imageWithContentsOfFile:self.lastsanp];
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:message, happyImage, nil] applicationActivities:nil];
    
   // [self presentViewController:avc animated:YES completion:nil];
   
    [self presentViewController:avc animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
