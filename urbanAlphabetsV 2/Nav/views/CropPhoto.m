//
//  CropPhoto.m
//  UrbanAlphabets
//
//  Created by Suse on 10/12/13.
//  Copyright (c) 2013 moi. All rights reserved.
//

#import "CropPhoto.h"
#import "BottomNavBar.h"
#import "AssignLetter.h"

@interface CropPhoto (){
    AssignLetter *assignLetter;
    
    //stepper for zooming
    C4Stepper *zoomStepper;
    
    //overlay rectangles
    C4Shape *upperRect;
    C4Shape *lowerRect;
    C4Shape *leftRect;
    C4Shape *rightRect;
    //saving image
    CGContextRef graphicsContext;
    
    UIImageView *photoTakenView;

}
@property (nonatomic) BottomNavBar *bottomNavBar;
@property(nonatomic) UIImage *photoTaken;

@end

@implementation CropPhoto

-(void)setup{
    self.title=@"Crop Photo";
    
    //back button
    CGRect frame = CGRectMake(0, 0, 60,20);
    UIButton *backButton = [[UIButton alloc] initWithFrame:frame];
    [backButton setBackgroundImage:UA_BACK_BUTTON forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [backButton setShowsTouchWhenHighlighted:YES];
    
    UIBarButtonItem *leftButton =[[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem=leftButton;
    
    //bottomNavbar WITH 1 ICONS
    CGRect bottomBarFrame = CGRectMake(0, self.canvas.height-UA_BOTTOM_BAR_HEIGHT, self.canvas.width, UA_BOTTOM_BAR_HEIGHT);
    self.bottomNavBar = [[BottomNavBar alloc] initWithFrame:bottomBarFrame centerIcon:UA_ICON_OK withFrame:CGRectMake(0, 0, 90, 45)];
    [self.canvas addShape:self.bottomNavBar];
    
   
    
    [self listenFor:@"touchesBegan" fromObject:self.bottomNavBar.centerImage andRunMethod:@"saveImage"];
    
    //--------------------------------------------------
    //ZOOM STEPPER
    //--------------------------------------------------
    zoomStepper=[C4Stepper stepper];
    zoomStepper.center=CGPointMake(zoomStepper.width/2+5, self.bottomNavBar.center.y);
    zoomStepper.backgroundColor=UA_NAV_BAR_COLOR;
    zoomStepper.tintColor=UA_TYPE_COLOR;
    [zoomStepper runMethod:@"stepperValueChanged:" target:self forEvent:VALUECHANGED];
    [self.canvas addSubview:zoomStepper];
    zoomStepper.maximumValue=10.0f;
    zoomStepper.minimumValue=0.5f;
    zoomStepper.value=1.0f;
    zoomStepper.stepValue=0.25f;
}

-(void)displayImage:(UIImage*)image{
    NSLog(@"display image, photoTaken: %@", image);
    self.photoTaken=image;
    photoTakenView=[[UIImageView alloc]initWithFrame:CGRectMake(0, UA_TOP_WHITE+UA_TOP_BAR_HEIGHT, self.canvas.width, self.canvas.height-UA_TOP_WHITE-UA_TOP_BAR_HEIGHT*2)];
    photoTakenView.image=self.photoTaken;
    [self.canvas addSubview:photoTakenView];
    //pan gesture
    UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(handlePan:)];
    
    [photoTakenView addGestureRecognizer:pgr];
    //[self.photoTaken addGesture:PAN name:@"pan" action:@"move:"];
    //initialize the overlay
    [self transparentOverlay];
    
}
-(IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    
    CGPoint translation = [recognizer translationInView:self.view];
    
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x, recognizer.view.center.y + translation.y);
    
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    
}
-(void)transparentOverlay{
    float touchY1=86.764+UA_TOP_WHITE+UA_TOP_BAR_HEIGHT;
    float touchX1=50.532;
    float touchY2=86.764+266.472+UA_TOP_WHITE+UA_TOP_BAR_HEIGHT;
    float touchX2= self.canvas.width-50.3532;
    //upper rect
    upperRect=[C4Shape rect: CGRectMake(0, UA_TOP_WHITE+UA_TOP_BAR_HEIGHT, self.canvas.width, touchY1-(UA_TOP_WHITE+UA_TOP_BAR_HEIGHT))];
    upperRect.fillColor=UA_OVERLAY_COLOR;
    upperRect.lineWidth=0;
    [self.canvas addShape:upperRect];
    
    //lower rect
    lowerRect=[C4Shape rect:CGRectMake(0, touchY2, self.canvas.width, self.canvas.height-touchY2-UA_BOTTOM_BAR_HEIGHT)];
    lowerRect.fillColor=UA_OVERLAY_COLOR;
    lowerRect.lineWidth=0;
    [self.canvas addShape:lowerRect];
    
    //left rect
    leftRect = [C4Shape rect:CGRectMake(0, touchY1, touchX1, touchY2-touchY1)];
    leftRect.fillColor=UA_OVERLAY_COLOR;
    leftRect.lineWidth=0;
    [self.canvas addShape:leftRect];
    
    //right rect
    rightRect = [C4Shape rect: CGRectMake(touchX2, touchY1, self.canvas.width-touchX2, touchY2-touchY1)];
    rightRect.fillColor=UA_OVERLAY_COLOR;
    rightRect.lineWidth=0;
    [self.canvas addShape:rightRect];
    
}
-(void)stepperValueChanged:(UIStepper*)theStepper{
    float oldHeight=self.photoTaken.size.height;
    float oldWidth=self.photoTaken.size.width;
    float oldX=photoTakenView.frame.origin.x+oldWidth/2;
    float oldY=photoTakenView.frame.origin.y+oldHeight/2;
   // self.photoTaken.height=self.canvas.height*theStepper.value;
    float newHeight=self.canvas.height*theStepper.value;
    float newWidth=self.canvas.width*theStepper.value;
    
    float newX=self.canvas.center.x-((self.canvas.center.x-oldX)*newWidth/oldWidth);
    float newY=self.canvas.center.y-((self.canvas.center.y-oldY)*newHeight/oldHeight);
    [self.canvas removeObject:photoTakenView];
    photoTakenView=[[UIImageView alloc]initWithFrame:CGRectMake(newX, newY,newWidth, newHeight)];
    [self.canvas addSubview:photoTakenView];
}

//--------------------------------------------------
//NAVIGATION
//--------------------------------------------------
-(void)goBack{
    [self.navigationController popViewControllerAnimated:YES];
}
//--------------------------------------------------
//SAVE IMAGE
//--------------------------------------------------
-(void)saveImage{
    self.bottomNavBar.centerImageView.backgroundColor=UA_HIGHLIGHT_COLOR;
    //crop image
    self.croppedPhoto=[self cropImage:self.photoTaken withOrigin:photoTakenView.frame.origin toArea:CGRectMake(51, UA_TOP_WHITE+UA_TOP_BAR_HEIGHT+86.764, self.canvas.width-2*51, 266)];
    //------------------------------------------------------------------------------------------------
    //might cause problems here!!!!
    
    //self.croppedPhoto.origin=CGPointMake(0, 0);
    //------------------------------------------------------------------------------------------------
    // save the photo to photo library and app's image directory
    [self exportHighResImage];
    
    //this goes to the next view
    /*assignLetter = [[AssignLetter alloc] initWithNibName:@"AssignLetter" bundle:[NSBundle mainBundle]];
    [assignLetter setup:self.croppedPhoto];
    
    [self.navigationController pushViewController:assignLetter animated:YES];*/
}
-(UIImage *)cropImage:(UIImage *)originalImage withOrigin:(CGPoint)origin toArea:(CGRect)rect{
    //grab the image scale
    CGFloat scale = originalImage.scale;
    
    //begin an image context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, scale);
    
    //create a new context ref
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    //shift BACKWARDS in both directions because this moves the image
    //the area to crop shifts INTO: (0, 0, rect.size.width, rect.size.height)
    CGContextTranslateCTM(c, origin.x-rect.origin.x, origin.y-rect.origin.y);
    
    //render the original image into the context
    [originalImage drawInRect:CGRectMake(0, 0, rect.size.width, rect.size.height)];
    //[originalImage renderInContext:c];
    
    //grab a UIImage from the context
    UIImage *newUIImage = UIGraphicsGetImageFromCurrentImageContext();
    
    //end the image context
    UIGraphicsEndImageContext();
    
    //create a new C4Image
    UIImage *newImage = newUIImage;
    
    //return the new image
    return newImage;
}
-(void)exportHighResImage {
    graphicsContext = [self createHighResImageContext];
    //[self.croppedPhoto renderInContext:graphicsContext];
    [self.croppedPhoto drawInRect:CGRectMake(0, 0, self.croppedPhoto.size.width, self.croppedPhoto.size.height)];
    NSString *fileName = [NSString stringWithFormat:@"letter%@.jpg", [NSDate date]];
    [self saveImage:fileName];
    //[self saveImageToLibrary];
}
-(CGContextRef)createHighResImageContext { //setting up image context
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(218, 266), YES, 5.0f);
    return UIGraphicsGetCurrentContext();
}
-(void)saveImage:(NSString *)fileName {
    UIImage  *image = UIGraphicsGetImageFromCurrentImageContext();
    NSData *imageData = UIImagePNGRepresentation(image);
    //save in a certain folder
    NSString *dataPath = [[self documentsDirectory] stringByAppendingPathComponent:@"/letters"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:nil];
    NSString *savePath = [dataPath stringByAppendingPathComponent:fileName];
    [imageData writeToFile:savePath atomically:YES];
}
-(void)saveImageToLibrary {
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
}
-(NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return paths[0];
}


@end