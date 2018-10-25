//
//  FirstViewController.m
//  GroovTube
//
//  Created by Culann Mac Cabe on 21/02/2013.
//  Copyright (c) 2013 Culann Mac Cabe. All rights reserved.
//
#define GUAGE_HEIGHT 575
#import "GPUImage.h"
#import "FirstViewController.h"
/*
#import  "GPUImageBulgeDistortionFilter.h"
#import  "GPUImageSwirlFilter.h"
#import "GPUImageZoomBlurFilter.h"
#import"GPUImageVignetteFilter.h"
#import "GPUImageToonFilter.h"
//#import "GPUImageToneCurveFilter.h"
#import "GPUImageThresholdSketchFilter.h"
#import "GPUImageDilationFilter.h"
#import "GPUImageDissolveBlendFilter.h"
#import "GPUImageStretchDistortionFilter.h"
#import "GPUImageSphereRefractionFilter.h"
#import "GPUImagePolkaDotFilter.h"
#import "GPUImagePosterizeFilter.h"
#import "GPUImagePixellateFilter.h"
#import "GPUImageHazeFilter.h"
#import "GPUImageErosionFilter.h"
#import "GPUImagePicture.h"
#import "GPUImageView.h"
#import "GPUImageExposureFilter.h"

#import "GPUImageTiltShiftFilter.h"
#import "GPUImageContrastFilter.h"*/
#import "BTLEManager.h"
#import <CoreMIDI/CoreMIDI.h>
#import <AudioToolbox/AudioToolbox.h>

static void	MyMIDIReadProc(const MIDIPacketList *pktlist, void *refCon, void *connRefCon);
void MyMIDINotifyProc (const MIDINotification  *message, void *refCon);
typedef void(^RunTimer)(void);
@interface FirstViewController ()<BTLEManagerDelegate>
{
    GPUImagePicture *sourcePicture;
    GPUImageFilter *stillImageFilter;
    GPUImageView *imageView;
    CGFloat  defaultRadius;
    CGFloat  defaultScale;
    CGFloat  targetRadius;
    CGFloat  targetScale;
    
    CADisplayLink *displayLink;
    BOOL animationRunning;
    NSTimeInterval drawDuration;
    CFTimeInterval lastDrawTime;
    CGFloat drawProgress;
    
    int inorout;
    
    
    
    MIDIPortRef inPort ;
    MIDIPortRef outPort ;
    
    UIButton  *picselect;
    
    UIPopoverController *popover;
    
    UIImagePickerController *imagePickerController;
    
    UIButton  *togglebutton;
    BOOL   toggleIsON;
    float threshold;
    
    float mass;
    BOOL isaccelerating;
    float acceleration;// force/ mass
    float distance;
    float time;
    
    float sketchamount;
    
    BOOL ledTestIsOn;

    
}

@property (nonatomic, retain) IBOutlet UIToolbar *myToolbar;

@property (nonatomic, retain) NSMutableArray *capturedImages;
@property(nonatomic,strong)BTLEManager  *btleMager;
@property(nonatomic,strong)UIImageView  *btOnOfImageView;
// toolbar buttons
//- (IBAction)photoLibraryAction:(id)sender;
//- (IBAction)cameraAction:(id)sender;
@property (assign) SystemSoundID tickSound;
@property(nonatomic,strong)UIButton *ledTestButton;


@end
@implementation FirstViewController
-(void)background

{
    self.btleMager.delegate=nil;
    self.btleMager=nil;
    [displayLink invalidate];
    displayLink=nil;
}
-(void)foreground
{
    self.btleMager=[BTLEManager new];
    self.btleMager.delegate=self;
    [self.btleMager startWithDeviceName:@"GroovTube 2.0" andPollInterval:0.1];
    //[self.btleMager setTreshold:60];

}
-(void)btleManagerConnected:(BTLEManager *)manager
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.btOnOfImageView setImage:[UIImage imageNamed:@"Bluetooth-CONNECTED"]];

    });

}

-(void)btleManagerDisconnected:(BTLEManager *)manager

{
    dispatch_async(dispatch_get_main_queue(), ^{

    [self.btOnOfImageView setImage:[UIImage imageNamed:@"Bluetooth-DISCONNECTED"]];
    });

}
-(IBAction)sliderchanged:(id)sender
{
    sketchamount=self.testSlider.value;

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        sketchamount=0;
        self.title = @"Groov";
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
        _animationrate=1;
        picselect=[UIButton buttonWithType:UIButtonTypeCustom];
        picselect.frame=CGRectMake(0, self.view.frame.size.height-120, 108, 58);
        [picselect addTarget:self action:@selector(photoButtonLibraryAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:picselect];
        
        [picselect setBackgroundImage:[UIImage imageNamed:@"PickPhotoButton.png"] forState:UIControlStateNormal];
        
         self.capturedImages = [NSMutableArray array];
        
        
        
     /*   AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:
                                                    [[NSBundle mainBundle] pathForResource:@"tick"
                                                                                    ofType:@"aiff"]],
                                         &_tickSound);*/
        
        imagePickerController = [[UIImagePickerController alloc] init] ;
        imagePickerController.delegate = self;
        
      //  [self.view addSubview:imagePickerController.view];

        togglebutton=[UIButton buttonWithType:UIButtonTypeCustom];
        togglebutton.frame=CGRectMake(110, self.view.frame.size.height-120, 108, 58);
        [togglebutton addTarget:self action:@selector(toggleDirection:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:togglebutton];
        
        [togglebutton setBackgroundImage:[UIImage imageNamed:@"BreathDirection_EXHALE.png"] forState:UIControlStateNormal];
        toggleIsON=NO;
        threshold=0;
        
        
        self.btOnOfImageView=[[UIImageView alloc]initWithFrame:CGRectMake(10, 10, 100, 100)];
        [self.btOnOfImageView setImage:[UIImage imageNamed:@"Bluetooth-DISCONNECTED"]];
        [self.view addSubview:self.btOnOfImageView];
        self.ledTestButton=[[UIButton alloc]initWithFrame:CGRectMake(110, 10, 100, 100)];
        [self.ledTestButton setBackgroundColor:[UIColor greenColor]];
        [self.ledTestButton addTarget:self action:@selector(testLed:) forControlEvents:UIControlEventTouchUpInside];
       //dead [self.view addSubview:self.ledTestButton];
    }
    return self;
}

-(IBAction)testLed:(id)sender
{
    if (ledTestIsOn==YES) {
    
        ledTestIsOn=NO;
        [self.btleMager performSelector:@selector(ledLeftOff)];
    }else
    {
        [self.btleMager performSelector:@selector(ledLeftOn)];
        ledTestIsOn=YES;
    }
}
-(void)btleManagerBreathBegan:(BTLEManager*)manager
{
    NSLog(@"Midi Began");
    if (![self allowBreath]) {
        return;
    }
    //isaccelerating=YES;
}
-(void)btleManagerBreathStopped:(BTLEManager *)manager
{
    NSLog(@"Midi Stopped");

    isaccelerating=NO;
}
-(void)btleManager:(BTLEManager*)manager inhaleWithValue:(float)percentOfmax{
    if (toggleIsON==NO) {
        return ;
    }
    currentdirection=midiinhale;
    //self.velocity=(percentOfmax/10.0)*127.0;
    self.velocity=(percentOfmax)*127.0;
    isaccelerating=YES;
  //  NSLog(@"inhaleWithValue %f",percentOfmax);
}

-(void)btleManager:(BTLEManager*)manager exhaleWithValue:(float)percentOfmax
{
  /*  if (![self allowBreath]) {
        isaccelerating=NO;

        return;
    }*/
    if (toggleIsON==YES) {
        return ;
    }
    currentdirection=midiexhale;
    //self.velocity=(percentOfmax/10.0)*127.0;
    self.velocity=(percentOfmax)*127.0;
    isaccelerating=YES;
//
 //   NSLog(@"exhaleWithValue %f",percentOfmax);
    
}
-(BOOL)allowBreath
{
    if (toggleIsON) {
        if (currentdirection==midiexhale) {
            return NO;
        }
    }else if (!toggleIsON)
    {
        
        if (currentdirection==midiinhale) {
            return NO;
        }
    }
    
    return YES;
    
}

- (IBAction)toggleDirection:(id)sender
{
    
    switch (toggleIsON) {
        case 0:
            toggleIsON=YES;
            [togglebutton setBackgroundImage:[UIImage imageNamed:@"BreathDirection_INHALE.png"] forState:UIControlStateNormal];
            break;
        case 1:
            [togglebutton setBackgroundImage:[UIImage imageNamed:@"BreathDirection_EXHALE.png"] forState:UIControlStateNormal];
            toggleIsON=NO;

            break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

// this get called when an image has been chosen from the library or taken from the camera
//
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [self setupDisplayFilteringWithImage:image];
   
    //obtaining saving path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"latest_photo.png"];
    
    //extracting image from the picker and saving it
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]){
       // UIImage *editedImage = [info objectForKey:UIImagePickerControllerEditedImage];
        NSData *webData = UIImagePNGRepresentation(image);
        [webData writeToFile:imagePath atomically:YES];
    }
    
   // [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
   // [self.delegate didFinishWithCamera];    // tell our delegate we are finished with the picker
}

- (IBAction)photoButtonLibraryAction:(id)sender
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        popover = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
        [popover presentPopoverFromRect:CGRectMake(0, 0, 500, 500) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        //[self presentModalViewController:imagePickerController animated:YES];
    }
}
@synthesize midiexhale,midiinhale,velocity;
@synthesize midiIsOn;
-(void)setThreshold:(float)value
{
    threshold=value;
}
-(void)setBTTreshold:(float)value
{
    [self.btleMager setTreshold:value];
}
-(void)setBTBoost:(float)value
{
    [self.btleMager setRangeReduction:value];
}
-(void)setRate:(float)value
{
    self.animationrate=value;
}
-(void) appendToTextView: (NSString*) moreText {
	dispatch_async(dispatch_get_main_queue(), ^{
		_outputtext.text = [NSString stringWithFormat:@"%@%@\n",
                            _outputtext.text, moreText];
		[_outputtext scrollRangeToVisible:NSMakeRange(_outputtext.text.length-1, 1)];
	});
}

-(void)viewDidAppear:(BOOL)animated
{
    if (!displayLink) {
        [self setupDisplayFiltering];
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateimage)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        animationRunning = YES;
        [displayLink setFrameInterval:8];
        //[self makeTimer];
        acceleration=0.1;
        distance=0;
        time=0;
        [self toggleDirection:nil];
        [self toggleDirection:nil];
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    midiinhale=61;
    midiexhale=73;
    velocity=0;
    midiIsOn=false;
    targetRadius=0;
    defaultScale=1.5;
    defaultRadius=0;
   // [self setupMIDI];
	// Do any additional setup after loading the view, typically from a nib.
}
-(void)updateimage
{
    /***
     @"Bulge",@"Swirl",@"Blur",@"Vignette",@"Toon",
     @"Tone",@"Sketch",@"Polka",
     @"Posterize",@"Pixellate",@"Haze",@"Erosion"
     */
   // self.velocity+=1;
    
    float fVel= (float)self.velocity;
   // float rate = fVel/5;
    float rate = fVel;
    //NSLog(@"rate == %f",rate);
    
    if (isaccelerating)
    {
        if (self.velocity>=threshold) {

        targetRadius=targetRadius+((rate/500)*_animationrate);
        }
        
    }else
    {
        //force-=force*0.03;
        // targetRadius=targetRadius-((35.0/500)*_animationrate);
         targetRadius=targetRadius-((40.0/500)*_animationrate);
    }

    //if (inorout==midiinhale) {
   // }else
   // {
       // targetRadius=targetRadius-((rate/1000)*_animationrate);
   // }
    
    
    if (targetRadius<0.001) {
        targetRadius=0.001;
    }
    
    if (targetRadius>1) {
        targetRadius=1;
    }
   // NSLog(@"target radius %f",targetRadius);

    if ([stillImageFilter isKindOfClass:[GPUImageBulgeDistortionFilter class]])
    
    {
        if (targetRadius<0.001) {
            targetRadius=0.0;
        }
        [(GPUImageBulgeDistortionFilter*)stillImageFilter setRadius:targetRadius];
        
    }else if ([stillImageFilter isKindOfClass:[GPUImageSwirlFilter class]])
    {
        [(GPUImageSwirlFilter*)stillImageFilter setRadius:targetRadius];

    }else if ([stillImageFilter isKindOfClass:[GPUImageZoomBlurFilter class]])
    {
        [(GPUImageZoomBlurFilter*)stillImageFilter setBlurSize:targetRadius];

    }else if ([stillImageFilter isKindOfClass:[GPUImageVignetteFilter class]])
    {
        [(GPUImageVignetteFilter*)stillImageFilter setVignetteStart:1-targetRadius];

        
    }else if ([stillImageFilter isKindOfClass:[GPUImageToonFilter class]])
    {
        [(GPUImageToonFilter*)stillImageFilter setThreshold:1-(targetRadius-0.1)];

        
    }else if ([stillImageFilter isKindOfClass:[GPUImageExposureFilter class]])
    {
        [(GPUImageExposureFilter*)stillImageFilter setExposure:targetRadius+0.1];
        
    }else if ([stillImageFilter isKindOfClass:[GPUImagePolkaDotFilter class]])
    {
        //[(GPUImagePolkaDotFilter*)stillImageFilter setDotScaling:targetRadius];
        [(GPUImagePolkaDotFilter*)stillImageFilter setFractionalWidthOfAPixel:targetRadius/10];

        
    }else if ([stillImageFilter isKindOfClass:[GPUImagePosterizeFilter class]])
    {
        [(GPUImagePosterizeFilter*)stillImageFilter setColorLevels:11-(10*targetRadius)];
        
    }else if ([stillImageFilter isKindOfClass:[GPUImagePixellateFilter class]])
    {
        [(GPUImagePixellateFilter*)stillImageFilter setFractionalWidthOfAPixel:targetRadius/10];
        
    }else if ([stillImageFilter isKindOfClass:[GPUImageContrastFilter class]])
    {
        [(GPUImageContrastFilter*)stillImageFilter setContrast:1-targetRadius];
      
        //[(GPUImageThresholdSketchFilter*)stillImageFilter setSlope:targetRadius/3];
    }

    //NSLog(@"value == %f",targetRadius);
    
    [sourcePicture processImage];

    /**
     self.topFocusLevel = 0.4;
     self.bottomFocusLevel = 0.6;
     self.focusFallOffRate = 0.2;
     self.blurSize = 2.0;*/
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)setupDisplayFilteringWithImage:(UIImage*)aImage
{
    
    //cleanup
    [sourcePicture removeAllTargets];
    //[stillImageFilter destroyFilterFBO];
    //[stillImageFilter releaseInputTexturesIfNeeded];
    stillImageFilter=nil;
    [imageView removeFromSuperview];
    imageView=nil;
    imageView = [[GPUImageView alloc]initWithFrame:self.view.frame];
    [self.view insertSubview:imageView atIndex:0];
    
    stillImageFilter=[self filterForIndex:0];
    [sourcePicture addTarget:stillImageFilter];
    [stillImageFilter addTarget:imageView];

    //image set
    //dispatch_async(dispatch_get_main_queue(), ^{
        sourcePicture = [[GPUImagePicture alloc] initWithImage:aImage smoothlyScaleOutput:YES];
        stillImageFilter = [self filterForIndex:0];
        imageView = [[GPUImageView alloc]initWithFrame:self.view.frame];
        // [self.view addSubview:imageView];
        [self.view insertSubview:imageView atIndex:0];
        [sourcePicture addTarget:stillImageFilter];
        [stillImageFilter addTarget:imageView];
        [sourcePicture processImage];
    
   // });
   // [self start];
}
- (void)setupDisplayFiltering;
{
    UIImage *inputImage;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"latest_photo.png"];
    NSData  *data=[NSData dataWithContentsOfFile:imagePath];

    //inputImage=[UIImage imageWithData:data];
    //if (!inputImage) {
        inputImage=[UIImage imageNamed:@"giraffe-614141_1280.jpg"];
   // }
    
    NSLog(@"Retrieved image");
    NSLog(@"inputImage %@", inputImage);
       
    sourcePicture = [[GPUImagePicture alloc] initWithImage:inputImage smoothlyScaleOutput:YES];
    stillImageFilter = [self filterForIndex:0];
    imageView = [[GPUImageView alloc]initWithFrame:self.view.frame];
   // [self.view addSubview:imageView];
    [self.view insertSubview:imageView atIndex:0];
    [sourcePicture addTarget:stillImageFilter];
    [stillImageFilter addTarget:imageView];
    
    [sourcePicture processImage];
}

-(void)setFilter:(int)index
{
    [sourcePicture removeAllTargets];
    //[stillImageFilter destroyFilterFBO];
    //[stillImageFilter releaseInputTexturesIfNeeded];
    stillImageFilter=nil;
    [imageView removeFromSuperview];
    imageView=nil;
    imageView = [[GPUImageView alloc]initWithFrame:self.view.frame];
   // [self.view addSubview:imageView];
    [self.view insertSubview:imageView atIndex:0];
    stillImageFilter=[self filterForIndex:index];
    [sourcePicture addTarget:stillImageFilter];
    [stillImageFilter addTarget:imageView];
    
    
 

}

/***
 #import"GPUImageVignetteFilter.h"
 #import "GPUImageToonFilter.h"
 #import "GPUImageToneCurveFilter.h"
 #import "GPUImageThresholdSketchFilter.h"
 #import "GPUImageDilationFilter.h"
 #import "GPUImageDissolveBlendFilter.h"
 #import "GPUImageStretchDistortionFilter.h"
 #import "GPUImageSphereRefractionFilter.h"
 #import "GPUImagePolkaDotFilter.h"
 #import "GPUImagePosterizeFilter.h"
 #import "GPUImagePixellateFilter.h"
 #import "GPUImageHazeFilter.h"
 #import "GPUImageErosionFilter.h"
 */

-(GPUImageFilter*)filterForIndex:(int)index
{
    GPUImageFilter *filter;
    
    switch (index) {
        case 0:
            filter=[[GPUImageBulgeDistortionFilter alloc] init];
            break;
            
        case 1:
            filter=[[GPUImageSwirlFilter alloc] init];

            break;
            
        case 2:
            filter=[[GPUImageZoomBlurFilter alloc] init];

            break;
    
            
        case 3:
            filter=[[GPUImageToonFilter alloc] init];
            
            break;
            

        case 4:
            filter=[[GPUImageExposureFilter alloc] init];
            break;
            
                    
        case 5:
            filter=[[GPUImagePolkaDotFilter alloc] init];
            
            break;
        case 6:
            filter=[[GPUImagePosterizeFilter alloc] init];
            
            break;
            
        case 7:
            filter=[[GPUImagePixellateFilter alloc] init];
            
            break;
            
        case 8:
            filter=[[GPUImageContrastFilter alloc] init];
            break;
            

            
        default:
            break;
    }
    
    return filter;
}

/*#pragma mark - midi
-(void) setupMIDI {
	
	MIDIClientRef client = NULL;
	MIDIClientCreate(CFSTR("Midi Client"), MyMIDINotifyProc,(__bridge void*) self, &client);
	
	 inPort = NULL;
     outPort = NULL;

	MIDIInputPortCreate(client, CFSTR("Input port"), MyMIDIReadProc,(__bridge void*)  self, &inPort);
	MIDIOutputPortCreate(client, (CFStringRef)@"Output Port", &outPort);
	unsigned long sourceCount = MIDIGetNumberOfSources();
	for (int i = 0; i < sourceCount; ++i) {
		MIDIEndpointRef src = MIDIGetSource(i);
		CFStringRef endpointName = NULL;
		OSStatus nameErr = MIDIObjectGetStringProperty(src, kMIDIPropertyName, &endpointName);
		if (noErr == nameErr) {
		}
		MIDIPortConnectSource(inPort, src, NULL);
	}
	
}*/

-(void)midiNoteBegan:(int)direction vel:(int)pvelocity

{
    /**if (_aTimer) {
        
        dispatch_suspend(_aTimer);
        dispatch_source_cancel(_aTimer);
        _aTimer=nil;
    }
    inorout=direction;

    if (toggleIsON==YES) {
        //inorout=midiinhale;
        if (inorout==midiinhale) {
            inorout=midiexhale;
        }else if(inorout==midiexhale)
        {
            inorout=midiinhale;;

        }
    }**/
    
    
    currentdirection=direction;
    
    if (![self allowBreath]) {
        return;
    }
    isaccelerating=YES;
    self.velocity=pvelocity;
}


-(void)addText:(NSString*)str
{
    NSString  *newstring=[NSString stringWithFormat:@"%@\n%@",_textarea.text,str];
    [_textarea setText:newstring];
}
-(void)animate
{
    self.velocity+=0.1;
    if (self.velocity<threshold) {
        return;
    }
    float fVel= (float)self.velocity;
    float rate = fVel/10;
    
    
    
    if (inorout==midiinhale) {
        targetRadius=targetRadius+((45.0/100)*_animationrate);
    }else
    {
        targetRadius=targetRadius-((45.0/100)*_animationrate);
    }
    
    
    if (targetRadius<0.01) {
        targetRadius=0.01;
    }
    
    if (targetRadius>1) {
        targetRadius=1;
    }
    

}
-(void)start
{
    //  [self stop];
    //[self setDefaults];
   // if (!animationRunning)
   // {
        displayLink = [CADisplayLink displayLinkWithTarget:self
                                                  selector:@selector(animate)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        animationRunning = YES;
    //}
}
-(void)continueMidiNote:(int)pvelocity
{
    if (![self allowBreath]) {
        return;
    }

    self.velocity=pvelocity;
        
   
    
    
    
}
-(void)stopMidiNote
{
     // targetRadius=0;
    NSLog(@"make timer");
    isaccelerating=NO;
   // [self makeTimer];
}

#pragma mark MIDI Output
- (IBAction) sendMidiData
{
    [self performSelectorInBackground:@selector(sendMidiDataInBackground) withObject:nil];
}
/*-(void)sendValue:(int)note onoff:(int)onoff
{
    const UInt8 noteOn[]  = { 0x90, note, 127 };
   // const UInt8 noteOff[] = { 0x80, note, 0   };
    
    [self sendBytes:noteOn size:sizeof(noteOn)];
    [NSThread sleepForTimeInterval:0.01];
   // [self sendBytes:noteOff size:sizeof(noteOff)];


}*/


/*- (void) sendPacketList:(const MIDIPacketList *)packetList
{
    for (ItemCount index = 0; index < MIDIGetNumberOfDestinations(); ++index)
    {
        MIDIEndpointRef outputEndpoint = MIDIGetDestination(index);
        if (outputEndpoint)
        {
            // Send it
            MIDISend(outPort, outputEndpoint, packetList);
           // NSLogError(s, @"Sending MIDI");
        }
    }
}*/

/*- (void) sendBytes:(const UInt8*)data size:(UInt32)size
{
   // NSLog(@"%s(%u bytes to core MIDI)", __func__, unsigned(size));
    assert(size < 65536);
    Byte packetBuffer[size+100];
    MIDIPacketList *packetList = (MIDIPacketList*)packetBuffer;
    MIDIPacket     *packet     = MIDIPacketListInit(packetList);
    
    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, size, data);
    
    [self sendPacketList:packetList];
}*/

/*static void	MyMIDIReadProc(const MIDIPacketList *pktlist, void *refCon, void *connRefCon)
{
	
	FirstViewController *vc = (__bridge FirstViewController*) refCon;
	
	MIDIPacket *packet = (MIDIPacket *)pktlist->packet;
	int midiCommand = packet->data[0] >> 4;
    int note = packet->data[1] & 0x7F;
    int veolocity = packet->data[2] & 0x7F;
    //[vc appendToTextView:[NSString stringWithFormat:
    // @"Command =%d ,Note=%d, Velocity=%d",midiCommand, note, veolocity]];
    if (midiCommand == 0x09) {
        vc.midiIsOn=YES;
        //[vc update:note velocity:veolocity ison:midiCommand];
        [vc midiNoteBegan:note vel:veolocity];
    }
    
    if (midiCommand==11) {
        
       // NSLog(@"Command =%d ,Note=%d, Velocity=%d",midiCommand, note, veolocity);
        if (note==2) {
            //still going
            [vc continueMidiNote:veolocity];
        }else 
        {
            //ended
             [vc stopMidiNote];
            
           // [vc continueMidiNote:veolocity];
            
        }
    }
}*/

/*void MyMIDINotifyProc (const MIDINotification  *message, void *refCon) {
 
}*/

@end
