#import <UIKit/UIKit.h>

/// The text halo, in one file, because the effect has to agree with itself in
/// two places: the label that paints it and the controller that keeps that
/// label the right size.
///
/// Why a second label: a label's text is drawn into a backing store the size of
/// its own bounds, so a stroke or a glow that reaches past the glyphs is
/// clipped, silently. Drawing the stroke on the text label itself is exactly
/// that mistake -- the previous attempt at this feature produced nothing at all
/// on the phone. This is a separate label sitting one layer *behind* the text
/// with its frame grown by the effect's width, so the paint has somewhere to
/// go.
///
/// Why it can only ever show *outside* the glyphs: it draws the same string,
/// with the same font and the same alignment, and the text is drawn over it --
/// or, with adaptive colour on, the glyph-shaped patch of inverted backdrop is.
/// Whatever the halo paints inward of the glyph outline is covered by the glyph
/// itself. Nothing has to know which way CoreText strokes a glyph outline, and
/// no half-drawn ring can eat into a letter.

/// Halo settings as a widget set stores them.
@interface HeliumHaloStyle : NSObject

@property (nonatomic, assign) double outlineWidth;        // points, outside the glyphs
@property (nonatomic, strong) UIColor *outlineColor;
@property (nonatomic, assign) double glowWidth;           // points, blur radius
@property (nonatomic, strong) UIColor *glowColor;

@property (nonatomic, readonly) BOOL isActive;            // either effect switched on
@property (nonatomic, readonly) CGFloat pad;              // room the frame needs

/// True when two styles would paint the same thing. A repaint is skipped when
/// nothing that reaches the screen has changed, and the style is part of that:
/// dragging the width slider has to repaint even though the text is identical.
- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;

@end

/// Reads the halo keys out of one widget set's properties. Missing keys mean
/// "off": a widget set saved before this existed must not grow a halo.
HeliumHaloStyle *HeliumHaloStyleFromProperties(NSDictionary *properties);

/// "#RRGGBB" or "#RRGGBBAA", with or without the hash. nil if it is neither.
UIColor *HeliumHaloColorFromHexString(NSString *hex);

@interface HeliumHaloLabel : UILabel

/// Extra room on every side. The text is laid out in the box *minus* this, so
/// growing the frame never moves the glyphs relative to the text label's.
@property (nonatomic, assign) CGFloat haloPad;

@end

/// Repaint the halo for `attributedText`, which is the string already drawn on
/// top. Passing nil, or a style with both effects off, clears the label.
///
/// Visibility is deliberately not touched here: the caller hides the halo when
/// the text is hidden (a disabled widget, or a rotation the widget does not
/// show in), and a repaint every second must not undo that.
void HeliumDrawHalo(HeliumHaloLabel *haloLabel, NSAttributedString *attributedText, double fontSize, HeliumHaloStyle *style);
