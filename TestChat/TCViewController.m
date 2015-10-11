//
//  TCViewController.m
//  TestChat
//
//  Created by Mike Lewis on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TCViewController.h"
#import <SocketRocket/SRWebSocket.h>
#import "TCChatCell.h"
#import "MCCSecurityManager.h"

@interface TCMessage : NSObject

- (id)initWithMessage:(NSString *)message fromMe:(BOOL)fromMe;

@property (nonatomic, retain, readonly) NSString *message;
@property (nonatomic, readonly)  BOOL fromMe;

@end


@interface TCViewController () <SRWebSocketDelegate, UITextViewDelegate> 

@end

@implementation TCViewController {
    SRWebSocket *_webSocket;
    NSMutableArray *_messages;
}

@synthesize inputView = _inputView;

#pragma mark - View lifecycle

- (void)viewDidLoad;
{
    [super viewDidLoad];
    _messages = [[NSMutableArray alloc] init];
    
    [self.tableView reloadData];
}

- (void)_reconnect;
{
    _webSocket.delegate = nil;
    [_webSocket close];
    
    
    _webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:@"wss://echoserversapitcloudd.cert.hana.ondemand.com/EchoServer/echoEndpoint"] proxyHost:@"proxy" proxyPort:8080];
    _webSocket.delegate = self;
    
    self.title = @"Opening Connection...";
    [_webSocket open];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _reconnect];
}

- (void)reconnect:(id)sender;
{
    [self _reconnect];
}

- (void)sendPing:(id)sender;
{
    [_webSocket sendPing:nil];
}

- (void)viewDidAppear:(BOOL)animated;
{
    [super viewDidAppear:animated];
    
    [_inputView becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    
    _webSocket.delegate = nil;
    [_webSocket close];
    _webSocket = nil;
}

#pragma mark - UITableViewController


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return _messages.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    TCChatCell *chatCell = (id)cell;
    TCMessage *message = [_messages objectAtIndex:indexPath.row];
    chatCell.textView.text = message.message;
    chatCell.nameLabel.text = message.fromMe ? @"Me" : @"Other";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    TCMessage *message = [_messages objectAtIndex:indexPath.row];

    return [self.tableView dequeueReusableCellWithIdentifier:message.fromMe ? @"SentCell" : @"ReceivedCell"];
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"Websocket Connected");
    self.title = @"Connected!";
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@":( Websocket Failed With Error %@", error);
    
    self.title = @"Connection Failed! (see logs)";
    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{
    NSLog(@"Received \"%@\"", message);
    [_messages addObject:[[TCMessage alloc] initWithMessage:message fromMe:NO]];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_messages.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView scrollRectToVisible:self.tableView.tableFooterView.frame animated:YES];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    self.title = @"Connection Closed! (see logs)";
    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;
{
    NSLog(@"Websocket received pong");
}



-(NSURLCredential*) credentialForWebSocket:(SRWebSocket *)webSocket{
    NSLog(@"didReceiveChallenge");
    MCCSecurityManager* mgr = [MCCSecurityManager sharedManager];
    
    NSURLCredential* credential = [NSURLCredential credentialWithIdentity:mgr.identity certificates:mgr.certificates persistence:NSURLCredentialPersistenceNone];
    

    return credential;
}



- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
    if ([text rangeOfString:@"\n"].location != NSNotFound) {
        NSString *message = [[textView.text stringByReplacingCharactersInRange:range withString:text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [_webSocket send:message];
        [_messages addObject:[[TCMessage alloc] initWithMessage:message fromMe:YES]];
        
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_messages.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView scrollRectToVisible:self.tableView.tableFooterView.frame animated:YES];

        textView.text = @"";
        return NO;
    }
    return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
{
    return YES;
}

@end

@implementation TCMessage

@synthesize message = _message;
@synthesize fromMe = _fromMe;

- (id)initWithMessage:(NSString *)message fromMe:(BOOL)fromMe;
{
    self = [super init];
    if (self) {
        _fromMe = fromMe;
        _message = message;
    }
    
    return self;
}

@end
