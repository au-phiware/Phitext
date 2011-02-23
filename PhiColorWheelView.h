//
//  ColorWheelView.h
//  ColorWheel
//
//  Created by Corin Lawson on 23/06/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhiColorWheelSegmentSlideGestureRecognizer : UIPanGestureRecognizer
{
	NSString *segment;
}

@property(retain, nonatomic) NSString * segment;

@end

@interface PhiColorWheelSegmentFlickGestureRecognizer : UISwipeGestureRecognizer
{
	NSString *segment;
}

@property(retain, nonatomic) NSString * segment;

@end

@interface PhiColorWheelSegmentDoubleTapGestureRecognizer : UITapGestureRecognizer
{
	NSString *segment;
}

@property(retain, nonatomic) NSString * segment;

@end


@interface PhiColorWheelView : UIView {
	NSMutableArray *baseColors;
	NSArray *addColors;
	NSInteger baseColorIndex;
	NSInteger addColorIndex;
	
	id delegate;
}

@property (nonatomic, assign) id delegate;

@property(retain, nonatomic) UIColor *baseColor;
@property(retain, nonatomic) UIColor *addColor;
@property(nonatomic) CGFloat strength;
@property(readonly, nonatomic) UIColor *color;

- (void)setBaseAndAddColorForColor:(CGColorRef)color;

@end

