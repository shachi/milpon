//
//  RTMTask.m
//  Milpon
//
//  Created by mootoh on 8/31/08.
//  Copyright 2008 deadbeaf.org. All rights reserved.
//

#import "RTMDatabase.h"
#import "RTMTask.h"

@implementation RTMTask

@synthesize iD, name, url, due, location, completed, priority, postponed, estimate;

- (id) initWithDB:(RTMDatabase *)ddb withParams:(NSDictionary *)params {
  if (self = [super initWithDB:ddb forID:[[params valueForKey:@"id"] integerValue]]) {
    self.name      = [params valueForKey:@"name"];
    self.url       = [params valueForKey:@"url"];
    self.due       = [params valueForKey:@"due"];
    self.location  = [params valueForKey:@"location_id"];
    self.completed = [params valueForKey:@"completed"];
    self.priority  = [[params valueForKey:@"priority"] integerValue];
    self.postponed = [[params valueForKey:@"postponed"] integerValue];
    self.estimate  = [params valueForKey:@"estimate"];
  }
  return self;
}

- (void) dealloc {
	[estimate release];
	[completed release];
  [location release];
	[due release];
	[url release];
	[name release];
	[super dealloc];
}

#if 0
#define BIND_CHECK(stmt) \
if (SQLITE_OK != ((stmt))) { @throw(@"sqlite bind failed"); }

- (void) save
{
	sqlite3_stmt *stmt = nil;
	static char *sql = "INSERT INTO task (id, due, has_due_time, added, completed, deleted, priority, postponed, estimate, task_series_id) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
	if (sqlite3_prepare_v2([RTMDatabase db], sql, -1, &stmt, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg([RTMDatabase db]));
	}
	BIND_CHECK(sqlite3_bind_int(stmt, 1, iD));
	BIND_CHECK(sqlite3_bind_text(stmt, 2, [due UTF8String], -1, SQLITE_TRANSIENT));
	BIND_CHECK(sqlite3_bind_int(stmt, 3, has_due_time));
	BIND_CHECK(sqlite3_bind_text(stmt, 4, [added UTF8String], -1, SQLITE_TRANSIENT));
	BIND_CHECK(sqlite3_bind_text(stmt, 5, [completed UTF8String], -1, SQLITE_TRANSIENT));
	BIND_CHECK(sqlite3_bind_int(stmt, 6, deleted));
	BIND_CHECK(sqlite3_bind_int(stmt, 7, priority));
	BIND_CHECK(sqlite3_bind_int(stmt, 8, postponed));
	BIND_CHECK(sqlite3_bind_text(stmt, 9, [estimate UTF8String], -1, SQLITE_TRANSIENT));
	BIND_CHECK(sqlite3_bind_int(stmt, 10, task_series_id));
	
	int success = sqlite3_step(stmt);
	if (success == SQLITE_ERROR) {
		NSAssert1(0, @"Error: failed to insert into the database with message '%s'.", sqlite3_errmsg([RTMDatabase db]));
	}
	sqlite3_finalize(stmt);
  NSLog(@"db path = %@", [[RTMDatabase theDB] path]);
  // [task_series save];
}
#endif // 0

+ (NSArray *) tasksForSQL:(NSString *)sql inDB:(RTMDatabase *)db {
	NSMutableArray *tasks = [NSMutableArray array];
	sqlite3_stmt *stmt = nil;

	if (sqlite3_prepare_v2([db handle], [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg([db handle]));
	}
	
  char *str;
	while (sqlite3_step(stmt) == SQLITE_ROW) {
    NSString *task_id   = [NSString stringWithFormat:@"%d", sqlite3_column_int(stmt, 0)];
    NSString *name      = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmt, 1)];

    str = (char *)sqlite3_column_text(stmt, 2);
    NSString *url       = (str && *str != 0) ? [NSString stringWithUTF8String:str] : @"";
    str = (char *)sqlite3_column_text(stmt, 3);
    NSString *due = nil;
    if (str && *str != '\0') {
      due = [NSString stringWithUTF8String:str];
      due = [due stringByReplacingOccurrencesOfString:@"T" withString:@"-"];
      due = [due stringByReplacingOccurrencesOfString:@"Z" withString:@" GMT"];      
    } else {
      due = @"";
    }
    NSString *location  = [NSString stringWithFormat:@"%d", sqlite3_column_int(stmt, 4)];
    NSString *priority  = [NSString stringWithFormat:@"%d", sqlite3_column_int(stmt, 5)];
    NSString *postponed = [NSString stringWithFormat:@"%d", sqlite3_column_int(stmt, 6)];
    str = (char *)sqlite3_column_text(stmt, 7);
    NSString *estimate  = (str && *str != '\0') ? [NSString stringWithUTF8String:str] : @"";

    NSArray *keys = [NSArray arrayWithObjects:@"id", @"name", @"url", @"due", @"location_id", @"priority", @"postponed", @"estimate", nil];
    NSArray *vals = [NSArray arrayWithObjects:task_id, name, url, due, location, priority, postponed, estimate, nil];
    NSDictionary *params = [NSDictionary dictionaryWithObjects:vals forKeys:keys];
    RTMTask *task = [[[RTMTask alloc] initWithDB:db withParams:params] autorelease];
		[tasks addObject:task];
	}
	sqlite3_finalize(stmt);
	return tasks;
}

+ (NSArray *) tasks:(RTMDatabase *)db {
	NSString *sql = [NSString stringWithUTF8String:"SELECT task.id,task_series.name,task_series.url,task.due,task_series.location_id,task.priority,task.postponed,task.estimate from task JOIN task_series ON task.task_series_id=task_series.id where task.completed='' ORDER BY task.due IS NULL ASC, task.due ASC, task.priority=0 ASC, task.priority ASC"];
  return [RTMTask tasksForSQL:sql inDB:db];
}

+ (NSArray *) tasksInList:(NSInteger)list_id inDB:(RTMDatabase *)db {
  NSString *sql = [NSString stringWithFormat:@"SELECT task.id,task_series.name,task_series.url,task.due,task_series.location_id,task.priority,task.postponed,task.estimate from task JOIN task_series ON task.task_series_id=task_series.id where task.completed='' AND list_id=%d ORDER BY task.priority=0 ASC,task.priority ASC, task.due IS NULL ASC, task.due ASC", list_id];

	//sqlite3_bind_int(stmt, 1, list_id);
  return [RTMTask tasksForSQL:sql inDB:db];
}

+ (NSArray *) completedTasks:(RTMDatabase *)db {
  NSString *sql = [NSString stringWithUTF8String:"SELECT task.id,task_series.id,task_series.list_id from task JOIN task_series ON task.task_series_id=task_series.id where task.completed='1'"];

	NSMutableArray *tasks = [NSMutableArray array];
	sqlite3_stmt *stmt = nil;

	if (sqlite3_prepare_v2([db handle], [sql UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg([db handle]));
	}
	
	while (sqlite3_step(stmt) == SQLITE_ROW) {
    NSString *task_id   = [NSString stringWithFormat:@"%d", sqlite3_column_int(stmt, 0)];
    NSString *task_series_id   = [NSString stringWithFormat:@"%d", sqlite3_column_int(stmt, 1)];
    NSString *list_id   = [NSString stringWithFormat:@"%d", sqlite3_column_int(stmt, 2)];

    NSArray *keys = [NSArray arrayWithObjects:@"task_id", @"task_series_id", @"list_id", nil];
    NSArray *vals = [NSArray arrayWithObjects:task_id, task_series_id, list_id, nil];
    NSDictionary *params = [NSDictionary dictionaryWithObjects:vals forKeys:keys];
    [tasks addObject:params];
	}
	sqlite3_finalize(stmt);
	return tasks;
}

+ (void) createTaskSeries:(NSDictionary *)task_series inDB:(RTMDatabase *)db {
	sqlite3_stmt *stmt = nil;
	static const char *sql = "INSERT INTO task_series (id, name, url, location_id, list_id) VALUES (?, ?, ?, ?, ?)";
	if (SQLITE_OK != sqlite3_prepare_v2([db handle], sql, -1, &stmt, NULL))
    @throw [NSString stringWithFormat:@"failed in preparing sqlite statement: '%s'.", sqlite3_errmsg([db handle])];

	sqlite3_bind_int(stmt,  1, [[task_series valueForKey:@"id"] integerValue]);
	sqlite3_bind_text(stmt, 2, [[task_series valueForKey:@"name"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(stmt, 3, [[task_series valueForKey:@"url"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(stmt,  4, [[task_series valueForKey:@"location_id"] integerValue]);
	sqlite3_bind_int(stmt,  5, [[task_series valueForKey:@"list_id"] integerValue]);
	
	if (SQLITE_ERROR == sqlite3_step(stmt))
    @throw [NSString stringWithFormat:@"failed in inserting into the database: '%s'.", sqlite3_errmsg([db handle])];

	sqlite3_finalize(stmt);
}

+ (void) createTask:(NSDictionary *)task inDB:(RTMDatabase *)db inTaskSeries:(NSInteger)task_series_id {
	sqlite3_stmt *stmt = nil;
	static const char *sql = "INSERT INTO task "
    "(id, due, completed, priority, postponed, estimate, task_series_id) "
    "VALUES (?, ?, ?, ?, ?, ?, ?)";
	if (SQLITE_OK != sqlite3_prepare_v2([db handle], sql, -1, &stmt, NULL))
    @throw [NSString stringWithFormat:@"failed in preparing sqlite statement: '%s'.", sqlite3_errmsg([db handle])];

	sqlite3_bind_int(stmt,  1, [[task valueForKey:@"id"] integerValue]);
	sqlite3_bind_text(stmt, 2, [[task valueForKey:@"due"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(stmt, 3, [[task valueForKey:@"completed"] UTF8String], -1, SQLITE_TRANSIENT);
  NSString *pri = [task valueForKey:@"priority"];
  NSInteger priority = [pri isEqualToString:@"N"] ? 0 : [pri integerValue];

	sqlite3_bind_int(stmt,  4, priority);
	sqlite3_bind_int(stmt,  5, [[task valueForKey:@"postponed"] integerValue]);
	sqlite3_bind_text(stmt, 6, [[task valueForKey:@"estimate"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(stmt,  7, task_series_id);
	
	if (SQLITE_ERROR == sqlite3_step(stmt))
    @throw [NSString stringWithFormat:@"failed in inserting into the database: '%s'.", sqlite3_errmsg([db handle])];

	sqlite3_finalize(stmt);
}

+ (void) createNote:(NSDictionary *)note inDB:(RTMDatabase *)db inTaskSeries:(NSInteger)task_series_id {
	sqlite3_stmt *stmt = nil;
	static const char *sql = "INSERT INTO note "
    "(id, title, text, created, modified, task_series_id) "
    "VALUES (?, ?, ?, ?, ?, ?)";
	if (SQLITE_OK != sqlite3_prepare_v2([db handle], sql, -1, &stmt, NULL))
    @throw [NSString stringWithFormat:@"failed in preparing sqlite statement: '%s'.", sqlite3_errmsg([db handle])];

	sqlite3_bind_int(stmt,  1, [[note valueForKey:@"id"] integerValue]);
	sqlite3_bind_text(stmt, 2, [[note valueForKey:@"title"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(stmt, 3, [[note valueForKey:@"text"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(stmt, 4, [[note valueForKey:@"created"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(stmt, 5, [[note valueForKey:@"modified"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(stmt,  6, task_series_id);
	
	if (SQLITE_ERROR == sqlite3_step(stmt))
    @throw [NSString stringWithFormat:@"failed in inserting into the database: '%s'.", sqlite3_errmsg([db handle])];

	sqlite3_finalize(stmt);
}

+ (void) createRRule:(NSDictionary *)rrule inDB:(RTMDatabase *)db inTaskSeries:(NSInteger)task_series_id {
	sqlite3_stmt *stmt = nil;
	static const char *sql = "INSERT INTO rrule (every, rule, task_series_id) VALUES (?, ?, ?)";
	if (SQLITE_OK != sqlite3_prepare_v2([db handle], sql, -1, &stmt, NULL))
    @throw [NSString stringWithFormat:@"failed in preparing sqlite statement: '%s'.", sqlite3_errmsg([db handle])];

	sqlite3_bind_text(stmt, 1, [[rrule valueForKey:@"every"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(stmt, 2, [[rrule valueForKey:@"rule"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(stmt,  3, task_series_id);
	
	if (SQLITE_ERROR == sqlite3_step(stmt))
    @throw [NSString stringWithFormat:@"failed in inserting into the database: '%s'.", sqlite3_errmsg([db handle])];

	sqlite3_finalize(stmt);
}

+ (void) create:(NSDictionary *)task_series inDB:(RTMDatabase *)db {
  // TaskSeries
  [RTMTask createTaskSeries:task_series inDB:db];

  // Tasks
  NSInteger task_series_id = [[task_series valueForKey:@"id"] integerValue];

  NSDictionary *task;
  NSArray *tasks = [task_series valueForKey:@"tasks"];
  for (task in tasks) {
    if ([[task valueForKey:@"completed"] isEqualToString:@"1"] || 
        [[task valueForKey:@"deleted"] isEqualToString:@"1"])
      continue;
    [RTMTask createTask:task inDB:db inTaskSeries:task_series_id];
  }

  // Notes
  NSDictionary *note;
  NSArray *notes = [task_series valueForKey:@"notes"];
  for (note in notes)
    [RTMTask createNote:note inDB:db inTaskSeries:task_series_id];

  // RRules
  NSDictionary *rrule = [task_series valueForKey:@"rrule"];
  if (rrule)
    [RTMTask createRRule:rrule inDB:db inTaskSeries:task_series_id];

  // Tag
}

+ (void) erase:(RTMDatabase *)db from:(NSString *)table {
	sqlite3_stmt *stmt = nil;
	const char *sql = [[NSString stringWithFormat:@"delete from %@", table] UTF8String];
	if (sqlite3_prepare_v2([db handle], sql, -1, &stmt, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg([db handle]));
	}
	if (sqlite3_step(stmt) == SQLITE_ERROR) {
		NSLog(@"erase all %@ from DB failed.", table);
		return;
	}
	sqlite3_finalize(stmt);
}

+ (void) erase:(RTMDatabase *)db {
  [RTMTask erase:db from:@"task_series"];
  [RTMTask erase:db from:@"task"];
  [RTMTask erase:db from:@"note"];
  [RTMTask erase:db from:@"tag"];
  [RTMTask erase:db from:@"location"];
}

/*
 * TODO: should call finalize on error.
 */
+ (NSString *) lastSync:(RTMDatabase *)db {
	sqlite3_stmt *stmt = nil;
	const char *sql = "select * from last_sync";
	if (sqlite3_prepare_v2([db handle], sql, -1, &stmt, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg([db handle]));
    return nil;
	}
	if (sqlite3_step(stmt) == SQLITE_ERROR) {
		NSLog(@"get 'last sync' from DB failed.");
		return nil;
	}

  char *ls = (char *)sqlite3_column_text(stmt, 0);
  if (!ls) return nil;
  NSString *result = [NSString stringWithUTF8String:ls];

	sqlite3_finalize(stmt);

  return result;
}

+ (void) updateLastSync:(RTMDatabase *)db {
  NSDate *now = [NSDate date];
  NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
  [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
  [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
  [formatter setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];
  NSString *last_sync = [formatter stringFromDate:now];
  last_sync = [last_sync stringByReplacingOccurrencesOfString:@"_" withString:@"T"];
  last_sync = [last_sync stringByAppendingString:@"Z"];

	sqlite3_stmt *stmt = nil;
	const char *sql = "UPDATE last_sync SET sync_date=?";
	if (sqlite3_prepare_v2([db handle], sql, -1, &stmt, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg([db handle]));
    return;
	}

	sqlite3_bind_text(stmt, 1, [last_sync UTF8String], -1, SQLITE_TRANSIENT);

	if (sqlite3_step(stmt) == SQLITE_ERROR) {
		NSLog(@"update 'last sync' to DB failed.");
		return;
	}

	sqlite3_finalize(stmt);
}

- (void) complete {
	sqlite3_stmt *stmt = nil;
	const char *sql = "UPDATE task SET completed=? where id=?";
	if (sqlite3_prepare_v2([db handle], sql, -1, &stmt, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg([db handle]));
    return;
	}

	sqlite3_bind_text(stmt, 1, "1", -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(stmt, 2, iD);

	if (sqlite3_step(stmt) == SQLITE_ERROR) {
		NSLog(@"update 'completed' to DB failed.");
		return;
	}

	sqlite3_finalize(stmt);
  completed = @"1";
}

- (void) uncomplete {
	sqlite3_stmt *stmt = nil;
	const char *sql = "UPDATE task SET completed=? where id=?";
	if (sqlite3_prepare_v2([db handle], sql, -1, &stmt, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg([db handle]));
    return;
	}

	sqlite3_bind_text(stmt, 1, "", -1, SQLITE_TRANSIENT);
	sqlite3_bind_int(stmt, 2, iD);

	if (sqlite3_step(stmt) == SQLITE_ERROR) {
		NSLog(@"update 'completed' to DB failed.");
		return;
	}

	sqlite3_finalize(stmt);

  completed = @"";
}

// TODO: should also remove from task_series
+ (void) remove:(NSInteger)iid fromDB:(RTMDatabase *)db {
	sqlite3_stmt *stmt = nil;
	static char *sql = "delete from task where id=?";
	if (sqlite3_prepare_v2([db handle], sql, -1, &stmt, NULL) != SQLITE_OK) {
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg([db handle]));
	}
	sqlite3_bind_int(stmt, 1, iid);

	if (sqlite3_step(stmt) == SQLITE_ERROR) {
		NSLog(@"failed in removing %d from task.", iid);
		return;
	}
  sqlite3_finalize(stmt);
}

- (BOOL) is_completed {
  return (completed && ![completed isEqualToString:@""]);
}

@end
