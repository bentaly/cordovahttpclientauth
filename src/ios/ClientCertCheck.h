#import "Foundation/Foundation.h"
#import "Cordova/CDV.h"

@interface ClientCertCheck : CDVPlugin

@property (nonatomic, strong) NSMutableData *connectionData;
@property (nonatomic, strong) NSMutableData *responseData;

- (void) open:(CDVInvokedUrlCommand*)command;

@end
