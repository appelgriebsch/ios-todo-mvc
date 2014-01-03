//
//  APGRTodoListitemCell.m
//  touchdb-ios-sample
//
//  Created by Andreas Gerlach on 9/30/13.
//  Copyright (c) 2013 Appelgriebsch. All rights reserved.
//

#import "APGRTodoListItemCell.h"

@interface APGRTodoListItemCell()

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UISwitch *finished;

@end

@implementation APGRTodoListItemCell

- (IBAction)todoListItemFinished:(id)sender {
    
    NSMutableDictionary* dictProps = [[self.document properties] mutableCopy];
    
    BOOL wasFinished = [dictProps[@"finished"] boolValue];
    
    dictProps[@"finished"] = wasFinished ? @"false" : @"true";
    
    NSError* error;
    [[self.document currentRevision] putProperties:dictProps error:&error];
}

- (void) setDocument:(CBLDocument *)document {
    
    _document = document;
    
    NSDictionary *values = [document properties];
    
    self.title.text = [values valueForKey:@"title"];
    self.finished.on = [[values valueForKey:@"finished"] boolValue];
    
    if ([[self.document getConflictingRevisions:nil] count] > 1) {
        self.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
