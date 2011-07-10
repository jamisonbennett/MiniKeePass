/*
 * Copyright 2011 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "EntryViewController.h"

@implementation EntryViewController

@synthesize entry;
@synthesize isNewEntry;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delaysContentTouches = YES;

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    [cancelButton release];    
    
    appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    titleCell = [[TitleFieldCell alloc] init];
    titleCell.textLabel.text = @"Title";
    titleCell.textField.delegate = self;
    titleCell.textField.returnKeyType = UIReturnKeyNext;
    
    imageButtonCell = [[ImageButtonCell alloc] initWithLabel:@"Image"];
    [imageButtonCell.imageButton addTarget:self action:@selector(imageButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    usernameCell = [[TextFieldCell alloc] init];
    usernameCell.textLabel.text = @"Username";
    usernameCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    usernameCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    usernameCell.textField.delegate = self;
    usernameCell.textField.returnKeyType = UIReturnKeyNext;
    
    passwordCell = [[PasswordFieldCell alloc] init];
    passwordCell.textLabel.text = @"Password";
    passwordCell.textField.delegate = self;
    passwordCell.textField.returnKeyType = UIReturnKeyNext;
    
    urlCell = [[UrlFieldCell alloc] init];
    urlCell.textLabel.text = @"URL";
    urlCell.textField.delegate = self;
    urlCell.textField.returnKeyType = UIReturnKeyDone;
    
    commentsCell = [[TextViewCell alloc] init];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPressed)];
    [self.view addGestureRecognizer:tapGesture];
    [tapGesture release];
}

- (void)dealloc {
    [titleCell release];
    [usernameCell release];
    [passwordCell release];
    [urlCell release];
    [commentsCell release];
    [entry release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Mark the view as not being canceled
    canceled = NO;
    
    // Add listeners to the keyboard
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    // Update the fields
    titleCell.textField.text = entry.title;
    
    selectedImageIndex = entry.image;
    [imageButtonCell.imageButton setImage:[appDelegate loadImage:entry.image] forState:UIControlStateNormal];
    
    usernameCell.textField.text = entry.username;
    passwordCell.textField.text = entry.password;
    urlCell.textField.text = entry.url;
    commentsCell.textView.text = entry.notes;
    
    if (isNewEntry) {
        [titleCell.textField becomeFirstResponder];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    originalHeight = self.view.frame.size.height;
}

- (void)viewWillDisappear:(BOOL)animated {
    if (!canceled && [self isDirty]) {
        entry.title = titleCell.textField.text;
        entry.username = usernameCell.textField.text;
        entry.password = passwordCell.textField.text;
        entry.url = urlCell.textField.text;
        entry.notes = commentsCell.textView.text;
        
        appDelegate.databaseDocument.dirty = YES;
        
        // Save the database document
        [appDelegate.databaseDocument save];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Remove listeners from the keyboard
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationWillResignActive:(id)sender {
    // Resign first responder to prevent password being in sight and UI glitchs
    [titleCell.textField resignFirstResponder];
    [usernameCell.textField resignFirstResponder];
    [passwordCell.textField resignFirstResponder];
    [urlCell.textField resignFirstResponder];
    [commentsCell.textView resignFirstResponder];
}

- (void)cancelPressed {
    canceled = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

BOOL stringsEqual(NSString *str1, NSString *str2) {
    str1 = str1 == nil ? @"" : [str1 stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    str2 = str2 == nil ? @"" : [str2 stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    return [str1 isEqualToString:str2];
}

- (BOOL)isDirty {
    return !(stringsEqual(entry.title, titleCell.textField.text) &&
        entry.image == selectedImageIndex &&
        stringsEqual(entry.username, usernameCell.textField.text) &&
        stringsEqual(entry.password, passwordCell.textField.text) &&
        stringsEqual(entry.url, urlCell.textField.text) &&
        stringsEqual(entry.notes, commentsCell.textView.text));
}

- (void)tapPressed {
    [titleCell.textField resignFirstResponder];
    [usernameCell.textField resignFirstResponder];
    [passwordCell.textField resignFirstResponder];
    [urlCell.textField resignFirstResponder];
    [commentsCell.textView resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == titleCell.textField) {
        [usernameCell.textField becomeFirstResponder];
    } else if (textField == usernameCell.textField) {
        [passwordCell.textField becomeFirstResponder];
    } else if (textField == passwordCell.textField) {
        [urlCell.textField becomeFirstResponder];
    } else if (textField == urlCell.textField) {
        [urlCell.textField resignFirstResponder];
    }
    
    return NO;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 5;
        case 1:
            return 1;
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return 40;
        case 1:
            return 104;
    }
    
    return 40;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return nil;
        case 1:
            return @"Comments";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    return titleCell;
                case 1:
                    return imageButtonCell;
                case 2:
                    return usernameCell;
                case 3:
                    return passwordCell;
                case 4:
                    return urlCell;
            }
        case 1:
            return commentsCell;
    }
    
    return nil;
}

- (void)imageButtonPressed {
    ImagesViewController *imagesViewController = [[ImagesViewController alloc] init];
    imagesViewController.delegate = self;
    [imagesViewController setSelectedImage:entry.image];
    [self.navigationController pushViewController:imagesViewController animated:YES];
    [imagesViewController release];
}

- (void)imagesViewController:(ImagesViewController *)controller imageSelected:(NSUInteger)index {
    selectedImageIndex = index;
}

@end
