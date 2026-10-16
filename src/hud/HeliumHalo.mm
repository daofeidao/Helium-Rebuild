#import "HeliumHalo.h"

#import "../extensions/UsefulFunctions.h"

@implementation HeliumHaloStyle

- (BOOL)isActive
{
    return self.outlineWidth > 0.0 || self.glowWidth > 0.0;
}

- (CGFloat)pad
{
    if (!self.isActive)
        return 0.0;
    // Ceil because a fractional pad would put the inner text box off the pixel
    // grid and blur the glyphs that are supposed to line up with the text.
    return ceil(MAX(self.outlineWidth, self.glowWidth));
}

@end

HeliumHaloStyle *HeliumHaloStyleFromProperties(NSDictionary *properties)
{
    HeliumHaloStyle *style = [[HeliumHaloStyle alloc] init];
    if (![properties isKindOfClass:[NSDictionary class]])
        return style;

    // The width keys are the only ones that decide whether anything is drawn,
    // so a toggle that is on with a width of zero stays invisible rather than
    // growing a halo nobody asked for. The caps are the maxima the editor's
    // sliders offer -- kept in step with EditWidgetSetView -- so a value left
    // over from an older build cannot draw a halo the slider cannot describe.
    double outlineWidth = getDoubleFromDictKey(properties, @"textOutlineWidth", 0.0);
    double glowWidth = getDoubleFromDictKey(properties, @"textGlowWidth", 0.0);
    style.outlineWidth = getBoolFromDictKey(properties, @"textOutlineEnabled") ? MIN(2.0, MAX(0.0, outlineWidth)) : 0.0;
    style.glowWidth = getBoolFromDictKey(properties, @"textGlowEnabled") ? MIN(6.0, MAX(0.0, glowWidth)) : 0.0;

    // Dark by default: the halo exists to hold white text apart from whatever
    // is behind it, and that is the one colour that always can.
    style.outlineColor = HeliumHaloColorFromHexString(getStringFromDictKey(properties, @"textOutlineColor", @"#000000")) ?: [UIColor blackColor];
    style.glowColor = HeliumHaloColorFromHexString(getStringFromDictKey(properties, @"textGlowColor", @"#000000")) ?: [UIColor blackColor];
    return style;
}

UIColor *HeliumHaloColorFromHexString(NSString *hex)
{
    if (![hex isKindOfClass:[NSString class]])
        return nil;

    NSString *clean = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    if ([clean hasPrefix:@"#"])
        clean = [clean substringFromIndex:1];
    if (clean.length != 6 && clean.length != 8)
        return nil;

    unsigned int value = 0;
    if (![[NSScanner scannerWithString:clean] scanHexInt:&value])
        return nil;

    CGFloat red, green, blue, alpha = 1.0;
    if (clean.length == 8) {
        // RRGGBBAA
        red = ((value >> 24) & 0xFF) / 255.0;
        green = ((value >> 16) & 0xFF) / 255.0;
        blue = ((value >> 8) & 0xFF) / 255.0;
        alpha = (value & 0xFF) / 255.0;
    } else {
        red = ((value >> 16) & 0xFF) / 255.0;
        green = ((value >> 8) & 0xFF) / 255.0;
        blue = (value & 0xFF) / 255.0;
    }
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@implementation HeliumHaloLabel

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    // The frame is grown by haloPad so the stroke and the glow have room. The
    // text is laid out in the un-grown box, which is the same box the text
    // label gets, so the glyphs land in the same place and the halo lines up
    // with the letters instead of sitting a few points off.
    CGFloat pad = self.haloPad;
    if (pad > 0.0)
        bounds = CGRectInset(bounds, pad, pad);
    return [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
}

@end

void HeliumDrawHalo(HeliumHaloLabel *haloLabel, NSAttributedString *attributedText, double fontSize, HeliumHaloStyle *style)
{
    if (!haloLabel)
        return;

    BOOL wantsOutline = style.outlineWidth > 0.0;
    BOOL wantsGlow = style.glowWidth > 0.0;

    if (!attributedText || attributedText.length == 0 || !style.isActive) {
        haloLabel.attributedText = nil;
        haloLabel.haloPad = 0.0;
        haloLabel.layer.shadowOpacity = 0.0f;
        haloLabel.layer.shadowRadius = 0.0;
        return;
    }

    haloLabel.haloPad = style.pad;

    NSMutableAttributedString *halo = [[NSMutableAttributedString alloc] initWithAttributedString:attributedText];
    NSRange whole = NSMakeRange(0, halo.length);

    // One colour over the whole string. The text itself keeps coloured runs
    // (the transfer-rate arrows and bars), and those must not punch holes in
    // the halo.
    UIColor *paintColor = wantsOutline ? style.outlineColor : style.glowColor;
    [halo addAttribute:NSForegroundColorAttributeName value:paintColor range:whole];

    if (wantsOutline) {
        // NSStrokeWidthAttributeName is a percentage of the font size, and the
        // stroke straddles the glyph outline, so the number has to say twice
        // the width that should end up visible outside the letter. Capped at
        // 100%: past that the "outline" swallows the glyph and stops being an
        // outline.
        double percent = MIN(100.0, (2.0 * style.outlineWidth / MAX(fontSize, 0.1)) * 100.0);
        [halo addAttribute:NSStrokeColorAttributeName value:style.outlineColor range:whole];
        [halo addAttribute:NSStrokeWidthAttributeName value:@(-percent) range:whole];
    }

    haloLabel.attributedText = halo;

    CALayer *layer = haloLabel.layer;
    if (wantsGlow) {
        // A layer shadow rather than an NSShadow attribute: the shadow is
        // composited around the layer's rendered glyphs, so it reaches past the
        // bounds without being clipped, and it is drawn behind the content, so
        // the part under the glyphs never shows.
        layer.shadowColor = style.glowColor.CGColor;
        layer.shadowOffset = CGSizeZero;
        layer.shadowRadius = style.glowWidth;
        layer.shadowOpacity = 1.0f;
    } else {
        layer.shadowOpacity = 0.0f;
        layer.shadowRadius = 0.0;
    }
    // The glow lives outside the bounds. Anything that clips here would cut the
    // halo off at the frame edge, which is the whole failure this design exists
    // to avoid.
    layer.masksToBounds = NO;
}
