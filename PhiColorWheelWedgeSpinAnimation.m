//
//  ColorWheelWedgeSpinAnimation.m
//  ColorWheel
//
//  Created by Corin Lawson on 28/06/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import "PhiColorWheelWedgeSpinAnimation.h"
#import "PhiColorWheelLayer.h"

@interface PhiColorWheelLayer (ColorWheelWedgeSpinAnimation)

- (void)setTransitionBaseColor:(CGColorRef)aColor;
- (void)setTransitionAddColor:(CGColorRef)aColor;

@end

@implementation PhiColorWheelLayer (ColorWheelWedgeSpinAnimation)

- (void)setTransitionBaseColor:(CGColorRef)aColor {
	if (!CGColorEqualToColor(transitionBaseColor, aColor)) {
		CGColorRelease(transitionBaseColor);
		transitionBaseColor = CGColorRetain(aColor);
	}
}
- (void)setTransitionAddColor:(CGColorRef)aColor {
	if (!CGColorEqualToColor(transitionAddColor, aColor)) {
		CGColorRelease(transitionAddColor);
		transitionAddColor = CGColorRetain(aColor);
	}
}

@end

@implementation PhiColorWheelWedgeSpinAnimation

@synthesize direction;
@synthesize fromValue, toValue;

- (id)init {
	if (self = [super init]) {
		self.duration = 1.5;
	}
	return self;
}

- (void)animationDidStart:(CAAnimation *)anim {
	if ([self.delegate respondsToSelector:@selector(animationDidStart:)]) {
		[self.delegate animationDidStart:self];
	}
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	if ([self.delegate respondsToSelector:@selector(animationDidStop:finished:)]) {
		[self.delegate animationDidStop:self finished:flag];
	}
}
/**/
- (void)runActionForKey:(NSString *)key object:(id)object arguments:(NSDictionary *)dict {
	if ([object isKindOfClass:[PhiColorWheelLayer class]] && ([key isEqualToString:@"baseColor"] || [key isEqualToString:@"addColor"])) {
		PhiColorWheelLayer *layer = (PhiColorWheelLayer *)object;
		CABasicAnimation *wheel = [CABasicAnimation animationWithKeyPath:[key stringByAppendingString:@"AngleWeight"]];
		wheel.fromValue = [NSNumber numberWithFloat:0.0];
		wheel.toValue = [NSNumber numberWithFloat:self.direction==PhiColorWheelWedgeSpinDirectionAnticlockwise?1.0:-1.0];
		wheel.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		wheel.duration = self.duration; 
		wheel.delegate = self;
		
		if (self.fromValue) {
			if ([key isEqualToString:@"baseColor"]) {
				[layer setTransitionBaseColor:self.fromValue];
			} else if ([key isEqualToString:@"addColor"]) {
				[layer setTransitionAddColor:self.fromValue];
			}
		} else {
			if ([key isEqualToString:@"baseColor"]) {
				[layer setTransitionBaseColor:(CGColorRef)[[layer presentationLayer] valueForKey:key]];
			} else if ([key isEqualToString:@"addColor"]) {
				[layer setTransitionAddColor:(CGColorRef)[[layer presentationLayer] valueForKey:key]];
			}
		}

		if (self.toValue) {
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
			[layer setValue:(id)self.toValue forKey:key];
			[CATransaction commit];
		}
		
		[layer addAnimation:wheel forKey:[wheel keyPath]];
	}
}
/*/
- (void)runActionForKey:(NSString *)key object:(id)object arguments:(NSDictionary *)dict {
	if ([object isKindOfClass:[ColorWheelLayer class]] && ([key isEqualToString:@"baseColor"] || [key isEqualToString:@"addColor"])) {
		ColorWheelLayer *layer = (ColorWheelLayer *)object;
		CAAnimationGroup *pair = [CAAnimationGroup animation];
		CABasicAnimation *wheel = [CABasicAnimation animationWithKeyPath:[key stringByAppendingString:@"AngleWeight"]];
		CAKeyframeAnimation *colorTransition = [CAKeyframeAnimation animationWithKeyPath:key];
		wheel.fromValue = [NSNumber numberWithFloat:0.0];
		wheel.toValue = [NSNumber numberWithFloat:self.direction==ColorWheelWedgeSpinDirectionAnticlockwise?1.0:-1.0];
		pair.animations = [NSArray arrayWithObjects:wheel, colorTransition, nil];
		pair.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
		pair.duration = self.duration;
		pair.delegate = self;
		colorTransition.calculationMode = kCAAnimationDiscrete;
		colorTransition.keyTimes = [NSArray arrayWithObjects:
									[NSNumber numberWithFloat:0.0],
//									[NSNumber numberWithFloat:1.0],
									nil];
		colorTransition.values = [NSArray arrayWithObjects:
//								  self.fromValue?self.fromValue:[[layer presentationLayer] valueForKey:key],
								  self.toValue?self.toValue:[[layer modelLayer] valueForKey:key],
								  nil];
		colorTransition.additive = self.additive;
		colorTransition.cumulative = self.cumulative;
		colorTransition.removedOnCompletion = self.removedOnCompletion;
		
		if ([key isEqualToString:@"baseColor"]) {
			[layer setTransitionBaseColor:[[layer presentationLayer] valueForKey:key]];
		} else if ([key isEqualToString:@"addColor"]) {
			[layer setTransitionAddColor:[[layer presentationLayer] valueForKey:key]];
		}
		
		[pair runActionForKey:key object:layer arguments:dict];
	}
}
/**/
@end
