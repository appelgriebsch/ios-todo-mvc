//
//  APGRTodoItemViewController.h
//  touchdb-ios-sample
//
//  Created by Andreas Gerlach on 10/1/13.
//  Copyright (c) 2013 Appelgriebsch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface APGRTodoItemViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, weak) CBLDocument* document;

@end
