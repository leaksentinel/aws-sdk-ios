//
// Copyright 2010-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

#import "AWSUserPoolForgotPasswordViewController.h"
#import <AWSUserPoolsSignIn/AWSUserPoolsSignIn.h>
#import "AWSFormTableCell.h"
#import "AWSFormTableDelegate.h"
#import "AWSUserPoolsUIHelper.h"
#import <AWSAuthCore/AWSUIConfiguration.h>

@interface AWSUserPoolForgotPasswordViewController ()

@property (nonatomic, strong) AWSCognitoIdentityUserPool *pool;
@property (nonatomic, strong) AWSCognitoIdentityUser *user;
@property (nonatomic, strong) AWSFormTableCell *userNameRow;
@property (nonatomic, strong) AWSFormTableDelegate *tableDelegate;

@end

@interface AWSUserPoolNewPasswordViewController ()

@property (nonatomic, strong) AWSCognitoIdentityUser *user;
@property (nonatomic, strong) AWSFormTableCell *updatedPasswordRow;
@property (nonatomic, strong) AWSFormTableCell *confirmationCodeRow;
@property (nonatomic, strong) AWSFormTableDelegate *tableDelegate;

@end

@implementation AWSUserPoolForgotPasswordViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUp];
    self.pool = [AWSCognitoIdentityUserPool defaultCognitoIdentityUserPool];
}

// This is used to dismiss the keyboard, user just has to tap outside the
// user name and password views and it will dismiss
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch.phase == UITouchPhaseBegan) {
        [self.view endEditing:YES];
    }
    
    [super touchesBegan:touches withEvent:event];
}

- (void)setUp {
    _userNameRow = [[AWSFormTableCell alloc] initWithPlaceHolder:@"Email" type:InputTypeText];
    _tableDelegate = [AWSFormTableDelegate new];
    [self.tableDelegate addCell:self.userNameRow];
    self.tableView.delegate = self.tableDelegate;
    self.tableView.dataSource = self.tableDelegate;
    [self.tableView reloadData];
    [AWSUserPoolsUIHelper setUpFormShadowForView:self.tableFormView];
    [self setUpBackground];
}

- (void)setUpBackground {
    if ([AWSUserPoolsUIHelper isBackgroundColorFullScreen:self.config]) {
        self.view.backgroundColor = [AWSUserPoolsUIHelper getBackgroundColor:self.config];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    self.title = @"Forgot Password";
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.tableFormView.center.y)];
    backgroundImageView.backgroundColor = [AWSUserPoolsUIHelper getBackgroundColor:self.config];
    backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view insertSubview:backgroundImageView atIndex:0];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([@"NewPasswordSegue" isEqualToString:segue.identifier]){
        AWSUserPoolNewPasswordViewController * confirmForgot = segue.destinationViewController;
        confirmForgot.config = self.config;     // fixes bgd color bug
        confirmForgot.user = self.user;
    }
}

- (IBAction)onForgotPassword:(id)sender {
    NSString *userName = [self.tableDelegate getValueForCell:self.userNameRow forTableView:self.tableView];
    if ([userName isEqualToString:@""]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Missing Email"
                                                                                 message:@"Please enter a valid email address."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController
                           animated:YES
                         completion:nil];
        return;
    }
    self.user = [self.pool getUser:userName];
    [[self.user forgotPassword] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserForgotPasswordResponse *> * _Nonnull task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(task.error){
                
                // replace poor AWS error messages with user-friendly versions
                NSErrorUserInfoKey errorType = task.error.userInfo[@"__type"];
                NSErrorUserInfoKey errorTitle = @"Error";
                NSErrorUserInfoKey errorMessage = task.error.userInfo[@"message"];
                
                if([errorType  isEqual: @"UserNotFoundException"]) {
                    errorTitle = @"Account Not Found";
                    errorMessage = @"We couldn't find an account associated with that email address.";
                }
         
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:errorTitle
                                                      message:errorMessage
                                               preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:ok];
                [self presentViewController:alertController
                                   animated:YES
                                 completion:nil];
            }else {
                [self performSegueWithIdentifier:@"NewPasswordSegue" sender:sender];
            }
        });
        return nil;
    }];
}

@end

@implementation AWSUserPoolNewPasswordViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUp];
}

// This is used to dismiss the keyboard, user just has to tap outside the
// user name and password views and it will dismiss
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch.phase == UITouchPhaseBegan) {
        [self.view endEditing:YES];
    }
    
    [super touchesBegan:touches withEvent:event];
}

- (void)setUp {
    _confirmationCodeRow = [[AWSFormTableCell alloc] initWithPlaceHolder:@"Verification Code" type:InputTypeText];
    _updatedPasswordRow = [[AWSFormTableCell alloc] initWithPlaceHolder:@"New Password" type:InputTypePassword];
    _tableDelegate = [AWSFormTableDelegate new];
    [self.tableDelegate addCell:self.confirmationCodeRow];
    [self.tableDelegate addCell:self.updatedPasswordRow];
    self.tableView.delegate = self.tableDelegate;
    self.tableView.dataSource = self.tableDelegate;
    [self.tableView reloadData];
    [AWSUserPoolsUIHelper setUpFormShadowForView:self.tableFormView];
    [self setUpBackground];
}

- (void)setUpBackground {
    if ([AWSUserPoolsUIHelper isBackgroundColorFullScreen:self.config]) {
        self.view.backgroundColor = [AWSUserPoolsUIHelper getBackgroundColor:self.config];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    self.title = @"Reset Password";
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.tableFormView.center.y)];
    backgroundImageView.backgroundColor = [AWSUserPoolsUIHelper getBackgroundColor:self.config];
    backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view insertSubview:backgroundImageView atIndex:0];
}

- (IBAction)onUpdatePassword:(id)sender {
    //confirm forgot password with input from ui.
    NSString *confirmationCode = [self.tableDelegate getValueForCell:self.confirmationCodeRow forTableView:self.tableView];
    NSString *updatedPassword = [self.tableDelegate getValueForCell:self.updatedPasswordRow forTableView:self.tableView];
    if ([confirmationCode isEqualToString:@""] || [updatedPassword isEqualToString:@""]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Missing Information"
                                                                                 message:@"Please enter valid verification code and password values."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController
                           animated:YES
                         completion:nil];
        return;
    }
    [[self.user confirmForgotPassword:confirmationCode password:updatedPassword] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserConfirmForgotPasswordResponse *> * _Nonnull task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(task.error){

                // replace poor AWS error messages with user-friendly versions
                NSErrorUserInfoKey errorType = task.error.userInfo[@"__type"];
                NSErrorUserInfoKey errorTitle = @"Error";
                NSErrorUserInfoKey errorMessage = task.error.userInfo[@"message"];
                
                if([errorType  isEqual: @"InvalidParameterException"]) {
                    if ([errorMessage containsString:@"greater than or equal to 6"]) {
                        errorMessage = @"Password must be at least 6 characters long.";
                        errorTitle = @"Password Strength";
                    }
                }

                if([errorType  isEqual: @"CodeMismatchException"]) {
                    if ([errorMessage containsString:@"Invalid verification code"]) {
                        errorMessage = @"Please enter a valid password reset code.";
                        errorTitle = @"Invalid Code";
                    }
                }

                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:errorTitle
                                                                                         message:errorMessage
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:ok];
                [self presentViewController:alertController
                                   animated:YES
                                 completion:nil];
                
            }else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Password Reset"
                                                                                         message:@"Your password was successfully reset."
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.navigationController popToRootViewControllerAnimated:YES];
                }];
                [alertController addAction:ok];
                [self presentViewController:alertController
                                   animated:YES
                                 completion:nil];
            }
        });
        return nil;
    }];
}

@end

