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
#define kMeterToMileDivisor 1609.34
#define kNumberOfPlaces 8

@interface RootViewController () <CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource>

@property CLLocationManager *manager;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property NSMutableArray *pizzaPlaces;
@property NSMutableArray *nearbyPizzaPlaces;
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
    self.nearbyPizzaPlaces = [NSMutableArray array];
    
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
            NSLog(@"%@",pizzaPlace.placemark.locality);
            CLLocationDistance distance = [pizzaPlace.placemark.location distanceFromLocation:location];
            pizzaPlace.distanceInMiles = distance/kMeterToMileDivisor; //TODO: trouble shoot
//            [self getDirectionsTo:mapItem];
            [self.pizzaPlaces addObject:pizzaPlace];
        }
        [self sortByNearest:kNumberOfPlaces];
        [self.tableView reloadData];
    }];
}

//- (void)getDirectionsTo:(MKMapItem *)destinationMapItem
//{
//    MKDirectionsRequest *request = [MKDirectionsRequest new];
//    request.source = [MKMapItem mapItemForCurrentLocation];
//    request.destination = destinationMapItem;
//    
//    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
//    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
//        NSArray *routes = response.routes;
//        MKRoute *route = routes.firstObject;
//        
//        int x = 1;
//        NSMutableString *directionsString = [NSMutableString string];
//        
//        for (MKRouteStep *step in route.steps)
//        {
//            [directionsString appendFormat:@"%d: %@\n", x, step.instructions];
//            x++;
//        }
//        
//        self.directions = directionsString;
//        
//    }];
//}


#pragma mark - Table View delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.nearbyPizzaPlaces.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    PizzaPlace *pizzaPlace = self.nearbyPizzaPlaces[indexPath.row];
    cell.textLabel.text = pizzaPlace.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.02f mi", pizzaPlace.distanceInMiles];
    return cell;
}

#pragma mark - IBActions

- (IBAction)onSearchButtonTapped:(UIBarButtonItem *)sender
{
    [self.pizzaPlaces removeAllObjects];
    [self.manager startUpdatingLocation];
}

#pragma mark - helper methods

- (double)convertToDegrees:(double)km
{
    float degrees = km/kDegreeToKmConversionDivisor;
    return degrees;
}

- (void)sortByNearest:(NSInteger)numOfPlaces
{
    for (int x = 0; x < numOfPlaces; x++)
    {
        PizzaPlace *nearbyPizzaPlace = [[PizzaPlace alloc] init];
        nearbyPizzaPlace = self.pizzaPlaces[0];
        PizzaPlace *comparePlace = self.pizzaPlaces[0];
        for (int y = 0; y < self.pizzaPlaces.count; y++)
        {
            comparePlace = self.pizzaPlaces[y];
            if (nearbyPizzaPlace.distanceInMiles > comparePlace.distanceInMiles)
            {
                nearbyPizzaPlace = comparePlace;
            }
        }
        [self.nearbyPizzaPlaces addObject:nearbyPizzaPlace];
        [self.pizzaPlaces removeObject:nearbyPizzaPlace];
    }
}

@end
