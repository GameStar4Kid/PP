//
//  WeatherInfoTableViewCell.m
//  PP
//
//  Created by Nguyen Xuan Tho on 7/12/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "WeatherInfoTableViewCell.h"

static CGFloat const kHeightOfLabel = 21.0;

@interface WeatherInfoTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblValue;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintWidthOfTitleLabel;

@end

@implementation WeatherInfoTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)loadDataForWeatherInfoCell:(DataCellType)cellType andValue:(NSString *)value {
    switch (cellType) {
        case DataCellType_Age: {
            self.lblTitle.text = NSLocalizedString(@"Age", nil);
        }
            break;
        case DataCellType_MeteorologicalData:{
            self.lblTitle.text = NSLocalizedString(@"Weather", nil);
        }
            break;
            
        default:
            break;
    }
    CGSize size = [self.lblTitle sizeThatFits:CGSizeMake(CGFLOAT_MAX, kHeightOfLabel)];
    self.constraintWidthOfTitleLabel.constant = size.width;
    self.lblValue.text = value;
}

@end
