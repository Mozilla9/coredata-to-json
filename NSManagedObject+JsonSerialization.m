//
//  NSManagedObject+JsonSerialization.m
//
//  Created by Serge Maslyakov on 30/04/15.
//


#import "NSManagedObject+JsonSerialization.h"


/**
* For ignoring serialization set this key in userInfo dictionary for a CoreData attribute.
*
*/
static const NSString *const kNotSerializeToJSON = @"notSerializeToJSON";

/**
* MagicalRecord mappedKey support.
* It is strongly recommended to use MagicalRecord.
*/
extern const NSString *const kMagicalRecordImportAttributeKeyMapKey;




@implementation NSManagedObject (JsonSerialization)

/**
* Grabbed from here https://gist.github.com/nuthatch/5607405
*
*/
- (NSDictionary *)toDictionaryWithTraversalHistory:(NSMutableSet *)traversalHistory
{
    NSArray *attributes = self.entity.attributesByName.allKeys;
    NSArray *relationships = self.entity.relationshipsByName.allKeys;

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:attributes.count + relationships.count + 1];

    NSMutableSet *localTraversalHistory = nil;

    if (!traversalHistory)
    {
        localTraversalHistory = [NSMutableSet setWithCapacity:attributes.count + relationships.count + 1];
    }
    else
    {
        localTraversalHistory = traversalHistory;
    }

    [localTraversalHistory addObject:self];


    for (NSString *attr in attributes)
    {
        NSDictionary *userInfo = ((NSPropertyDescription *)self.entity.attributesByName[attr]).userInfo;
        if (userInfo[kNotSerializeToJSON])
        {
            continue;
        }

        NSObject *value = [self valueForKey:attr];
        NSString *attrKey = attr;

        if (userInfo[kMagicalRecordImportAttributeKeyMapKey])
        {
            attrKey = userInfo[kMagicalRecordImportAttributeKeyMapKey];
        }

        if (value)
        {
            dict[attrKey] = value;
        }
    }

    for (NSString *relationship in relationships)
    {
        NSDictionary *userInfo = ((NSRelationshipDescription *)self.entity.relationshipsByName[relationship]).userInfo;
        if (userInfo[kNotSerializeToJSON])
        {
            continue;
        }

        NSObject *value = [self valueForKey:relationship];
        NSString *relationshipKey = relationship;

        if (userInfo[kMagicalRecordImportAttributeKeyMapKey])
        {
            relationshipKey = userInfo[kMagicalRecordImportAttributeKeyMapKey];
        }

        if ([value isKindOfClass:[NSSet class]])
        {
            // To-many relationship
            // The core data set holds a collection of managed objects
            NSSet *relatedObjects = (NSSet *)value;

            // Our set holds a collection of dictionaries
            NSMutableArray *dictSet = [NSMutableArray arrayWithCapacity:relatedObjects.count];

            for (NSManagedObject *relatedObject in relatedObjects)
            {
                if (![localTraversalHistory containsObject:relatedObject])
                {
                    [dictSet addObject:[relatedObject toDictionaryWithTraversalHistory:localTraversalHistory]];
                }
            }

            dict[relationshipKey] = [NSArray arrayWithArray:dictSet];
        }
        else if ([value isKindOfClass:[NSOrderedSet class]])
        {
            // To-many relationship
            // The core data set holds an ordered collection of managed objects
            NSOrderedSet *relatedObjects = (NSOrderedSet *)value;

            // Our ordered set holds a collection of dictionaries
            NSMutableArray *dictSet = [NSMutableArray arrayWithCapacity:relatedObjects.count];

            for (NSManagedObject *relatedObject in relatedObjects)
            {
                if (![localTraversalHistory containsObject:relatedObject])
                {
                    [dictSet addObject:[relatedObject toDictionaryWithTraversalHistory:localTraversalHistory]];
                }
            }

            dict[relationshipKey] = [NSArray arrayWithArray:dictSet];
        }
        else if ([value isKindOfClass:[NSManagedObject class]])
        {
            // To-one relationship
            NSManagedObject *relatedObject = (NSManagedObject *)value;

            if (![localTraversalHistory containsObject:relatedObject])
            {
                // Call toDictionary on the referenced object and put the result back into our dictionary.
                dict[relationshipKey] = [relatedObject toDictionaryWithTraversalHistory:localTraversalHistory];
            }
        }
    }

    if (!traversalHistory)
    {
        [localTraversalHistory removeAllObjects];
    }

    return dict;
}

- (NSDictionary *)toDictionary
{
    NSMutableSet *traversedObjects = nil;
    return [self toDictionaryWithTraversalHistory:traversedObjects];
}

@end