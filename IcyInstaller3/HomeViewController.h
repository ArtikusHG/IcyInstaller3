//
//  HomeViewController.h
//  IcyInstaller3
//
//  Created by ArtikusHG on 7/20/18.
//  Copyright © 2018 ArtikusHG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IcyUniversalMethods.h"
#import "IcyDPKGViewController.h"

@interface HomeViewController : UIViewController <UIWebViewDelegate>
+ (UIWebView *)getWelcomeWebView;
- (void)load;
@end
