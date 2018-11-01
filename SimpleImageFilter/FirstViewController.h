//
//  FirstViewController.h
//  GroovTube
//
//  Created by Culann Mac Cabe on 21/02/2013.
//  Copyright (c) 2013 Culann Mac Cabe. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SETTINGS_DELEGATE

-(void)sendValue:(int)note onoff:(int)onoff;
-(void)setFilter:(int)index;
-(void)setRate:(float)value;
-(void)setThreshold:(float)value;
-(void)setBTTreshold:(float)value;
-(void)setBTBoost:(float)value;

@end

@interface FirstViewController : UIViewController<SETTINGS_DELEGATE,UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    int midiinhale;
    int midiexhale;
    int currentdirection;
    BOOL midiIsOn;
}

@property(nonatomic,strong) UITextView  *outputtext;
@property(nonatomic,strong)IBOutlet  UITextView  *textarea;
@property(nonatomic,strong)IBOutlet UISlider  *testSlider;
@property  dispatch_source_t  aTimer;
@property int midiinhale;
@property int midiexhale;
@property float velocity;
@property float animationrate;
@property BOOL midiIsOn;
-(IBAction)sliderchanged:(id)sender;
-(void)continueMidiNote:(int)pvelocity;
-(void)stopMidiNote;
-(void)midiNoteBegan:(int)direction vel:(int)pvelocity;
-(void)makeTimer;
-(void)background;
-(void)foreground;

@end
