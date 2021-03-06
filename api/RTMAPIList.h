//
//  RTMAPIList.h
//  Milpon
//
//  Created by mootoh on 8/31/08.
//  Copyright 2008 deadbeaf.org. All rights reserved.
//

/**
 * access to RTM Web API.
 */
@interface RTMAPIList : NSObject {
  enum method_t {
    LISTS_ADD,
    LISTS_ARCHIVE,
    LISTS_DELETE,
    LISTS_GETLIST,
    LISTS_SETDEFAULTLIST,
    LISTS_SETNAME,
    LISTS_UNARCHIVE    
  } method;
}

/**
 * call rtm.lists.add
 *
 * @return added list id. if failed, return nil.
 */
- (NSString *) add:(NSString *)name withFilter:(NSString *)filter;
/**
 * call rtm.lists.delete
 *
 * @return deletion has been done successfully or not.
 */
- (BOOL) delete:(NSString *)list_id;
/**
 * call rtm.lists.getList
 *
 * @return array of dictionaries containing list properties.
 *         if failed, return nil.
 */
- (NSArray *) getList;

#if 0
// -------------------------------------------------------------------
// not implemented yet.
//
/**
 * call rtm.lists.archive
 */
- (void) archive:(NSString *)list_id;
/**
 * call rtm.lists.setDefaultList
 *
 * won't implement this.
 */
- (void) setDefaultList:(NSString *)list_id;
/**
 * call rtm.lists.setName
 */
- (void) setName:(NSString *)name forList:(NSString *)list_id;
/**
 * call rtm.lists.unarchive
 */
- (void) unarchive:(NSString *)list_id;
#endif // 0
@end
