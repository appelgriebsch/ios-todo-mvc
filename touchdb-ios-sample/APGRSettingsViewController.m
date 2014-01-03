//
//  APGRSettingsViewController.m
//  touchdb-ios-sample
//
//  Created by Andreas Gerlach on 9/30/13.
//  Copyright (c) 2013 Appelgriebsch. All rights reserved.
//

#import "APGRSettingsViewController.h"

@interface APGRSettingsViewController ()

@property(nonatomic, strong) NSURL* couchDBServerUrl;
@property (weak, nonatomic) IBOutlet UITextField *couchDBUrlEntry;
@property (weak, nonatomic) IBOutlet UISwitch *checkReplicationEnabled;

@end

@implementation APGRSettingsViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
    self.couchDBServerUrl = [[NSUserDefaults standardUserDefaults] URLForKey:@"url"];
    
    if (self.couchDBServerUrl)
        [self.couchDBUrlEntry setText:self.couchDBServerUrl.absoluteString];
    
    [self.checkReplicationEnabled setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"replEnabled"] animated:YES];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)checkReplicationEnabledChanged:(UISwitch *)sender {
    
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"replEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)editingEnded:(id)sender {
    
    [sender resignFirstResponder];
}

- (IBAction)databaseServerUrlChanged:(UITextField *)textField {
    
    if (textField.text.length > 0) {
        
        self.couchDBServerUrl = [NSURL URLWithString:textField.text];
        
        if (self.couchDBServerUrl.user.length == 0) {
            
            UIAlertView* credentials = [[UIAlertView alloc] initWithTitle:@"Login"
                                                                  message:@"Please provide your user credentials"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                        otherButtonTitles:@"Login", nil];
            
            credentials.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
            [credentials show];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        
        NSString* userName = [alertView textFieldAtIndex:0].text;
        NSString* pwd = [alertView textFieldAtIndex:1].text;
        
        [[NSUserDefaults standardUserDefaults] setObject:userName forKey:@"user"];
        [[NSUserDefaults standardUserDefaults] setObject:pwd forKey:@"pwd"];
        [[NSUserDefaults standardUserDefaults] setURL: self.couchDBServerUrl forKey:@"url"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end
