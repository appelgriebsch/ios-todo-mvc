//
//  APGRViewController.h
//  touchdb-ios-sample
//
//  Created by Andreas Gerlach on 9/30/13.
//  Copyright (c) 2013 Appelgriebsch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Couchbaselite/CBLUITableSource.h> 

@class CBLDatabase, CBLReplication;

@interface APGRTodoListViewController : UIViewController<CBLUITableDelegate, UITextFieldDelegate>

@property(nonatomic, strong) IBOutlet UITableView *tableView;
@property(nonatomic, strong) IBOutlet UIProgressView *progressBar;
@property(nonatomic, strong) IBOutlet CBLUITableSource* dataSource;

@end
