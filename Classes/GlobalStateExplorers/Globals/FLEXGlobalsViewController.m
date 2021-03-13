//
//  FLEXGlobalsViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 2014-05-03.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXGlobalsViewController.h"
#import "FLEXUtility.h"
//#import "FLEXRuntimeUtility.h"
//#import "FLEXObjcRuntimeViewController.h"
//#import "FLEXGlobalsEntry.h"
#import "FLEXManager+Private.h"
#import "FLEXNetworkMITMViewController.h"
#import "FLEXGlobalsSection.h"
#import "UIBarButtonItem+FLEX.h"

@interface FLEXGlobalsViewController ()
/// Only displayed sections of the table view; empty sections are purged from this array.
@property (nonatomic) NSArray<FLEXGlobalsSection *> *sections;
/// Every section in the table view, regardless of whether or not a section is empty.
@property (nonatomic, readonly) NSArray<FLEXGlobalsSection *> *allSections;
@property (nonatomic, readonly) BOOL manuallyDeselectOnAppear;
@end

@implementation FLEXGlobalsViewController
@dynamic sections, allSections;

#pragma mark - Initialization

+ (NSString *)globalsTitleForSection:(FLEXGlobalsSectionKind)section {
    switch (section) {
        case FLEXGlobalsSectionCustom:
            return @"Custom Additions";
        case FLEXGlobalsSectionProcessAndEvents:
            return @"Process and Events";
        case FLEXGlobalsSectionAppShortcuts:
            return @"App Shortcuts";
        case FLEXGlobalsSectionMisc:
            return @"Miscellaneous";

        default:
            @throw NSInternalInconsistencyException;
    }
}

+ (FLEXGlobalsEntry *)globalsEntryForRow:(FLEXGlobalsRow)row {
    switch (row) {
        case FLEXGlobalsRowNetworkHistory:
            return [FLEXNetworkMITMViewController flex_concreteGlobalsEntry:row];
        default:
            @throw [NSException
                exceptionWithName:NSInternalInconsistencyException
                reason:@"Missing globals case in switch" userInfo:nil
            ];
    }
}

+ (NSArray<FLEXGlobalsSection *> *)defaultGlobalSections {
    static NSMutableArray<FLEXGlobalsSection *> *sections = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary<NSNumber *, NSArray<FLEXGlobalsEntry *> *> *rowsBySection = @{
            @(FLEXGlobalsSectionProcessAndEvents) : @[
                [self globalsEntryForRow:FLEXGlobalsRowNetworkHistory],
            ]
        };

        sections = [NSMutableArray array];
        for (FLEXGlobalsSectionKind i = FLEXGlobalsSectionCustom + 1; i < FLEXGlobalsSectionCount; ++i) {
            NSString *title = [self globalsTitleForSection:i];
            [sections addObject:[FLEXGlobalsSection title:title rows:rowsBySection[@(i)]]];
        }
    });
    
    return sections;
}


#pragma mark - Overrides

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"💪  FLEX";
    self.showsSearchBar = YES;
    self.searchBarDebounceInterval = kFLEXDebounceInstant;
    self.navigationItem.backBarButtonItem = [UIBarButtonItem flex_backItemWithTitle:@"Back"];
    
    _manuallyDeselectOnAppear = NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 10;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self disableToolbar];
    
    if (self.manuallyDeselectOnAppear) {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }
}

- (NSArray<FLEXGlobalsSection *> *)makeSections {
    NSMutableArray<FLEXGlobalsSection *> *sections = [NSMutableArray array];
    // Do we have custom sections to add?
    if (FLEXManager.sharedManager.userGlobalEntries.count) {
        NSString *title = [[self class] globalsTitleForSection:FLEXGlobalsSectionCustom];
        FLEXGlobalsSection *custom = [FLEXGlobalsSection
            title:title
            rows:FLEXManager.sharedManager.userGlobalEntries
        ];
        [sections addObject:custom];
    }

    [sections addObjectsFromArray:[self.class defaultGlobalSections]];

    return sections;
}

@end
