//
// AppController.j
// FlickrPhoto
//
// Created by Ross Boucher.
// Copyright 2008 - 2010, 280 North, Inc. All rights reserved.

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

var SliderToolbarItemIdentifier = "SliderToolbarItemIdentifier",
	AddToolbarItemIdentifier = "AddToolbarItemIdentifier",
	RemoveToolbarItemIdentifier = "RemoveToolbarItemIdentifier";

/*
   Important note about CPJSONPConnection: CPJSONPConnection is ONLY for JSONP APIs.
   If aren't sure you NEED JSONP (see http://ajaxian.com/archives/jsonp-json-with-padding ),
   you most likely don't want to use CPJSONPConnection, but rather the more standard
   CPURLConnection. CPJSONPConnection is designed for cross-domain
   connections, and if you are making requests to the same domain (as most web
   applications do), you do not need it.
 */

@implementation AppController : CPObject
{
	CPString                lastIdentifier;
	CPDictionary            photosets;
	CPDictionary            hosts;
	UpdaterView				sideStatus;
	CPToolbar				toolbar;

	CPCollectionView        listCollectionView;
	CPCollectionView        photosCollectionView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
	//the first thing we need to do is create a window to take up the full screen
	//we'll also create a toolbar to go with it, and grab its size for future reference

	var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
		contentView = [theWindow contentView], toolbar = [[CPToolbar alloc] initWithIdentifier:"Photos"], bounds = [contentView bounds];

	//we tell the toolbar that we want to be its delegate and attach it to theWindow
	[toolbar setDelegate:self];
	[toolbar setVisible:true];
	[theWindow setToolbar:toolbar];
	hosts = [[CPDictionary alloc] init];


	sideStatus =  [[UpdaterView alloc] initWithFrame:CGRectMake(0, 0, 200, 32)];
	var listScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 32, 200, CGRectGetHeight(bounds) - 58)];
	[listScrollView setAutohidesScrollers:YES];
	[listScrollView setAutoresizingMask:CPViewHeightSizable];
	[[listScrollView contentView] setBackgroundColor:[CPColor colorWithRed:32.0/255.0 green:32.0/255.0 blue:32.0/255.0 alpha:1.0]];
	[sideStatus setBackgroundColor:[[listScrollView contentView] backgroundColor]];


	//and we add it to the window's content view, so it will show up on the screen
	[contentView addSubview:sideStatus];
	[contentView addSubview:listScrollView];    

	//repeat the process with another collection view for the actual photos
	//this time we'll use a different view for the prototype (PhotoCell)

	var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(200, 0, CGRectGetWidth(bounds) - 200, CGRectGetHeight(bounds) - 58)];

	[scrollView setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable];
	[scrollView setDocumentView:photosCollectionView];
	[scrollView setAutohidesScrollers:YES];

	var photosListItem = [[CPCollectionViewItem alloc] init];
	[photosListItem setView:[[PhotosListCell alloc] initWithFrame:CGRectMakeZero()]];

	listCollectionView = [[CPCollectionView alloc] initWithFrame:CGRectMake(0, 0, 200, 0)];

	[listCollectionView setDelegate:self]; //we want delegate methods
	[listCollectionView setItemPrototype:photosListItem]; //set the item prototype

	[listCollectionView setMinItemSize:CGSizeMake(20.0, 45.0)];
	[listCollectionView setMaxItemSize:CGSizeMake(1000.0, 45.0)];
	[listCollectionView setMaxNumberOfColumns:1]; //setting a single column will make this appear as a vertical list

	[listCollectionView setVerticalMargin:0.0];
	[listCollectionView setAutoresizingMask:CPViewWidthSizable];

	//finally, we put our collection view inside the scroll view as it's document view, so it can be scrolled
	[listScrollView setDocumentView:listCollectionView];


	[[scrollView contentView] setBackgroundColor:[CPColor colorWithCalibratedWhite:0.25 alpha:1.0]];

	[contentView addSubview:scrollView];    

	//bring forward the window to display it
	[theWindow orderFront:self];

	var request = [CPURLRequest requestWithURL:"http://data.vectec.net/uptime/json.php"];

	// see important note about CPJSONPConnection above
	[CPJSONPConnection sendRequest:request callback:"jsoncallback" delegate:self];

}

- (void)refresh:(id)sender
{
	//create a new request for the photos with the tag returned from the javascript prompt
	//var request = [CPURLRequest requestWithURL:"http://www.flickr.com/services/rest/?"+
	//        "method=flickr.photos.search&tags="+encodeURIComponent(string)+
	//        "&media=photos&machine_tag_mode=any&per_page=20&format=json&api_key=ca4dd89d3dfaeaf075144c3fdec76756"];
	var request = [CPURLRequest requestWithURL:"http://data.vectec.net/uptime/json.php"];
	[sideStatus setLoaded:NO];
	// see important note about CPJSONPConnection above
	[CPJSONPConnection sendRequest:request callback:"jsoncallback" delegate:self];

}

- (void)remove:(id)sender
{
	//remove this photo
	[self removeImageListWithIdentifier:[[photosets allKeys] objectAtIndex:[[listCollectionView selectionIndexes] firstIndex]]];
}

- (void)collectionViewDidChangeSelection:(CPCollectionView)aCollectionView
{
	if (aCollectionView == listCollectionView)
	{
		var listIndex = [[listCollectionView selectionIndexes] firstIndex],
			key = [listCollectionView content][listIndex];

		[photosCollectionView setContent:[photosets objectForKey:key]];
		[photosCollectionView setSelectionIndexes:[CPIndexSet indexSet]];
	}
}

- (void)connection:(CPJSONPConnection)aConnection didReceiveData:(CPString)data
{
	//this method is called when the network request returns. the data is the returned
	//information from flickr. we set the array of photo urls as the data to our collection view

	//[self addImageList:data.photos.photo withIdentifier:lastIdentifier];
	[self addHosts:data.hosts];
	[sideStatus setLoaded:YES];
	//alert("I got teh dataz");
}

- (void)connection:(CPJSONPConnection)aConnection didFailWithError:(CPString)error
{
	alert(error); //a network error occurred
}

- (void)addHosts:(CPArray)hostList
{
	//[hosts setObject:hostList];
	var i;
	for(i = 0; i < [hostList count]; i++){
		var host = [hostList objectAtIndex:i];
		var hostName = [[CPString alloc] initWithString:host.host];
		[hosts setObject:host forKey:hostName];
	}

	//[listCollectionView setContent:[[photosets allKeys] copy]];
	//[listCollectionView setContent:[[hosts allKeys] copy]];
	[listCollectionView setContent:[hostList copy]];
	[listCollectionView reloadContent];
	//[listCollectionView setSelectionIndexes:[CPIndexSet indexSetWithIndex:[[photosets allKeys] indexOfObject:aString]]];
}


//these two methods are the toolbar delegate methods, and tell the toolbar what it should display to the user

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar
{
	return [self toolbarDefaultItemIdentifiers:aToolbar];
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar
{
	return [AddToolbarItemIdentifier, RemoveToolbarItemIdentifier, CPToolbarFlexibleSpaceItemIdentifier, SliderToolbarItemIdentifier];
}

//this delegate method returns the actual toolbar item for the given identifier

- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)anItemIdentifier willBeInsertedIntoToolbar:(BOOL)aFlag
{
	var toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:anItemIdentifier];

	if (anItemIdentifier == SliderToolbarItemIdentifier)
	{

	}
	else if (anItemIdentifier == AddToolbarItemIdentifier)
	{
		var image = [[CPImage alloc] initWithContentsOfFile:"Resources/add.png" size:CPSizeMake(30, 25)],
			highlighted = [[CPImage alloc] initWithContentsOfFile:"Resources/addHighlighted.png" size:CPSizeMake(30, 25)];

		[toolbarItem setImage:image];
		[toolbarItem setAlternateImage:highlighted];

		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(refresh:)];
		[toolbarItem setLabel:"Refresh List"];

		[toolbarItem setMinSize:CGSizeMake(32, 32)];
		[toolbarItem setMaxSize:CGSizeMake(32, 32)];
	}

	return toolbarItem;
}

@end

/*
   This code demonstrates how to add a category to an existing class.
   In this case, we are adding the class method +flickr_labelWithText: to 
   the CPTextField class. Later on, we can call [CPTextField flickr_labelWithText:"foo"]
   to return a new text field with the string foo.

   Best practices suggest prefixing category methods with your unique prefix, to prevent collisions.
 */

@implementation CPTextField (CreateLabel)

	+ (CPTextField)flickr_labelWithText:(CPString)aString
{
	var label = [[CPTextField alloc] initWithFrame:CGRectMakeZero()];
	alert("CATEGORY METHOD IS CALLED");
	[label setStringValue:aString];
	[label sizeToFit];
	[label setTextShadowColor:[CPColor whiteColor]];
	[label setTextShadowOffset:CGSizeMake(0, 1)];

	return label;
}

@end

@implementation UpdaterView : CPView
{
	CPImage                        spinner;
	CPTextField                label;
	CPImageView                imageView;
}

- (id)initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];
	spinner = [[CPImage alloc] initWithContentsOfFile:"Resources/spinner.gif"];
	var imageRect = CGRectMake(-1,-1,16,16);
	imageView = [[CPImageView alloc] initWithFrame:imageRect];
	[imageView setImage:spinner];
	[imageView setImageScaling:CPScaleProportionally];

	label = [CPTextField labelWithTitle:"Loading..."];
	[label setTextColor:[CPColor grayColor]];
	[label setTextShadowColor:[CPColor blackColor]];
	var frameHeight = CGRectGetHeight(aFrame);
	[imageView setFrameOrigin:CGPointMake(12, (frameHeight/2.0)-8)];
	[self addSubview:imageView];
	[label setFrameOrigin:CGPointMake(32, (frameHeight/2.0)-(8))];
	[self addSubview:label];
	return self;
}

- (void)setLoaded:(BOOL)flag
{
	if(flag){
		[label setHidden:YES];
		[imageView setHidden:YES];
		//[label setStringValue:"Loaded."];
	}else{
		[label setHidden:NO];
		[imageView setHidden:NO];
		[label setStringValue:"Loading..."];

	}
	[[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
}


@end

// This class wraps our slider + labels combo

@implementation PhotoResizeView : CPView
{
}

- (id)initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];

	var slider = [[CPSlider alloc] initWithFrame:CGRectMake(30, CGRectGetHeight(aFrame)/2.0 - 8, CGRectGetWidth(aFrame) - 65, 24)];

	[slider setMinValue:50.0];
	[slider setMaxValue:250.0];
	[slider setIntValue:150.0];
	[slider setAction:@selector(adjustImageSize:)];

	[self addSubview:slider];

	var label = [CPTextField flickr_labelWithText:"50"];
	[label setFrameOrigin:CGPointMake(0, CGRectGetHeight(aFrame)/2.0 - 4.0)];
	[self addSubview:label];

	label = [CPTextField flickr_labelWithText:"250"];
	[label setFrameOrigin:CGPointMake(CGRectGetWidth(aFrame) - CGRectGetWidth([label frame]), CGRectGetHeight(aFrame)/2.0 - 4.0)];
	[self addSubview:label];

	return self;
}

@end

// This class displays a single photo collection inside our list of photo collecitions

@implementation PhotosListCell : CPView
{
	CPTextField     label;
	CPView          highlightView;
	CPView                        normalView;
	JSObject                hostObject;
}

- (void)setRepresentedObject:(JSObject)anObject
{
	if(!label)
	{
		label = [[CPTextField alloc] initWithFrame:CGRectInset([self bounds], 4, 4)];

		[label setFont:[CPFont systemFontOfSize:16.0]];
		[label setTextShadowColor:[CPColor grayColor]];
		[label setTextShadowOffset:CGSizeMake(0, 1)];

		[self addSubview:label];
	}
	var levelOne = [[CPString alloc] initWithString:""];
	var levelTwo = [[CPString alloc] initWithString:""];


	if(anObject.uptime < 60){
		levelOne = (anObject.uptime + "s");
	}else if (anObject.uptime < 3600){
		levelOne = (Math.floor(anObject.uptime/60) + "m, ");
		levelTwo = (Math.floor(anObject.uptime%60) + "s");

		//[levelOne setStringValue:(anObject.uptime/60 + "m, ")];
		//[levelTwo setStringValue:(anObject.uptime%60 + "s")];
	}else if (anObject.uptime < 86400){
		//[levelOne setStringValue:(anObject.uptime/3600 + "h, ")];
		//[levelTwo setStringValue:(((anObject.uptime/60)%60) + " minutes")];
		levelOne = (Math.floor(anObject.uptime/3600) + "h, ");
		levelTwo = (Math.floor((anObject.uptime/60)%60) + "m");
	}else{
		levelOne = (Math.floor(anObject.uptime/86400) + "d, ");
		levelTwo = (Math.floor((anObject.uptime/3600)%24) + "h");
	}


	[label setStringValue:(anObject.host+" "+levelOne+levelTwo)];
	hostObject = anObject;
	[label sizeToFit];

	[label setFrameOrigin:CGPointMake(10,CGRectGetHeight([label bounds]) / 2.0)];
}

- (void)setSelected:(BOOL)flag
{
	if(!highlightView)
	{
		highlightView = [[CPView alloc] initWithFrame:CGRectCreateCopy([self bounds])];
		normalView  = [[CPView alloc] initWithFrame:CGRectCreateCopy([self bounds])];
		if (hostObject.lastHeard < 310){
			[highlightView setBackgroundColor:[CPColor colorWithRed:70.0/255.0 green:84.0/255.0 blue:70.0/255.0 alpha:1.0]];
			[normalView setBackgroundColor:[CPColor colorWithRed:50.0/255.0 green:64.0/255.0 blue:50.0/255.0 alpha:1.0]];
		}else if(hostObject.lastHeard < 620){
			[highlightView setBackgroundColor:[CPColor colorWithRed:84.0/255.0 green:84.0/255.0 blue:70.0/255.0 alpha:1.0]];
			[normalView setBackgroundColor:[CPColor colorWithRed:64.0/255.0 green:64.0/255.0 blue:50.0/255.0 alpha:1.0]];
		}else if(hostObject.lastHeard < 3600){
			[highlightView setBackgroundColor:[CPColor colorWithRed:84.0/255.0 green:70.0/255.0 blue:70.0/255.0 alpha:1.0]];
			[normalView setBackgroundColor:[CPColor colorWithRed:64.0/255.0 green:50.0/255.0 blue:50.0/255.0 alpha:1.0]];
		}else if(hostObject.lastHeard < 86400){
			[highlightView setBackgroundColor:[CPColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:84.0/255.0 alpha:1.0]];
			[normalView setBackgroundColor:[CPColor colorWithRed:50.0/255.0 green:50.0/255.0 blue:64.0/255.0 alpha:1.0]];
		}else{
			[highlightView setBackgroundColor:[CPColor grayColor]];
			[normalView setBackgroundColor:[CPColor clearColor]];
		}


	}

	if(flag)
	{
		[self addSubview:highlightView positioned:CPWindowBelow relativeTo:label];
		[normalView removeFromSuperview];
		[label setTextColor:[CPColor blackColor]];    
		[label setTextShadowColor:[CPColor grayColor]];
	}
	else
	{
		[highlightView removeFromSuperview];
		[self addSubview:normalView positioned:CPWindowBelow relativeTo:label];
		[label setTextColor:[CPColor grayColor]];
		[label setTextShadowColor:[CPColor blackColor]];
	}
}

@end

// This class displays a single photo from our collection

@implementation PhotoCell : CPView
{
	CPImage         image;
	CPImageView     imageView;
	CPView          highlightView;
}

- (void)setRepresentedObject:(JSObject)anObject
{
	if(!imageView)
	{
		imageView = [[CPImageView alloc] initWithFrame:CGRectMakeCopy([self bounds])];
		[imageView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
		[imageView setImageScaling:CPScaleProportionally];
		[imageView setHasShadow:YES];
		[self addSubview:imageView];
	}

	[image setDelegate:nil];

	image = [[CPImage alloc] initWithContentsOfFile:thumbForFlickrPhoto(anObject)];

	[image setDelegate:self];

	if([image loadStatus] == CPImageLoadStatusCompleted)
		[imageView setImage:image];
	else
		[imageView setImage:nil];
}

- (void)imageDidLoad:(CPImage)anImage
{
	[imageView setImage:anImage];
}

- (void)setSelected:(BOOL)flag
{
	if(!highlightView)
	{
		highlightView = [[CPView alloc] initWithFrame:[self bounds]];
		[highlightView setBackgroundColor:[CPColor colorWithCalibratedWhite:0.8 alpha:0.6]];
		[highlightView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
	}

	if(flag)
	{
		[highlightView setFrame:[self bounds]];
		[self addSubview:highlightView positioned:CPWindowBelow relativeTo:imageView];
	}
	else
		[highlightView removeFromSuperview];
}

@end

// helper javascript functions for turning a Flickr photo object into a URL for getting the image

function urlForFlickrPhoto(photo)
{
	return "http://farm"+photo.farm+".static.flickr.com/"+photo.server+"/"+photo.id+"_"+photo.secret+".jpg";
}

function thumbForFlickrPhoto(photo)
{
	return "http://farm"+photo.farm+".static.flickr.com/"+photo.server+"/"+photo.id+"_"+photo.secret+"_m.jpg";
}
