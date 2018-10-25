//
//  FirstViewController.h
//  GroovTube
//
//  Created by Culann Mac Cabe on 21/02/2013.
//  Copyright (c) 2013 Culann Mac Cabe. All rights reserved.
//

#import <UIKit/UIKit.h>
/*
 setBTTreshold
 */
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

@property int midiinhale;
@property int midiexhale;
@property float velocity;
@property float animationrate;
@property(nonatomic,strong)IBOutlet UISlider  *testSlider;
-(IBAction)sliderchanged:(id)sender;
@property BOOL midiIsOn;
@property(nonatomic,strong) UITextView  *outputtext;
@property  dispatch_source_t  aTimer;
@property(nonatomic,strong)IBOutlet  UITextView  *textarea;
-(void)continueMidiNote:(int)pvelocity;
-(void)stopMidiNote;
-(void)midiNoteBegan:(int)direction vel:(int)pvelocity;
-(void)makeTimer;
-(void)background;
-(void)foreground;
@end
