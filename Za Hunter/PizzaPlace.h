//
//  PizzaPlace.h
//  Za Hunter
//
//  Created by Mobile Making on 11/5/14.
//  Copyright (c) 2014 Alex Hsu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface PizzaPlace : NSObject

@property NSString *name;
@property MKPlacemark *placemark;
@property NSMutableString *directions;
@property double distanceInMiles;

- (instancetype)initWithMapItem:(MKMapItem *)mapItem;

@end
