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

@interface TagsViewController : BaseTabViewController

@property NSMutableArray *customTags;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

- (void)librefmDidLoadTopTags:(BOOL)ok
                         tags:(NSDictionary*)tags;

- (void)addTag:(NSString*)tag;

@end
