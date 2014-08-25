//
//  ESSFriednListViewController.m
//  SyncChat
//
//  Created by essadmin on 6/27/14.
//  Copyright (c) 2014 TS. All rights reserved.
//

#import "ESSFriednListViewController.h"
#import "ESSMUCManager.h"

@interface ESSFriednListViewController ()
- (IBAction)done:(id)sender;
@end

@implementation ESSFriednListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // Do any additional setup after loading the view.
    _friendListTable.backgroundColor=[UIColor clearColor];
    _friendListTable.separatorColor=[UIColor blackColor];
    _friendListTable.rowHeight=47;
    [_friendListTable reloadData];
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
- (IBAction)done:(id)sender{
    NSArray *selectedIndexPaths  = [self.friendListTable indexPathsForSelectedRows];
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    NSLog(@"%@",selectedIndexPaths);
    xmppRoomStorage = [[XMPPRoomMemoryStorage alloc] init];
    XMPPJID *roomJID ;
    if ([selectedIndexPaths count]>0) {
        
        for (int count = 0 ; count < [selectedIndexPaths count]; count++) {
            NSIndexPath *idexPath =[selectedIndexPaths objectAtIndex:count];
            userSelected = [[self fetchedResultsController] objectAtIndexPath:idexPath];
            NSLog(@"roomJID : %@",_selectedRoom.roomJID);
            NSLog(@"userSelected.jid %@",userSelected.jid );
            roomJID = [XMPPJID jidWithString:_selectedRoom.roomJID];
            
            [[ESSMUCManager sharedInstance].currentRoom inviteUser:userSelected.jid withMessage:@"Please join my room."];
            [temp addObject:userSelected.jidStr];
        }
        [_selectedRoom setBuddiesList:temp];
    }else{
        [ESSHelper showAlertWithTitle:@"" andMessage:@"Please select friend to invite"];
        
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
    
}


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
	[[self friendListTable] reloadData];
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
	return [[[self fetchedResultsController] sections] count];
}

- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
{
    NSArray *sections = [[self fetchedResultsController] sections];
    
    if (sectionIndex < [sections count])
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
        
        int section = [sectionInfo.name intValue];
        switch (section)
        {
            case 0  : return @"Available";
            case 1  : return @"Away";
            default : return @"Offline";
        }
    }
    
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    
    NSArray *sections = [[self fetchedResultsController] sections];
    
    if (sectionIndex < [sections count])
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
        NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:sectionInfo.objects];
        NSMutableArray *store = [[NSMutableArray alloc]init];
        for (int count = 0 ; count< [temp count];count++){
            userSelected =(XMPPUserCoreDataStorageObject*) [temp objectAtIndex:count];
            NSLog(@"Before  : %@", userSelected.displayName);
            if ([userSelected.displayName rangeOfString:@"conference"].location != NSNotFound) {
               //[temp removeObjectAtIndex:count];
                [store addObject:[temp objectAtIndex:count]];
            }
        }
        [temp removeObjectsInArray:store];
        
        NSLog(@"%i",[temp count]);
        return  [temp count];//sectionInfo.numberOfObjects;//
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
    cellBackground.backgroundColor=[UIColor grayColor];
    cellBackground.alpha=0.5;
    [cell.contentView addSubview:cellBackground];
    
    
    userSelected = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    UILabel * cellText=[[UILabel alloc] initWithFrame:CGRectMake(70,0,tableView.frame.size.width,tableView.rowHeight)];
    cellText.textColor=[UIColor whiteColor];
   if ([userSelected.displayName rangeOfString:@"conference"].location == NSNotFound)
        cellText.text=  [ESSHelper displayName:userSelected.displayName];//userSelected.displayName;//

    [cell.contentView addSubview:cellText];
    UIView * profilePic=  [self getProfileImageView:userSelected];
    [cell.contentView addSubview:profilePic];
    
    return cell;
}
-(void)removeAllObject:(UIView *)viewObj{
    NSArray *viewsToRemove = [viewObj subviews];
    for (UIView *v in viewsToRemove) {
        [v removeFromSuperview];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    // userSelected=[[self fetchedResultsController] objectAtIndexPath:indexPath];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
    }
    
}


@end
