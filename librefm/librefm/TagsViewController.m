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

@interface TagsViewController ()

@property NSMutableArray *tagLabels;

@end

@implementation TagsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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
        [self updateTags:tags];
    } else {
        NSLog(@"librefmDidLoadTopTags failed");
    }
}

- (void)updateTags:(NSDictionary*)tagDict
{
    for(UILabel *v in self.tagLabels) {
        v.hidden = YES;
        [self.view bringSubviewToFront:v];
        [v removeFromSuperview];
    }
    [self.tagLabels removeAllObjects];

    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        HPLTagCloudGenerator *tagGenerator = [[HPLTagCloudGenerator alloc] init];
        tagGenerator.size = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
        tagGenerator.tagDict = tagDict;
        
        self.tagLabels = [tagGenerator generateTagViews];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            for(UILabel *v in self.tagLabels) {
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tagViewTapped:)];
                [v addGestureRecognizer:tap];
                [v setUserInteractionEnabled:YES];
                
                v.textColor = [UIColor customBlueColor];
                [v setNeedsDisplay];
                [self.view addSubview:v];
            }
        });
    });
}

- (void)tagViewTapped:(UITapGestureRecognizer *)recognizer
{
    UILabel *label = (UILabel *)recognizer.view;
    label.textColor = [UIColor customYellowColor];
    NSLog(@"tagViewTapped '%@'", label.text);
    
    [UIView transitionWithView:self.view
                      duration:0.003
                       options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void){
                        [super viewWillAppear:YES];
                    } completion:^(BOOL finished){
                        [self switchToTabIndex:TabPlayer];
                    }];

    /*NSMutableDictionary *tagDict = [NSMutableDictionary new];
    for (int i = 0 ; i < rand() % 10 + 50; ++i)
        tagDict[[NSString stringWithFormat:@"%d", i]] = @(i + (rand() % 2));
    [self updateTags:tagDict];*/
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
