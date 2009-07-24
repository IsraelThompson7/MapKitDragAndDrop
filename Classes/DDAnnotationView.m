//
//  DDAnnotationView.m
//  MapKitDragAndDrop
//
//  Created by digdog on 7/24/09.
//  Copyright 2009 digdog software. All rights reserved.
//

#import "DDAnnotationView.h"
#import "DDAnnotation.h"

#pragma mark -
#pragma mark DDAnnotationView implementation

@implementation DDAnnotationView

@synthesize mapView = _mapView;

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
	
	if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
		self.enabled = YES;
		self.canShowCallout = YES;
		self.multipleTouchEnabled = NO;
		self.animatesDrop = YES;
		
		UIImageView *leftIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mobileme_32.png"]];
		self.leftCalloutAccessoryView = leftIconView;
		[leftIconView release];

        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        self.rightCalloutAccessoryView = rightButton;		
	}
	return self;
}

#pragma mark -
#pragma mark Handling events

// Reference: iPhone Application Programming Guide > Device Support > Displaying Maps and Annotations > Displaying Annotations > Handling Events in an Annotation View

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	// The view is configured for single touches only.
    UITouch* aTouch = [touches anyObject];
    _startLocation = [aTouch locationInView:[self superview]];
    _originalCenter = self.center;
	
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

    UITouch* aTouch = [touches anyObject];
    CGPoint newLocation = [aTouch locationInView:[self superview]];
    CGPoint newCenter;
	
	// If the user's finger moved more than 5 pixels, begin the drag.
    if ((abs(newLocation.x - _startLocation.x) > 5.0) || (abs(newLocation.y - _startLocation.y) > 5.0)) {
		_isMoving = YES;		
	}
	
	// If dragging has begun, adjust the position of the view.
    if (_isMoving) {
        newCenter.x = _originalCenter.x + (newLocation.x - _startLocation.x);
        newCenter.y = _originalCenter.y + (newLocation.y - _startLocation.y);
        self.center = newCenter;
    } else {
		// Let the parent class handle it.
        [super touchesMoved:touches withEvent:event];		
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

    if (_isMoving) {
        // Update the map coordinate to reflect the new position.
        CGPoint newCenter = self.center;
        DDAnnotation* theAnnotation = (DDAnnotation *)self.annotation;
        CLLocationCoordinate2D newCoordinate = [_mapView convertPoint:newCenter toCoordinateFromView:self.superview];
		
        [theAnnotation changeCoordinate:newCoordinate];

		// Try to reverse geocode here
		MKReverseGeocoder *reverseGeocoder = [[MKReverseGeocoder alloc] initWithCoordinate:newCoordinate];
		reverseGeocoder.delegate = self;
		[reverseGeocoder start];
		
        // Clean up the state information.
        _startLocation = CGPointZero;
        _originalCenter = CGPointZero;
        _isMoving = NO;
    } else {
        [super touchesEnded:touches withEvent:event];		
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {

    if (_isMoving) {
        // Move the view back to its starting point.
        self.center = _originalCenter;
		
        // Clean up the state information.
        _startLocation = CGPointZero;
        _originalCenter = CGPointZero;
        _isMoving = NO;
    } else {
        [super touchesCancelled:touches withEvent:event];		
	}
}

#pragma mark -
#pragma mark CLLocationManagerDelegate methods

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark {
	
	DDAnnotation* theAnnotation = (DDAnnotation *)self.annotation;
	theAnnotation.placemark = placemark;

	// TODO: MapKit Notification not working, possible bug.
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MKAnnotationCalloutInfoDidChangeNotification" object:self];
	
	geocoder.delegate = nil;
	[geocoder release];
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error {
	DDAnnotation* theAnnotation = (DDAnnotation *)self.annotation;
	theAnnotation.placemark = nil;
	
	geocoder.delegate = nil;
	[geocoder release];
}

@end