//
//  PizzaPlace.m
//  Za Hunter
//
//  Created by Mobile Making on 11/5/14.
//  Copyright (c) 2014 Alex Hsu. All rights reserved.
//

#import "PizzaPlace.h"

@implementation PizzaPlace

- (instancetype)initWithMapItem:(MKMapItem *)mapItem
{
    self = [super init];
    self.name = mapItem.name;
    self.placemark = mapItem.placemark;
    
    return self;
}

@end
