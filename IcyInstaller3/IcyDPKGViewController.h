//
//  IcyDPKGViewController.h
//  IcyInstaller3
//
//  Created by ArtikusHG on 10/26/18.
//  Copyright © 2018 ArtikusHG. All rights reserved.
//

#import <UIKit/UIKit.h>
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface IcyDPKGViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>

- (void)addItemToQuery:(NSString *)item;
- (void)addNameToQuery:(NSString *)name;
+ (void)respring;

@end
