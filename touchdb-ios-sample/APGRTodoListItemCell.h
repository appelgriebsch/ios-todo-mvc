//
//  APGRTodoListitemCell.h
//  touchdb-ios-sample
//
//  Created by Andreas Gerlach on 9/30/13.
//  Copyright (c) 2013 Appelgriebsch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CouchbaseLite/CouchbaseLite.h>

@interface APGRTodoListItemCell : UITableViewCell

@property(nonatomic, weak) CBLDocument* document;

@end
