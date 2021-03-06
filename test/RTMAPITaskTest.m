//
//  RTMAPITaskTest.m
//  Milpon
//
//  Created by mootoh on 8/31/08.
//  Copyright 2008 deadbeaf.org. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "RTMAPITask.h"
#import "RTMAPI.h"
#import "RTMDatabase.h"
#import "RTMAuth.h"

@interface RTMAPITaskTest : SenTestCase {
  RTMDatabase *db;
  RTMAuth *auth;
  RTMAPI *api;
}
@end

@implementation RTMAPITaskTest

- (void) setUp {
  db   = [[RTMDatabase alloc] init];
  auth = [[RTMAuth alloc] initWithDB:db];
  api  = [[RTMAPI alloc] init];
  [RTMAPI setApiKey:auth.api_key];
  [RTMAPI setSecret:auth.shared_secret];
  [RTMAPI setToken:auth.token];
}

- (void) tearDown {
  [api release];
  [auth release];
  [db release];
}

- (void) testGetList {
	RTMAPITask *api_task = [[[RTMAPITask alloc] init] autorelease];
	NSArray *tasks = [api_task getList];
  STAssertNotNil(tasks, @"task getList should not be nil");		
	STAssertTrue([tasks count] > 0, @"tasks should be one or more.");
}

- (void) testGetListForID {
	RTMAPITask *api_task = [[[RTMAPITask alloc] init] autorelease];
	STAssertTrue([[api_task getListForList:@"977050"] count] > 0, @"tasks in Inbox should be one or more.");
}

- (void) testGetListWithLastSync {
	RTMAPITask *api_task = [[[RTMAPITask alloc] init] autorelease];

  NSDate *now = [NSDate date];
  NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
  [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
  [formatter setDateFormat:@"yyyy-MM-ddTHH:mm:ssZ"];

  NSString *last_sync = [formatter stringFromDate:now];

	NSArray *tasks = [api_task getListWithLastSync:last_sync];
  STAssertNotNil(tasks, @"task getListWithLastSync should not be nil");		
	STAssertTrue([tasks count] == 0, @"tasks should be zero");
}

- (void) testAdd_and_Delete {
	RTMAPITask *api_task = [[[RTMAPITask alloc] init] autorelease];
  NSDictionary *ids = [api_task add:@"task add from API." inList:nil];
	STAssertNotNil([ids valueForKey:@"task_series_id"], @"check created task_series id");
	STAssertNotNil([ids valueForKey:@"task_id"], @"check created task id");

  STAssertTrue([api_task delete:[ids valueForKey:@"task_id"] inTaskSeries:[ids valueForKey:@"task_series_id"] inList:[ids valueForKey:@"list_id"]], @"check delete");
}

- (void) testAddInList_and_Delete {
	RTMAPITask *api_task = [[[RTMAPITask alloc] init] autorelease];
  NSDictionary *ids = [api_task add:@"task add from API specifying list." inList:@"4922895"];
	STAssertNotNil([ids valueForKey:@"task_series_id"], @"check created task_series id");
	STAssertNotNil([ids valueForKey:@"task_id"], @"check created task id");

  STAssertTrue([api_task delete:[ids valueForKey:@"task_id"] inTaskSeries:[ids valueForKey:@"task_series_id"] inList:[ids valueForKey:@"list_id"]], @"check delete");
}

@end
