//
//  RTMSynchronizer.m
//  Milpon
//
//  Created by mootoh on 8/31/08.
//  Copyright 2008 deadbeaf.org. All rights reserved.
//

#import "RTMSynchronizer.h"
#import "RTMList.h"
#import "RTMTask.h"
#import "RTMAuth.h"
#import "RTMAPIList.h"
#import "RTMAPITask.h"
#import "RTMPendingTask.h"
#import "ProgressView.h"

@implementation RTMSynchronizer

- (id) initWithDB:(RTMDatabase *)ddb withAuth:aauth {
  if (self = [super init]) {
    db   = [ddb retain];
    auth = [aauth retain];
  }
  return self;
}

- (void) dealloc {
  [auth release];
  [db release];
  [super dealloc];
}

- (void) replaceLists {
  [RTMList erase:db];

	RTMAPIList *api_list = [[[RTMAPIList alloc] init] autorelease];
	NSArray *lists = [api_list getList];

  NSDictionary *list;
  for (list in lists)
    [RTMList create:list inDB:db];
}

- (void) syncLists {
	RTMAPIList *api_list = [[[RTMAPIList alloc] init] autorelease];
	NSArray *new_lists = [api_list getList];
  NSArray *old_lists = [RTMList allLists:db];

  // remove only existing in olds
  RTMList *old;
  NSDictionary *new;
  for (old in old_lists) {
    BOOL found = NO;
    for (new in new_lists) {
      if (old.iD == [[new objectForKey:@"id"] integerValue]) {
        found = YES;
        break;
      }
    }
    if (! found)
      [RTMList remove:old.iD fromDB:db];
  }

  // insert only existing in news
  old_lists = [RTMList allLists:db];
  for (new in new_lists) {
    BOOL found = NO;
    for (old in old_lists) {
      if (old.iD == [[new objectForKey:@"id"] integerValue]) {
        found = YES;
        break;
      }
    }
    if (! found)
      [RTMList create:new inDB:db];
  }
}

- (void) replaceTasks {
  [RTMTask erase:db];

	RTMAPITask *api_task = [[[RTMAPITask alloc] init] autorelease];
	NSArray *tasks = [api_task getList];
  if (tasks)
    [RTMTask updateLastSync:db];

  for (NSDictionary *task_series in tasks)
    [RTMTask create:task_series inDB:db];
}

- (void) syncTasks {
	RTMAPITask *api_task = [[[RTMAPITask alloc] init] autorelease];
  NSString *last_sync = [RTMTask lastSync:db];

	NSArray *tasks_new = [api_task getListWithLastSync:last_sync];
  if (tasks_new && 0 < [tasks_new count]) {
    [RTMTask updateLastSync:db];

    // sync existing tasks, remove obsoletes, ...

    NSArray *tasksInDB = [RTMTask tasks:db];
    for (NSDictionary *task_new in tasks_new) {
      BOOL found = NO;
      // TODO: use more efficient search
      for (RTMTask *task_old in tasksInDB) {
        NSArray *entries = [task_new valueForKey:@"tasks"];
        for (NSDictionary *tsk in entries) {
          NSInteger tsk_id = [[tsk valueForKey:@"id"] integerValue];
          if (tsk_id == task_old.iD) {
            // TODO: chance to replace
            found = YES;
            break;
          }
        }
      }

      if (!found) {
        // TODO: care about dup task_series
        [RTMTask create:task_new inDB:db];
      }
    }
  }
}

- (void) uploadPendingTasks:(ProgressView *)progressView {
  NSArray *pendings = [RTMPendingTask allTasks:db];
	RTMAPITask *api_task = [[RTMAPITask alloc] init];

  [progressView progressBegin];
  [progressView updateMessage:[NSString stringWithFormat:@"uploading 0/%d tasks", pendings.count]];

  int i=0;
  for (RTMPendingTask *task in pendings) {
    NSString *list_id = [NSString stringWithFormat:@"%d", task.list_id];
    NSDictionary *task_ret = [api_task add:task.name inList:list_id];

    // if added successfuly
    NSMutableDictionary *ids = [NSMutableDictionary dictionaryWithDictionary:task_ret];
    [ids setObject:list_id forKey:@"list_id"];

    //[api_task setUrl:task.url forIDs:ids];
    if (task.due && ![task.due isEqualToString:@""]) 
      [api_task setDue:task.due forIDs:ids];

    if (0 != task.location_id)
      [api_task setLocation:task.location_id forIDs:ids];

    if (0 != task.priority)
      [api_task setPriority:task.priority forIDs:ids];

    if (task.estimate && ![task.estimate isEqualToString:@""]) 
      [api_task setEstimate:task.estimate forIDs:ids];

    // TODO: set tags
    // TODO: set notes

    // remove from DB
    [RTMPendingTask remove:task.iD fromDB:db];

    [progressView updateMessage:[NSString stringWithFormat:@"uploading %d/%d tasks", i, pendings.count] withProgress:(float)i/pendings.count];
    i++;
  }

  [progressView updateMessage:@"" withProgress:1.0];
  [progressView progressEnd];
}

// TODO: sync only dirty tasks.
- (void) syncCompletedTasks {
	RTMAPITask *api_task = [[RTMAPITask alloc] init];

  NSArray *tasks = [RTMTask completedTasks:db];
  for (NSDictionary *task in tasks) {
    if ([api_task complete:task]) {
      [RTMTask remove:[[task objectForKey:@"task_id"] integerValue] fromDB:db];
    }
  }
}

@end
