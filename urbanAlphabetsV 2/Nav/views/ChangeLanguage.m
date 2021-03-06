//
//  ChangeLanguage.m
//  UrbanAlphabets
//
//  Created by Suse on 12/12/13.
//  Copyright (c) 2013 moi. All rights reserved.
//

#import "ChangeLanguage.h"
#import "BottomNavBar.h"
#import "C4WorkSpace.h"
#import "AlphabetInfo.h"
#import "AlphabetView.h"

@interface ChangeLanguage (){
    C4WorkSpace *workspace;
    AlphabetInfo *alphabetInfo;
    AlphabetView *alphabetView;
    
    NSMutableArray *shapesForBackground;
    NSArray *languages; //all languages available
    NSMutableArray *languageLabels; //for all texts
    C4Image *checkedIcon;
    int elementNoChosen;
    //images loaded from documents directory
    C4Image *loadedImage;
    int letterToChange;

}
@property (nonatomic) BottomNavBar *bottomNavBar;
@property (readwrite) NSString *currentLanguage;
@property (readwrite) NSString *chosenLanguage;
@end

@implementation ChangeLanguage
-(void) setupWithLanguage: (NSString*)passedLanguage {
    self.title=@"Change Language";
    self.currentLanguage=passedLanguage;
    //back button
    CGRect frame = CGRectMake(0, 0, 60,20);
    UIButton *backButton = [[UIButton alloc] initWithFrame:frame];
    [backButton setBackgroundImage:UA_BACK_BUTTON forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [backButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *leftButton =[[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem=leftButton;
    
    languages=[NSArray arrayWithObjects:@"Danish/Norwegian", @"English", @"Finnish/Swedish", @"German", @"Russian", @"Spanish", nil];
    shapesForBackground=[[NSMutableArray alloc]init];
    languageLabels=[[NSMutableArray alloc]init];
    
    //bottomNavbar WITH 1 ICONS
    CGRect bottomBarFrame = CGRectMake(0, self.canvas.height-UA_BOTTOM_BAR_HEIGHT, self.canvas.width, UA_BOTTOM_BAR_HEIGHT);
    self.bottomNavBar = [[BottomNavBar alloc] initWithFrame:bottomBarFrame centerIcon:UA_ICON_OK withFrame:CGRectMake(0, 0, 90, 45)];
    [self.canvas addShape:self.bottomNavBar];
    [self listenFor:@"touchesBegan" fromObject:self.bottomNavBar.centerImage andRunMethod:@"changeLanguage"];
    
    //content
    int selectedLanguage=20;
    for (int i=0; i<[languages count]; i++) {
        //underlying shape
        float height=46.203;
        float yPos=UA_TOP_WHITE+UA_TOP_BAR_HEIGHT+i*height;
        C4Shape *shape=[C4Shape rect:CGRectMake(0, yPos, self.canvas.width, height)];
        shape.lineWidth=2;
        shape.strokeColor=UA_NAV_BAR_COLOR;
        shape.fillColor=UA_NAV_CTRL_COLOR;
        if ([[languages objectAtIndex:i ] isEqualToString: self.currentLanguage]) {
            shape.fillColor=UA_HIGHLIGHT_COLOR;
            selectedLanguage=i;
        }
        [shapesForBackground addObject:shape];
        [self.canvas addShape:shape];
        //text label
        C4Label *label=[C4Label labelWithText:[languages objectAtIndex:i] font:UA_NORMAL_FONT];
        label.textColor=UA_TYPE_COLOR;
        float heightLabel=46.203;
        float yPosLabel=UA_TOP_WHITE+UA_TOP_BAR_HEIGHT+i*heightLabel+label.height/2+4;
        label.origin=CGPointMake(49.485, yPosLabel);
        [self.canvas addLabel:label];
        [self listenFor:@"touchesBegan" fromObject:shape andRunMethod:@"languageChanged:"];
        [languageLabels addObject:label];
    }
    //√icon only 1x
    checkedIcon=UA_ICON_CHECKED;
    checkedIcon.width= 35;
    float height=46.202999;
    checkedIcon.center=CGPointMake(checkedIcon.width/2+5, UA_TOP_WHITE+UA_TOP_BAR_HEIGHT+(selectedLanguage+1)*height-height/2);
    [self.canvas addImage:checkedIcon];
}
-(void)languageChanged:(NSNotification *)notification{
    C4Shape *clickedObject = (C4Shape *)[notification object];
    //figure out which object was clicked
    float yPos=clickedObject.origin.y;
    yPos=yPos-UA_TOP_WHITE-UA_TOP_BAR_HEIGHT;
    float elementNumber=yPos/clickedObject.height;
    elementNoChosen=lroundf(elementNumber);
    for (int i=0; i<[shapesForBackground count]; i++) {
        C4Shape *shape=[shapesForBackground objectAtIndex:i];
        if (i==elementNoChosen) {
            shape.fillColor=UA_HIGHLIGHT_COLOR;
        } else {
            shape.fillColor=UA_NAV_CTRL_COLOR;
        }
    }
    checkedIcon.center=CGPointMake(checkedIcon.width/2+5, UA_TOP_WHITE+UA_TOP_BAR_HEIGHT+(elementNumber+1)*clickedObject.height-clickedObject.height/2);
}
//--------------------------------------------------
//NAVIGATION
//--------------------------------------------------
-(void)goBack{
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)changeLanguage{
    self.chosenLanguage=[languages objectAtIndex:elementNoChosen];
    id obj = [self.navigationController.viewControllers objectAtIndex:0];
    workspace=(C4WorkSpace*)obj;
    workspace.currentLanguage=self.chosenLanguage;
    workspace.oldLanguage=self.currentLanguage;
    [self updateLanguage];
    
    [self.navigationController popViewControllerAnimated:NO];
    obj=[self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count]-1];
    alphabetInfo=(AlphabetInfo*)obj;
    [alphabetInfo changeLanguage];
}
-(void)checkIfLetterExistsInDocumentsDirectory:(int)number{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path= [[paths objectAtIndex:0] stringByAppendingString:@"/"];
    path=[path stringByAppendingPathComponent:workspace.alphabetName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]){
        NSString *letterToAdd=@" ";
        if ([workspace.currentLanguage isEqualToString:@"Finnish/Swedish"]) {
            letterToAdd=[workspace.finnish objectAtIndex:number];
        }else if([workspace.currentLanguage isEqualToString:@"German"]){
            letterToAdd=[workspace.german objectAtIndex:number];
        }else if([workspace.currentLanguage isEqualToString:@"English"]){
            letterToAdd=[workspace.english objectAtIndex:number];
        }else if([workspace.currentLanguage isEqualToString:@"Danish/Norwegian"]){
            letterToAdd=[workspace.danish objectAtIndex:number];
        }else if([workspace.currentLanguage isEqualToString:@"Spanish"]){
            letterToAdd=[workspace.spanish objectAtIndex:number];
        }else if([workspace.currentLanguage isEqualToString:@"Russian"]){
            letterToAdd=[workspace.russian objectAtIndex:number];
        }
    NSString *filePath=[[path stringByAppendingPathComponent:letterToAdd] stringByAppendingString:@".jpg"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
        UIImage *img = [UIImage imageWithData:imageData];
        loadedImage=[C4Image imageWithUIImage:img];
    }else{
        if ([letterToAdd isEqualToString:@"?"]) {
            letterToAdd=@"-";
        }else if([letterToAdd isEqualToString:@"."]){
            letterToAdd=@"";
        }
        NSString *filepath=@"letter_";
        filepath=[filepath stringByAppendingString:letterToAdd];
        filepath=[filepath stringByAppendingString:@".png"];
        loadedImage=[C4Image imageNamed:filepath];
        
    }
    }
}
-(void)updateLanguage{
    letterToChange=0;
    //Finnish>german
    if ([workspace.currentLanguage isEqual:@"German"] && [workspace.oldLanguage isEqual:@"Finnish/Swedish"]) {
        //change Å to Ü
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //Finnish>Danish
    if ([workspace.currentLanguage isEqual:@"Danish/Norwegian"] && [workspace.oldLanguage isEqual:@"Finnish/Swedish"]) {
        //change Ä to AE
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö to danishO
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //Finnish>English
    if ([workspace.currentLanguage isEqual:@"English"] && [workspace.oldLanguage isEqual:@"Finnish/Swedish"]) {
        //change Ä to +
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö to $
        letterToChange=27;
         [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
         [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
         [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Å to ,
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //German>Finnish
    if ([workspace.currentLanguage isEqual:@"Finnish/Swedish"] && [workspace.oldLanguage isEqual:@"German"]) {
        //change Ü to Å
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //Danish/Finnish
    if ([workspace.currentLanguage isEqual:@"Finnish/Swedish"] && [workspace.oldLanguage isEqual:@"Danish/Norwegian"]) {
        //change Ä to AE
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö to danishO
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //English>Finnish
    if ([workspace.currentLanguage isEqual:@"Finnish/Swedish"] && [workspace.oldLanguage isEqual:@"English"]) {
        //change Ä to +
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö to $
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Å to ,
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //German>English
    if ([workspace.currentLanguage isEqual:@"English"] && [workspace.oldLanguage isEqual:@"German"]) {
        //change Ä to +
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö to $
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Å to ,
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //Danish>English
    if ([workspace.currentLanguage isEqual:@"English"] && [workspace.oldLanguage isEqual:@"Danish/Norwegian"]) {
        //change Ä to +
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö to $
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Å to ,
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //English>German
    if ([workspace.currentLanguage isEqual:@"German"] && [workspace.oldLanguage isEqual:@"English"]) {
        //change Ä
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Å to ,
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //English>Danish
    if ([workspace.currentLanguage isEqual:@"Danish/Norwegian"] && [workspace.oldLanguage isEqual:@"English"]) {
        //change Ä
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Å to ,
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //German>Danish
    if ([workspace.currentLanguage isEqual:@"Danish/Norwegian"] && [workspace.oldLanguage isEqual:@"German"]) {
        //change Ä
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Å to ,
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //Danish>German
    if ([workspace.currentLanguage isEqual:@"German"] && [workspace.oldLanguage isEqual:@"Danish/Norwegian"]) {
        //change Ä
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Å to Ü
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //-------------------------------
    //SPANISH
    //-------------------------------
    //English>Spanish
    if ([workspace.currentLanguage isEqual:@"Spanish"] && [workspace.oldLanguage isEqual:@"English"]) {
        //insert spanishN
        letterToChange=26;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //+ is going to position 27
        //delete $
        [workspace.currentAlphabet removeObjectAtIndex:28];
    }
    //Spanish>English
    if ([workspace.currentLanguage isEqual:@"English"] && [workspace.oldLanguage isEqual:@"Spanish"]) {
        //delete spanishN
        [workspace.currentAlphabet removeObjectAtIndex:26];
        //insert $
        letterToChange=27;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //Finnish>Spanish
    if ([workspace.currentLanguage isEqual:@"Spanish"] && [workspace.oldLanguage isEqual:@"Finnish/Swedish"]) {
        //change Ä to +
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö to $
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Å to ,
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //Spanish>Finnish
    if ([workspace.currentLanguage isEqual:@"Finnish/Swedish"] && [workspace.oldLanguage isEqual:@"Spanish"]) {
        //change Ä to +
        [workspace.currentAlphabet removeObjectAtIndex:26];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_Ä.png"] atIndex:26];
        //change Ö to $
        [workspace.currentAlphabet removeObjectAtIndex:27];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_Ö.png"] atIndex:27];
        //change Å to ,
        [workspace.currentAlphabet removeObjectAtIndex:28];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_Å.png"] atIndex:28];
    }
    //Danish>Spanish
    if ([workspace.currentLanguage isEqual:@"Spanish"] && [workspace.oldLanguage isEqual:@"Danish/Norwegian"]) {
        //change Ä to +
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö to $
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Å to ,
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //Spanish>Danish
    if ([workspace.currentLanguage isEqual:@"Danish/Norwegian"] && [workspace.oldLanguage isEqual:@"Spanish"]) {
        //change Ä
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Å to ,
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //German>Spanish
    if ([workspace.currentLanguage isEqual:@"Spanish"] && [workspace.oldLanguage isEqual:@"German"]) {
        //change Ä to +
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö to $
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Å to ,
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //Spanish>German
    if ([workspace.currentLanguage isEqual:@"German"] && [workspace.oldLanguage isEqual:@"Spanish"]) {
        //change Ä
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Ö
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change Å to ,
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //-------------------------------
    //RUSSIAN
    //-------------------------------
    //Finnish,German,English,Norwegian>Russian
    if ([workspace.currentLanguage isEqual:@"Russian"] && ([workspace.oldLanguage isEqual:@"Finnish/Swedish"]||[workspace.oldLanguage isEqual:@"German"] ||[workspace.oldLanguage isEqual:@"Danish/Norwegian"] || [workspace.oldLanguage isEqual:@"English"]|| [workspace.oldLanguage isEqual:@"Spanish"])) {
        //change RusB
        letterToChange=1;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //copy c to right position (17)
        [workspace.currentAlphabet insertObject:[workspace.currentAlphabet objectAtIndex:3] atIndex:17];
        //remove C
        [workspace.currentAlphabet removeObjectAtIndex:3];
        //change RusG
        letterToChange=3;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];

        //change RusD
        letterToChange=4;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change RusJo
        letterToChange=6;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change RusSche
        letterToChange=7;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change RusSe
        letterToChange=8;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change RusI
        letterToChange=9;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change RusIkratkoje
        letterToChange=10;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change RusL
        letterToChange=12;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change RusN
        letterToChange=14;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //insert rus p
        letterToChange=16;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //shift T into right position
        [workspace.currentAlphabet removeObjectAtIndex:19];
        [workspace.currentAlphabet removeObjectAtIndex:20];
        [workspace.currentAlphabet removeObjectAtIndex:21];
        [workspace.currentAlphabet removeObjectAtIndex:19];
        //copy X /RusCha into right position
        letterToChange=22;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:25];
        //shirt Y /RusU into right position
        [workspace.currentAlphabet removeObjectAtIndex:20];
        [workspace.currentAlphabet removeObjectAtIndex:20];
        [workspace.currentAlphabet removeObjectAtIndex:20];
        //change RusF
        letterToChange=21;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change RusZ
        letterToChange=23;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change RusTsche
        letterToChange=24;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change RusScha
        letterToChange=25;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change RusTscheScha
        letterToChange=26;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change RusMjachkiSnak
        letterToChange=27;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //change RusUi
        letterToChange=28;
        [workspace.currentAlphabet removeObjectAtIndex:letterToChange];
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //add RusE
        letterToChange=29;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //add RusJu
        letterToChange=30;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        //add RusJa
        letterToChange=31;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //Russian>Finnish,German,English,Norwegian
    if ( ([workspace.currentLanguage isEqual:@"Finnish/Swedish"]||[workspace.currentLanguage isEqual:@"German"] ||[workspace.currentLanguage isEqual:@"Danish/Norwegian"] || [workspace.currentLanguage isEqual:@"English"]|| [workspace.currentLanguage isEqual:@"Spanish"]) && [workspace.oldLanguage isEqual:@"Russian"]) {
        [workspace.currentAlphabet removeObjectAtIndex:31]; //RusJa
        [workspace.currentAlphabet removeObjectAtIndex:30];
        [workspace.currentAlphabet removeObjectAtIndex:29];
        [workspace.currentAlphabet removeObjectAtIndex:28];
        [workspace.currentAlphabet removeObjectAtIndex:27];
        [workspace.currentAlphabet removeObjectAtIndex:26];
        [workspace.currentAlphabet removeObjectAtIndex:25];
        [workspace.currentAlphabet removeObjectAtIndex:24];
        [workspace.currentAlphabet removeObjectAtIndex:23];
        
        [workspace.currentAlphabet removeObjectAtIndex:21];
        
        
        [workspace.currentAlphabet removeObjectAtIndex:16];
        
        [workspace.currentAlphabet removeObjectAtIndex:12];

        [workspace.currentAlphabet removeObjectAtIndex:10];
        [workspace.currentAlphabet removeObjectAtIndex:9];
        [workspace.currentAlphabet removeObjectAtIndex:8];
        [workspace.currentAlphabet removeObjectAtIndex:7];
        [workspace.currentAlphabet removeObjectAtIndex:6];
        
        [workspace.currentAlphabet removeObjectAtIndex:4];
        [workspace.currentAlphabet removeObjectAtIndex:3];
        [workspace.currentAlphabet removeObjectAtIndex:1];
        //copy RusS to C
        C4Image *image=[workspace.currentAlphabet objectAtIndex:8];
        [workspace.currentAlphabet insertObject:image atIndex:2];
        [workspace.currentAlphabet removeObjectAtIndex:9];
        //copy RusN to H
        image=[workspace.currentAlphabet objectAtIndex:6];
        [workspace.currentAlphabet insertObject:image atIndex:4];
        [workspace.currentAlphabet removeObjectAtIndex:7];
        //change order of y and x
        image=[workspace.currentAlphabet objectAtIndex:11];
        [workspace.currentAlphabet insertObject:image atIndex:10];
        [workspace.currentAlphabet removeObjectAtIndex:12];
        
       //insert objects needed
        letterToChange=3;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=5;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=6;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=8;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=9;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=11;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=13;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=16;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=17;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=18;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=20;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=21;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=22;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=25;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        
        //now special letters for all languages
        letterToChange=26;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=27;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=28;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
         letterToChange=29;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=30;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
        
        letterToChange=31;
        [self checkIfLetterExistsInDocumentsDirectory:letterToChange];
        [workspace.currentAlphabet insertObject:loadedImage atIndex:letterToChange];
    }
    //REDRAW THE ALPHABET WHEN READY
    id obj = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count]-3];
    alphabetView=(AlphabetView*)obj;
    [alphabetView redrawAlphabet];
}


@end
