// The IME backend of macOS and iOS (docs/TEXT.md, "Typing text"). sokol_app owns the window and its view, so the input method
// is attached to them from here, without editing sokol:
//  - macOS: the game's NSView gets NSTextInputClient (class_addProtocol + class_addMethod) and its keyDown: is replaced. While a
//    TextField has the focus (ime_set_enabled) a key goes through interpretKeyEvents, so the input method can compose; its
//    marked text becomes Input::on_composition_update, its insertText a commit. A key the input method did not use goes to the
//    game as before (KEY_DOWN and CHAR events through sokol_app), so game keys, dead keys and Option-accents work unchanged.
//  - iOS: sokol_app's hidden UITextField (the keyboard's first responder) keeps the marked text, and its delegate is replaced
//    by one that reads the field after each change: marked text is an update, the text that replaces it a commit.
// What a key did is decided by ime_text.h (tested on every host); tests/ime_text_tests.cpp drives the client's protocol methods
// on macOS. Everything here runs on the main thread, where sokol_app calls the game.
#include <TargetConditionals.h>

#include <algorithm>
#include <vector>

#include <fa/platform/input.h>

#include "ime_apple.h"
#include "ime_impl.h"
#include "ime_text.h"
#include "sokol_app.h"
#include "sokol_window.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>
#endif

namespace {

std::u16string to_u16(NSString* s) {
    std::u16string out(s.length, u'\0');
    if (!out.empty()) [s getCharacters:reinterpret_cast<unichar*>(out.data()) range:NSMakeRange(0, s.length)];
    return out;
}

// Typed text as the game gets it: control characters are keys, not text (the same filter as app.cpp's CHAR events).
void deliver_text(fa::Input& input, const std::u32string& text) {
    for (const char32_t c : text)
        if (c >= 32 && c != 127) input.on_text(c);
}

float dpi_scale() {
    const float s = sapp_dpi_scale();
    return s > 0.0f ? s : 1.0f;
}

fa::Input* g_input = nullptr;

}  // namespace

#if !TARGET_OS_IPHONE
// ---- macOS ------------------------------------------------------------------------------------------------------------------

// The view's NSTextInputClient: the state of the composition, and what a key down made of it.
@interface FaImeClient : NSObject <NSTextInputClient> {
@public
    fa::Input* input;
    BOOL enabled;
    BOOL hasMarked;
    NSUInteger markedLength;  // UTF-16 units of the marked text
    NSRange markedSelection;  // the caret / clause inside it, UTF-16
    fa::Rect caret;           // framebuffer pixels, as ime_set_caret_rect() got it
    // While keyDown: runs:
    BOOL inKeyDown;
    BOOL consumed;
    BOOL command;
    NSString* plain;
}
@property(nonatomic, weak) NSView* view;
- (void)keyDown:(NSEvent*)event inView:(NSView*)view;
- (void)cancelComposition;
@end

@implementation FaImeClient

- (BOOL)active {
    return enabled && input != nullptr;
}

- (void)deliverPlain:(NSString*)s {
    if (input) deliver_text(*input, fa::ime_text::utf16_to_utf32(to_u16(s)));
}

- (void)cancelComposition {
    const BOOL was = hasMarked;
    hasMarked = NO;
    markedLength = 0;
    markedSelection = NSMakeRange(0, 0);
    if (input && input->composing()) input->on_composition_cancel();
    if (was) [[NSTextInputContext currentInputContext] discardMarkedText];
}

- (void)keyDown:(NSEvent*)event inView:(NSView*)view {
    const NSEventModifierFlags chord = event.modifierFlags & (NSEventModifierFlagCommand | NSEventModifierFlagControl);
    if (![self active] || (!hasMarked && chord != 0)) {  // Cmd and Ctrl chords are shortcuts, not text
        fa_sapp_macos_key_down((__bridge const void*)event, true);
        return;
    }
    fa::ime_text::KeyOutcome o;
    o.wasComposing = hasMarked;
    inKeyDown = YES;
    consumed = NO;
    command = NO;
    plain = nil;
    [view interpretKeyEvents:@[ event ]];
    inKeyDown = NO;
    NSString* text = plain;
    plain = nil;
    o.composing = hasMarked;
    o.consumed = consumed;
    o.command = command;
    o.plainText = text != nil;
    o.plainTextIsEventText = text != nil && [text isEqualToString:event.characters];
    switch (fa::ime_text::decide_key(o)) {
        case fa::ime_text::KeyAction::Swallow: break;
        case fa::ime_text::KeyAction::GameWithoutText:
            fa_sapp_macos_key_down((__bridge const void*)event, false);
            [self deliverPlain:text];
            break;
        case fa::ime_text::KeyAction::Game: fa_sapp_macos_key_down((__bridge const void*)event, true); break;
    }
}

// ---- NSTextInputClient
- (void)insertText:(id)string replacementRange:(NSRange)replacementRange {
    NSString* s = [string isKindOfClass:[NSAttributedString class]] ? [string string] : (NSString*)string;
    if (![self active]) return;
    if (hasMarked) {  // the composition ends with this text: delivered once, as a commit, never also as plain text
        hasMarked = NO;
        markedLength = 0;
        markedSelection = NSMakeRange(0, 0);
        consumed = YES;
        input->on_composition_commit(fa::ime_text::utf16_to_utf32(to_u16(s)));
    } else if (inKeyDown) {  // keyDown: decides after interpretKeyEvents whether sokol_app also sends this as CHAR events
        plain = plain ? [plain stringByAppendingString:s] : s;
    } else {  // the emoji picker, dictation, services: no key event, no CHAR events
        [self deliverPlain:s];
    }
}

- (void)setMarkedText:(id)string selectedRange:(NSRange)selectedRange replacementRange:(NSRange)replacementRange {
    if (![self active]) return;
    const BOOL attributed = [string isKindOfClass:[NSAttributedString class]];
    NSString* s = attributed ? [string string] : (NSString*)string;
    consumed = YES;
    if (s.length == 0) {  // the input method took back the last character: the composition is over
        [self cancelComposition];
        return;
    }
    __block std::vector<fa::ime_text::Run> runs;  // filled by the block below
    if (attributed)  // the clause the IME converts is drawn thick
        [(NSAttributedString*)string enumerateAttribute:NSUnderlineStyleAttributeName
                                                inRange:NSMakeRange(0, s.length)
                                                options:0
                                             usingBlock:^(id value, NSRange range, BOOL*) {
                                                 if (![value isKindOfClass:[NSNumber class]]) return;
                                                 const bool thick = ([value integerValue] & 7) == NSUnderlineStyleThick;
                                                 runs.push_back(fa::ime_text::Run{range.location, range.length, thick});
                                             }];
    const std::u16string text = to_u16(s);
    const std::size_t selLoc = selectedRange.location == NSNotFound ? text.size() : selectedRange.location;
    fa::ime_text::Marked m = fa::ime_text::marked_from_utf16(text, selLoc, selectedRange.length, runs);
    hasMarked = YES;
    markedLength = s.length;
    markedSelection = NSMakeRange(std::min<NSUInteger>(selLoc, s.length), selectedRange.length);
    input->on_composition_update(std::move(m.text), m.caret, m.selLength);
}

- (void)unmarkText {
    if (!hasMarked) return;
    consumed = YES;  // the marked text is dropped, not typed: a commit arrives through insertText
    [self cancelComposition];
}

- (NSRange)selectedRange {
    return hasMarked ? markedSelection : NSMakeRange(NSNotFound, 0);
}

- (NSRange)markedRange {
    return hasMarked ? NSMakeRange(0, markedLength) : NSMakeRange(NSNotFound, 0);
}

- (BOOL)hasMarkedText {
    return hasMarked;
}

- (NSAttributedString*)attributedSubstringForProposedRange:(NSRange)range actualRange:(NSRangePointer)actualRange {
    return nil;
}

- (NSArray<NSAttributedStringKey>*)validAttributesForMarkedText {
    return @[];
}

// Where the candidate window goes: the caret's rectangle on the screen (AppKit's origin is the bottom left).
- (NSRect)firstRectForCharacterRange:(NSRange)range actualRange:(NSRangePointer)actualRange {
    NSView* v = self.view;
    if (v == nil) return NSZeroRect;
    const float s = dpi_scale();
    NSRect r = NSMakeRect(caret.x / s, caret.y / s, caret.w / s, caret.h / s);
    if (caret.w <= 0 && caret.h <= 0) r = NSMakeRect(0, 0, 1, 16);  // no caret yet: the window's top left
    if (!v.isFlipped) r.origin.y = v.bounds.size.height - r.origin.y - r.size.height;
    r = [v convertRect:r toView:nil];
    if (v.window) r = [v.window convertRectToScreen:r];
    return r;
}

- (NSUInteger)characterIndexForPoint:(NSPoint)point {
    return NSNotFound;
}

- (void)doCommandBySelector:(SEL)selector {
    command = YES;  // Enter, Backspace, arrows...: the game gets them as keys
}

@end

namespace {

FaImeClient* g_client = nil;

FaImeClient* client() {
    if (!g_client) g_client = [[FaImeClient alloc] init];
    return g_client;
}

// The view's own methods forward to the client, so the view class stays sokol's.
void view_keyDown(id self, SEL, NSEvent* event) {
    if (g_client)
        [g_client keyDown:event inView:self];
    else
        fa_sapp_macos_key_down((__bridge const void*)event, true);
}
void view_insertText(id, SEL, id s, NSRange r) { [g_client insertText:s replacementRange:r]; }
void view_setMarkedText(id, SEL, id s, NSRange sel, NSRange r) { [g_client setMarkedText:s selectedRange:sel replacementRange:r]; }
void view_unmarkText(id, SEL) { [g_client unmarkText]; }
NSRange view_selectedRange(id, SEL) { return [g_client selectedRange]; }
NSRange view_markedRange(id, SEL) { return [g_client markedRange]; }
BOOL view_hasMarkedText(id, SEL) { return [g_client hasMarkedText]; }
id view_attributedSubstring(id, SEL, NSRange r, NSRangePointer a) { return nil; }
id view_validAttributes(id, SEL) { return @[]; }
NSRect view_firstRect(id, SEL, NSRange r, NSRangePointer a) { return [g_client firstRectForCharacterRange:r actualRange:a]; }
NSUInteger view_characterIndex(id, SEL, NSPoint) { return NSNotFound; }
void view_doCommand(id, SEL, SEL s) { [g_client doCommandBySelector:s]; }

Class g_hookedClass = Nil;

void add_method(Class cls, SEL sel, IMP imp, const char* types) {
    if (!class_addMethod(cls, sel, imp, types)) NSLog(@"FactorIA: the IME could not add %s to the view", sel_getName(sel));
}

// Makes sokol_app's view an NSTextInputClient. Idempotent; a key still reaches the game as before until ime_set_enabled(true).
void install_on_view() {
    NSView* view = (__bridge NSView*)fa_sapp_macos_view();
    if (view == nil) return;
    Class cls = object_getClass(view);
    if (cls == g_hookedClass) return;
    g_hookedClass = cls;
    client().view = view;
    class_addProtocol(cls, @protocol(NSTextInputClient));
    const NSString* range = [NSString stringWithUTF8String:@encode(NSRange)];
    const NSString* rect = [NSString stringWithUTF8String:@encode(NSRect)];
    auto t = ^(NSString* format) { return [format UTF8String]; };
    Method key = class_getInstanceMethod(cls, @selector(keyDown:));
    method_setImplementation(key, (IMP)view_keyDown);
    add_method(cls, @selector(insertText:replacementRange:), (IMP)view_insertText,
               t([NSString stringWithFormat:@"v@:@%@", range]));
    add_method(cls, @selector(setMarkedText:selectedRange:replacementRange:), (IMP)view_setMarkedText,
               t([NSString stringWithFormat:@"v@:@%@%@", range, range]));
    add_method(cls, @selector(unmarkText), (IMP)view_unmarkText, "v@:");
    add_method(cls, @selector(selectedRange), (IMP)view_selectedRange, t([NSString stringWithFormat:@"%@@:", range]));
    add_method(cls, @selector(markedRange), (IMP)view_markedRange, t([NSString stringWithFormat:@"%@@:", range]));
    add_method(cls, @selector(hasMarkedText), (IMP)view_hasMarkedText, t([NSString stringWithFormat:@"%s@:", @encode(BOOL)]));
    add_method(cls, @selector(attributedSubstringForProposedRange:actualRange:), (IMP)view_attributedSubstring,
               t([NSString stringWithFormat:@"@@:%@^%@", range, range]));
    add_method(cls, @selector(validAttributesForMarkedText), (IMP)view_validAttributes, "@@:");
    add_method(cls, @selector(firstRectForCharacterRange:actualRange:), (IMP)view_firstRect,
               t([NSString stringWithFormat:@"%@@:%@^%@", rect, range, range]));
    add_method(cls, @selector(characterIndexForPoint:), (IMP)view_characterIndex,
               t([NSString stringWithFormat:@"%s@:%s", @encode(NSUInteger), @encode(NSPoint)]));
    add_method(cls, @selector(doCommandBySelector:), (IMP)view_doCommand, "v@::");
}

}  // namespace

namespace fa {

void ime_apple_attach(Input* input) {
    g_input = input;
    if (!input) {
        if (g_client) {
            [g_client cancelComposition];
            g_client->input = nullptr;
        }
        return;
    }
    client()->input = input;
    install_on_view();
}

void ime_apple_keyboard_shown() {}

void ime_backend_set_enabled(bool enabled) {
    if (!enabled) [client() cancelComposition];
    client()->enabled = enabled;
    if (enabled) install_on_view();
}

void ime_backend_set_caret_rect(Rect framebufferPixels) { client()->caret = framebufferPixels; }

void ime_backend_cancel() {
    if (g_client) [g_client cancelComposition];
}

// ---- test hooks
namespace ime_apple_test {
struct Client {
    FaImeClient* c = nil;
    NSView* view = nil;
};
Client* create(Input& input, bool enabled) {
    Client* h = new Client;
    h->c = [[FaImeClient alloc] init];
    h->c->input = &input;
    h->c->enabled = enabled;
    h->view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
    h->c.view = h->view;
    return h;
}
void destroy(Client* h) { delete h; }
void set_marked(Client* h, std::u16string_view text, std::size_t selLoc, std::size_t selLen,
                std::span<const ime_text::Run> runs) {
    NSString* s = [NSString stringWithCharacters:reinterpret_cast<const unichar*>(text.data()) length:text.size()];
    NSMutableAttributedString* a = [[NSMutableAttributedString alloc] initWithString:s];
    for (const ime_text::Run& r : runs)
        [a addAttribute:NSUnderlineStyleAttributeName
                  value:@(r.emphasized ? NSUnderlineStyleThick : NSUnderlineStyleSingle)
                  range:NSMakeRange(r.start, r.length)];
    [h->c setMarkedText:a selectedRange:NSMakeRange(selLoc, selLen) replacementRange:NSMakeRange(NSNotFound, 0)];
}
void insert_text(Client* h, std::u16string_view text) {
    NSString* s = [NSString stringWithCharacters:reinterpret_cast<const unichar*>(text.data()) length:text.size()];
    [h->c insertText:s replacementRange:NSMakeRange(NSNotFound, 0)];
}
void unmark(Client* h) { [h->c unmarkText]; }
void cancel(Client* h) { [h->c cancelComposition]; }
bool has_marked(const Client* h) { return [h->c hasMarkedText]; }
void set_enabled(Client* h, bool enabled) {
    if (!enabled) [h->c cancelComposition];
    h->c->enabled = enabled;
}
void set_caret_rect(Client* h, Rect r) { h->c->caret = r; }
Rect first_rect(Client* h) {
    const NSRect r = [h->c firstRectForCharacterRange:NSMakeRange(0, 0) actualRange:nullptr];
    return {float(r.origin.x), float(r.origin.y), float(r.size.width), float(r.size.height)};
}
}  // namespace ime_apple_test

}  // namespace fa

#else
// ---- iOS --------------------------------------------------------------------------------------------------------------------
// sokol_app's hidden UITextField holds "x" (so Backspace has something to delete) and what the keyboard types after it. Its
// delegate returns NO for everything and sends CHAR events, which cannot compose: ours lets the field change, reads it after
// each change (UITextFieldTextDidChangeNotification), turns what the keyboard marks into a composition update and what it
// leaves unmarked into text, and puts the field back to "x". Enter and Backspace stay sokol_app's.
namespace {
bool g_enabled = false;
bool g_composing = false;  // an update was sent and no commit yet
bool g_suppress = false;   // the field is being changed by us
NSString* const kSentinel = @"x";
}  // namespace

@interface FaImeFieldDelegate : NSObject <UITextFieldDelegate>
@property(nonatomic, weak) id<UITextFieldDelegate> sokol;
@end

namespace {
FaImeFieldDelegate* g_delegate = nil;
id g_observer = nil;

bool active() { return g_enabled && g_input != nullptr; }

void reset_field(UITextField* tf) {
    g_suppress = true;
    [tf unmarkText];
    tf.text = kSentinel;
    g_suppress = false;
}

void field_changed(UITextField* tf) {
    if (g_suppress || !active()) return;
    NSString* text = tf.text ?: @"";
    if (UITextRange* marked = tf.markedTextRange) {
        const NSInteger loc = std::clamp<NSInteger>([tf offsetFromPosition:tf.beginningOfDocument toPosition:marked.start], 0,
                                                    NSInteger(text.length));
        const NSInteger len =
            std::clamp<NSInteger>([tf offsetFromPosition:marked.start toPosition:marked.end], 0, NSInteger(text.length) - loc);
        const std::u16string pre = to_u16([text substringWithRange:NSMakeRange(loc, len)]);
        NSInteger selLoc = 0, selLen = 0;
        if (UITextRange* sel = tf.selectedTextRange) {
            selLoc = [tf offsetFromPosition:tf.beginningOfDocument toPosition:sel.start] - loc;
            selLen = [tf offsetFromPosition:sel.start toPosition:sel.end];
        }
        selLoc = std::clamp<NSInteger>(selLoc, 0, NSInteger(pre.size()));
        selLen = std::clamp<NSInteger>(selLen, 0, NSInteger(pre.size()) - selLoc);
        fa::ime_text::Marked m = fa::ime_text::marked_from_utf16(pre, std::size_t(selLoc), std::size_t(selLen), {});
        g_composing = true;
        g_input->on_composition_update(std::move(m.text), m.caret, m.selLength);
        return;
    }
    NSString* body = [text hasPrefix:kSentinel] ? [text substringFromIndex:kSentinel.length] : text;
    const std::u32string typed = fa::ime_text::utf16_to_utf32(to_u16(body));
    if (g_composing) {
        g_composing = false;
        std::u32string visible;
        for (const char32_t c : typed)
            if (c >= 32 && c != 127) visible.push_back(c);
        g_input->on_composition_commit(std::move(visible));
    } else {
        deliver_text(*g_input, typed);
        if ([body isEqualToString:@" "]) {  // sokol_app also sends the Space key
            g_input->on_key(fa::Key::Space, true);
            g_input->on_key(fa::Key::Space, false);
        }
    }
    reset_field(tf);
}

// sokol_app creates the field on the first sapp_show_keyboard(): take over its delegate then.
void install_on_field() {
    UITextField* tf = (__bridge UITextField*)fa_sapp_ios_textfield();
    if (tf == nil || g_delegate != nil) return;
    g_delegate = [[FaImeFieldDelegate alloc] init];
    g_delegate.sokol = tf.delegate;
    tf.delegate = g_delegate;
    g_observer = [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification
                                                                   object:tf
                                                                    queue:nil
                                                               usingBlock:^(NSNotification*) { field_changed(tf); }];
}
}  // namespace

@implementation FaImeFieldDelegate
- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    if (active() && (g_composing || textField.markedTextRange != nil)) return YES;  // the marked text is edited in the field
    const BOOL key = string.length == 0 || [string isEqualToString:@"\n"];  // Backspace, Enter: keys, as in sokol_app
    if (active() && !key) return YES;  // read in field_changed once the keyboard has settled what it is
    return [self.sokol textField:textField shouldChangeCharactersInRange:range replacementString:string];
}
@end

namespace fa {

void ime_apple_attach(Input* input) {
    g_input = input;
    if (!input && g_composing) {
        g_composing = false;
        if (UITextField* tf = (__bridge UITextField*)fa_sapp_ios_textfield()) reset_field(tf);
    }
    if (input) install_on_field();
}

void ime_apple_keyboard_shown() {
    if (g_input) install_on_field();
}

// ime_set_enabled shows and hides nothing: the keyboard is mobile_show_keyboard()'s (the UI calls both while a TextField has
// the focus). Enabled means "the keyboard's marked text is a composition".
void ime_backend_set_enabled(bool enabled) {
    g_enabled = enabled;
    if (enabled) install_on_field();
    else ime_backend_cancel();
}

// The field is a hidden view: the system places its candidate bar and a hardware keyboard's popup by the field's frame.
void ime_backend_set_caret_rect(Rect r) {
    UITextField* tf = (__bridge UITextField*)fa_sapp_ios_textfield();
    if (tf == nil) return;
    const float s = dpi_scale();
    tf.frame = CGRectMake(r.x / s, r.y / s, std::max(r.w / s, 1.0f), std::max(r.h / s, 1.0f));
}

void ime_backend_cancel() {
    g_composing = false;
    if (UITextField* tf = (__bridge UITextField*)fa_sapp_ios_textfield()) reset_field(tf);
}

}  // namespace fa

#endif
