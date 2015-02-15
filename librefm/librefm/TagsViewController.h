//
//  TagsViewController.h
//  librefm
//
//  Created by sbar on 21/07/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabBarViewController.h"
#import "BaseTabViewController.h"

@interface TagsViewController : BaseTabViewController<UIAlertViewDelegate>

@property NSMutableArray *customTags;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) NSString *selectedTag;
@property (weak, nonatomic) IBOutlet UILabel *loggedInAsLabel;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

- (void)librefmDidLoadTopTags:(BOOL)ok
                         tags:(NSDictionary*)tags;

- (void)librefmDidLogin:(BOOL)ok
               username:(NSString*)username
               password:(NSString*)password
                  error:(NSError *)error;

- (void)librefmDidLogout;

- (IBAction)loginButtonClicked:(id)sender;
- (IBAction)iconsWebsiteButton:(id)sender;
- (void)addTag:(NSString*)tag;
- (void)removeSelectedTag;

@end
