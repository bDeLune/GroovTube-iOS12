#define GUAGE_HEIGHT 575

#import "GPUImage.h"
#import "FirstViewController.h"

#import <AudioToolbox/AudioToolbox.h>
#import "BTLEManager.h"

typedef void(^RunTimer)(void);
@interface FirstViewController ()<BTLEManagerDelegate, UIImagePickerControllerDelegate>
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
    BOOL  toggleIsON;
    float threshold;
    float mass;
    BOOL isaccelerating;
    float acceleration;
    float distance;
    float time;
    float sketchamount;
    BOOL ledTestIsOn;
}

@property (nonatomic, retain) IBOutlet UIToolbar *myToolbar;
@property (nonatomic, retain) NSMutableArray *capturedImages;
@property(nonatomic,strong)BTLEManager  *btleMager;
@property(nonatomic,strong)UIImageView  *btOnOfImageView;
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
    
        imagePickerController = [[UIImagePickerController alloc] init] ;
        imagePickerController.delegate = self;
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
    self.velocity=(percentOfmax)*127.0;
    isaccelerating=YES;
}

-(void)btleManager:(BTLEManager*)manager exhaleWithValue:(float)percentOfmax
{
    if (toggleIsON==YES) {
        return ;
    }
    
    currentdirection=midiexhale;
    self.velocity=(percentOfmax)*127.0;
    isaccelerating=YES;
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    UIImage *image = chosenImage;
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    //UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [self setupDisplayFilteringWithImage:image];
   
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"latest_photo.png"];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]){
        NSData *webData = UIImagePNGRepresentation(image);
        [webData writeToFile:imagePath atomically:YES];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)photoButtonLibraryAction:(id)sender
{
    //if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    //    popover = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
    //    [popover presentPopoverFromRect:CGRectMake(0, 0, 500, 500) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    //}
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self presentViewController:picker animated:YES completion:NULL];

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

-(void)viewWillAppear:(BOOL)animated    //was viewdidappear
{

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
    
    if (!displayLink) {
        [self setupDisplayFiltering];
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateimage)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        animationRunning = YES;
        [displayLink setPreferredFramesPerSecond:20];
        acceleration=0.1;
        distance=0;
        time=0;
        [self toggleDirection:nil];
        [self toggleDirection:nil];
    }
}

-(void)updateimage
{
    float fVel= (float)self.velocity;
    float rate = fVel;

    if (isaccelerating)
    {
        if (self.velocity>=threshold) {

        targetRadius=targetRadius+((rate/500)*_animationrate);
        }
    }else
    {
         targetRadius=targetRadius-((40.0/500)*_animationrate);
    }
    
    if (targetRadius<0.001) {
        targetRadius=0.001;
    }
    
    if (targetRadius>1) {
        targetRadius=1;
    }

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
    }

    [sourcePicture processImage];
}

-(void)setupDisplayFilteringWithImage:(UIImage*)aImage
{
    [sourcePicture removeAllTargets];
    stillImageFilter=nil;
    [imageView removeFromSuperview];
    imageView=nil;
    imageView = [[GPUImageView alloc]initWithFrame:self.view.frame];
    [self.view insertSubview:imageView atIndex:0];
    stillImageFilter=[self filterForIndex:0];
    [sourcePicture addTarget:stillImageFilter];
    [stillImageFilter addTarget:imageView];

    sourcePicture = [[GPUImagePicture alloc] initWithImage:aImage smoothlyScaleOutput:YES];
    stillImageFilter = [self filterForIndex:0];
    imageView = [[GPUImageView alloc]initWithFrame:self.view.frame];
    [self.view insertSubview:imageView atIndex:0];
    [sourcePicture addTarget:stillImageFilter];
    [stillImageFilter addTarget:imageView];
    [sourcePicture processImage];
}

- (void)setupDisplayFiltering;
{
    UIImage *inputImage;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *imagePath = [documentsDirectory stringByAppendingPathComponent:@"latest_photo.png"];
    NSData  *data=[NSData dataWithContentsOfFile:imagePath];

    inputImage=[UIImage imageWithData:data];
    if (!inputImage) {
        inputImage=[UIImage imageNamed:@"giraffe-614141_1280.jpg"];
    }
    
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
    stillImageFilter=nil;
    [imageView removeFromSuperview];
    imageView=nil;
    imageView = [[GPUImageView alloc]initWithFrame:self.view.frame];
    [self.view insertSubview:imageView atIndex:0];
    stillImageFilter=[self filterForIndex:index];
    [sourcePicture addTarget:stillImageFilter];
    [stillImageFilter addTarget:imageView];
}

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

-(void)midiNoteBegan:(int)direction vel:(int)pvelocity
{

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
        displayLink = [CADisplayLink displayLinkWithTarget:self
                                                  selector:@selector(animate)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        animationRunning = YES;
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
    NSLog(@"make timer");
    isaccelerating=NO;
}

@end
