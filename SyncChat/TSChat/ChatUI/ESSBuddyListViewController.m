//
//  TSBuddyListViewController.m
//  TSChat
//
//  Created by essadmin on 5/2/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "ESSBuddyListViewController.h"

@interface ESSBuddyListViewController ()
{
    BOOL isGroupSelected;
    int selectedGroupIndex;
    BOOL isSideViewDisplayed;
    int alertIndex ;
}
- (IBAction)signOut:(id)sender;
@end

@implementation ESSBuddyListViewController
/*
 #define profileImageSize 40
 #define profileSornerRadius 20
 #define messageTextFeildWidth 240
 #define messageFont @"Arial Rounded MT Bold"
 */
@synthesize  userSelected;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textColor = [UIColor darkTextColor];
        titleLabel.font = [UIFont boldSystemFontOfSize:10.0];
        titleLabel.numberOfLines = 1;
        titleLabel.adjustsFontSizeToFitWidth = YES;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        
        if ([[ESSHelper appDelegate] connect])
        {
            titleLabel.text = [[[[ESSHelper appDelegate] xmppStream] myJID] bare];
        } else
        {
            titleLabel.text = @"No JID";
        }
        [titleLabel sizeToFit];
        self.navigationItem.titleView = titleLabel;
    }
    return self;
}
- (UIBarButtonItem *)backButton
{
    UIImage *image = [UIImage imageNamed:@"menuBTN.png"];
    CGRect buttonFrame = CGRectMake(0, 5, 35, 35);
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    [button addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:image forState:UIControlStateNormal];
    
    UIBarButtonItem *item= [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return item;
}
-(IBAction)backButtonPressed:(id)sender {
    //[[ESSHelper appDelegate] disconnect];
    // [self.navigationController popViewControllerAnimated:YES];
    _sideView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"BG.jpeg"]];
    if (isSideViewDisplayed) {
        
        isSideViewDisplayed = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.sideView.frame=CGRectMake(self.sideView.frame.origin.x+160,self.sideView.frame.origin.y,self.sideView.frame.size.width, self.sideView.frame.size.height);
        } completion:^(BOOL finished){
        }];
        
    }else{
        isSideViewDisplayed = YES;
        [UIView animateWithDuration:0.3 animations:^{
            self.sideView.frame=CGRectMake(self.sideView.frame.origin.x-160,self.sideView.frame.origin.y,self.sideView.frame.size.width, self.sideView.frame.size.height);
        } completion:^(BOOL finished){
        }];    }
    
}



// navigate to Sync lock Screen
-(void)NavigateToSync:(NSNotification *)notify{
    
    if(![self.navigationController.visibleViewController isKindOfClass:[ESSSyncViewController class]])
        [self performSegueWithIdentifier:@"segueToSync" sender:nil];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    isSideViewDisplayed = YES;
    [ESSMUCManager sharedInstance].rooomArray=[[NSMutableArray alloc] init];
    self.navigationController.navigationBar.hidden = NO;
    self.navigationItem.leftBarButtonItem=[self backButton];
    self.navigationItem.rightBarButtonItem=[ESSHelper loggedInUserProfileImageBarButton];
    if (_groupFriendSegment.selectedSegmentIndex == 0) {
        _addGroup.hidden=YES;
        _addFriedn.hidden=NO;
    }
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(NavigateToSync:)
                                                name:@"HMIStatusFullForNavigate"
                                              object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(reloadTableData)
                                                name:@"GroupTableDataload"
                                              object:nil];
    
    
    // Do any additional setup after loading the view.
    _buddyListTable.backgroundColor=[UIColor clearColor];
    _buddyListTable.separatorColor=[UIColor blackColor];
    _buddyListTable.rowHeight=47;
    [_buddyListTable reloadData];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark Accessors


/*- (ESSAppDelegate *)appDelegate
 {
 return (ESSAppDelegate *)[[UIApplication sharedApplication] delegate];
 }*/

#pragma mark View lifecycle


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated
{
    
	[super viewWillDisappear:animated];
}

- (IBAction)signOut:(id)sender{
    [[ESSHelper appDelegate] disconnect];
	[[[ESSHelper appDelegate] xmppvCardTempModule] removeDelegate:self];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:kXMPPmyJID];
    [[NSUserDefaults standardUserDefaults]removeObjectForKey:kXMPPmyPassword];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark NSFetchedResultsController


- (NSFetchedResultsController *)fetchedResultsController
{
	if (fetchedResultsController == nil)
	{
		NSManagedObjectContext *moc = [[ESSHelper appDelegate] managedObjectContext_roster];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
		                                          inManagedObjectContext:moc];
		
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
		NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
		
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:10];
		
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:moc
		                                                                 sectionNameKeyPath:@"sectionNum"
		                                                                          cacheName:nil];
        
        [fetchedResultsController setDelegate:self];
        
  		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error])
		{
			DDLogError(@"Error performing fetch: %@", error);
		}
        
	}
	
	return fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // self.buddyListTable.rowHeight = 80;
    NSLog(@"%@",controller.cacheName) ;
	[[self buddyListTable] reloadData];
}

- (void)tableUpdate:(NSNotification *)notfy{
    [[self buddyListTable] reloadData];
}
- (void)configurePhotoForCell:(UITableViewCell *)cell user:(XMPPUserCoreDataStorageObject *)user
{
	// Our xmppRosterStorage will cache photos as they arrive from the xmppvCardAvatarModule.
	// We only need to ask the avatar module for a photo, if the roster doesn't have it.
	
	if (user.photo != nil)
	{
		cell.imageView.image = user.photo;
	}
	else
	{
		NSData *photoData = [[[ESSHelper appDelegate] xmppvCardAvatarModule] photoDataForJID:user.jid];
        
		if (photoData != nil){
            cell.imageView.frame = CGRectMake(5, 5, 50, 50);
			cell.imageView.image = [UIImage imageWithData:photoData];
        }
		else{
            cell.imageView.frame = CGRectMake(5, 5, 50, 50);
			cell.imageView.image = [UIImage imageNamed:@"images.png"];
        }
	}
}
-(UIView *)getProfileImageView:(XMPPUserCoreDataStorageObject *)user {
    
    UIImageView * profileFrame=[[UIImageView alloc ] initWithFrame:CGRectMake(0 , 0, profileImageSize +2, profileImageSize +2)];
    profileFrame.image =[UIImage imageNamed:@"WhiteBoader.png"];
    [self.view addSubview:profileFrame];
    profileFrame.clipsToBounds = YES;
    profileFrame.layer.cornerRadius = profileSornerRadius;
    
    
    UIImageView * profileImage=[[UIImageView alloc ] initWithFrame:CGRectMake(1 , 1, profileImageSize, profileImageSize)];
    
    if (user.photo != nil )
	{
        profileImage.image  = user.photo;
	}
	else if (user != nil)
	{
		NSData *photoData = [[[ESSHelper appDelegate] xmppvCardAvatarModule] photoDataForJID:user.jid];
        
		if (photoData != nil){
            profileImage.image  = [UIImage imageWithData:photoData];
        }
		else{
            profileImage.image  = [UIImage imageNamed:@"images.png"];
        }
	}else{
        profileImage.image  = [UIImage imageNamed:@"Talk-2-512.png"];
    }
    
    [self.view addSubview:profileImage];
    
    
    
    
    profileImage.clipsToBounds = YES;
    profileImage.layer.cornerRadius = profileSornerRadius;
    UIView * userProfile = [[UIView alloc] initWithFrame:CGRectMake(20 , 2, profileImage.frame.size.width, profileImage.frame.size.height)];
    userProfile.backgroundColor=[UIColor clearColor];
    [userProfile addSubview:profileFrame];
    [userProfile addSubview:profileImage];
    
    return userProfile;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return (!isGroupSelected)?[[[self fetchedResultsController] sections] count]:1;
}

- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
{
    if (!isGroupSelected) {
        NSArray *sections = [[self fetchedResultsController] sections];
        
        if (sectionIndex < [sections count])
        {
            id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
            
            int section = [sectionInfo.name intValue];
            switch (section)
            {
                case 0  : return @"Available";
                case 1  : return @"Away";
                default :
                {
                    NSLog(@"Offline   : %@",sectionInfo.objects);
                    return @"Offline";
                }
            }
        }
        
    }else{
        
        return @"";
    }
    
	return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    if (!isGroupSelected) {
        NSArray *sections = [[self fetchedResultsController] sections];
        
        if (sectionIndex < [sections count])
        {
            id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
            NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:sectionInfo.objects];
            NSMutableArray *store = [[NSMutableArray alloc]init];
            for (int count = 0 ; count<[temp count];count++){
                userSelected =(XMPPUserCoreDataStorageObject*) [temp objectAtIndex:count];
                //  NSLog(@"Before  : %@", userSelected.displayName);
                if ([userSelected.displayName rangeOfString:@"conference"].location != NSNotFound) {
                    //[temp removeObjectAtIndex:count];
                    [store addObject:[temp objectAtIndex:count]];
                }
                if ([userSelected.displayName isEqualToString:@"ios3_jij@conference.jabber.ru.com" ]) {
                    [store addObject:[temp objectAtIndex:count]];
                }
            }
            [temp removeObjectsInArray:store];
            NSLog(@"%i",[temp count]);
            return  [temp count];//sectionInfo.numberOfObjects;//
        }
    }else{
        
        return [groupsList count];
        
    }
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
	}
	[self removeAllObject:cell.contentView];
    cell.backgroundColor=[UIColor clearColor];
    UIView * cellBackground=[[UIView alloc] initWithFrame:CGRectMake(0,0,tableView.frame.size.width,tableView.rowHeight)];
    cellBackground.backgroundColor=[ESSMainViewController colorWithHexString:@"#BBDAEC"];
    cellBackground.alpha=0.5;
    [cell.contentView addSubview:cellBackground];
    UILabel * cellText=[[UILabel alloc] initWithFrame:CGRectMake(70,0,tableView.frame.size.width,tableView.rowHeight)];
    cellText.textColor=[ESSMainViewController colorWithHexString:@"#535456"];
    
    cellText.font= [UIFont fontWithName:messageFont size:16];
    
    if (!isGroupSelected) {
        userSelected = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        if ([userSelected.displayName rangeOfString:@"conference"].location == NSNotFound)
            cellText.text=  [ESSHelper displayName:userSelected.displayName];//userSelected.displayName;//
        if ([userSelected.displayName isEqualToString:@"ios3_jij@conference.jabber.ru.com" ])
            cellText.text=  [ESSHelper displayName:userSelected.displayName];
        [cell.contentView addSubview:cellText];
        UIView * profilePic=  [self getProfileImageView:userSelected];
        [cell.contentView addSubview:profilePic];
        
    }else{
        UIView * profilePic=  [self getProfileImageView:nil];
        [cell.contentView addSubview:profilePic];
        Room *roomsCreated = [groupsList objectAtIndex:indexPath.row];
        cellText.text= [NSString stringWithFormat:@"%@ " ,roomsCreated.name];
        [cell.contentView addSubview:cellText];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self
                   action:@selector(addFriendIntoGroup:)
         forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:@"AddFriend" forState:UIControlStateNormal];
        [button  setImage:[UIImage imageNamed:@"addFriedn.png"] forState:UIControlStateNormal];
        button.tag = indexPath.row;
        button.frame = CGRectMake(280,1,40,40);
        [cell.contentView  addSubview:button];
    }
    
    return cell;
}

-(void)removeAllObject:(UIView *)viewObj{
    NSArray *viewsToRemove = [viewObj subviews];
    for (UIView *v in viewsToRemove) {
        [v removeFromSuperview];
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!isGroupSelected) {
        userSelected=[[self fetchedResultsController] objectAtIndexPath:indexPath];
    }else{
        selectedGroupIndex = indexPath.row;
    }
    [self performSegueWithIdentifier:@"frindToChatView" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    xmppRoomStorage = [[XMPPRoomMemoryStorage alloc] init];
    if ([[segue identifier] isEqualToString:@"frindToChatView"]) {
        ESSHomeViewController *chatView = (ESSHomeViewController *) [segue destinationViewController];
        if (!isGroupSelected) {
            chatView.chatType = @"chat";
            chatView.userSelected= userSelected;
        }else{
            chatView.chatType = @"groupchat";
            Room *room = (Room *)[groupsList objectAtIndex:selectedGroupIndex];
            XMPPJID *roomJID = [XMPPJID jidWithString:room.roomJID];
            [[ESSMUCManager sharedInstance] createRoomWithJid:roomJID] ;
        }
    }
    if ([[segue identifier] isEqualToString:@"segueToFriednList"]){
        ESSFriednListViewController *friendList = (ESSFriednListViewController *) [segue destinationViewController];
        friendList.selectedRoom =(Room *) [groupsList objectAtIndex:selectedGroupIndex];
        Room *room = (Room *)[groupsList objectAtIndex:selectedGroupIndex];
        XMPPJID *roomJID = [XMPPJID jidWithString:room.roomJID];
        [[ESSMUCManager sharedInstance] createRoomWithJid:roomJID] ;
        NSLog(@"%@",friendList.selectedRoom) ;
    }
}


#pragma mark SegmentControll fro Groups

- (IBAction)segmentSwitch:(id)sender {
    UISegmentedControl *segmentedControl = (UISegmentedControl *) sender;
    NSInteger selectedSegment = segmentedControl.selectedSegmentIndex;
    
    if (selectedSegment == 0) {
        //toggle the correct view to be visible
        isGroupSelected = NO;
        _addGroup.hidden=YES;
        _addFriedn.hidden=NO;
        [_buddyListTable reloadData];
    }
    else{
        //toggle the correct view to be visible
        isGroupSelected = YES;
        _addFriedn.hidden=YES;
        _addGroup.hidden=NO;
        [self reloadTableData];
    }
}

- (void)reloadTableData{
    [[ESSMUCManager sharedInstance]  askForCreatedGroup:^(NSMutableArray *groupArray) {
        dispatch_async(dispatch_get_main_queue(), ^{
            groupsList = [NSMutableArray arrayWithArray:groupArray];
            [_buddyListTable reloadData];
        });
    }];
}
-(IBAction)addFriendIntoGroup:(id)sender{
    // [ESSHelper showAlertWithTitle:@"Invite friend" andMessage:@"Into Group"];
    UIButton *btn = (UIButton *)sender;
    selectedGroupIndex = btn.tag;
    [self performSegueWithIdentifier:@"segueToFriednList" sender:nil];
}

- (IBAction)createRoomOrInviteFriedn:(id)sender{
    if (isGroupSelected) {
        [[ESSMUCManager sharedInstance] createGroups:^(NSMutableArray *groupArray) {
            dispatch_async(dispatch_get_main_queue(), ^{
                groupsList = [NSMutableArray arrayWithArray:groupArray];
                NSLog(@"Group Array : %@",groupArray);
                [_buddyListTable reloadData];
            });
        }];
    }else{
        alertIndex = 0;
        UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Enter the user name" message:@"e.g peter" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput ;
        [alert show];
        // [ESSHelper showAlertWithTitle:@"Invite Friend" andMessage:@"Enter the user name"];
    }
    
}


#pragma mark delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput)
    {
        if (alertIndex == 0) {
            UITextField* username = [alertView textFieldAtIndex:0];
            NSString *jidString = [NSString stringWithFormat:@"%@@%@",username.text,kXMPPServer];
            [[ESSHelper appDelegate] sendInvitationToJID:jidString withNickName:username.text];
        }else if (alertIndex == 1){
    
        }
        
    }
    
}

- (IBAction)settingView:(id)sender{
    alertIndex = 1;
    UIAlertView* alert = [[UIAlertView alloc]initWithTitle:@"Enter Server url" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput ;
    [alert show];
}

@end
