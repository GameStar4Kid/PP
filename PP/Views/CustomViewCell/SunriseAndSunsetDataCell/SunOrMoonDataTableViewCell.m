//
//  SunOrMoonDataTableViewCell.m
//  PP
//
//  Created by Nguyen Xuan Tho on 7/12/16.
//  Copyright © 2016 IVC. All rights reserved.
//

#import "SunOrMoonDataTableViewCell.h"

static CGFloat const kHeightOfLabel = 21.0;

@interface SunOrMoonDataTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *lblRiseTime;
@property (weak, nonatomic) IBOutlet UILabel *lblRiseTimeValue;
@property (weak, nonatomic) IBOutlet UILabel *lblSetTime;
@property (weak, nonatomic) IBOutlet UILabel *lblSetTimeValue;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintWithOfRiseTimeLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintWithOfSetTimeLabel;

@end

@implementation SunOrMoonDataTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)loadDataForSunOrMoonCell:(DataCellType)cellType andRiseValue:(NSString *)riseValue andSetValue:(NSString *)setValue {
    switch (cellType) {
        case DataCellType_Sun: {
            self.lblRiseTime.text = NSLocalizedString(@"Sunrise time", nil);
            self.lblSetTime.text = NSLocalizedString(@"Sunset time", nil);
            
        }
            break;
        case DataCellType_Moon:{
            self.lblRiseTime.text = NSLocalizedString(@"Moonrise time", nil);
            self.lblSetTime.text = NSLocalizedString(@"Moonset time", nil);
        }
            break;
            
        default:
            break;
    }
    self.constraintWithOfRiseTimeLabel.constant = [self widthOfLabel:self.lblRiseTime];
    self.constraintWithOfSetTimeLabel.constant = [self widthOfLabel:self.lblSetTime];
    self.lblRiseTimeValue.text = riseValue;
    self.lblSetTimeValue.text = setValue;
}

- (CGFloat)widthOfLabel:(UILabel *)lbl {
    CGSize size = [lbl sizeThatFits:CGSizeMake(CGFLOAT_MAX, kHeightOfLabel)];
    
    return size.width;
}

@end
