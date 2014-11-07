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
#define kNumberOfPlaces 4
#define kSecondsToMinutes 60
#define kEatingTime 30

@interface RootViewController () <CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource>

@property CLLocationManager *manager;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property NSMutableArray *pizzaPlaces;
@property NSMutableArray *nearbyPizzaPlaces;
@property CLLocation *myLocation;
@property NSString *totalTimeString;
@property double totalTime;
@property (strong, nonatomic) IBOutlet UITextView *textView;

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
            self.myLocation = location;
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
        //TODO: check for error
        [self.pizzaPlaces removeAllObjects];
        [self.nearbyPizzaPlaces removeAllObjects];

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

- (void)getTimes
{
    MKPlacemark *sourcePlacemark = [[MKPlacemark alloc] initWithCoordinate:self.myLocation.coordinate addressDictionary:nil];
    MKMapItem *sourceMapItem = [[MKMapItem alloc] initWithPlacemark:sourcePlacemark];
    NSMutableString *timeString = [NSMutableString string];

    self.totalTime = kEatingTime * kSecondsToMinutes * self.nearbyPizzaPlaces.count;
    
    //TODO: print out times in order
    PizzaPlace *currentLocation = [[PizzaPlace alloc] initWithMapItem:sourceMapItem];
    currentLocation.name = @"Original Location";
    [self.nearbyPizzaPlaces addObject:currentLocation];
    
    for (PizzaPlace *pizzaPlace in self.nearbyPizzaPlaces)
    {
        MKDirectionsRequest *request = [MKDirectionsRequest new];
        request.source = sourceMapItem;
        request.destination = [[MKMapItem alloc] initWithPlacemark:pizzaPlace.placemark];
        
        MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
        [directions calculateETAWithCompletionHandler:^(MKETAResponse *response, NSError *error) {
            NSTimeInterval time = response.expectedTravelTime;
            self.totalTime = self.totalTime + time;
            [timeString appendFormat:@"%d min to %@\n", (int)time/kSecondsToMinutes, pizzaPlace.name];
            self.textView.text = timeString;
            self.totalTimeString = [NSString stringWithFormat:@"%d min including %d min at each place", (int)self.totalTime/kSecondsToMinutes, kEatingTime];
            [self.tableView reloadData];
        }];
        
        sourceMapItem = request.destination;
    }
    
    [self.nearbyPizzaPlaces removeObject:currentLocation];
    
}

//- (NSMutableArray *)getDirections
//{
//    NSMutableArray *directionsStrings = [NSMutableArray array];
//
//    MKMapItem *sourceMapItem = [MKMapItem mapItemForCurrentLocation];
//    
//    for (PizzaPlace *pizzaPlace in self.pizzaPlaces)
//    {
//        MKDirectionsRequest *request = [MKDirectionsRequest new];
//        request.source = sourceMapItem;
//        request.destination = [[MKMapItem alloc] initWithPlacemark:pizzaPlace.placemark];
//        
//        MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
//        [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
//            NSArray *routes = response.routes;
//            MKRoute *route = routes.firstObject;
//            
//            int x = 1;
//            NSMutableString *directionsStringSegment = [NSMutableString string];
//            
//            for (MKRouteStep *step in route.steps)
//            {
//                [directionsStringSegment appendFormat:@"%d: %@\n", x, step.instructions];
//                x++;
//            }
//            
//            [directionsStrings addObject:directionsStringSegment];
//            
//        }];
//        
//    }
//
//    
//    return [NSString stringWithString:directionsString];
//    
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UILabel *myLabel = [[UILabel alloc] init];
    myLabel.frame = CGRectMake(0, 20, 320, 50);
    myLabel.backgroundColor = [UIColor lightGrayColor];
    myLabel.font = [UIFont boldSystemFontOfSize:14];
    myLabel.text = [self tableView:tableView titleForFooterInSection:section];
    myLabel.textAlignment = NSTextAlignmentCenter;
    
    UIView *footerView = [[UIView alloc] init];
    [footerView addSubview:myLabel];
    
    return footerView;

}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return self.totalTimeString;
}

#pragma mark - IBActions

- (IBAction)onSearchButtonTapped:(UIBarButtonItem *)sender
{
    [self.pizzaPlaces removeAllObjects];
    [self.nearbyPizzaPlaces removeAllObjects];

    [self.manager startUpdatingLocation];
}

- (IBAction)onCrawlButtonTapped:(UIButton *)sender
{
    // get pizza place 1 and get time to walk from current location
    
    [self getTimes];
    
//    for (PizzaPlace *pizzaPlace in self.nearbyPizzaPlaces)
//    {
//        <#statements#>
//    }
    
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