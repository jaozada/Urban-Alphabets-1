//
//  AddAlphabet.m
//  UrbanAlphabets
//
//  Created by Suse on 09/01/14.
//  Copyright (c) 2014 moi. All rights reserved.
//

#import "AddAlphabet.h"
#import "C4WorkSpace.h"
#import "BottomNavBar.h"
#import "AlphabetView.h"

@interface AddAlphabet (){
    C4WorkSpace *workspace;
    AlphabetView *alphabetView;
    int notificationCounter; //to make sure the ok button is only added 1x
    
    //the new alphabet name
    UITextView *textInput;
    NSString *name;
    
    //for the languages
    NSMutableArray *shapesForBackground;
    NSMutableArray *languageLabels; //for all texts
    C4Image *checkedIcon;
    int elementNoChosen;
    float firstShapeY;
    //magic for dismissing the keyboard
    UITapGestureRecognizer * tapGesture;
    C4Shape *navigation;
}
@property (nonatomic) BottomNavBar *bottomNavBar;
@end

@implementation AddAlphabet

-(void) setup{
    self.title=@"Add New Alphabet";
    name=@" "; //default new alphabet name
    notificationCounter=0;
    
    //back button
    CGRect frame = CGRectMake(0, 0, 60,20);
    UIButton *backButton = [[UIButton alloc] initWithFrame:frame];
    [backButton setBackgroundImage:UA_BACK_BUTTON forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [backButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *leftButton =[[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.leftBarButtonItem=leftButton;
    
    //bottom bar
    CGRect bottomBarFrame = CGRectMake(0, self.canvas.height-UA_BOTTOM_BAR_HEIGHT, self.canvas.width, UA_BOTTOM_BAR_HEIGHT);
    self.bottomNavBar = [[BottomNavBar alloc] initWithFrame:bottomBarFrame centerIcon:UA_ICON_OK withFrame:CGRectMake(0, 0, 90, 45) ];
    [self.canvas addShape:self.bottomNavBar];
    self.bottomNavBar.centerImageView.hidden=YES;
    
    shapesForBackground = [[NSMutableArray alloc] init];
}
-(void)grabCurrentLanguageViaNavigationController {
    id obj = [self.navigationController.viewControllers objectAtIndex:0];
    workspace=(C4WorkSpace*)obj;

    //name label
    C4Label *nameLabel=[C4Label labelWithText:@"Name:" font:UA_NORMAL_FONT];
    nameLabel.origin=CGPointMake(20, 100);
    [self.canvas addLabel:nameLabel];

    //text field
    CGRect textViewFrame = CGRectMake(nameLabel.center.x+nameLabel.width, nameLabel.origin.y, self.canvas.width-40-(nameLabel.center.x+nameLabel.width), nameLabel.height+5);
    textInput = [[UITextView alloc] initWithFrame:textViewFrame];
    textInput.returnKeyType = UIReturnKeyDone;
    textInput.layer.borderWidth=1.0f;
    textInput.layer.borderColor=[UA_OVERLAY_COLOR CGColor];
    [textInput becomeFirstResponder];
    textInput.delegate = self;
    [self.view addSubview:textInput];
    //magic for dismissing the keyboard
    tapGesture = [[UITapGestureRecognizer alloc]
                  initWithTarget:self
                  action:@selector(hideKeyBoard)];
    [self.view addGestureRecognizer:tapGesture];

    //language label
    C4Label *languageLabel=[C4Label labelWithText:@"Language:" font:UA_NORMAL_FONT];
    languageLabel.origin=CGPointMake(20, nameLabel.origin.y+40);
    [self.canvas addLabel:languageLabel];
    
    //available languages
    firstShapeY=languageLabel.origin.y+languageLabel.height+10;
    for (int i=0; i<[workspace.languages count]; i++) {
        //underlying shape
        float height=46.203;
        float yPos=i*height+firstShapeY;
        C4Shape *shape=[C4Shape rect:CGRectMake(0, yPos, self.canvas.width, height)];
        shape.lineWidth=2;
        shape.strokeColor=UA_NAV_BAR_COLOR;
        shape.fillColor=UA_NAV_CTRL_COLOR;
        
        [shapesForBackground addObject:shape];
        [self.canvas addShape:shape];
        
        //text label
        C4Label *label=[C4Label labelWithText:[workspace.languages objectAtIndex:i] font:UA_NORMAL_FONT];
        label.textColor=UA_TYPE_COLOR;
        float heightLabel=46.203;
        float yPosLabel=i*heightLabel+label.height/2+4+languageLabel.origin.y+languageLabel.height+10;
        label.origin=CGPointMake(49.485, yPosLabel);
        [self.canvas addLabel:label];
        [self listenFor:@"touchesBegan" fromObject:shape andRunMethod:@"languageChanged:"];
        [languageLabels addObject:label];
    }

}
-(void)languageChanged:(NSNotification *)notification{
    C4Shape *clickedObject = (C4Shape *)[notification object];
    //figure out which object was clicked
    float yPos=clickedObject.origin.y;
    /*C4Shape *firstShape=[shapesForBackground objectAtIndex:0];
    C4Log(@"firstShape: %@", firstShape);
    C4Log(@"firstShape center: %@", firstShape.frame);*/
    float firstYPos=firstShapeY;
    //C4Log(@"start of language fields: %@", firstYPos);
    yPos=yPos-firstYPos;
    //C4Log(@"calculated YPos         : %@", yPos);
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
    if (elementNoChosen<[workspace.languages count] && ![name isEqual:@" "] && notificationCounter<2) {
        self.bottomNavBar.centerImageView.hidden=NO;
        C4Shape *shape=[C4Shape rect:CGRectMake(self.bottomNavBar.centerImageView.frame.origin.x-20, self.bottomNavBar.frame.origin.y-10, self.bottomNavBar.centerImage.size.width+40, self.bottomNavBar.centerImage.size.height+20)];
        shape.lineWidth=2;
        shape.strokeColor=UA_NAV_CTRL_COLOR;
        shape.fillColor=UA_NAV_CTRL_COLOR;
        [self.canvas addShape:shape];
        [self listenFor:@"touchesBegan" fromObject:shape andRunMethod:@"addAlphabet"];
        notificationCounter++;
    }
}
-(void)addAlphabet{
    self.bottomNavBar.centerImageView.backgroundColor=UA_HIGHLIGHT_COLOR;
    
    //add new alphabet to my alphabets
    [workspace.myAlphabets addObject:name];
    //add a new language to languages array (so u can reload correctly later)
    [workspace.myAlphabetsLanguages addObject: [workspace.languages objectAtIndex:elementNoChosen]];
    //C4Log(@"my alphabets: %@", workspace.myAlphabets);
    //set alphabet name to new one
    workspace.alphabetName=name;
    //set current alphabet to new alphabet
    [workspace loadDefaultAlphabet];
    //set current language to language chosen
    workspace.currentLanguage=[workspace.languages objectAtIndex:elementNoChosen];
    //C4Log(@"current Language: %@", workspace.currentLanguage);
    //set old language to Finnish/swedish > the default one
    workspace.oldLanguage=@"Finnish/Swedish";
    //C4Log(@"old language: %@", workspace.oldLanguage);
    //set it to the right language
    [self updateLanguage];

    //go to alphabets view
    //C4Log(@"number of view Controllers: %d",[self.navigationController.viewControllers count]);
    id obj = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count]-3];
    //C4Log(@"obj:%@", obj);
    alphabetView=(AlphabetView*)obj;
    [alphabetView redrawAlphabet];
    [self.navigationController popToViewController:alphabetView animated:NO];
    
    //delete oldest alphabet if more than a certain number are added (so we don't need a scroll view here)
    if ([workspace.myAlphabets count]>8) {
        [workspace.myAlphabets removeObjectAtIndex:0];
        [workspace.myAlphabetsLanguages removeObjectAtIndex:0];
    }
}
-(void)updateLanguage{
    //this is a copy of update language from change language view
    //Finnish>german
    if ([workspace.currentLanguage isEqual:@"German"] && [workspace.oldLanguage isEqual:@"Finnish/Swedish"]) {
        //change Å to Ü
        [workspace.currentAlphabet removeObjectAtIndex:28];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_Ü.png"] atIndex:28];
    }
    //Finnish>Danish
    if ([workspace.currentLanguage isEqual:@"Danish/Norwegian"] && [workspace.oldLanguage isEqual:@"Finnish/Swedish"]) {
        //change Ä to AE
        [workspace.currentAlphabet removeObjectAtIndex:26];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_ae.png"] atIndex:26];
        //change Ö to danishO
        [workspace.currentAlphabet removeObjectAtIndex:27];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_danisho.png"] atIndex:27];
    }
    //Finnish>English
    if ([workspace.currentLanguage isEqual:@"English"] && [workspace.oldLanguage isEqual:@"Finnish/Swedish"]) {
        //change Ä to +
        [workspace.currentAlphabet removeObjectAtIndex:26];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_+.png"] atIndex:26];
        //change Ö to $
        [workspace.currentAlphabet removeObjectAtIndex:27];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_$.png"] atIndex:27];
        //change Å to ,
        [workspace.currentAlphabet removeObjectAtIndex:28];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_,.png"] atIndex:28];
    }
    //-------------------------------
    //SPANISH
    //Finnish>Spanish
    if ([workspace.currentLanguage isEqual:@"Spanish"] && [workspace.oldLanguage isEqual:@"Finnish/Swedish"]) {
        //change Ä to +
        [workspace.currentAlphabet removeObjectAtIndex:26];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_spanishN.png"] atIndex:26];
        //change Ö to $
        [workspace.currentAlphabet removeObjectAtIndex:27];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_+.png"] atIndex:27];
        //change Å to ,
        [workspace.currentAlphabet removeObjectAtIndex:28];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_,.png"] atIndex:28];
    }
    //Finnish,German,English,Norwegian>Russian
    if ([workspace.currentLanguage isEqual:@"Russian"] && [workspace.oldLanguage isEqual:@"Finnish/Swedish"]) {
        //change RusB
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusB.png"] atIndex:1];
        
        //copy c to right position (17)
        [workspace.currentAlphabet insertObject:[workspace.currentAlphabet objectAtIndex:3] atIndex:17];
        //remove C
        [workspace.currentAlphabet removeObjectAtIndex:3];
        
        //change RusG
        [workspace.currentAlphabet removeObjectAtIndex:3];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusG.png"] atIndex:3];
        //add RusD
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusD.png"] atIndex:4];
        //change RusJo
        [workspace.currentAlphabet removeObjectAtIndex:6];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusJo.png"] atIndex:6];
        
        //change RusSche
        [workspace.currentAlphabet removeObjectAtIndex:7];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusSche.png"] atIndex:7];
        //change RusSe
        [workspace.currentAlphabet removeObjectAtIndex:8];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusSe.png"] atIndex:8];
        //change RusI
        [workspace.currentAlphabet removeObjectAtIndex:9];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusI.png"] atIndex:9];
        //change RusIkratkoje
        [workspace.currentAlphabet removeObjectAtIndex:10];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusIkratkoje.png"] atIndex:10];
        //change RusL
        [workspace.currentAlphabet removeObjectAtIndex:12];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusL.png"] atIndex:12];
        //change RusN
        [workspace.currentAlphabet removeObjectAtIndex:14];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusN.png"] atIndex:14];
        //insert rus p
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusP.png"] atIndex:16];
        
        //shift T into right position
        [workspace.currentAlphabet removeObjectAtIndex:19];
        [workspace.currentAlphabet removeObjectAtIndex:20];
        [workspace.currentAlphabet removeObjectAtIndex:21];
        [workspace.currentAlphabet removeObjectAtIndex:19];
        
        //copy X /RusCha into right position
        [workspace.currentAlphabet insertObject:[workspace.currentAlphabet objectAtIndex:22] atIndex:25];
        
        //shirt Y /RusU into right position
        [workspace.currentAlphabet removeObjectAtIndex:20];
        [workspace.currentAlphabet removeObjectAtIndex:20];
        [workspace.currentAlphabet removeObjectAtIndex:20];
        //change RusF
        [workspace.currentAlphabet removeObjectAtIndex:21];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusF.png"] atIndex:21];
        //change RusZ
        [workspace.currentAlphabet removeObjectAtIndex:23];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusZ.png"] atIndex:23];
        //change RusTsche
        [workspace.currentAlphabet removeObjectAtIndex:24];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusTsche.png"] atIndex:24];
        //change RusScha
        [workspace.currentAlphabet removeObjectAtIndex:25];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusScha.png"] atIndex:25];
        //change RusTscheScha
        [workspace.currentAlphabet removeObjectAtIndex:26];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusTschescha.png"] atIndex:26];
        //change RusMjachkiSnak
        [workspace.currentAlphabet removeObjectAtIndex:27];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusMjachkiSnak.png"] atIndex:27];
        //change RusUi
        [workspace.currentAlphabet removeObjectAtIndex:28];
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusUi.png"] atIndex:28];
        //add RusE
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusE.png"] atIndex:29];
        //add RusJu
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusJu.png"] atIndex:30];
        //add RusJa
        [workspace.currentAlphabet insertObject:[C4Image imageNamed:@"letter_RusJa.png"] atIndex:31];
    }
    id obj = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count]-3];
    alphabetView=(AlphabetView*)obj;
    [alphabetView redrawAlphabet];
}
-(void)goBack{
    [self.navigationController popViewControllerAnimated:NO];
}
-(void)hideKeyBoard {
    [textInput resignFirstResponder];
}
//------------------------------------------------------------------------
//STUFF TO HANDLE THE KEYBOARD INPUT
//------------------------------------------------------------------------

#pragma mark -
#pragma mark UITextViewDelegate Methods
- (void)textViewDidBeginEditing:(UITextView *)textView{}
- (void)textViewDidEndEditing:(UITextView *)textView{
    name=textView.text;
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    NSCharacterSet *doneButtonCharacterSet = [NSCharacterSet newlineCharacterSet];
    NSRange replacementTextRange = [text rangeOfCharacterFromSet:doneButtonCharacterSet];
    NSUInteger location = replacementTextRange.location;
    if (textView.text.length + text.length > 140){//140 characters are in the textView
        if (location != NSNotFound){ //Did not find any newline characters
            [textView resignFirstResponder];
        }
        return NO;
    }
    else if (location != NSNotFound){ //Did not find any newline characters
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}
- (void)textViewDidChange:(UITextView *)textView{}

@end
