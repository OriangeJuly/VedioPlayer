//
//  ViewController.m
//  AVvedio
//
//  Created by apple on 15/10/19.
//  Copyright © 2015年 apple. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <lame/lame.h>

@interface ViewController ()<AVAudioPlayerDelegate,AVAudioRecorderDelegate>
{
    AVAudioPlayer *_avaudioPlayer;
    AVAudioRecorder *_recorder;
}
@property (weak, nonatomic) IBOutlet UIImageView *imageFlash;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor yellowColor];
    //      （中断）通知要放到这个位置
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruption:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    
    [self testAvdio];
    //     rate属性设置和获取播放速率
    _avaudioPlayer.enableRate = YES;
    _avaudioPlayer.rate = 1.2f;
    _avaudioPlayer.volume = 0.9f;
    _avaudioPlayer.numberOfLoops = 2;
    NSLog(@"Song whole time :%f",_avaudioPlayer.duration);
#pragma mark//   与其他音频会话共存的需求设置（setCategory：有多种不同类别设置）
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *audioSessionError = nil;
    if ([audioSession setCategory:AVAudioSessionCategoryAmbient error:&audioSessionError   ]) {
        NSLog(@"设置会话类型成功");
        
    }else
    {
        NSLog(@"Set Faied");
    }
    
    NSArray *imagesArray;
    imagesArray = [NSArray arrayWithObjects:
                   [UIImage imageNamed:@"分类.PNG"],
                   [UIImage imageNamed:@"1.PNG"],
                   [UIImage imageNamed:@"Media3x.png"],
                   [UIImage imageNamed:@"nuoyi.jpg"],nil];
    
    
    self.imageFlash.animationImages = imagesArray;
    self.imageFlash.animationDuration = 10;
    self.imageFlash.animationRepeatCount = 30;
    [self.imageFlash startAnimating];
    
}

- (void)testAvdio
{
#if 0
    // 本地URL
    NSURL *url = [NSURL fileURLWithPath:@"/Users/apple/Desktop/new.mp4"];
    _avaudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
#endif
    //  网络URL
    NSURL *url = [NSURL URLWithString:@"http://m2.music.126.net/maT2OlTX7HUXjBBZrlYlCw==/7831821325669280.mp3"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    _avaudioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
    _avaudioPlayer.delegate = self;
    [_avaudioPlayer prepareToPlay];

}
- (void)handleInterruption:(NSNotification *)notification
{
        NSLog(@"%@",notification.userInfo);
        AVAudioSessionInterruptionType interruptType;
        NSNumber *value =
        notification.userInfo[@"AVAudioSessionInterruptionTypeKey"];
        interruptType = value.integerValue;
        if ([notification.userInfo[@"AVAudioSessionInterruptionTypeKey"]
             isEqual: @(AVAudioSessionInterruptionTypeBegan)]) { //中断开始,来电话了
            [_avaudioPlayer pause];
        }else if(interruptType == AVAudioSessionInterruptionTypeEnded)
        {
            //中断结束,是否恢复播放
            if([notification.userInfo[@"AVAudioSessionInterruptionOptionKey"]
                isEqual:@(AVAudioSessionInterruptionOptionShouldResume)]){
                [_avaudioPlayer play];

            }
        }
}

- (IBAction)playButton:(id)sender {
    [_avaudioPlayer play];
}
- (IBAction)pauseButton:(id)sender {
    [_avaudioPlayer pause];
}
- (IBAction)stopButton:(id)sender {
    [_avaudioPlayer stop];
}


//  A:  录音的设置
- (NSDictionary *) audioRecordingSettings
{
    
    NSDictionary *result = nil;
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    /*[settings setValue:[NSNumber
                        numberWithInteger:kAudioFormatAppleLossless] forKey:AVFormatIDKey];*///  method A
    [settings setValue:[NSNumber numberWithInteger:kAudioFormatLinearPCM] forKey:AVFormatIDKey];  //   method  B
    [settings setValue:[NSNumber numberWithFloat: 44100.0f]
                forKey:AVSampleRateKey];
    [settings setValue:[NSNumber numberWithInteger:1]
                forKey:AVNumberOfChannelsKey];
    [settings setValue:[NSNumber numberWithInteger:AVAudioQualityLow]
                forKey:AVEncoderAudioQualityKey];
    result = [NSDictionary dictionaryWithDictionary:settings];
    return result;
}

            #pragma mark//   before record must 向用户请求录音授权（隐私问题）
- (IBAction)recoderButton:(id)sender {
    
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            //    method A:  Apple不支持录制输出mp3编码，支持AAC编码，所以文件名后缀为.m4a
           // NSURL *recordFileUrl = [NSURL fileURLWithPath:@"/Users/apple/Desktop/再见再见.m4a"];
            NSURL *recordFileUrl = [NSURL fileURLWithPath:@"/Users/apple/Desktop/hello.pcm"];
            NSDictionary *settings = [self audioRecordingSettings];
            NSError *err;
            _recorder = [[AVAudioRecorder alloc] initWithURL:recordFileUrl settings:settings error:&err];
            if (_recorder != nil) {
                _recorder.delegate = self;
                [_recorder prepareToRecord];
                [_recorder record];
                [_recorder performSelector:@selector(stop) withObject:nil afterDelay:10];
            }
            else
            {
                NSLog(@"没有授权所以不能录音哦");
                
            }
            
        }
    }];
}


            #pragma mark//B:flame方法录音用到的MP3编码方法封装
-  (void)convertPcmFile:(NSString*)pcmFile toMp3File:(NSString*)mp3File {
    int read, write;
    //C⽅方法打开⽂文件
    FILE *pcm = fopen(pcmFile.UTF8String, "rb");
    FILE *mp3 = fopen(mp3File.UTF8String, "wb");
    const int PCM_SIZE = 8192;
    const int MP3_SIZE = 8192;
    //准备内存缓冲区
    short int pcm_buffer[PCM_SIZE*2];
    unsigned char mp3_buffer[MP3_SIZE];
    //初始化编码器
    lame_t lame = lame_init();
    lame_set_in_samplerate(lame, 44100);//设置采样率,务必和pcm⽂文件采样率⼀一致 lame_set_VBR(lame, vbr_default);//设置默认动态⽐比特率 lame_init_params(lame);//初始化这些参数
    do {//先读PCM⽂文件数据
        read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
        if (read == 0){
            write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
        }
        else
        {//把PCM原始⾳音频数据帧按照2个声道转换为MP3压缩的数据,务必和录音设置⼀一致
            write = lame_encode_buffer_interleaved(lame, pcm_buffer, read,
            mp3_buffer, MP3_SIZE);
        }//写⼊入到输出⽂文件中
        fwrite(mp3_buffer, write, 1, mp3);
    }
    while (read != 0);
    lame_close(lame);
    fclose(mp3);
    fclose(pcm);
    return;
}



#pragma mark//    AVAudioPlayerDelegate method
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag) {
        [self convertPcmFile:@"/Users/apple/Desktop/hello.pcm" toMp3File:@"/Users/apple/Desktop/hello.mp3"];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error
{
    NSLog(@"kazhula");
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
