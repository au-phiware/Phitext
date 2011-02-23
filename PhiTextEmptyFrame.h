//
//  PhiTextEmptyFrame.h
//  Phitext
//
//  Created by Corin Lawson on 7/04/10.
//  Copyright 2010 Corin Lawson. All rights reserved.
//

#import "PhiTextFrame.h"

@interface PhiTextEmptyFrame : PhiTextFrame {

}

- (id)initInPath:(CGPathRef)constraints forDocument:(PhiTextDocument *)doc attributes:(NSDictionary *)attributes;
- (void)setWidth:(CGFloat)width;

@end
