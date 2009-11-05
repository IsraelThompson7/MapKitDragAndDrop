//
//  DDAnnotation.m
//  MapKitDragAndDrop
//
//  Created by digdog on 7/24/09.
//  Copyright 2009 digdog software.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//   
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//   
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//


#import "DDAnnotation.h"

@interface DDAnnotation ()
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) MKPlacemark *placemark;
- (void)notifyCalloutInfo:(MKPlacemark *)placemark;
@end


#pragma mark -
#pragma mark DDAnnotation implementation

@implementation DDAnnotation

@synthesize coordinate = _coordinate; // property declared in MKAnnotation.h
@synthesize title = _title;
@synthesize placemark = _placemark;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate title:(NSString*)title {
	if (self = [super init]) {
		[self changeCoordinate:coordinate];
		_title = [title retain];
		_placemark = nil;
	}
	return self;
}

#pragma mark -
#pragma mark MKAnnotation Methods

- (NSString *)title {
	return _title;
}

- (NSString *)subtitle {
	NSString* subtitle = nil;
	
	if (_placemark) {
		subtitle = [[_placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
	} else {
		subtitle = [NSString stringWithFormat:@"%lf, %lf", _coordinate.latitude, _coordinate.longitude];
	}
	
	return subtitle;
}

#pragma mark -
#pragma mark Change coordinate

- (void)changeCoordinate:(CLLocationCoordinate2D)coordinate {
	_coordinate = coordinate;
	
	// Try to reverse geocode here
	// Note: LLVM/Clang Static analyzer might report potentical leak, but it won't because we release in delegate methods 
	MKReverseGeocoder *reverseGeocoder = [[MKReverseGeocoder alloc] initWithCoordinate:_coordinate];
	reverseGeocoder.delegate = self;
	[reverseGeocoder start];
}

#pragma mark -
#pragma mark MKReverseGeocoderDelegate methods

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)newPlacemark {
	[self notifyCalloutInfo:newPlacemark];
	geocoder.delegate = nil;
	[geocoder release];
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error {
	[self notifyCalloutInfo:nil];
	geocoder.delegate = nil;
	[geocoder release];
}

#pragma mark -
#pragma mark MKAnnotationView Notification

- (void)notifyCalloutInfo:(MKPlacemark *)newPlacemark {
	[self willChangeValueForKey:@"subtitle"]; // Workaround for SDK 3.0, otherwise callout info won't update.
	self.placemark = newPlacemark;
	[self didChangeValueForKey:@"subtitle"]; // Workaround for SDK 3.0, otherwise callout info won't update.
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"MKAnnotationCalloutInfoDidChangeNotification" object:self]];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
	[_title release], _title = nil;
	[_placemark release], _placemark = nil;
	[super dealloc];
}

@end
