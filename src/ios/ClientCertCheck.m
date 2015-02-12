
#import "Cordova/CDV.h"
#import "Cordova/CDVViewController.h"
#import "ClientCertCheck.h"

@implementation ClientCertCheck

- (void)open:(NSMutableArray *)arguments withDict:(NSMutableDictionary *)options
{
    NSLog(@"Arguments: %@", arguments);
    NSLog(@"Options: %@", options);
    
    NSURL *serverURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@",
                                [options objectForKey:@"host"]]];

    NSMutableURLRequest *connectionRequest = [NSMutableURLRequest requestWithURL:serverURL
                                cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    [connectionRequest setHTTPMethod:@"POST"];
    [connectionRequest setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    [connectionRequest setHTTPBody:[[options objectForKey:@"data"] dataUsingEncoding:NSUTF8StringEncoding]];
                
    NSURLConnection *aConnection = [[NSURLConnection alloc] initWithRequest:connectionRequest delegate:self];
    self.connectionData = [[NSMutableData alloc] init];
    self.connectionData = [options objectForKey:@"data"];
    self.responseData = [[NSMutableData alloc] init];
}

/* NSURLConnection Delegate Methods */

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"in didReceiveData ");
    [self.responseData appendData:data];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return YES;
}

- (NSURLCredential *)credentialWithIdentity:(SecIdentityRef)identity certificates:(NSArray *)certArray persistence:(NSURLCredentialPersistence)persistence {

  NSString *certPath = [[NSBundle mainBundle] pathForResource:@"mmpp00-client" ofType:@"pfx"];
  NSData *certData   = [[NSData alloc] initWithContentsOfFile:certPath];

  SecIdentityRef myIdentity;  // ???

  SecCertificateRef myCert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);
  SecCertificateRef certArray1[1] = { myCert };
  CFArrayRef myCerts = CFArrayCreate(NULL, (void *)certArray1, 1, NULL);
  CFRelease(myCert);
  NSURLCredential *credential = [NSURLCredential credentialWithIdentity:myIdentity
                              certificates:(__bridge NSArray *)myCerts
                               persistence:NSURLCredentialPersistencePermanent];
  CFRelease(myCerts);
  return credential;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSLog(@"in didReceiveAuthenticationChallenge ");
    
    NSString *thePath = [[NSBundle mainBundle] pathForResource:@"certificate" ofType:@"pfx"];
    NSData *PKCS12Data = [[NSData alloc] initWithContentsOfFile:thePath];
    CFDataRef inPKCS12Data = (__bridge CFDataRef)PKCS12Data;    
    SecIdentityRef identity;
    [self extractIdentity :inPKCS12Data :&identity];
    
    SecCertificateRef certificate = NULL;
    SecIdentityCopyCertificate (identity, &certificate); 

    const void *certs[] = {certificate};
    CFArrayRef certArray = CFArrayCreate(kCFAllocatorDefault, certs, 1, NULL);

    NSURLCredential *credential = [NSURLCredential credentialWithIdentity:identity certificates:(__bridge NSArray *)certArray persistence:NSURLCredentialPersistencePermanent];
    [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"in connectionDidFinishLoading ");
    NSMutableString *string = [[NSMutableString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    
    // Remove newlines from xml to allow the javascript callback write to work
    NSString *newString = [[string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    
    NSString* jsCallback = [NSString stringWithFormat:@"window.plugins.ClientCertCheck._dataReceived('%@');", newString];
    NSLog(@"%@", jsCallback);
    [self writeJavascript:jsCallback];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"in didFailWithError ");
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;     // Never cache
}

- (OSStatus)extractIdentity:(CFDataRef)inP12Data :(SecIdentityRef*)identity {
    OSStatus securityError = errSecSuccess;

    CFStringRef password = CFSTR("password");
    const void *keys[] = { kSecImportExportPassphrase };
    const void *values[] = { password };

    CFDictionaryRef options = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);

    CFArrayRef items = CFArrayCreate(NULL, 0, 0, NULL);
    securityError = SecPKCS12Import(inP12Data, options, &items);

    if (securityError == 0) {
        CFDictionaryRef ident = CFArrayGetValueAtIndex(items,0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue(ident, kSecImportItemIdentity);
        *identity = (SecIdentityRef)tempIdentity;
    }

    if (options) {
        CFRelease(options);
    }

    return securityError;
}

@end