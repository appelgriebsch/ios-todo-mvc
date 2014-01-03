//
//  APGRTodoItemViewController.m
//  touchdb-ios-sample
//
//  Created by Andreas Gerlach on 10/1/13.
//  Copyright (c) 2013 Appelgriebsch. All rights reserved.
//

#import "APGRTodoItemViewController.h"

@interface APGRTodoItemViewController ()

@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (weak, nonatomic) IBOutlet UITableView *conflictRevisions;
@property (weak, nonatomic) IBOutlet UILabel *conflictRevLabel;

@property (strong, nonatomic) NSArray *conflicts;
@property (strong, nonatomic) CBLRevision *keepRevision;

@end

@implementation APGRTodoItemViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    NSDictionary* properties = [self.document properties];
    self.titleField.text = [properties valueForKey:@"title"];
    self.conflicts = [self.document getConflictingRevisions:nil];
    
    if (self.conflicts.count > 1) {
        [self.titleField setEnabled:FALSE];
        [self.conflictRevisions reloadData];
        [self.conflictRevisions setHidden:FALSE];
        [self.conflictRevLabel setHidden:FALSE];
    }
    else {
        [self.conflictRevisions setHidden:TRUE];
        [self.conflictRevLabel setHidden:TRUE];
    }
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setDocument:(CBLDocument *)document {
    
    _document = document;
}
- (IBAction)finishedEditing:(id)sender {
    
    [sender resignFirstResponder];
}

- (IBAction)save:(id)sender {
    
    if ([self.conflicts count] > 1) {
        
        NSError* error;
        for (CBLRevision* revision in self.conflicts) {
            
            if (revision == self.keepRevision)
                [[revision document] putProperties:[revision properties] error:&error];
            
            [revision deleteDocument:&error];
        }
    }
    else {
    
        NSMutableDictionary* newProps = nil;
        
        // is this a new document?
        if (!self.document.currentRevision) {
            
            newProps = [NSMutableDictionary dictionaryWithDictionary:
                        @{@"title": self.titleField.text,
                          @"type": @"todo",
                          @"finished": @"false",
                          @"created": [CBLJSON JSONObjectWithDate: [NSDate date]],
                          @"user": [[NSUserDefaults standardUserDefaults] stringForKey:@"user"]}];
        }
        else {
            
            newProps = [[self.document properties] mutableCopy];
            newProps[@"title"] = self.titleField.text;
        }
        
        NSError* error;
        [self.document putProperties:newProps error:&error];
    }

    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.conflicts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:@"todolist-item-rev"];
    
    if (!cell) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"todolist-item-rev"];
    }
    
    CBLRevision *docRev = [self.conflicts objectAtIndex:indexPath.row];
    NSDictionary *prop = [docRev properties];
    
    cell.textLabel.text = [prop valueForKey:@"title"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    self.keepRevision = [self.conflicts objectAtIndex:indexPath.row];
}

@end
