//
//  ColorWheelLayer.m
//  ColorWheel
//
//  Created by Corin Lawson on 24/06/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import "PhiColorWheelLayer.h"
#import "PhiColorWheelWedgeSpinAnimation.h"

@interface PhiColorWheelLayer ()
@property (nonatomic, readonly) CGColorRef transitionAddColor;
@property (nonatomic, readonly) CGColorRef transitionBaseColor;
@end

@implementation PhiColorWheelLayer

@dynamic wedgeCornerRadius, wedgeHeight, wedgeWindowHeight, wedgeWindowArc;
@dynamic baseColor, addColor;
@dynamic strength, wedgeMargin;
@dynamic baseColorAngleWeight, addColorAngleWeight;

- (id)init {
	if (self = [super init]) {
		transitionAddColor = NULL;
		transitionBaseColor = NULL;
		self.anchorPoint = CGPointMake(0.5, 1.0);
	}
	return self;
}

- (id)initWithLayer:(id)layer {
	if (self = [super initWithLayer:layer]) {
		if ([layer isKindOfClass:[PhiColorWheelLayer class]]) {
			transitionAddColor = CGColorRetain([(PhiColorWheelLayer *)layer transitionAddColor]);
			transitionBaseColor = CGColorRetain([(PhiColorWheelLayer *)layer transitionBaseColor]);
		}
	}
	return self;
}

- (void)dealloc {
	CGColorRelease(color);
	CGColorRelease(transitionColor);
	CGColorRelease(transitionAddColor);
	CGColorRelease(transitionBaseColor);
	
    [super dealloc];
}

+ (BOOL)needsDisplayForKey:(NSString *)key {
	return [key isEqualToString:@"strength"]
	|| [key isEqualToString:@"baseColor"]
	|| [key isEqualToString:@"addColor"]
	|| [key isEqualToString:@"wedgeMargin"]
	|| [key isEqualToString:@"wedgeCornerRadius"]
	|| [key isEqualToString:@"wedgeHeight"]
	|| [key isEqualToString:@"wedgeWindowHeight"]
	|| [key isEqualToString:@"wedgeWindowArc"]
	|| [key isEqualToString:@"baseColorAngleWeight"]
	|| [key isEqualToString:@"addColorAngleWeight"]
	|| [CALayer needsDisplayForKey:key];
}

+ (id)defaultValueForKey:(NSString *)key {
	if ([key isEqualToString:@"wedgeMargin"]) {
		return [NSNumber numberWithFloat:4.0];
	} else if ([key isEqualToString:@"strength"]) {
		return [NSNumber numberWithFloat:0.5];
	} else if ([key isEqualToString:@"baseColorAngleWeight"]) {
		return [NSNumber numberWithFloat:0.0];
	} else if ([key isEqualToString:@"addColorAngleWeight"]) {
		return [NSNumber numberWithFloat:0.0];
	}
	return [CALayer defaultValueForKey:key];
}

+ (id <CAAction>)defaultActionForKey:(NSString *)key {
	if ([key isEqualToString:@"strength"] || [key isEqualToString:@"addColorAngleWeight"] || [key isEqualToString:@"baseColorAngleWeight"]) {
		CAAnimation *a = [CABasicAnimation animationWithKeyPath:key];
		return a;
	}
	if ([key isEqualToString:@"baseColor"] || [key isEqualToString:@"addColor"]) {
		return [[[PhiColorWheelWedgeSpinAnimation alloc] init] autorelease];
	}
	return [CALayer defaultActionForKey:key];
}

- (BOOL)needsDisplayOnBoundsChange {
	return YES;
}

#pragma mark Draw Wedge

struct arc {
	CGFloat start;
	CGFloat end;
};
struct wedge_window {
	CGFloat outer;
	CGFloat inner;
};
struct wedge {
	struct arc arc;
	struct arc outerArc;
	struct arc innerArc;
	struct wedge_window baseWindow;
	struct wedge_window resultWindow;
	struct wedge_window addWindow;
};

- (void)drawInContext:(CGContextRef)c {
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGFloat colorComponents[4] = {0.0, 0.0, 0.0, 1.0};
	CGColorRef wheelColor = CGColorCreate(space, colorComponents);
	colorComponents[0] = 1.0;
	colorComponents[1] = 1.0;
	colorComponents[2] = 0.95;
	colorComponents[3] = 0.33;
	CGColorRef wheelHighlightColor = CGColorCreate(space, colorComponents);
	CGFloat margin = MIN(self.wedgeMargin, self.bounds.size.height / 27.0);
	CGFloat cornerRadius = self.wedgeCornerRadius;
	CGFloat height = self.wedgeHeight;
	CGFloat wwHeight = self.wedgeWindowHeight;
	CGFloat wedgeWidth = self.wedgeWindowArc; //Radians

	if (height <= 0.0)
		height = self.bounds.size.height - margin - 0.5;
	if (wwHeight <= 0.0)
		wwHeight = height / 12.0;
	if (cornerRadius <= 0.0)
		cornerRadius = 1.618 * margin;
	if (wedgeWidth <= 0.0)
		wedgeWidth = 2.0 * asinf(((self.bounds.size.width - 3.0 * margin) / 2.0 - 0.5) / height);
	
	CGFloat wedgeWidthSpacing = asinf(margin / (2.0 * height)); //Radians
	CGFloat spacedWedgeWidth = wedgeWidth + 2.0 * wedgeWidthSpacing;
	CGFloat wedgeAngle = M_PI / -2.0f;
	CGFloat baseAngleWeight = transitionBaseColor?self.baseColorAngleWeight:0.0;
	CGFloat addAngleWeight = transitionAddColor?self.addColorAngleWeight:0.0;
	CGFloat marginOffsetFactor = 2.0 / sinf(wedgeWidth) * cosf(wedgeWidth / 2.0);
	CGFloat highlightInset = margin * 0.5;
	CGFloat highlightWidth = margin * 0.5;
	struct wedge w;
	w.arc.start = wedgeAngle - wedgeWidth * 0.5;
	w.arc.end   = wedgeAngle + wedgeWidth * 0.5;
	CGMutablePathRef wheel = CGPathCreateMutable();
	CGMutablePathRef resultClip = CGPathCreateMutable();
	CGMutablePathRef highlightEdge = CGPathCreateMutable();
	CGMutablePathRef highlight = CGPathCreateMutable();
	CGMutablePathRef baseClip = CGPathCreateMutable();
	CGMutablePathRef addWedge[2] = {NULL, NULL};
	CGMutablePathRef addClip = CGPathCreateMutable();
	
	CGContextTranslateCTM(c, CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds));
	
	CGContextSaveGState(c); {
#pragma mark Draw Base Color Wedge Window
		CGContextSaveGState(c); {
			CGMutablePathRef baseWedge;

			CGPathAddArc(baseClip, NULL, 0.0, 0.0, height,
						 w.arc.start, w.arc.end, NO);
			CGPathAddArc(baseClip, NULL, 0.0, 0.0, height - wwHeight - 1.0,
						 w.arc.end, w.arc.start, YES);
			CGPathCloseSubpath(baseClip);
			CGContextBeginPath(c);
			CGContextAddPath(c, baseClip);
			CGContextClip(c);
		
			if (baseAngleWeight != 0.0) {
				baseWedge = CGPathCreateMutable();
				CGPathAddArc(baseWedge, NULL, 0.0, 0.0, height,
							 wedgeAngle - spacedWedgeWidth * (baseAngleWeight - 0.5),
							 wedgeAngle - spacedWedgeWidth * (baseAngleWeight + 0.5), NO);
				CGPathAddArc(baseWedge, NULL, 0.0, 0.0, height - wwHeight - 1.0,
							 wedgeAngle - spacedWedgeWidth * (baseAngleWeight + 0.5),
							 wedgeAngle - spacedWedgeWidth * (baseAngleWeight - 0.5), YES);
				CGPathCloseSubpath(baseWedge);
				
				CGContextBeginPath(c);
				CGContextAddPath(c, baseWedge);
				CGContextSetFillColorWithColor(c, [self baseColor]);
				CGContextFillPath(c);
				CGPathRelease(baseWedge);
			}
			//
			baseWedge = CGPathCreateMutable();
			CGPathAddArc(baseWedge, NULL, 0.0, 0.0, height,
						 wedgeAngle - spacedWedgeWidth * (baseAngleWeight + 0.5),
						 wedgeAngle - spacedWedgeWidth * (baseAngleWeight - 0.5), NO);
			CGPathAddArc(baseWedge, NULL, 0.0, 0.0, height - wwHeight - 1.0,
						 wedgeAngle - spacedWedgeWidth * (baseAngleWeight - 0.5),
						 wedgeAngle - spacedWedgeWidth * (baseAngleWeight + 0.5), YES);
			CGPathCloseSubpath(baseWedge);
			
			CGContextBeginPath(c);
			CGContextAddPath(c, baseWedge);
			if (baseAngleWeight != 0.0)
				CGContextSetFillColorWithColor(c, transitionBaseColor);
			else
				CGContextSetFillColorWithColor(c, [self baseColor]);
			CGContextFillPath(c);
			CGPathRelease(baseWedge);
			/**/
			CGContextBeginPath(c);
			CGContextMoveToPoint(c, height * cosf(wedgeAngle - spacedWedgeWidth * (baseAngleWeight + 0.5)),
								 height * sinf(wedgeAngle - spacedWedgeWidth * (baseAngleWeight + 0.5)));
			CGContextAddLineToPoint(c, (height - wwHeight - 1.0) * cosf(wedgeAngle - spacedWedgeWidth * (baseAngleWeight + 0.5)),
									(height - wwHeight - 1.0) * sinf(wedgeAngle - spacedWedgeWidth * (baseAngleWeight + 0.5)));
			CGContextSetLineCap(c, kCGLineCapButt);
			CGContextSetLineWidth(c, margin);
			CGContextSetStrokeColorWithColor(c, wheelColor);
			CGContextStrokePath(c);
			CGContextSetLineWidth(c, highlightWidth);
			CGContextSetStrokeColorWithColor(c, wheelHighlightColor);
			CGContextStrokePath(c);
			/**/
			CGContextBeginPath(c);
			CGContextMoveToPoint(c, height * cosf(wedgeAngle - spacedWedgeWidth * (baseAngleWeight - 0.5)),
								 height * sinf(wedgeAngle - spacedWedgeWidth * (baseAngleWeight - 0.5)));
			CGContextAddLineToPoint(c, (height - wwHeight - 1.0) * cosf(wedgeAngle - spacedWedgeWidth * (baseAngleWeight - 0.5)),
									(height - wwHeight - 1.0) * sinf(wedgeAngle - spacedWedgeWidth * (baseAngleWeight - 0.5)));
			CGContextSetLineCap(c, kCGLineCapButt);
			CGContextSetLineWidth(c, margin);
			CGContextSetStrokeColorWithColor(c, wheelColor);
			CGContextStrokePath(c);
			CGContextSetLineWidth(c, highlightWidth);
			CGContextSetStrokeColorWithColor(c, wheelHighlightColor);
			CGContextStrokePath(c);
			/**/
		} CGContextRestoreGState(c);
		
#pragma mark Draw Result Color Wedge Window
		CGContextSaveGState(c); {
			CGMutablePathRef resultWedge;
			CGFloat angleWeight = 0.0;
			if (baseAngleWeight != 0.0 || addAngleWeight != 0.0) {
				if (baseAngleWeight == 0.0) {
					angleWeight = self.addColorAngleWeight;
				} else if (addAngleWeight == 0.0 || (self.baseColorAngleWeight) <= (self.addColorAngleWeight)) {
					angleWeight = self.baseColorAngleWeight;
				} else {
					angleWeight = self.addColorAngleWeight;
				}
			}
			
			CGPathAddArc(resultClip, NULL, 0.0, 0.0,
						 self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight,
						 w.arc.start, w.arc.end, NO);
			CGPathAddArc(resultClip, NULL, 0.0, 0.0,
						 self.strength * (height - 4.0 * wwHeight) + wwHeight,
						 w.arc.end, w.arc.start, YES);
			CGPathCloseSubpath(resultClip);
			CGContextBeginPath(c);
			CGContextAddPath(c, resultClip);
			CGContextClip(c);

			CGContextBeginPath(c);
			CGContextAddPath(c, resultClip);
			CGContextSetFillColorWithColor(c, self.color);
			CGContextFillPath(c);

			if (angleWeight != 0.0) {
/**/				
				resultWedge = CGPathCreateMutable();
				CGPathAddArc(resultWedge, NULL, 0.0, 0.0, self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight,
							 wedgeAngle - spacedWedgeWidth * (angleWeight + 0.5),
							 wedgeAngle - spacedWedgeWidth * (angleWeight - 0.5), NO);
				CGPathAddArc(resultWedge, NULL, 0.0, 0.0, self.strength * (height - 4.0 * wwHeight) + wwHeight,
							 wedgeAngle - spacedWedgeWidth * (angleWeight - 0.5),
							 wedgeAngle - spacedWedgeWidth * (angleWeight + 0.5), YES);
				CGPathCloseSubpath(resultWedge);
				CGContextBeginPath(c);
				CGContextAddPath(c, resultWedge);
				CGContextSetFillColorWithColor(c, [self transitionColor]);
				CGContextFillPath(c);
				CGPathRelease(resultWedge);
/**/
				if (baseAngleWeight != 0.0 && addAngleWeight != 0.0) {
					struct arc resultWedgeArc;
					CGColorRef transitionMidColor = NULL;
					CGFloat midAngleWeight = 0.0;
					if (self.baseColorAngleWeight >= self.addColorAngleWeight) {
						midAngleWeight = self.baseColorAngleWeight;
					} else {
						midAngleWeight = self.addColorAngleWeight;
					}
					
					resultWedgeArc.start = MAX(wedgeAngle - spacedWedgeWidth * (midAngleWeight - 0.5), wedgeAngle - spacedWedgeWidth * (angleWeight + 0.5));
					resultWedgeArc.end = wedgeAngle - spacedWedgeWidth * (angleWeight - 0.5);
					if (resultWedgeArc.start < w.arc.end) {
						if (self.baseColorAngleWeight >= self.addColorAngleWeight) {
							transitionMidColor = [self copyColorWithBaseColor:self.baseColor addColor:transitionAddColor];
						} else {
							transitionMidColor = [self copyColorWithBaseColor:transitionBaseColor addColor:self.addColor];
						}
						resultWedge = CGPathCreateMutable();
						CGPathAddArc(resultWedge, NULL, 0.0, 0.0, self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight,
									 resultWedgeArc.start, resultWedgeArc.end,
									 NO);
						CGPathAddArc(resultWedge, NULL, 0.0, 0.0, self.strength * (height - 4.0 * wwHeight) + wwHeight,
									 resultWedgeArc.end, resultWedgeArc.start,
									 YES);
						CGPathCloseSubpath(resultWedge);
						CGContextBeginPath(c);
						CGContextAddPath(c, resultWedge);
						CGContextSetFillColorWithColor(c, transitionMidColor);
						CGContextFillPath(c);
						CGPathRelease(resultWedge);
						CGColorRelease(transitionMidColor);
					}
					
					resultWedgeArc.start = wedgeAngle - spacedWedgeWidth * (midAngleWeight + 0.5);
					resultWedgeArc.end = MIN(wedgeAngle - spacedWedgeWidth * (angleWeight + 0.5), wedgeAngle - spacedWedgeWidth * (midAngleWeight - 0.5));
					if (resultWedgeArc.end > w.arc.start) {
						if (self.baseColorAngleWeight <= self.addColorAngleWeight) {
							transitionMidColor = [self copyColorWithBaseColor:self.baseColor addColor:transitionAddColor];
						} else {
							transitionMidColor = [self copyColorWithBaseColor:transitionBaseColor addColor:self.addColor];
						}
						resultWedge = CGPathCreateMutable();
						CGPathAddArc(resultWedge, NULL, 0.0, 0.0, self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight,
									 resultWedgeArc.start, resultWedgeArc.end,
									 NO);
						CGPathAddArc(resultWedge, NULL, 0.0, 0.0, self.strength * (height - 4.0 * wwHeight) + wwHeight,
									 resultWedgeArc.end, resultWedgeArc.start,
									 YES);
						CGPathCloseSubpath(resultWedge);
						CGContextBeginPath(c);
						CGContextAddPath(c, resultWedge);
						CGContextSetFillColorWithColor(c, transitionMidColor);
						CGContextFillPath(c);
						CGPathRelease(resultWedge);
						CGColorRelease(transitionMidColor);
					}
					
					CGContextBeginPath(c);
					CGContextMoveToPoint(c, (self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight) * cosf(wedgeAngle - spacedWedgeWidth * (midAngleWeight - 0.5)),
										 (self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight) * sinf(wedgeAngle - spacedWedgeWidth * (midAngleWeight - 0.5)));
					CGContextAddLineToPoint(c, (self.strength * (height - 4.0 * wwHeight) + wwHeight) * cosf(wedgeAngle - spacedWedgeWidth * (midAngleWeight - 0.5)),
											(self.strength * (height - 4.0 * wwHeight) + wwHeight) * sinf(wedgeAngle - spacedWedgeWidth * (midAngleWeight - 0.5)));
					CGContextMoveToPoint(c, (self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight) * cosf(wedgeAngle - spacedWedgeWidth * (midAngleWeight + 0.5)),
										 (self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight) * sinf(wedgeAngle - spacedWedgeWidth * (midAngleWeight + 0.5)));
					CGContextAddLineToPoint(c, (self.strength * (height - 4.0 * wwHeight) + wwHeight) * cosf(wedgeAngle - spacedWedgeWidth * (midAngleWeight + 0.5)),
											(self.strength * (height - 4.0 * wwHeight) + wwHeight) * sinf(wedgeAngle - spacedWedgeWidth * (midAngleWeight + 0.5)));
					CGContextSetLineCap(c, kCGLineCapButt);
					CGContextSetLineWidth(c, margin);
					CGContextSetStrokeColorWithColor(c, wheelColor);
					CGContextStrokePath(c);
					CGContextSetLineWidth(c, highlightWidth);
					CGContextSetStrokeColorWithColor(c, wheelHighlightColor);
					CGContextStrokePath(c);
				}
			
				/**/
				CGContextBeginPath(c);
				CGContextMoveToPoint(c, (self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight) * cosf(wedgeAngle - spacedWedgeWidth * (angleWeight + 0.5)),
									 (self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight) * sinf(wedgeAngle - spacedWedgeWidth * (angleWeight + 0.5)));
				CGContextAddLineToPoint(c, (self.strength * (height - 4.0 * wwHeight) + wwHeight) * cosf(wedgeAngle - spacedWedgeWidth * (angleWeight + 0.5)),
										(self.strength * (height - 4.0 * wwHeight) + wwHeight) * sinf(wedgeAngle - spacedWedgeWidth * (angleWeight + 0.5)));
				CGContextMoveToPoint(c, (self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight) * cosf(wedgeAngle - spacedWedgeWidth * (angleWeight - 0.5)),
									 (self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight) * sinf(wedgeAngle - spacedWedgeWidth * (angleWeight - 0.5)));
				CGContextAddLineToPoint(c, (self.strength * (height - 4.0 * wwHeight) + wwHeight) * cosf(wedgeAngle - spacedWedgeWidth * (angleWeight - 0.5)),
										(self.strength * (height - 4.0 * wwHeight) + wwHeight) * sinf(wedgeAngle - spacedWedgeWidth * (angleWeight - 0.5)));
				CGContextSetLineCap(c, kCGLineCapButt);
				CGContextSetLineWidth(c, margin);
				CGContextSetStrokeColorWithColor(c, wheelColor);
				CGContextStrokePath(c);
				CGContextSetLineWidth(c, highlightWidth);
				CGContextSetStrokeColorWithColor(c, wheelHighlightColor);
				CGContextStrokePath(c);
				/**/
			}
		} CGContextRestoreGState(c);

#pragma mark Build Wedge Border
		CGFloat marginAdjustmentAngle;
		CGFloat marginStartAngle;
		CGFloat marginEndAngle;
		
		marginAdjustmentAngle = (CGFloat)atanf(cornerRadius / (height + (marginOffsetFactor + 1.0) * margin - cornerRadius));
		marginStartAngle = w.arc.end - marginAdjustmentAngle;
		marginEndAngle = w.arc.start + marginAdjustmentAngle;
		CGPathAddArc(wheel, NULL, 0, marginOffsetFactor * margin,
					 height + (marginOffsetFactor + 1.0) * margin, 
					 wedgeAngle, marginStartAngle, NO);
		CGPathAddArc(wheel, NULL,
					 (height + (marginOffsetFactor + 1.0) * margin - cornerRadius) * (CGFloat)cosf(marginStartAngle),
					 marginOffsetFactor * margin + (height + (marginOffsetFactor + 1.0) * margin - cornerRadius) * (CGFloat)sinf(marginStartAngle),
					 cornerRadius, marginStartAngle, marginStartAngle + M_PI / 2.0, NO);
		
		marginAdjustmentAngle = (CGFloat)atanf(cornerRadius / (wwHeight + (marginOffsetFactor - 1.0) * margin + cornerRadius));
		if (2.0 * marginAdjustmentAngle > wedgeWidth) {
			marginStartAngle = wedgeAngle;
			CGPathAddArc(wheel, NULL,
						 (wwHeight + (marginOffsetFactor - 1.0) * margin + cornerRadius) * (CGFloat)cosf(marginStartAngle),
						 marginOffsetFactor * margin + (wwHeight + (marginOffsetFactor - 1.0) * margin + cornerRadius) * (CGFloat)sinf(marginStartAngle),
						 cornerRadius, marginStartAngle + M_PI / 2.0, marginEndAngle + M_PI * 3.0 / 2.0, NO);
		} else {
			marginStartAngle = w.arc.end - marginAdjustmentAngle;
			marginEndAngle = w.arc.start + marginAdjustmentAngle;
			CGPathAddArc(wheel, NULL,
						 (wwHeight + (marginOffsetFactor - 1.0) * margin + cornerRadius) * (CGFloat)cosf(marginStartAngle),
						 marginOffsetFactor * margin + (wwHeight + (marginOffsetFactor - 1.0) * margin + cornerRadius) * (CGFloat)sinf(marginStartAngle),
						 cornerRadius, marginStartAngle + M_PI / 2.0, marginStartAngle + M_PI, NO);
			CGPathAddArc(wheel, NULL, 0, marginOffsetFactor * margin, wwHeight + (marginOffsetFactor - 1.0) * margin, 
						 marginStartAngle, w.arc.start, YES);
			CGPathAddArc(wheel, NULL,
						 (wwHeight + (marginOffsetFactor - 1.0) * margin + cornerRadius) * (CGFloat)cosf(marginEndAngle),
						 marginOffsetFactor * margin + (wwHeight + (marginOffsetFactor - 1.0) * margin + cornerRadius) * (CGFloat)sinf(marginEndAngle),
						 cornerRadius, marginEndAngle + M_PI, marginEndAngle + M_PI * 3.0 / 2.0, NO);
		}
		
		marginAdjustmentAngle = (CGFloat)atanf(cornerRadius / (height + (marginOffsetFactor + 1.0) * margin - cornerRadius));
		marginEndAngle = w.arc.start + marginAdjustmentAngle;
		CGPathAddArc(wheel, NULL,
					 (height + (marginOffsetFactor + 1.0) * margin - cornerRadius) * (CGFloat)cosf(marginEndAngle),
					 marginOffsetFactor * margin + (height + (marginOffsetFactor + 1.0) * margin - cornerRadius) * (CGFloat)sinf(marginEndAngle),
					 cornerRadius, marginEndAngle - M_PI / 2.0, marginEndAngle, NO);
		CGPathAddArc(wheel, NULL, 0, marginOffsetFactor * margin, height + (marginOffsetFactor + 1.0) * margin, 
					 marginEndAngle, wedgeAngle +               0.0, NO);
		
		CGPathAddPath(wheel, NULL, resultClip);
		CGPathAddPath(wheel, NULL, baseClip);
		
		marginAdjustmentAngle = (CGFloat)atanf((cornerRadius - highlightInset) / (height + (marginOffsetFactor + 1.0) * (margin - highlightInset) - (cornerRadius - highlightInset)));
		marginStartAngle = w.arc.end - marginAdjustmentAngle;
		marginEndAngle = w.arc.start + marginAdjustmentAngle;
		CGPathAddArc(highlightEdge, NULL, 0, marginOffsetFactor * (margin - highlightInset), height + (marginOffsetFactor + 1.0) * (margin - highlightInset), marginStartAngle, marginEndAngle, YES);
		CGPathAddArc(highlightEdge, NULL,
					 (height + (marginOffsetFactor + 1.0) * (margin - highlightInset) - (cornerRadius - highlightInset)) * (CGFloat)cosf(marginEndAngle),
					 marginOffsetFactor * (margin - highlightInset) + (height + (marginOffsetFactor + 1.0) * (margin - highlightInset) - (cornerRadius - highlightInset)) * (CGFloat)sinf(marginEndAngle),
					 cornerRadius - highlightInset, marginEndAngle, marginEndAngle - M_PI / 2.0, YES);
		marginAdjustmentAngle = (CGFloat)atanf((cornerRadius - highlightInset) / (wwHeight + (marginOffsetFactor - 1.0) * (margin - highlightInset) + cornerRadius - highlightInset));
		marginEndAngle = w.arc.start + marginAdjustmentAngle;
		CGPathAddLineToPoint(highlightEdge, NULL,
							 (wwHeight + (marginOffsetFactor - 1.0) * (margin - highlightInset) + cornerRadius - highlightInset) * (CGFloat)cosf(marginEndAngle) + (cornerRadius - highlightInset) * (CGFloat)cosf(marginEndAngle + M_PI * 3.0 / 2.0),
							 marginOffsetFactor * (margin - highlightInset) + (wwHeight + (marginOffsetFactor - 1.0) * (margin - highlightInset) + cornerRadius - highlightInset) * (CGFloat)sinf(marginEndAngle) + (cornerRadius - highlightInset) * (CGFloat)sinf(marginEndAngle + M_PI * 3.0 / 2.0)
							 );
		
#pragma mark Build Add Color Wedge Window
		CGFloat tipHeight = MIN(height - 2.3 * wwHeight, self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight);
		CGFloat addMidHeight = tipHeight + wwHeight;
		CGPoint marginOffsetPoint = CGPointZero;
		CGPathAddArc(addClip, NULL,
					 0.0, 0.0,
					 height - wwHeight,
					 w.arc.start, w.arc.end, NO);
		CGPathAddArc(addClip, NULL,
					 0.0, 0.0,
					 wwHeight,
					 w.arc.end, w.arc.start, YES);
		CGPathCloseSubpath(addClip);
#ifdef DRAW_ADD_SYMBOL
		CGPathAddEllipseInRect(addClip, NULL, CGRectMake(-wwHeight / 2.0, -height + wwHeight - wwHeight / 2.0 + margin, wwHeight, wwHeight));
#endif
		
		//tipHeight = 0.0;
		if (addAngleWeight != 0.0) {
			CGFloat aaw;
			if (addAngleWeight < 0.0)
				aaw = addAngleWeight + 1.0;
			else
				aaw = addAngleWeight - 1.0;
			addWedge[0] = CGPathCreateMutable();
			marginOffsetPoint = CGPointMake(marginOffsetFactor * margin * 0.5 * cosf(wedgeAngle - wedgeWidth * aaw + 1.0 * asinf(1.0 / (4.0 * marginOffsetFactor))),
											marginOffsetFactor * margin * 0.5 * (sinf(wedgeAngle - wedgeWidth * aaw + 1.0 * asinf(1.0 / (4.0 * marginOffsetFactor))) + 1.0));
			CGPathAddArc(addWedge[0], NULL,
						 marginOffsetPoint.x,
						 marginOffsetPoint.y,
						 height - wwHeight - margin,
						 wedgeAngle - wedgeWidth * (aaw + 0.5),
						 wedgeAngle - wedgeWidth * (aaw - 0.5), NO);
			CGPathAddLineToPoint(addWedge[0], NULL,
								 marginOffsetPoint.x + addMidHeight * cosf(wedgeAngle - wedgeWidth * (aaw - 0.5)),
								 marginOffsetPoint.y + addMidHeight * sinf(wedgeAngle - wedgeWidth * (aaw - 0.5)));
			if (tipHeight > addMidHeight * sinf(w.arc.end)) {
				CGPathAddLineToPoint(addWedge[0], NULL,
									 marginOffsetPoint.x + tipHeight * cosf(wedgeAngle - wedgeWidth * aaw),
									 marginOffsetPoint.y + tipHeight * sinf(wedgeAngle - wedgeWidth * aaw));
			}
			CGPathAddLineToPoint(addWedge[0], NULL,
								 marginOffsetPoint.x + addMidHeight * cosf(wedgeAngle - wedgeWidth * (aaw + 0.5)),
								 marginOffsetPoint.y + addMidHeight * sinf(wedgeAngle - wedgeWidth * (aaw + 0.5)));

			marginOffsetPoint = CGPointMake(marginOffsetFactor * margin * 0.5 * cosf(wedgeAngle - wedgeWidth * addAngleWeight + 1.0 * asinf(1.0 / (4.0 * marginOffsetFactor))),
											marginOffsetFactor * margin * 0.5 * (sinf(wedgeAngle - wedgeWidth * addAngleWeight + 1.0 * asinf(1.0 / (4.0 * marginOffsetFactor))) + 1.0));
		}
		addWedge[1] = CGPathCreateMutable();
//		marginOffsetPoint = CGPointZero;
		CGPathAddArc(addWedge[1], NULL,
					 marginOffsetPoint.x,
					 marginOffsetPoint.y,
					 height - wwHeight - margin,
					 wedgeAngle - wedgeWidth * (addAngleWeight + 0.5),
					 wedgeAngle - wedgeWidth * (addAngleWeight - 0.5), NO);
		CGPathAddLineToPoint(addWedge[1], NULL,
							 marginOffsetPoint.x + addMidHeight * cosf(wedgeAngle - wedgeWidth * (addAngleWeight - 0.5)),
							 marginOffsetPoint.y + addMidHeight * sinf(wedgeAngle - wedgeWidth * (addAngleWeight - 0.5)));
		if (tipHeight > addMidHeight * sinf(w.arc.end)) {
			CGPathAddLineToPoint(addWedge[1], NULL,
								 marginOffsetPoint.x + tipHeight * cosf(wedgeAngle - wedgeWidth * addAngleWeight),
								 marginOffsetPoint.y + tipHeight * sinf(wedgeAngle - wedgeWidth * addAngleWeight));
		}
		CGPathAddLineToPoint(addWedge[1], NULL,
							 marginOffsetPoint.x + addMidHeight * cosf(wedgeAngle - wedgeWidth * (addAngleWeight + 0.5)),
							 marginOffsetPoint.y + addMidHeight * sinf(wedgeAngle - wedgeWidth * (addAngleWeight + 0.5)));
		
#pragma mark Draw Shadow
		CGContextSetShadow(c, CGSizeMake(margin * -0.618, margin * 0.618), margin * 1.618);
		CGContextSetFillColorWithColor(c, wheelColor);
		
		CGFloat overlap = (self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight - (height - 2.3 * wwHeight)) / (wwHeight * 0.3);
		if (overlap > 0.0) {
			CGContextSaveGState(c); {
				CGColorSpaceRef graySpace = CGColorSpaceCreateDeviceGray();
				CGFloat shadowColorComponents[] = {0.0, overlap / 3.0};
				CGColorRef shadowColor = CGColorCreate(graySpace, shadowColorComponents);
				CGContextSetShadowWithColor(c, CGSizeMake(margin * -0.618, margin * 0.618), margin * 1.618, shadowColor);

				CGContextBeginPath(c);
				CGContextAddPath(c, addClip);
				CGContextClip(c);
				
				if (addAngleWeight != 0.0) {
					CGContextBeginPath(c);
					CGContextAddPath(c, addWedge[0]);
					CGContextFillPath(c);
				}
				
				CGContextBeginPath(c);
				CGContextAddPath(c, addWedge[1]);
				CGContextFillPath(c);

				CGColorRelease(shadowColor);
				CGColorSpaceRelease(graySpace);
			} CGContextRestoreGState(c);
		}
		
#pragma mark Draw Wedge Border (with shadow)
		CGContextBeginPath(c);
		CGContextAddPath(c, wheel);
		CGContextSetFillColorWithColor(c, wheelColor);
		CGContextEOFillPath(c);
#ifdef DRAW_ADD_SYMBOL
		CGContextBeginPath(c);
		CGContextAddEllipseInRect(c, CGRectMake(-wwHeight / 2.0, -height + wwHeight - wwHeight / 2.0 + margin, wwHeight, wwHeight));
		CGContextFillPath(c);
#endif
	} CGContextRestoreGState(c);
	/**/
#pragma mark Build Wedge Highlight
	CGPathAddArc(highlight, NULL,
				 0.0, marginOffsetFactor * (margin - highlightInset - highlightWidth / 2.0),
				 height - wwHeight + (marginOffsetFactor - 1.0) * (margin - highlightInset - highlightWidth / 2.0),
				 w.arc.end, w.arc.start, YES);
	CGPathAddLineToPoint(highlight, NULL,
						 (height + wwHeight) / 2.0 * (CGFloat)cosf(w.arc.start),
						 marginOffsetFactor * (margin - highlightInset - highlightWidth / 2.0) + (height + wwHeight) / 2.0 * (CGFloat)sinf(w.arc.start));
	CGPathAddLineToPoint(highlight, NULL,
						 (height - wwHeight * 2.5) * (CGFloat)cosf(w.arc.end),
						 marginOffsetFactor * (margin - highlightInset - highlightWidth / 2.0) + (height - wwHeight * 2.5) * (CGFloat)sinf(w.arc.end));
	
	CGPathMoveToPoint(highlightEdge, NULL,
					  (height - 1.0 * wwHeight - highlightInset) * (CGFloat)cosf(w.arc.end),
					  (height - 1.0 * wwHeight - highlightInset) * (CGFloat)sinf(w.arc.end));
	CGPathAddArc(highlightEdge, NULL,
				 0, 0,
				 height - 1.0 * wwHeight - highlightInset,
				 w.arc.end, w.arc.start, YES);
	
#pragma mark Draw Wedge Highlight
	CGContextSaveGState(c); {
		CGContextBeginPath(c);
		CGContextAddPath(c, wheel);
		CGContextEOClip(c);
		
#ifdef DRAW_ADD_SYMBOL
		CGContextBeginPath(c);
		CGContextAddPath(c, highlight);
		CGContextAddEllipseInRect(c, CGRectMake(-wwHeight / 2.0, -height + wwHeight - wwHeight / 2.0 + margin, wwHeight, wwHeight));
		CGContextSetFillColorWithColor(c, wheelHighlightColor);
		CGContextFillPath(c);
#endif
	} CGContextRestoreGState(c);
	
#ifdef DRAW_ADD_SYMBOL
	CGContextSaveGState(c); {
		CGContextBeginPath(c);
		CGContextAddEllipseInRect(c, CGRectMake(-wwHeight / 2.0, -height + wwHeight - wwHeight / 2.0 + margin, wwHeight, wwHeight));
		CGContextSetFillColorWithColor(c, wheelHighlightColor);
		CGContextFillPath(c);
	} CGContextRestoreGState(c);
#endif
	
#pragma mark Draw Add Color Wedge Window
	CGContextSaveGState(c); {
		CGContextBeginPath(c);
		CGContextAddPath(c, addClip);
		CGContextEOClip(c);

		if (addAngleWeight != 0.0) {
			CGContextBeginPath(c);
			CGContextAddPath(c, addWedge[0]);
			CGContextSetFillColorWithColor(c, self.addColor);
			CGContextFillPath(c);
		}
		
		CGContextBeginPath(c);
		CGContextAddPath(c, addWedge[1]);
		if (addAngleWeight != 0.0)
			CGContextSetFillColorWithColor(c, transitionAddColor);
		else
			CGContextSetFillColorWithColor(c, self.addColor);
		CGContextFillPath(c);
	} CGContextRestoreGState(c);
		
	CGContextSaveGState(c); {
		CGContextBeginPath(c);
		CGContextAddPath(c, highlightEdge);
		CGContextSetLineWidth(c, highlightWidth);
		CGContextSetLineCap(c, kCGLineCapRound);
		CGContextSetStrokeColorWithColor(c, wheelHighlightColor);
		CGContextStrokePath(c);
	} CGContextRestoreGState(c);
	
#ifdef DRAW_ADD_SYMBOL
	CGContextSaveGState(c); {
		CGContextBeginPath(c);
		CGContextSetFillColorWithColor(c, wheelColor);
		CGContextAddEllipseInRect(c, CGRectMake(-wwHeight / 2.0 + margin / 2.0, -height + wwHeight - wwHeight / 2.0 + 3.0 * margin / 2.0, wwHeight - margin, wwHeight - margin));
		CGContextFillPath(c);

		CGColorRef symbolColor = CGColorCreateCopyWithAlpha(wheelHighlightColor, 0.88);
		CGContextBeginPath(c);
		CGContextSetLineCap(c, kCGLineCapRound);
		CGContextSetLineWidth(c, margin * 1.5);
		CGContextSetStrokeColorWithColor(c, symbolColor);
		CGContextMoveToPoint(c, -(wwHeight - 4.0 * margin) / 2.0, -height + wwHeight + margin);
		CGContextAddLineToPoint(c, (wwHeight - 4.0 * margin) / 2.0, -height + wwHeight + margin);
		CGContextMoveToPoint(c, 0.0, -height + wwHeight + margin - (wwHeight - 4.0 * margin) / 2.0);
		CGContextAddLineToPoint(c, 0.0, -height + wwHeight + margin + (wwHeight - 4.0 * margin) / 2.0);
		CGContextStrokePath(c);
		CGColorRelease(symbolColor);
	} CGContextRestoreGState(c);
#endif
	
	/**/
	CGColorSpaceRelease(space);
	CGColorRelease(wheelColor);
	CGColorRelease(wheelHighlightColor);
	CGPathRelease(wheel);
	CGPathRelease(addWedge[0]);
	CGPathRelease(addWedge[1]);
	CGPathRelease(addClip);
	CGPathRelease(baseClip);
	CGPathRelease(resultClip);
	CGPathRelease(highlightEdge);
	CGPathRelease(highlight);
}

+ (void)computeColor:(CGFloat *)colorComponents fromBaseColor:(CGFloat *)baseComponents withAddColor:(CGFloat *)addComponents forStrength:(CGFloat)strength model:(CGColorSpaceModel)model {
	CGFloat magnitude = 0.0;
	size_t noc = 3;
	switch (model) {
		case kCGColorSpaceModelCMYK:
			noc++;
		case kCGColorSpaceModelRGB:
			for (int i = 0; i < noc; i++) {
				magnitude += addComponents[i];
			}
			//White is the absence of ink ie. adding white is to remove ink uniformally
			if (magnitude == 0.0f) {
				for (int i = 0; i < noc; i++) {
					colorComponents[i] = MAX(MIN(baseComponents[i] - (strength) * addComponents[noc], 1.0f), 0.0f);
				}
			} else if (magnitude == 4.0f) {
				for (int i = 0; i < noc; i++) {
					if (baseComponents[i] > 0.0) {
						colorComponents[i] = baseComponents[i] * (1.0 - strength) + addComponents[i] * strength;
					} else {
						colorComponents[i] = 0.0f;
					}
				}
			} else {
				int i;
/*				for (i = 0; i < 3; i++) {
					colorComponents[i] = MAX(MIN(baseComponents[i] - strength * (1.0 - addComponents[i]), 1.0f), 0.0f);
				}
				if (noc > 3) {
					colorComponents[i] = MAX(MIN(baseComponents[i] + strength * addComponents[i], 1.0f), 0.0f);
				}
*/				for (i = 0; i < noc; i++) {
					colorComponents[i] = baseComponents[i] * (1.0 - strength) + addComponents[i] * strength;
				}
			}
			break;
		case kCGColorSpaceModelLab:
			colorComponents[0] = baseComponents[0];
			magnitude = ABS(addComponents[1]) + ABS(addComponents[2]);
			if (magnitude == 0.0f) {
				if (addComponents[0] == 0.0) {
					colorComponents[0] *= 1.0 - strength;
				} else {
					colorComponents[0] *= strength * addComponents[0] / 100.0;
				}
			} else {
				for (int i = 1; i < noc; i++) {
					colorComponents[i] = baseComponents[i] * (1.0 - strength) + addComponents[i] * strength;
				}
			}
			
			break;
		default:
			break;
	}
	colorComponents[noc] = 1.0;
}
+ (BOOL)computeBaseColor:(CGFloat *)baseComponents andStrength:(CGFloat *)strength fromColor:(CGFloat *)colorComponents forAddColor:(CGFloat *)addComponents model:(CGColorSpaceModel)model {
	CGFloat magnitude = 0.0;
	CGFloat min = 0.0;
	size_t noc = 3;
	int i;
	BOOL identityColor = NO;
	*strength = min;
	
	switch (model) {
		case kCGColorSpaceModelCMYK:
			noc++;
		case kCGColorSpaceModelRGB:
			identityColor = YES;
			for (i = 0; i < noc && identityColor; i++)
				identityColor = (addComponents[i] == colorComponents[i]);
			if (identityColor)
				break;
			
			for (i = 0; i < noc; i++) {
				magnitude += addComponents[i];
			}
			//White is the absence of ink ie. adding white is to remove ink uniformally
			if (magnitude == 0.0f) {
				for (i = 0; i < noc; i++) {
					*strength = 1.0 - colorComponents[i];
					if (*strength < min)
						min = *strength;
				}
				*strength = min;
				for (i = 0; i < noc; i++)
					baseComponents[i] = MAX(MIN(colorComponents[i] + (*strength) * addComponents[noc], 1.0f), 0.0f);
			} else {
				for (i = 0; i < noc; i++) {
					if (colorComponents[i] < addComponents[i]) {
						*strength = colorComponents[i] / addComponents[i];
					} else if (colorComponents[i] > addComponents[i]) {
						*strength = (colorComponents[i] - 1.0) / (addComponents[i] - 1.0);
					} else {
						//b = c = a -> s is undef
					}
					if (min <= 0.0 || (0.0 < *strength && *strength < min))
						min = *strength;
				}
				*strength = min;
				for (i = 0; i < noc; i++) {
					baseComponents[i] = MAX(MIN((colorComponents[i] - addComponents[i] * *strength) / (1.0 - *strength), 1.0f), 0.0f);
				}
			}
			break;
		case kCGColorSpaceModelLab:
			/* TODO:
			colorComponents[0] = baseComponents[0];
			magnitude = ABS(addComponents[1]) + ABS(addComponents[2]);
			if (magnitude == 0.0f) {
				if (addComponents[0] == 0.0) {
					colorComponents[0] *= 1.0 - strength;
				} else {
					colorComponents[0] *= strength * addComponents[0] / 100.0;
				}
			} else {
				for (i = 1; i < noc; i++) {
					colorComponents[i] = baseComponents[i] * (1.0 - strength) + addComponents[i] * strength;
				}
			}
			*/
			break;
		default:
			break;
	}
	baseComponents[noc] = 1.0;
	
	CGFloat computedComponents[noc + 1];
	//NSLog(@"baseComponents:  %1.2f|%1.2f %1.2f %1.2f %1.2f", *strength, baseComponents[0], baseComponents[1], baseComponents[2], baseComponents[3]);
	[PhiColorWheelLayer computeColor:computedComponents fromBaseColor:baseComponents withAddColor:addComponents forStrength:*strength model:model];
	//NSLog(@"computedComponents:   %1.2f %1.2f %1.2f %1.2f", computedComponents[0], computedComponents[1], computedComponents[2], computedComponents[3]);
	BOOL match = YES;
	if (!identityColor) for (i = 0; i < noc && match; i++)
		match = (computedComponents[i] == colorComponents[i]);
	if (!match || identityColor) {
		memcpy(baseComponents, colorComponents, noc * sizeof(CGFloat));
		*strength = 0.0;
	}
	return identityColor || (match && *strength != 0.0 && baseComponents[3] != 1.0);
}

- (CGColorRef)copyColorWithBaseColor:(CGColorRef)base addColor:(CGColorRef)add {
	CGColorRef c;
	
	CGColorSpaceRef space = CGColorGetColorSpace(base);
	CGFloat colorComponents[CGColorSpaceGetNumberOfComponents(space)];
	CGFloat *baseComponents = (CGFloat *)CGColorGetComponents(base);
	CGFloat *addComponents = (CGFloat *)CGColorGetComponents(add);
	
	[[self class] computeColor:colorComponents fromBaseColor:baseComponents withAddColor:addComponents forStrength:(1.0 - self.strength) model:CGColorSpaceGetModel(space)];
	
	c = CGColorCreate(space, colorComponents);
	
	return c;
}

- (CGColorRef)color {
	CGColorRelease(color);
	
	color = [self copyColorWithBaseColor:self.baseColor addColor:self.addColor];
	
	return color;
}

- (CGColorRef)transitionColor {
	CGColorRelease(transitionColor);
	CGColorRef base = self.baseColor;
	CGColorRef add = self.addColor;
	
	if (self.baseColorAngleWeight != 0.0) {
		base = transitionBaseColor;
	}
	
	if (self.addColorAngleWeight != 0.0) {
		add = transitionAddColor;
	}
	
	transitionColor = [self copyColorWithBaseColor:base addColor:add];
	
	return transitionColor;
}

- (CGColorRef)transitionBaseColor {
	return transitionBaseColor;
}

- (CGColorRef)transitionAddColor {
	return transitionAddColor;
}

/*
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
*/
- (void)translateSegment:(NSString *)segment by:(CGPoint)point inLayer:(CALayer *)layer {
	point = [self convertPoint:point fromLayer:layer];
	CGFloat height = self.wedgeHeight;
	CGFloat wwHeight = self.wedgeWindowHeight;
	
	if (height <= 0.0)
		height = self.bounds.size.height - self.wedgeMargin - 0.5;
	if (wwHeight <= 0.0)
		wwHeight = height / 12.0;
	
	if ([segment isEqualToString:@"strength"]) {
		self.strength = MAX(MIN(self.strength - point.y / (height - 4.0 * wwHeight), 1.0), 0.0);
	}
}

- (BOOL)containsPoint:(CGPoint)point inSegment:(NSString *)segment inLayer:(CALayer *)layer {
	point = [self convertPoint:point fromLayer:layer];
	CGFloat height = self.wedgeHeight;
	CGFloat wwHeight = self.wedgeWindowHeight;
	CGFloat wedgeWidth = self.wedgeWindowArc; //Radians
	CGFloat wedgeAngle = M_PI / -2.0f;

	if (height <= 0.0)
		height = self.bounds.size.height - self.wedgeMargin - 0.5;
	if (wwHeight <= 0.0)
		wwHeight = height / 12.0;
	if (wedgeWidth <= 0.0)
		wedgeWidth = 2.0 * asinf(((self.bounds.size.width - 3.0 * self.wedgeMargin) / 2.0 - 0.5) / height);
	
	CGFloat x = point.x - CGRectGetMidX(self.bounds);
	CGFloat y = point.y - CGRectGetMaxY(self.bounds);
	CGFloat r = sqrtf(x * x + y * y);
	CGFloat t = atanf(y / x);
	CGFloat al = wedgeAngle - wedgeWidth * 0.5;
	CGFloat au = wedgeAngle + wedgeWidth * 0.5;
	
	if (x < 0)
		t += M_PI;
	while (t < 0)
		t += 2.0 * M_PI;
	while (al < 0.0 || au < 0.0) {
		al += 2.0 * M_PI;
		au += 2.0 * M_PI;
	}
	while (al > 0.0 || au > 0.0) {
		al -= 2.0 * M_PI;
		au -= 2.0 * M_PI;
	}
	al += 2.0 * M_PI;
	au += 2.0 * M_PI;

	if (al < t && t < au) {
		if ([segment isEqualToString:@"strength"]) {
			if (r >= self.strength * (height - 4.0 * wwHeight) + wwHeight && r <= self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight) {
				return YES;
			}
		} else if ([segment isEqualToString:@"baseColor"]) {
			if (r >= height - wwHeight && r <= height) {
				return YES;
			}
		} else if ([segment isEqualToString:@"addColor"]) {
			if (r > self.strength * (height - 4.0 * wwHeight) + 2.0 * wwHeight && r <= height - wwHeight) {
				return YES;
			}
		} else {
			if (r >= wwHeight && r <= height) {//TODO: include border
				return YES;
			}
		}
	}
	return NO;
}

@end
