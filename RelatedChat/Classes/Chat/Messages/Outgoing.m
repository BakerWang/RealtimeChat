//
// Copyright (c) 2016 Related Code - http://relatedcode.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "Outgoing.h"
#import "AppDelegate.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
@interface Outgoing()
{
	NSString *groupId;
	UIView *view;
}
@end
//-------------------------------------------------------------------------------------------------------------------------------------------------

@implementation Outgoing

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (id)initWith:(NSString *)groupId_ View:(UIView *)view_
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	self = [super init];
	groupId = groupId_;
	view = view_;
	return self;
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)send:(NSString *)text Video:(NSURL *)video Picture:(UIImage *)picture Audio:(NSString *)audio
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	FObject *message = [FObject objectWithPath:FMESSAGE_PATH Subpath:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	message[FMESSAGE_GROUPID] = groupId;
	message[FMESSAGE_USERID] = [FUser currentId];
	message[FMESSAGE_USER_NAME] = [FUser name];
	message[FMESSAGE_STATUS] = TEXT_DELIVERED;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	if (text != nil) [self sendTextMessage:message Text:text];
	else if (picture != nil) [self sendPictureMessage:message Picture:picture];
	else if (video != nil) [self sendVideoMessage:message Video:video];
	else if (audio != nil) [self sendAudioMessage:message Audio:audio];
	else [self sendLoactionMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)sendTextMessage:(FObject *)message Text:(NSString *)text
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	message[FMESSAGE_TEXT] = text;
	message[FMESSAGE_TYPE] = [RELEmoji isEmoji:text] ? MESSAGE_EMOJI : MESSAGE_TEXT;
	[self sendMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)sendPictureMessage:(FObject *)message Picture:(UIImage *)picture
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSData *dataPicture = UIImageJPEGRepresentation(picture, 0.6);
	NSData *cryptedPicture = [RELCryptor encryptData:dataPicture groupId:groupId];
	NSString *md5Picture = [RELChecksum md5HashOfData:cryptedPicture];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"message_image", @"jpg")];
	FIRStorageUploadTask *task = [reference putData:cryptedPicture metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		[hud hide:YES];
		[task removeAllObservers];
		if (error == nil)
		{
			NSString *link = metadata.downloadURL.absoluteString;
			NSString *file = [DownloadManager fileImage:link];
			[dataPicture writeToFile:[RELDir document:file] atomically:NO];

			message[FMESSAGE_PICTURE] = link;
			message[FMESSAGE_PICTURE_WIDTH] = @(picture.size.width);
			message[FMESSAGE_PICTURE_HEIGHT] = @(picture.size.height);
			message[FMESSAGE_PICTURE_MD5] = md5Picture;
			message[FMESSAGE_TEXT] = @"[Picture message]";
			message[FMESSAGE_TYPE] = MESSAGE_PICTURE;
			[self sendMessage:message];
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[task observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot)
	{
		hud.progress = (float) snapshot.progress.completedUnitCount / (float) snapshot.progress.totalUnitCount;
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)sendVideoMessage:(FObject *)message Video:(NSURL *)video
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSNumber *duration = [RELVideo duration:video];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSData *dataVideo = [NSData dataWithContentsOfFile:video.path];
	NSData *cryptedVideo = [RELCryptor encryptData:dataVideo groupId:groupId];
	NSString *md5Video = [RELChecksum md5HashOfData:cryptedVideo];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"message_video", @"mp4")];
	FIRStorageUploadTask *task = [reference putData:cryptedVideo metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		[hud hide:YES];
		[task removeAllObservers];
		if (error == nil)
		{
			NSString *link = metadata.downloadURL.absoluteString;
			NSString *file = [DownloadManager fileVideo:link];
			[dataVideo writeToFile:[RELDir document:file] atomically:NO];

			message[FMESSAGE_VIDEO] = link;
			message[FMESSAGE_VIDEO_DURATION] = duration;
			message[FMESSAGE_VIDEO_MD5] = md5Video;
			message[FMESSAGE_TEXT] = @"[Video message]";
			message[FMESSAGE_TYPE] = MESSAGE_VIDEO;
			[self sendMessage:message];
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[task observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot)
	{
		hud.progress = (float) snapshot.progress.completedUnitCount / (float) snapshot.progress.totalUnitCount;
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)sendAudioMessage:(FObject *)message Audio:(NSString *)audio
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
	hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSNumber *duration = [RELAudio duration:audio];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	NSData *dataAudio = [NSData dataWithContentsOfFile:audio];
	NSData *cryptedAudio = [RELCryptor encryptData:dataAudio groupId:groupId];
	NSString *md5Audio = [RELChecksum md5HashOfData:cryptedAudio];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	FIRStorage *storage = [FIRStorage storage];
	FIRStorageReference *reference = [[storage referenceForURL:FIREBASE_STORAGE] child:Filename(@"message_audio", @"m4a")];
	FIRStorageUploadTask *task = [reference putData:cryptedAudio metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error)
	{
		[hud hide:YES];
		[task removeAllObservers];
		if (error == nil)
		{
			NSString *link = metadata.downloadURL.absoluteString;
			NSString *file = [DownloadManager fileAudio:link];
			[dataAudio writeToFile:[RELDir document:file] atomically:NO];

			message[FMESSAGE_AUDIO] = link;
			message[FMESSAGE_AUDIO_DURATION] = duration;
			message[FMESSAGE_VIDEO_MD5] = md5Audio;
			message[FMESSAGE_TEXT] = @"[Audio message]";
			message[FMESSAGE_TYPE] = MESSAGE_AUDIO;
			[self sendMessage:message];
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[task observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot)
	{
		hud.progress = (float) snapshot.progress.completedUnitCount / (float) snapshot.progress.totalUnitCount;
	}];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)sendLoactionMessage:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	AppDelegate *app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
	message[FMESSAGE_LATITUDE] = @(app.coordinate.latitude);
	message[FMESSAGE_LONGITUDE] = @(app.coordinate.longitude);
	message[FMESSAGE_TEXT] = @"[Location message]";
	message[FMESSAGE_TYPE] = MESSAGE_LOCATION;
	[self sendMessage:message];
}

//-------------------------------------------------------------------------------------------------------------------------------------------------
- (void)sendMessage:(FObject *)message
//-------------------------------------------------------------------------------------------------------------------------------------------------
{
	message[FMESSAGE_TEXT] = [RELCryptor encryptText:message[FMESSAGE_TEXT] groupId:groupId];
	//---------------------------------------------------------------------------------------------------------------------------------------------
	[message saveInBackground:^(NSError *error)
	{
		if (error == nil)
		{
			UpdateRecents(groupId, message[FMESSAGE_TEXT]);
			SendPushNotification1(message);
		}
		else [ProgressHUD showError:@"Message sending failed."];
	}];
}

@end
