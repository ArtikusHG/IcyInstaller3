//
//  ViewController.m
//  IcyInstaller3
//
//  Created by ArtikusHG on 2/8/18.
//  Copyright © 2018 ArtikusHG. All rights reserved.
//
#include <spawn.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <netdb.h>
#include "NSTask.h"
#import <dlfcn.h>
#import <sys/utsname.h>
#import "ViewController.h"
#import "HomeViewController.h"
#import "SourcesViewController.h"
#import "SearchViewController.h"
#import "ManageViewController.h"

@interface ViewController ()
// View Controllers
@property (strong, nonatomic) HomeViewController *homeViewController;
@property (strong, nonatomic) SourcesViewController *sourcesViewController;
@property (strong, nonatomic) SearchViewController *searchViewController;
@property (strong, nonatomic) ManageViewController *manageViewController;
@end

// Graceful closuer (by midnightchips)
@interface UIApplication (existing)
- (void)suspend;
- (void)terminateWithSuccess;
@end
@interface UIApplication (close)
- (void)close;
@end
@implementation UIApplication (close)

- (void)close {
    // Check if the current device supports background execution.
    BOOL multitaskingSupported = NO;
    // iOS < 4.0 compatibility check.
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) multitaskingSupported = [UIDevice currentDevice].multitaskingSupported;
    // Good practice, we're using a private method.
    if ([self respondsToSelector:@selector(suspend)]) {
        if (multitaskingSupported) {
            [self beginBackgroundTaskWithExpirationHandler:^{}];
            // Change the delay to your liking. I think 0.4 seconds feels just right (the "close" animation lasts 0.3 seconds).
            [self performSelector:@selector(exit) withObject:nil afterDelay:0.4];
        }
        [self suspend];
    }
    else [self exit];
}

- (void)exit {
    // Again, good practice.
    if ([self respondsToSelector:@selector(terminateWithSuccess)])
        [self terminateWithSuccess];
    else
        exit(EXIT_SUCCESS);
}

@end

@implementation ViewController
UIButton *_aboutButton;
NSUInteger oldApplications;
NSUInteger oldTweaks;

+ (UIButton *)getAboutButton {
    return _aboutButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Get device model and UDID
    struct utsname systemInfo;
    uname(&systemInfo);
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"udid"] == nil) [[NSUserDefaults standardUserDefaults] setObject:[self uniqueDeviceID] forKey:@"udid"];
    _deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    // Get arrays needed for reload
    oldApplications = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Applications/" error:nil].count;
    oldTweaks = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/MobileSubstrate/DynamicLibraries/" error:nil].count;
    // The navbar
    _navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 100)];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [UINavigationBar appearance].shadowImage = [UIImage new];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"darkMode"]) {
        _navigationBar.barTintColor = [UIColor blackColor];
        _navigationBar.backgroundColor = [UIColor blackColor];  
    } else {
        _navigationBar.barTintColor = [UIColor whiteColor];
        _navigationBar.backgroundColor = [UIColor whiteColor];
    }
    [self.view addSubview:_navigationBar];
    // Progress View
    // The button at the right
    _aboutButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 90,58,75,30)];
    _aboutButton.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.1];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"darkMode"]) [_aboutButton setTitle:@"Light" forState:UIControlStateNormal];
    else [_aboutButton setTitle:@"Dark" forState:UIControlStateNormal];
    [_aboutButton setTitleColor:[UIColor colorWithRed:0.00 green:0.52 blue:1.00 alpha:1.0] forState:UIControlStateNormal];
    [_aboutButton addTarget:self action:@selector(about) forControlEvents:UIControlEventTouchUpInside];
    [self makeViewRound:_aboutButton withRadius:5];
    [_navigationBar addSubview:_aboutButton];
    // The top label
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15,50,[UIScreen mainScreen].bounds.size.width - 130,40)];
    _nameLabel.backgroundColor = [UIColor clearColor];
    [_nameLabel setFont:[UIFont boldSystemFontOfSize:30]];
    _nameLabel.text = @"Home";
    [_navigationBar addSubview:_nameLabel];
    // The less top but still top label
    _dateLabel = [[UILabel alloc]initWithFrame:CGRectMake(15,30,[UIScreen mainScreen].bounds.size.width,20)];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitMonth fromDate:[NSDate date]];
    NSArray *weekdays = @[@"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday"];
    NSArray *months = @[@"January", @"February", @"March", @"April", @"May", @"June", @"July", @"August", @"September", @"October", @"November", @"December"];
    _dateLabel.text = [[NSString stringWithFormat:@"%@, %@ %zd",[weekdays objectAtIndex:[components weekday] - 1],[months objectAtIndex:[components month] - 1],(long)[components day]] uppercaseString];
    _dateLabel.textColor = [UIColor grayColor];
    [_dateLabel setFont:[UIFont boldSystemFontOfSize:13]];
    [_navigationBar addSubview:_dateLabel];
    // The tabbar
    _tabbar = [[UITabBar alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 49, [UIScreen mainScreen].bounds.size.width, 50)];
    _tabbar.delegate = self;
    NSMutableArray *tabBarItems = [[NSMutableArray alloc] initWithArray:@[[[UITabBarItem alloc] initWithTitle:@"Home" image:[UIImage imageNamed:@"icons/Home.png"] tag:0], [[UITabBarItem alloc] initWithTitle:@"Sources" image:[UIImage imageNamed:@"icons/Sources.png"] tag:1], [[UITabBarItem alloc] initWithTitle:@"Installed" image:[UIImage imageNamed:@"icons/Installed.png"] tag:2], [[UITabBarItem alloc] initWithTitle:@"Search" image:[UIImage imageNamed:@"icons/Search.png"] tag:3]]];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:10]} forState:UIControlStateNormal];
    _tabbar.items = tabBarItems;
    _tabbar.selectedItem = [tabBarItems objectAtIndex:0];
    [self.view addSubview:_tabbar];
    // View Controllers
    _homeViewController = [[HomeViewController alloc] init];
    _sourcesViewController = [[SourcesViewController alloc] init];
    _searchViewController = [[SearchViewController alloc] init];
    _manageViewController = [[ManageViewController alloc] init];
    [self.view addSubview:_homeViewController.view];
    [self.view addSubview:_sourcesViewController.view];
    [self.view addSubview:_searchViewController.view];
    [self.view addSubview:_manageViewController.view];
    _sourcesViewController.view.hidden = YES;
    _searchViewController.view.hidden = YES;
    _manageViewController.view.hidden = YES;
    // Fixup current views
    [self.view bringSubviewToFront:_tabbar];
    [self.view bringSubviewToFront:_navigationBar];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"darkMode"]) [self switchToDarkMode];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self loadStuff];
    });
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView == respringAlert && buttonIndex != [alertView cancelButtonIndex]) {
        pid_t pid;
        int status;
        const char *argv[] = {"killall", "-9", "backboardd", NULL};
        posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char**)argv, NULL);
        waitpid(pid, &status, 0);
    }
}

#pragma mark - Loading methods

- (void)loadStuff {
    // Check for needed directories
    if(![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Icy" isDirectory:nil]) [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Media/Icy" withIntermediateDirectories:NO attributes:nil error:nil];
    if(![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Icy/Repos" isDirectory:nil]) [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Media/Icy/Repos" withIntermediateDirectories:NO attributes:nil error:nil];
    if(![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Icy/Repos/updates" isDirectory:nil]) [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Media/Icy/Repos/updates" withIntermediateDirectories:NO attributes:nil error:nil];
    if(![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Icy/sources.list" isDirectory:nil]) [[NSFileManager defaultManager] createFileAtPath:@"/var/mobile/Media/Icy/sources.list" contents:nil attributes:nil];
    
    // Redirect log to a file
    freopen([@"/var/mobile/Media/Icy/log.txt" cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
    [[SourcesViewController getSourcesTableView] reloadData];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"darkMode"]) [self switchToDarkMode];
    else [self switchToLightMode];
}

UIAlertView *respringAlert;
- (void)respring {
    respringAlert = [[UIAlertView alloc] initWithTitle:@"Respring required" message:@"Would you like to respring right now?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [respringAlert show];
}

- (void)uicache {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reloading caches" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    [alert show];
    // Run uicache
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        pid_t pid;
        int status;
        const char *argv[] = {"uicache", NULL};
        posix_spawn(&pid, "/usr/bin/uicache", NULL, NULL, (char* const*)argv, NULL);
        waitpid(pid, &status, 0);
        [alert dismissWithClickedButtonIndex:0 animated:YES];
    });
}

- (void)willPresentAlertView:(UIAlertView *)alertView {
    [self.view endEditing:YES];
}

#pragma mark - Reload method

- (void)reload {
    NSArray *newApplications = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Applications/" error:nil];
    NSArray *newTweaks = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/MobileSubstrate/DynamicLibraries/" error:nil];
    if(newApplications.count != oldApplications) {
        oldApplications = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Applications/" error:nil].count;
        [self uicache];
    }
    if(newTweaks.count != oldTweaks) {
        oldTweaks = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/MobileSubstrate/DynamicLibraries/" error:nil].count;
        [self respring];
    }
}

- (void)about {
    if([_aboutButton.currentTitle isEqualToString:@"Dark"]) {
        [_aboutButton setTitle:@"Light" forState:UIControlStateNormal];
        [self switchToDarkMode];
        [[UIApplication sharedApplication] close];
        [[UIApplication sharedApplication] terminateWithSuccess];
    } else if([_aboutButton.currentTitle isEqualToString:@"Light"]) {
        [_aboutButton setTitle:@"Dark" forState:UIControlStateNormal];
        [self switchToLightMode];
        [[UIApplication sharedApplication] close];
        [[UIApplication sharedApplication] terminateWithSuccess];
    } else if([_aboutButton.currentTitle isEqualToString:@"Install"] && [SearchViewController getDepictionWebView].hidden) {
        [self messageWithTitle:@"Error" message:@"You need to search for a package first."];
    } else if([_aboutButton.currentTitle isEqualToString:@"Install"] && ![SearchViewController getDepictionWebView].hidden) {
        SearchViewController *searchViewController = [[SearchViewController alloc] init];
        [searchViewController downloadWithProgressAndURLString:[[SearchViewController getSearchFilenames] objectAtIndex:[SearchViewController getPackageIndex]] saveFilename:@"downloaded.deb"];
    } else if([_aboutButton.currentTitle isEqualToString:@"Backup"]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Backing up..." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
        [alert show];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Backup.txt"]) [[NSFileManager defaultManager] removeItemAtPath:@"/var/mobile/Backup.txt" error:nil];
            FILE *file = fopen("/var/lib/dpkg/status", "r");
            char str[999];
            while(fgets(str, 999, file) != NULL) {
                if(strstr(str, "Name:")) [[NSString stringWithFormat:@"%@%@", [[NSString stringWithContentsOfFile:@"/var/mobile/Backup.txt" encoding:NSUTF8StringEncoding error:nil] stringByReplacingOccurrencesOfString:@"(null)" withString:@""], [[NSString stringWithCString:str encoding:NSASCIIStringEncoding] stringByReplacingOccurrencesOfString:@"Name: " withString:@""]] writeToFile:@"/var/mobile/Backup.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
            }
            fclose(file);
            [alert dismissWithClickedButtonIndex:0 animated:YES];
            [alert release];
            [self messageWithTitle:@"Done" message:@"The package backup was saved to /var/mobile/Backup.txt"];
        });
    } else if([_aboutButton.currentTitle isEqualToString:@"Manage"]) [_sourcesViewController manage];
    else if([_aboutButton.currentTitle isEqualToString:@"Options"]) [_searchViewController showPackageOptions];
    else [self messageWithTitle:@"Some random shit happened" message:@"Literally the title."];
}

#pragma mark - Dark/light modes

- (void)switchToDarkMode {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"darkMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _aboutButton.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.1];
    [_aboutButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    [_toolbar setBarTintColor:[UIColor blackColor]];
    _nameLabel.textColor = [UIColor whiteColor];
    _navigationBar.backgroundColor = [UIColor blackColor];
    _tabbar.tintColor = [UIColor orangeColor];
    _tabbar.barTintColor = [UIColor blackColor];
    self.view.backgroundColor = [UIColor blackColor];
    [HomeViewController getWelcomeWebView].backgroundColor = [UIColor blackColor];
    [_homeViewController load];
    _sourcesViewController.view.backgroundColor = [UIColor blackColor];
    _manageViewController.view.backgroundColor = [UIColor blackColor];
    _searchViewController.view.backgroundColor = [UIColor blackColor];
    [SearchViewController getDismiss].backgroundColor = [UIColor blackColor];
    [SearchViewController getSearchField].textColor = [UIColor whiteColor];
    [SearchViewController getSearchField].keyboardAppearance = UIKeyboardAppearanceDark;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)switchToLightMode {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"darkMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _aboutButton.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.1];
    [_aboutButton setTitleColor:[UIColor colorWithRed:0.00 green:0.48 blue:1.00 alpha:1.0] forState:UIControlStateNormal];
    [_toolbar setBarTintColor:[UIColor whiteColor]];
    _nameLabel.textColor = [UIColor blackColor];
    _navigationBar.backgroundColor = [UIColor whiteColor];
    _tabbar.tintColor = [UIColor colorWithRed:0.00 green:0.48 blue:1.00 alpha:1.0];
    _tabbar.barTintColor = [UIColor whiteColor];
    self.view.backgroundColor = [UIColor whiteColor];
    [_homeViewController load];
    _sourcesViewController.view.backgroundColor = [UIColor whiteColor];
    _manageViewController.view.backgroundColor = [UIColor whiteColor];
    _searchViewController.view.backgroundColor = [UIColor whiteColor];
    [SearchViewController getDismiss].backgroundColor = [UIColor whiteColor];
    [SearchViewController getSearchField].textColor = [UIColor blackColor];
    [SearchViewController getSearchField].keyboardAppearance = UIKeyboardAppearanceLight;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Navigation methods

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    _nameLabel.text = item.title;
    _dateLabel.hidden = YES;
    if (tabBar.selectedItem.tag == 0) [self homeAction];
    else if(tabBar.selectedItem.tag == 1) [self sourcesAction];
    else if(tabBar.selectedItem.tag == 2) [self manageAction];
    else if(tabBar.selectedItem.tag == 3) [self searchAction];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"darkMode"]) [_aboutButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
    else [_aboutButton setTitleColor:[UIColor colorWithRed:0.00 green:0.52 blue:1.00 alpha:1.0] forState:UIControlStateNormal];
    [self.view bringSubviewToFront:_tabbar];
    [self.view bringSubviewToFront:_navigationBar];
}

- (void)homeAction {
    _dateLabel.hidden = NO;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"darkMode"]) [_aboutButton setTitle:@"Light" forState:UIControlStateNormal];
    else [_aboutButton setTitle:@"Dark" forState:UIControlStateNormal];
    _homeViewController.view.hidden = NO;
    [self.view bringSubviewToFront:_homeViewController.view];
}
- (void)sourcesAction {
    [_aboutButton setTitle:@"Manage" forState:UIControlStateNormal];
    _sourcesViewController.view.hidden = NO;
    [self.view bringSubviewToFront:_sourcesViewController.view];
}
- (void)manageAction {
    [_aboutButton setTitle:@"Backup" forState:UIControlStateNormal];
    _manageViewController.view.hidden = NO;
    [self.view bringSubviewToFront:_manageViewController.view];
}

- (void)searchAction {
    if([SearchViewController getOptions]) [_aboutButton setTitle:@"Options" forState:UIControlStateNormal];
    else [_aboutButton setTitle:@"Install" forState:UIControlStateNormal];
    _searchViewController.view.hidden = NO;
    [self.view bringSubviewToFront:_searchViewController.view];
}

#pragma mark - Small but useful bits of code

- (void)messageWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
    [alert show];
}

- (void)makeViewRound:(UIView *)view withRadius:(int)radius {
    view.layer.masksToBounds = YES;
    view.layer.cornerRadius = radius;
}

#pragma mark - UI Orientation methods

// Buggy. Way too buggy.
/*- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if(UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) [self changeToPortrait];
    else if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) [self changeToLandscape];
}*/

- (BOOL)shouldAutorotate {
    if([(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"]) return NO;
    else return YES;
}

- (void)changeToPortrait {
    if([SearchViewController getProgressTextView].text.length > 2) return;
    else [SearchViewController dismissDepiction];
    _tabbar.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 49, [UIScreen mainScreen].bounds.size.width, 50);
    if([(NSString*)[UIDevice currentDevice].model hasPrefix:@"iPad"]) _tabbar.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.width - 49, [UIScreen mainScreen].bounds.size.height, 50);
    _navigationBar.frame = CGRectMake(_navigationBar.frame.origin.x, _navigationBar.frame.origin.y, [UIScreen mainScreen].bounds.size.width, 100);
    [HomeViewController getWelcomeWebView].frame = CGRectMake(0,100,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height - 100);
    [SourcesViewController getSourcesTableView].frame = CGRectMake(0,100,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height - 100);
    [ManageViewController getManageTableView].frame = CGRectMake(0,100,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height - 100);
    [SearchViewController getSearchField].frame = CGRectMake(15,100,[UIScreen mainScreen].bounds.size.width - 30,35);
    [SearchViewController getSearchTableView].frame = CGRectMake(0,150,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height - 100);
    [ManageViewController dismissInfo];
}

- (void)changeToLandscape {
    if([SearchViewController getProgressTextView].text.length > 2) return;
    else [SearchViewController dismissDepiction];
    _tabbar.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.width - 49, [UIScreen mainScreen].bounds.size.height, 50);
    _navigationBar.frame = CGRectMake(_navigationBar.frame.origin.x, _navigationBar.frame.origin.y, [UIScreen mainScreen].bounds.size.height, 100);
    [HomeViewController getWelcomeWebView].frame = CGRectMake(0,100,[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width - 100);
    [SourcesViewController getSourcesTableView].frame = CGRectMake(0,100,[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width - 100);
    [ManageViewController getManageTableView].frame = CGRectMake(0,100,[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width - 100);
    [SearchViewController getSearchField].frame = CGRectMake(15,100,[UIScreen mainScreen].bounds.size.height - 30,35);
    [SearchViewController getSearchTableView].frame = CGRectMake(0,150,[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width - 100);
    [ManageViewController dismissInfo];
}

#pragma mark - Random backend methods
- (NSString *)runCommandWithOutput:(NSString *)command withArguments:(NSArray *)args errors:(BOOL)errors {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:command];
    [task setCurrentDirectoryPath:@"/"];
    [task setArguments:args];
    NSPipe *out = [NSPipe pipe];
    NSPipe *err = [NSPipe pipe];
    [task setStandardOutput:out];
    [task setStandardError:err];
    [task launch];
    [task waitUntilExit];
    [task release];
    if(errors) return [[[NSString alloc] initWithData:[[err fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];
    else return [[[NSString alloc] initWithData:[[out fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];
}

#pragma mark - Random methods

- (void)dealloc {
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)isNetworkAvailable {
    char *hostname;
    struct hostent *hostinfo;
    hostname = "google.com";
    hostinfo = gethostbyname (hostname);
    if (hostinfo == NULL) return NO;
    else return YES;
}

OBJC_EXTERN CFStringRef MGCopyAnswer(CFStringRef key) WEAK_IMPORT_ATTRIBUTE;
- (NSString *)uniqueDeviceID {
    CFStringRef udid = MGCopyAnswer(CFSTR("UniqueDeviceID"));
    return (NSString *)udid;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"darkMode"]) return UIStatusBarStyleLightContent;
    else return UIStatusBarStyleDefault;
}

@end
