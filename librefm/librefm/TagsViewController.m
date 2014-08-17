//
//  TagsViewController.m
//  librefm
//
//  Created by sbar on 21/07/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "TagsViewController.h"
#import "HPLTagCloudGenerator.h"
#import "UIColor+CustomColors.h"
#import "AppDelegate.h"
#import "LibrefmConnection.h"
#import "PlayerViewController.h"
#import "AddTagViewController.h"

@interface TagsViewController ()

@property NSMutableArray *tagLabels;
@property (atomic) NSMutableDictionary *tagDict;

@end

@implementation TagsViewController

__weak LibrefmConnection *_librefmConnection;
__weak PlayerViewController *_playerViewController;
AddTagViewController *_addTagViewController;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.customTags = [NSMutableArray new];
    // TODO: load custom tags
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    _librefmConnection = appDelegate.librefmConnection;
    _playerViewController = appDelegate.playerViewController;

    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    CGSize size = self.scrollView.frame.size;
    size.width *= 2.0f;
    size.height *= 2.0f;
    self.scrollView.contentSize = size;
    [self.scrollView setContentOffset:CGPointMake(40.0f, 140.0f) animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    for(UILabel *v in self.tagLabels) {
        v.textColor = [UIColor customBlueColor];
    }
}

- (void)librefmDidLoadTopTags:(BOOL)ok
                         tags:(NSDictionary*)tags
{
    if (ok) {
        [self updateTags:(NSMutableDictionary*)tags];
    } else {
        NSLog(@"librefmDidLoadTopTags failed");
    }
}

- (void)refresh
{
    if (self.tagDict != nil) {
        [self updateTags:self.tagDict];
    }
}

- (void)addTag:(NSString*)tag
{
    [self.customTags addObject:tag];
    // TODO: save

    [self refresh];
}

- (void)updateTags:(NSMutableDictionary*)tagDict
{
    self.tagDict = tagDict;

    for(UILabel *v in self.tagLabels) {
        v.hidden = YES;
        [self.scrollView bringSubviewToFront:v];
        [v removeFromSuperview];
    }
    [self.tagLabels removeAllObjects];

    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *tag in self.customTags) {
            [self.tagDict removeObjectForKey:tag];
        }

        HPLTagCloudGenerator *tagGenerator = [[HPLTagCloudGenerator alloc] init];
        tagGenerator.size = CGSizeMake(self.scrollView.contentSize.width, self.scrollView.contentSize.height);
        tagGenerator.tagDict = (NSDictionary*) self.tagDict;
        tagGenerator.customTags = self.customTags;
        
        self.tagLabels = [tagGenerator generateTagViews];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            for(UILabel *v in self.tagLabels) {
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tagViewTapped:)];
                [v addGestureRecognizer:tap];
                [v setUserInteractionEnabled:YES];
                
                v.textColor = [UIColor customBlueColor];
                [v setNeedsDisplay];
                [self.scrollView addSubview:v];
            }
        });
    });
}

- (void)tagViewTapped:(UITapGestureRecognizer *)recognizer
{
    UILabel *label = (UILabel *)recognizer.view;
    label.textColor = [UIColor customYellowColor];
    
    NSString *tag = label.text;
    NSLog(@"tagViewTapped '%@'", tag);
    
    if ([tag isEqualToString:@"+"]) {
        [self openAddTagScreen];
    } else {
        [UIView transitionWithView:self.view
                          duration:0.003
                           options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionTransitionCrossDissolve
                        animations:^(void){
                            [super viewWillAppear:YES];
                        } completion:^(BOOL finished) {
                            [self switchToTabIndex:TabPlayer];
                            [_playerViewController clearPlaylist];
                            [_librefmConnection radioTune:tag];
                        }];
    }

    /*NSMutableDictionary *tagDict = [NSMutableDictionary new];
    for (int i = 0 ; i < rand() % 10 + 50; ++i)
        tagDict[[NSString stringWithFormat:@"%d", i]] = @(i + (rand() % 2));
    [self updateTags:tagDict];*/
}

- (void)openAddTagScreen
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _addTagViewController = [storyboard instantiateViewControllerWithIdentifier:@"AddTagViewController"];
    _addTagViewController.transitioningDelegate = self;
    _addTagViewController.delegate = self;
    _addTagViewController.modalPresentationStyle = UIModalPresentationCustom;
    //_addTagViewController.librefmConnection = _librefmConnection;
    self.presentationViewHeightOffset = 450.0;
    [self presentViewController:_addTagViewController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
