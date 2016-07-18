//
//  SunOrMoonDataTableViewCell.h
//  PP
//
//  Created by Nguyen Xuan Tho on 7/12/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SunOrMoonDataTableViewCell : UITableViewCell

- (void)loadDataForSunOrMoonCell:(DataCellType)cellType andRiseValue:(NSString *)riseValue andSetValue:(NSString *)setValue;

@end
