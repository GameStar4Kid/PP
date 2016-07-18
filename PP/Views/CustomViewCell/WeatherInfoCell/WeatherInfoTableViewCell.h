//
//  WeatherInfoTableViewCell.h
//  PP
//
//  Created by Nguyen Xuan Tho on 7/12/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WeatherInfoTableViewCell : UITableViewCell

- (void)loadDataForWeatherInfoCell:(DataCellType)cellType andValue:(NSString *)value;

@end
