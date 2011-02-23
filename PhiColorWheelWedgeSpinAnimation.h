//
//  ColorWheelWedgeSpinAnimation.h
//  ColorWheel
//
//  Created by Corin Lawson on 28/06/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UISwipeGestureRecognizer.h>

typedef enum {
    PhiColorWheelWedgeSpinDirectionClockwise = UISwipeGestureRecognizerDirectionRight,
    PhiColorWheelWedgeSpinDirectionAnticlockwise = UISwipeGestureRecognizerDirectionLeft
} PhiColorWheelWedgeSpinDirection;

@interface PhiColorWheelWedgeSpinAnimation : CAPropertyAnimation {
	CALayer *_layer;
	PhiColorWheelWedgeSpinDirection direction;
	CGColorRef fromValue;
	CGColorRef toValue;
}

@property(nonatomic) PhiColorWheelWedgeSpinDirection direction;
@property(nonatomic) CGColorRef fromValue;
@property(nonatomic) CGColorRef toValue;

@end
