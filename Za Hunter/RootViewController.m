//
//  ViewController.m
//  Za Hunter
//
//  Created by Mobile Making on 11/5/14.
//  Copyright (c) 2014 Alex Hsu. All rights reserved.
//

#import "RootViewController.h"
#import "PizzaPlace.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#define kRadiusInKM 10.0
#define kDegreeToKmConversionDivisor 111.0

@interface RootViewController () <CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource>

@property CLLocationManager *manager;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property NSMutableArray *pizzaPlaces;
@property CLLocation *location;

@end

@implementation RootViewController

#pragma mark - View Controller life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.manager = [[CLLocationManager alloc] init];
    [self.manager requestWhenInUseAuthorization];
    self.manager.delegate = self;
    self.tableView.delegate = self;
    self.pizzaPlaces = [NSMutableArray array];

}

#pragma mark - Location Manager delegates

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *location in locations)
    {
        if (location.verticalAccuracy < 500 && location.horizontalAccuracy < 500)
        {
            NSLog(@"Location found.");
            self.location = location;
            [self findPizzaNear:location];
            [self.manager stopUpdatingLocation];
            NSLog(@"updating stopped");
            break;
        }
    }
}

- (void)findPizzaNear:(CLLocation *)location
{
    MKLocalSearchRequest *request = [MKLocalSearchRequest new];
    request.naturalLanguageQuery = @"pizza";
    CLLocationDegrees deltaInDegrees = [self convertToDegrees:kRadiusInKM] * 2;
    request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(deltaInDegrees, deltaInDegrees));
    
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        NSArray *mapItems = response.mapItems;
        for (MKMapItem *mapItem in mapItems)
        {
            PizzaPlace *pizzaPlace = [[PizzaPlace alloc] initWithMapItem:mapItem];
            NSLog(@"%@",pizzaPlace.name);
            [self.pizzaPlaces addObject:pizzaPlace];
        }
//        [self getDirectionsTo:mapItem];
    }];
}


#pragma mark - Table View delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.pizzaPlaces.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - IBActions

- (IBAction)onSearchButtonTapped:(UIBarButtonItem *)sender
{
    [self.manager startUpdatingLocation];
}

#pragma mark - helper methods

-(double)convertToDegrees:(double)km
{
    float degrees = km/kDegreeToKmConversionDivisor;
    return degrees;
}

@end
