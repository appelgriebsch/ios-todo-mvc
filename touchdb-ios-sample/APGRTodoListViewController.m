//
//  APGRViewController.m
//  touchdb-ios-sample
//
//  Created by Andreas Gerlach on 9/30/13.
//  Copyright (c) 2013 Appelgriebsch. All rights reserved.
//

#import "APGRTodoListViewController.h"
#import "APGRTodoListItemCell.h"
#import "APGRTodoItemViewController.h"
#import <CouchbaseLite/CouchbaseLite.h>

@interface APGRTodoListViewController ()

@property(nonatomic, strong)CBLDatabase *database;
@property(nonatomic, strong)NSURL* remoteSyncURL;

@property(nonatomic, strong)CBLReplication* pullReplication;
@property(nonatomic, strong)CBLReplication* pushReplication;

@property(nonatomic, strong)NSError* lastSyncError;

@end

@implementation APGRTodoListViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startSync)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:[NSUserDefaults standardUserDefaults]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Initialize Couchbase Lite and find/create my database:
    NSError* error;
    self.database = [[CBLManager sharedInstance] createDatabaseNamed: @"todo-items"
                                                               error: &error];
    if (!self.database)
        [self showAlert: @"Couldn't open database" error: error fatal: YES];

    // Define a view with a map function that indexes to-do items by creation date:
    [[self.database viewNamed: @"byDate"] setMapBlock: MAPBLOCK({
        
        id date = doc[@"created"];
        if (date)
            emit(date, doc);
        
    }) reduceBlock: nil version: @"1.1"];
    
    CBLLiveQuery* query = [[[self.database viewNamed:@"byDate"] query] asLiveQuery];
    query.descending = YES;
    
    self.dataSource.query = query;
    self.dataSource.labelProperty = @"title";
    
    [self startSync];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    
    [self stopSync];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Synchronization

- (void) startSync {
    
    if (!self.database)
        return;
    
    // setup bi-directional synchronization
    NSString* user = [[NSUserDefaults standardUserDefaults] stringForKey:@"user"];
    NSString* pwd = [[NSUserDefaults standardUserDefaults] stringForKey:@"pwd"];
    NSURL* url = [[NSUserDefaults standardUserDefaults] URLForKey:@"url"];
    BOOL bReplicationEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"replEnabled"];
    
    if (!url || !user || !pwd)
        return;
    
    [self stopSync];        // stop old synchronization (if still running)

    if (bReplicationEnabled) {
 
        int port = url.port.intValue ? url.port.intValue : ([url.scheme compare:@"http"] == 0 ? 80 : 433);
        NSString* serverUrl = [NSString stringWithFormat:@"%@://%@:%@@%@:%d%@", url.scheme, user, pwd, url.host, port, url.path];
        
        self.pushReplication = [self.database pushToURL:[NSURL URLWithString:serverUrl]];
        self.pullReplication = [self.database pullFromURL:[NSURL URLWithString:serverUrl]];
        self.pullReplication.filter = @"app/byUser";

        self.pushReplication.continuous = self.pullReplication.continuous = YES;
        
        NSLog(@"Starting sync w/ new server setting %@", [[NSUserDefaults standardUserDefaults] URLForKey:@"url"]);
    
        NSNotificationCenter* notific = [NSNotificationCenter defaultCenter];
        
        [notific addObserver: self selector: @selector(replicationProgress:)
                        name: kCBLReplicationChangeNotification object: self.pullReplication];
        
        [notific addObserver: self selector: @selector(replicationProgress:)
                        name: kCBLReplicationChangeNotification object: self.pushReplication];
        
        [self.pushReplication start];
        [self.pullReplication start];
    }
}

- (void) stopSync {
    
    NSNotificationCenter* notific = [NSNotificationCenter defaultCenter];
    
    if (self.pullReplication) {
        
        [self.pullReplication stop];
        [notific removeObserver:self name:NULL object:self.pullReplication];
        self.pullReplication = nil;
    }
    
    if (self.pushReplication) {
        
        [self.pushReplication stop];
        [notific removeObserver:self name:NULL object:self.pushReplication];
        self.pushReplication = nil;
    }
}

- (void) replicationProgress:(NSNotificationCenter *)n {
    
    if (self.pullReplication.mode == kCBLReplicationActive || self.pushReplication.mode == kCBLReplicationActive) {
        
        // Sync is active -- aggregate the progress of both replications and compute a fraction:
        unsigned completed = self.pullReplication.completed + self.pushReplication.completed;
        unsigned total = self.pullReplication.total + self.pushReplication.total;
        
        NSLog(@"SYNC progress: %u / %u", completed, total);
        
        self.progressBar.hidden = NO;
        
        // Update the progress bar, avoiding divide-by-zero exceptions:
        self.progressBar.progress = (completed / (float) MAX(total, 1u));
        
    } else {
        
        // Sync is idle -- hide the progress bar
        self.progressBar.hidden = YES;
    }
    
    // Check for any change in error status and display new errors:
    NSError* error = self.pullReplication.error ? self.pullReplication.error : self.pushReplication.error;

    if (error != self.lastSyncError) {
        
        self.lastSyncError = error;
        
        if (error)
            [self showAlert:@"Sync Error" error:error fatal:NO];
    }
}

#pragma mark Table View handling

- (UITableViewCell *)couchTableSource:(CBLUITableSource *)source
                cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;

    cell = [source.tableView dequeueReusableCellWithIdentifier:@"todolist-item"];
    
    if (cell) {
        
        APGRTodoListItemCell *todoCell = (APGRTodoListItemCell *)cell;
        CBLQueryRow *row = [source rowAtIndexPath:indexPath];
        CBLDocument *doc = row.document;
        
        todoCell.document = doc;
    }
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"showTodoItemSegue"]) {
        
        APGRTodoItemViewController* itemViewController = segue.destinationViewController;
        APGRTodoListItemCell* item = sender;
        
        itemViewController.document = item.document;
    }
    else if ([segue.identifier isEqualToString:@"createTodoItemSegue"]) {

        APGRTodoItemViewController* itemViewController = segue.destinationViewController;
        CBLDocument* newDocument = [self.database untitledDocument];
        itemViewController.document = newDocument;
    }
}

#pragma mark Alert Handling

- (void)showAlert: (NSString *)message error: (NSError *)error fatal: (BOOL)fatal {
    
    if (error) {
        
        message = [NSString stringWithFormat: @"%@\n\n%@", message, error.localizedDescription];
    }
    
    NSLog(@"ALERT: %@ (error=%@)", message, error);
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: (fatal ? @"Fatal Error" : @"Error")
                                                    message: message
                                                   delegate: (fatal ? self : nil)
                                          cancelButtonTitle: (fatal ? @"Quit" : @"Sorry")
                                          otherButtonTitles: nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    exit(0);
}


@end
