//
//  PizzaPlace.m
//  Za Hunter
//
//  Created by Mobile Making on 11/5/14.
//  Copyright (c) 2014 Alex Hsu. All rights reserved.
//

#import "PizzaPlace.h"
#import <MapKit/MapKit.h>

@implementation PizzaPlace

- (instancetype)initWithMapItem:(MKMapItem *)mapItem
{
    self = [super init];
    self.name = mapItem.name;
    self.placemark = mapItem.placemark;
    
//    [self getDirectionsTo:mapItem];
    
    return self;
}

- (void)getDirectionsTo:(MKMapItem *)destinationMapItem
{
    MKDirectionsRequest *request = [MKDirectionsRequest new];
    request.source = [MKMapItem mapItemForCurrentLocation];
    request.destination = destinationMapItem;
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        NSArray *routes = response.routes;
        MKRoute *route = routes.firstObject;
        
        int x = 1;
        NSMutableString *directionsString = [NSMutableString string];
        
        for (MKRouteStep *step in route.steps)
        {
            [directionsString appendFormat:@"%d: %@\n", x, step.instructions];
            x++;
        }
        
        self.directions = directionsString;
        
    }];
}

@end
