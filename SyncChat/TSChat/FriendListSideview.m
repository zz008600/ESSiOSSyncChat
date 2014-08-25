//
//  FriendListSideview.m
//  SyncChat
//
//  Created by FORD MODS on 22/05/14.
//  Copyright (c) 2014 ESS. All rights reserved.
//

#import "FriendListSideview.h"

@interface FriendListSideview ()

@end

@implementation FriendListSideview

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
      //  self.tableView.delegate=self;
      //  self.tableView.dataSource=self;
        self.tableView.separatorColor=[UIColor grayColor];
        self.tableView.backgroundColor=[UIColor clearColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (TSAppDelegate *)appDelegate
{
	return (TSAppDelegate *)[[UIApplication sharedApplication] delegate];
}



#pragma mark NSFetchedResultsController


- (NSFetchedResultsController *)fetchedResultsController
{
	if (fetchedResultsController == nil)
	{
		NSManagedObjectContext *moc = [[self appDelegate] managedObjectContext_roster];
		
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
    self.buddyListTable.rowHeight = 80;
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
		NSData *photoData = [[[self appDelegate] xmppvCardAvatarModule] photoDataForJID:user.jid];
        
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




#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
	return 2;//[[[self fetchedResultsController] sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
	NSArray *sections = [[self fetchedResultsController] sections];
	
	if (sectionIndex < [sections count])
	{
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
		return sectionInfo.numberOfObjects;
	}
	
	return 0;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"" forIndexPath:indexPath];
 //  cell.textLabel.text=@"FriendListsv ds dfs sdfsdf wdfdsaf afdsfas sd fsadfa";
   
    // Configure the cell...
    cell.contentView.backgroundColor=[UIColor blueColor];
    return cell;
}*/

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

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell=[tableView  dequeueReusableCellWithIdentifier:@"Abc"];
    
    if (cell==nil) {
        cell= [[ UITableViewCell alloc] initWithFrame:CGRectMake(0,0,tableView.frame.size.width,tableView.rowHeight)];
    }
    cell.backgroundColor=[UIColor clearColor];
    UIView * cellBackground=[[UIView alloc] initWithFrame:CGRectMake(0,0,tableView.frame.size.width,tableView.rowHeight)];
    cellBackground.backgroundColor=[UIColor grayColor];
    cellBackground.alpha=0.5;
    [cell.contentView addSubview:cellBackground];
    
    UILabel * cellText=[[UILabel alloc] initWithFrame:CGRectMake(10,0,tableView.frame.size.width,tableView.rowHeight)];
    cellText.text=@"Rahul Gupta";
    cellText.textColor=[UIColor whiteColor];
    
    [cell.contentView addSubview:cellText];
    return cell;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section; {
    UIView * sectionHeader=[[UIView alloc] initWithFrame:CGRectMake(0, 0,tableView.frame.size.width, tableView.sectionHeaderHeight)];
    sectionHeader.backgroundColor=[UIColor grayColor];
    UILabel * text=[[UILabel alloc] initWithFrame:CGRectMake(5, 0, 200, tableView.sectionHeaderHeight )];
    
    if (!section) {
    text.text=@"Friends";
    }else{
    text.text=@"Group";
    }
    
    [sectionHeader addSubview:text];
    return sectionHeader;
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/


// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
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

@end
