# CoreData entity to JSON

**Useful category for a serialize CoreData entity to JSON (NSDictionary)**

### Create CoreData entity from JSONModel object

```
#import "JSONModel.h"

@interface User : JSONModel

@property(nonatomic, copy) NSString <Optional> *name;
@property(nonatomic, copy) NSString <Optional> *email;
@property(nonatomic, copy) NSString <Optional> *phone;
@property(nonatomic, copy) NSString <Optional> *password;

- (NSManagedObject *)createCoreDataModel:(NSManagedObjectContext *)context

@end
```

```
#import "CDUser.h"
#import "NSManagedObject+MagicalDataImport.h"

@implementation User

- (Class)relatedCoreDataModelClass
{
    return [CDUser class];
}

- (NSManagedObject *)createCoreDataModel:(NSManagedObjectContext *)context
{
    return [[self relatedCoreDataModelClass] MR_importFromObject:[self toDictionary] inContext:context];
}
```

### Create JSONModel object from CoreData entity

```
#import "User.h"

#import "NSManagedObject+JsonSerialization.h"
#import "NSManagedObject+MagicalFinders.h"

@implementation UserManager

- (User *)loadUserWithPredicate:(NSPredicate *)predicate inContext:(NSManagedContext *)context
{
    CDUser *cdUser = [CDUser MR_findFirstWithPredicate:predicate inContext:context];
    
    NSDictionary *dict = [cdUser toDictionary];
    NSError *error = nil;
    
    User *user = [User initWithDictionary:dict error:&error];

    return user;
}

@end

```

### Notes

1) `notSerializeToJSON` key for relationship. 

It's allow to broke a relationship cycle. E.g. `CDUser` has a inverse relantionship to the entity `CDJob`. So when we will convert `CDUser` to the `NSDictionary`, this performing converting `CDJob` too. But `CDJob` has a relationship to the `CDUser`  and it is spawn a infinite cycle.

Example how use it.
![not_serialize_to_json](https://cloud.githubusercontent.com/assets/6338600/11869820/0f59a00c-a4dc-11e5-8778-fd2181b9dd3b.png)

2) `kMagicalRecordImportAttributeKeyMapKey` key.
Same how the `JSONKeyMapper`.

