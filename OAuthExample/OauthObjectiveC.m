
#import "OauthObjectiveC.h"
#import <CommonCrypto/CommonCrypto.h>
#import <CoreLocation/CoreLocation.h>

@interface OauthObjectiveC ()
{
    IBOutlet UILabel *labelWeatherDesc;
    
    CLLocationCoordinate2D miamiBeachGeoPos;
}
@end

@implementation OauthObjectiveC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    miamiBeachGeoPos = CLLocationCoordinate2DMake(25.7907, 80.1300);
    
    NSString *authHeader = [self generateOAuthHeader];
    
    NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:
                             authHeader, @"Authorization",
                             @"RaG2iD6k", @"Yahoo-App-Id",
                             @"application/json", @"Content-Type",
                             nil];
    
    NSMutableURLRequest *mutableReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://weather-ydn-yql.media.yahoo.com/forecastrss?lat=%@&lon=%@&format=json", @(miamiBeachGeoPos.latitude), @(miamiBeachGeoPos.longitude)]]];
    
    mutableReq.allHTTPHeaderFields = headers;
    
    mutableReq.HTTPMethod = @"GET";
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    __weak typeof(self) weakSelf = self;
    
    NSURLSessionDataTask *apiDataTask = [session dataTaskWithRequest:mutableReq completionHandler:^(NSData *data, NSURLResponse *response, NSError *connectionError) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        
        NSString *descString;
        
        if (! connectionError && httpResponse.statusCode == 200)
        {
            NSError *jsonParseError;
            
            NSDictionary *weatherResult = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParseError];
            
            if (weatherResult && ! jsonParseError)
            {
                NSDictionary *currentObservation = [weatherResult objectForKey:@"current_observation"];
                
                if (currentObservation.allKeys.count)
                {
                    descString = [NSString stringWithFormat:@"%@°F, %@",
                                   [[currentObservation objectForKey:@"condition"] objectForKey:@"temperature"],
                                   [[currentObservation objectForKey:@"condition"] objectForKey:@"text"]];
                }
            }
            
            else{
                descString = @"Something went wrong !";
            }
        }
        
        else{
            descString = connectionError.localizedDescription;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            typeof(self) strongSelf = weakSelf;
            
            strongSelf->labelWeatherDesc.text = descString;
        });
    }];
    
    [apiDataTask resume];
}


#pragma mark - OAuth

- (NSString *)generateOAuthHeader
{
    NSString *apiURL = @"https://weather-ydn-yql.media.yahoo.com/forecastrss";
    NSString *oauth_consumer_key = @"dj0yJmk9ZEZhRmZUZlp5cVBxJnM9Y29uc3VtZXJzZWNyZXQmc3Y9MCZ4PWQ3";
    NSString *consumerSecret = @"e1e4d05015cf323cff95c343a92e6f737c93b7ea";
    NSString *oauth_nonce = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
    NSString *oauth_signature_method = @"HMAC-SHA1";
    NSString *oauth_timestamp = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970]];
    NSString *oauth_version = @"1.0";
    
    NSString *encodedApiURL = urlformdata_encode(apiURL); 
    
    NSDictionary *allParams = [NSDictionary dictionaryWithObjectsAndKeys:
                               oauth_consumer_key, @"oauth_consumer_key",
                               oauth_nonce, @"oauth_nonce",
                               oauth_signature_method, @"oauth_signature_method",
                               oauth_timestamp, @"oauth_timestamp",
                               @"1.0", @"oauth_version",
                               @(miamiBeachGeoPos.latitude), @"lat",
                               @(miamiBeachGeoPos.longitude), @"lon",
                               @"json", @"format",
                               nil];
    
    NSMutableString *parameters = [NSMutableString string];
    
    NSArray *allkeys = [[allParams allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    for (NSString *key in allkeys){
        [parameters appendFormat:@"%@=%@&", key, [allParams objectForKey:key]];
    }
    
    parameters = [[parameters substringToIndex:parameters.length-1] copy];
    
    NSString *encodedParameters =  urlformdata_encode(parameters);
    
    NSString *signature = [NSString stringWithFormat:@"GET&%@&%@", encodedApiURL, encodedParameters];
    signature = [self hmac:signature withKey:[consumerSecret stringByAppendingString:@"&"]];
    
    NSString *authorizationHeader = [NSString stringWithFormat:@"OAuth oauth_consumer_key=\"%@\", oauth_nonce=\"%@\", oauth_timestamp=\"%@\", oauth_signature_method=\"%@\", oauth_signature=\"%@\", oauth_version=\"%@\"", oauth_consumer_key, oauth_nonce, oauth_timestamp, oauth_signature_method, signature, oauth_version, nil];
    
    return authorizationHeader;
}

- (NSString *)hmac:(NSString *)plainText withKey:(NSString *)key
{
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [plainText cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    NSString *hash = [HMAC base64EncodedStringWithOptions:0];
    
    return hash;
}

static NSString* urlformdata_encode(NSString* s) {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                 NULL,
                                                                                 (CFStringRef)s,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                 kCFStringEncodingUTF8 ));
}


#pragma mark - IBAction

- (IBAction) backTap:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

