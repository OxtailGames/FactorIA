// macOS and iOS: NSURLSession (system certificates, system proxy). App Transport Security applies: plain http:// to hosts
// other than loopback is refused by the system, which is the policy of docs/NETWORKING.md anyway. One ephemeral session per
// request (no cookies, no cache, nothing written to disk); its delegate collects the body (and stops it at the size limit)
// and refuses redirects to anything but https://.
#import <Foundation/Foundation.h>

#include <algorithm>
#include <cstring>

#include "fa/platform/http.h"

@interface FaHttpTask : NSObject <NSURLSessionDataDelegate> {
@public
    fa::HttpDone done;
    NSHTTPURLResponse* finalResponse;
}
@property(nonatomic, strong) NSMutableData* data;
@property(nonatomic) NSUInteger maxBytes;
@property(nonatomic) BOOL tooLarge;
@property(nonatomic) BOOL badRedirect;
@property(nonatomic, copy) NSString* host;
@property(nonatomic) double timeoutSec;
@end

@implementation FaHttpTask

- (void)URLSession:(NSURLSession*)session
                          task:(NSURLSessionTask*)task
    willPerformHTTPRedirection:(NSHTTPURLResponse*)response
                    newRequest:(NSURLRequest*)request
             completionHandler:(void (^)(NSURLRequest*))handler {
    if (![[request.URL.scheme lowercaseString] isEqualToString:@"https"]) {
        self.badRedirect = YES;
        handler(nil);  // stop here: the 3xx answer itself comes back, and is reported as an error below
        return;
    }
    handler(request);
}

- (void)URLSession:(NSURLSession*)session
              dataTask:(NSURLSessionDataTask*)task
    didReceiveResponse:(NSURLResponse*)response
     completionHandler:(void (^)(NSURLSessionResponseDisposition))handler {
    finalResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse*)response : nil;
    handler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession*)session dataTask:(NSURLSessionDataTask*)task didReceiveData:(NSData*)chunk {
    if (self.data.length + chunk.length > self.maxBytes) {
        self.tooLarge = YES;
        [task cancel];
        return;
    }
    [self.data appendData:chunk];
}

- (void)URLSession:(NSURLSession*)session task:(NSURLSessionTask*)task didCompleteWithError:(NSError*)error {
    fa::HttpResponse r;
    std::string host = self.host ? std::string([self.host UTF8String]) : std::string();
    if (self.badRedirect) {
        r.error = "the request to " + host + " was redirected to a URL that is not https://";
        r.hint = "Redirects are only followed to https:// addresses.";
    } else if (self.tooLarge) {
        r.error = "the response from " + host + " is longer than " + std::to_string([self maxBytes] / 1024) + " KB";
        r.hint = "http.fetch is for small texts (JSON, configuration); ask the server for less data.";
    } else if (error) {
        const NSInteger code = error.code;
        if (code == NSURLErrorTimedOut) {
            r.timedOut = true;
            r.error = "the request to " + host + " timed out after " + std::to_string(int(self.timeoutSec)) + " s";
            r.hint = "Check the connection, or raise the timeout option of http.fetch.";
        } else if (code == NSURLErrorCannotFindHost || code == NSURLErrorDNSLookupFailed) {
            r.error = "could not find the server " + host;
            r.hint = "Check the address, and that the player is online.";
        } else if (code == NSURLErrorCannotConnectToHost || code == NSURLErrorNotConnectedToInternet ||
                   code == NSURLErrorNetworkConnectionLost) {
            r.error = "could not connect to " + host;
            r.hint = "The server may be down, or the player offline.";
        } else if (code <= NSURLErrorServerCertificateHasBadDate && code >= NSURLErrorClientCertificateRequired) {
            r.error = "the secure connection to " + host + " failed: " + std::string([error.localizedDescription UTF8String]);
            r.hint = "The server's certificate is not trusted by this computer (an expired certificate, a wrong clock, or a proxy "
                     "that rewrites traffic).";
        } else if (code == NSURLErrorAppTransportSecurityRequiresSecureConnection) {
            r.error = "the system refuses a plain http:// connection to " + host;
            r.hint = "Use https:// (plain http is only allowed for localhost).";
        } else {
            r.error = "the request to " + host + " failed: " + std::string([error.localizedDescription UTF8String]);
            r.hint = "Check the connection, and that the server is up.";
        }
    } else if (!finalResponse) {
        r.error = "the request to " + host + " got no HTTP answer";
        r.hint = "Check the address.";
    } else {
        r.ok = true;
        r.status = static_cast<int>(finalResponse.statusCode);
        for (NSString* name in finalResponse.allHeaderFields) {
            NSString* value = [NSString stringWithFormat:@"%@", finalResponse.allHeaderFields[name]];
            r.headers.emplace_back([[name lowercaseString] UTF8String], [value UTF8String]);
        }
        r.body.assign(static_cast<const char*>(self.data.bytes), self.data.length);
    }
    fa::HttpDone callback = std::move(done);
    done = nullptr;
    [session finishTasksAndInvalidate];
    if (callback) callback(std::move(r));
}

@end

namespace fa {

namespace {

class UrlSessionClient final : public HttpClient {
public:
    std::string name() const override { return "nsurlsession"; }
    bool available() const override { return true; }
    void send(HttpRequest request, HttpDone done) override {
        @autoreleasepool {
            NSString* urlText = [NSString stringWithUTF8String:request.url.c_str()];
            NSURL* url = urlText ? [NSURL URLWithString:urlText] : nil;
            if (!url) {
                HttpResponse r;
                r.error = "the address is not a valid URL: " + request.url;
                r.hint = "Write it as https://host/path.";
                done(std::move(r));
                return;
            }
            NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
            req.HTTPMethod = [NSString stringWithUTF8String:request.method.c_str()];
            req.timeoutInterval = request.timeoutSec;
            for (const auto& [name, value] : request.headers)
                [req setValue:[NSString stringWithUTF8String:value.c_str()] forHTTPHeaderField:[NSString stringWithUTF8String:name.c_str()]];
            if (![req valueForHTTPHeaderField:@"User-Agent"])
                [req setValue:@"FactorIA/" FA_ENGINE_VERSION forHTTPHeaderField:@"User-Agent"];
            if (!request.body.empty()) req.HTTPBody = [NSData dataWithBytes:request.body.data() length:request.body.size()];

            NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            config.timeoutIntervalForRequest = request.timeoutSec;
            config.timeoutIntervalForResource = request.timeoutSec;
            config.waitsForConnectivity = NO;
            FaHttpTask* task = [[FaHttpTask alloc] init];
            task.data = [NSMutableData data];
            task.maxBytes = request.maxResponseBytes;
            task.host = url.host ?: urlText;
            task.timeoutSec = request.timeoutSec;
            task->done = std::move(done);
            NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:task delegateQueue:nil];
            [[session dataTaskWithRequest:req] resume];
        }
    }
};

}  // namespace

std::unique_ptr<HttpClient> make_system_http_client() { return std::make_unique<UrlSessionClient>(); }

}  // namespace fa
