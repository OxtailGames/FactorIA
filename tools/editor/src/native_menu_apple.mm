// macOS: the editor's menus in the system menu bar (NSApp.mainMenu), mirrored from the menu tree (menu_model.h).
//
// Layout of the bar: the app menu (About, Settings..., Services, Hide..., Quit), the menus of the tree (File, Edit, View, AI,
// Export, Help) and a Window menu before Help. Every item is a real NSMenuItem with its key equivalent, so the shortcuts work
// while the menus are closed. Items are enabled and checked directly (menus do not auto-enable), updated in place every frame
// by update(); the menus are rebuilt only when a label, a shortcut or the structure changed. A submenu with lazy children
// (Recent Projects, Open Scene) is filled by the delegate when it opens, never otherwise: also not when a key is looked up.
//
// What a click does is not run inside the Cocoa event: the action is queued and drain() runs it at the start of the next
// editor frame, on the main thread, where it can touch the editor and ImGui like any other frame code.
#include "native_menu.h"

#import <AppKit/AppKit.h>

#include <cctype>
#include <cstdlib>
#include <memory>
#include <mutex>
#include <utility>

namespace fa::editor {
class NativeMenuImpl;
namespace {

struct Node {
    menu::Item item;                              // without children
    std::vector<std::shared_ptr<Node>> kids;      // the items of a menu (for a lazy one: what it built when it last opened)
    __weak NSMenuItem* ns = nil;
    bool keyBound = true;                         // whether the item currently carries its key equivalent
};

NSString* ns_string(const std::string& s) { return [NSString stringWithUTF8String:s.c_str()]; }

std::shared_ptr<Node> make_node(const menu::Item& it) {
    auto n = std::make_shared<Node>();
    n->item = it.without_children();
    if (!it.lazyChildren)
        for (const menu::Item& c : it.children) n->kids.push_back(make_node(c));
    return n;
}

// Copies the live fields of the new tree onto the nodes of the same shape (the menus were not rebuilt).
void sync_node(Node& n, const menu::Item& src) {
    n.item = src.without_children();
    if (src.lazyChildren) return;  // its kids are what it built when it opened
    for (std::size_t i = 0; i < n.kids.size() && i < src.children.size(); ++i) sync_node(*n.kids[i], src.children[i]);
}

// Everything that, when it changes, needs the NSMenuItems made again.
void shape_of(const menu::Item& it, std::string& out) {
    out += it.is_separator() ? 'S' : it.is_menu() ? 'M' : 'A';
    out += it.label;
    out += '\x1f';
    out += it.shortcut_for(true);
    out += '\x1f';
    out += it.tooltipFn ? '1' : '0';
    out += it.tooltip;
    out += '\x1f';
    out += it.lazyChildren ? 'L' : 'N';
    out += '(';
    if (!it.lazyChildren)
        for (const menu::Item& c : it.children) shape_of(c, out);
    out += ')';
}

unichar function_key(int n) { return unichar(NSF1FunctionKey + (n - 1)); }

// Sets the key equivalent of an item from a platform-neutral shortcut: Ctrl is Command, Alt is Option.
void set_shortcut(NSMenuItem* mi, const std::string& shortcut) {
    const menu::Shortcut s = menu::parse_shortcut(shortcut);
    if (!s.valid()) return;
    NSString* key = nil;
    if (s.key.size() >= 2 && s.key[0] == 'f' && std::isdigit(static_cast<unsigned char>(s.key[1]))) {
        const unichar f = function_key(std::atoi(s.key.c_str() + 1));
        key = [NSString stringWithCharacters:&f length:1];
    } else {
        key = ns_string(s.key);
    }
    // With Shift a letter is written as its capital, which is how AppKit tells Cmd+Z from Cmd+Shift+Z.
    if (s.shift && s.key.size() == 1 && std::isalpha(static_cast<unsigned char>(s.key[0]))) key = key.uppercaseString;
    mi.keyEquivalent = key;
    NSEventModifierFlags m = 0;
    if (s.ctrl) m |= NSEventModifierFlagCommand;
    if (s.shift) m |= NSEventModifierFlagShift;
    if (s.alt) m |= NSEventModifierFlagOption;
    mi.keyEquivalentModifierMask = m;
}

void clear_shortcut(NSMenuItem* mi) {
    mi.keyEquivalent = @"";
    mi.keyEquivalentModifierMask = 0;
}

}  // namespace
}  // namespace fa::editor

@interface FANodeBox : NSObject {
@public
    std::shared_ptr<fa::editor::Node> node;
}
@end
@implementation FANodeBox
@end

@interface FAMenu : NSMenu {
@public
    std::shared_ptr<fa::editor::Node> node;  // the node of the item this menu hangs from
}
@end
@implementation FAMenu
@end

@interface FATarget : NSObject <NSMenuDelegate>
@property(nonatomic) fa::editor::NativeMenuImpl* owner;  // cleared when the NativeMenu goes away
- (void)fire:(id)sender;
- (void)showAbout:(id)sender;
@end

namespace fa::editor {

class NativeMenuImpl final : public NativeMenu {
public:
    explicit NativeMenuImpl(const NativeAppMenuSpec& spec) : spec_(spec) {
        target_ = [[FATarget alloc] init];
        target_.owner = this;
        root_ = [[NSMenu alloc] initWithTitle:@""];
        root_.autoenablesItems = NO;
        build_app_menu();
        NSNotificationCenter* nc = NSNotificationCenter.defaultCenter;
        observers_.push_back([nc addObserverForName:NSMenuDidBeginTrackingNotification object:root_ queue:nil usingBlock:^(NSNotification*) {
            tracking_ = true;
            refresh_all();
        }]);
        observers_.push_back([nc addObserverForName:NSMenuDidEndTrackingNotification object:root_ queue:nil usingBlock:^(NSNotification*) {
            tracking_ = false;
            refresh_all();
        }]);
        if (spec_.install) NSApp.mainMenu = root_;
        else [NSApplication sharedApplication];  // tests: AppKit sends a menu action (a click, a key) through NSApp
    }

    ~NativeMenuImpl() override {
        for (id o : observers_) [NSNotificationCenter.defaultCenter removeObserver:o];
        target_.owner = nullptr;
        if (spec_.install && NSApp.mainMenu == root_) NSApp.mainMenu = nil;
    }

    void update(const menu::MainMenu& menu, bool textInputActive) override {
        textInput_ = textInputActive;
        // A click item on the top level (the ImGui bar's "Export Game") becomes a menu of its own here: a system menu bar has no such thing.
        const std::vector<menu::Item>* tops = &menu.items;
        std::vector<menu::Item> wrapped;
        for (const menu::Item& t : menu.items)
            if (!t.is_menu()) {
                for (const menu::Item& u : menu.items) {
                    if (u.is_menu()) { wrapped.push_back(u); continue; }
                    std::string title = u.label;
                    while (!title.empty() && title.back() == '.') title.pop_back();
                    wrapped.push_back(menu::submenu(title, {u}));
                }
                tops = &wrapped;
                break;
            }
        std::string shape;
        for (const menu::Item& t : *tops) shape_of(t, shape);
        if (shape != shape_ || tops_.size() != tops->size()) {
            shape_ = std::move(shape);
            rebuild(*tops);
        } else {
            for (std::size_t i = 0; i < tops->size(); ++i) sync_node(*tops_[i], (*tops)[i]);
        }
        refresh_all();
    }

    int drain() override {
        std::vector<std::shared_ptr<Node>> run;
        {
            std::lock_guard<std::mutex> lock(mu_);
            run.swap(queue_);
        }
        int n = 0;
        for (const auto& node : run) {
            if (!node->item.enabled || !node->item.action) continue;  // turned off since the click
            node->item.action();
            ++n;
        }
        return n;
    }

    int pending() const override {
        std::lock_guard<std::mutex> lock(mu_);
        return int(queue_.size());
    }

    // ---- called by the Cocoa side ----
    void enqueue(const std::shared_ptr<Node>& node) {
        std::lock_guard<std::mutex> lock(mu_);
        queue_.push_back(node);
    }

    void will_open(FAMenu* m) {
        Node& n = *m->node;
        if (n.item.lazyChildren) {
            n.kids.clear();
            [m removeAllItems];
            for (const menu::Item& c : n.item.lazyChildren()) {
                n.kids.push_back(make_node(c));
                [m addItem:make_ns_item(n.kids.back())];
            }
        }
        for (const auto& k : n.kids) refresh(*k);
    }

    void show_about() {
        NSMutableDictionary* opts = [NSMutableDictionary dictionary];
        opts[NSAboutPanelOptionApplicationName] = ns_string(spec_.appName);
        opts[NSAboutPanelOptionApplicationVersion] = ns_string(spec_.version);
        if (!spec_.build.empty()) opts[NSAboutPanelOptionVersion] = ns_string(spec_.build);
        [NSApp orderFrontStandardAboutPanelWithOptions:opts];
    }

    // ---- tests ----
    std::vector<NativeItemInfo> snapshot() override { return describe(root_); }

    bool trigger(const std::vector<std::string>& titlePath) override {
        NSMenu* m = root_;
        for (std::size_t i = 0; i < titlePath.size(); ++i) {
            open(m);
            NSInteger at = -1;
            for (NSInteger k = 0; k < m.numberOfItems; ++k)
                if ([m itemAtIndex:k].title && titlePath[i] == [m itemAtIndex:k].title.UTF8String) { at = k; break; }
            if (at < 0) return false;
            NSMenuItem* mi = [m itemAtIndex:at];
            if (i + 1 == titlePath.size()) {
                if (!mi.enabled || mi.hasSubmenu) return false;
                [m performActionForItemAtIndex:at];
                return true;
            }
            if (!mi.hasSubmenu) return false;
            m = mi.submenu;
        }
        return false;
    }

    bool press_key(const std::string& shortcut) override {
        const menu::Shortcut s = menu::parse_shortcut(shortcut);
        if (!s.valid()) return false;
        NSEventModifierFlags flags = 0;
        if (s.ctrl) flags |= NSEventModifierFlagCommand;
        if (s.shift) flags |= NSEventModifierFlagShift;
        if (s.alt) flags |= NSEventModifierFlagOption;
        // With Shift held a letter key reports its capital in both strings, as a real key event does.
        std::string typed = s.key;
        if (s.shift && typed.size() == 1) typed[0] = char(std::toupper(static_cast<unsigned char>(typed[0])));
        NSString* chars = ns_string(typed);
        NSEvent* ev = [NSEvent keyEventWithType:NSEventTypeKeyDown
                                       location:NSZeroPoint
                                  modifierFlags:flags
                                      timestamp:0
                                   windowNumber:0
                                        context:nil
                                     characters:chars
                    charactersIgnoringModifiers:chars
                                      isARepeat:NO
                                        keyCode:0];
        return [root_ performKeyEquivalent:ev];
    }

private:
    NSMenuItem* make_ns_item(const std::shared_ptr<Node>& node) {
        Node& n = *node;
        const menu::Item& it = n.item;
        if (it.is_separator()) return [NSMenuItem separatorItem];
        NSMenuItem* mi = [[NSMenuItem alloc] initWithTitle:ns_string(it.label) action:(it.is_menu() ? nil : @selector(fire:)) keyEquivalent:@""];
        mi.target = target_;
        attach(mi, node);  // the item holds its node, so a click queued before a rebuild still has its action
        set_shortcut(mi, it.shortcut_for(true));
        if (it.is_menu()) {
            FAMenu* sub = [[FAMenu alloc] initWithTitle:ns_string(it.label)];
            sub.autoenablesItems = NO;
            sub.delegate = target_;
            sub->node = node;
            mi.submenu = sub;
            if (!it.lazyChildren)
                for (const auto& k : n.kids) [sub addItem:make_ns_item(k)];
        }
        const std::string tip = it.tooltip_text();
        if (!tip.empty()) mi.toolTip = ns_string(tip);
        return mi;
    }

    // The enabled / checked / tooltip state of an item and (recursively) its non-lazy children.
    void refresh(Node& n) {
        NSMenuItem* mi = n.ns;
        if (mi) {
            const bool on = n.item.enabled && !(textInput_ && n.item.yieldsToText);
            if (mi.enabled != on) mi.enabled = on;
            // A text box has the keyboard: Cmd+Z, Cmd+S... must reach it, and a menu item with that key equivalent would take them.
            // So these items give up their key while it is typing, unless the user is in the menus (then the shortcut is shown).
            const bool bound = !n.item.yieldsToText || !textInput_ || tracking_;
            if (bound != n.keyBound) {
                n.keyBound = bound;
                if (bound) set_shortcut(mi, n.item.shortcut_for(true));
                else clear_shortcut(mi);
            }
            const NSControlStateValue st = n.item.checked ? NSControlStateValueOn : NSControlStateValueOff;
            if (mi.state != st) mi.state = st;
            if (n.item.tooltipFn) {
                NSString* tip = ns_string(n.item.tooltipFn());
                if (![mi.toolTip isEqualToString:tip]) mi.toolTip = tip;
            }
        }
        if (!n.item.lazyChildren)
            for (const auto& k : n.kids) refresh(*k);
    }

    void refresh_all() {
        for (const auto& t : tops_) refresh(*t);
    }

    void rebuild(const std::vector<menu::Item>& tops) {
        while (root_.numberOfItems > 1) [root_ removeItemAtIndex:root_.numberOfItems - 1];
        tops_.clear();
        NSMenu* helpMenu = nil;
        NSInteger helpAt = -1;
        for (const menu::Item& t : tops) {
            tops_.push_back(make_node(t));
            NSMenuItem* mi = make_ns_item(tops_.back());
            if (t.label == "Help") { helpAt = root_.numberOfItems; helpMenu = mi.submenu; }
            [root_ addItem:mi];
        }
        NSMenuItem* windowItem = [[NSMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""];
        NSMenu* windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];  // standard items: the responder chain validates them
        [windowMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
        [windowMenu addItemWithTitle:@"Zoom" action:@selector(performZoom:) keyEquivalent:@""];
        [windowMenu addItem:[NSMenuItem separatorItem]];
        [windowMenu addItemWithTitle:@"Bring All to Front" action:@selector(arrangeInFront:) keyEquivalent:@""];
        windowItem.submenu = windowMenu;
        [root_ insertItem:windowItem atIndex:helpAt >= 0 ? helpAt : root_.numberOfItems];
        if (spec_.install) {
            NSApp.windowsMenu = windowMenu;
            if (helpMenu) NSApp.helpMenu = helpMenu;
        }
    }

    void build_app_menu() {
        NSString* name = ns_string(spec_.appName);
        NSMenuItem* appItem = [[NSMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""];
        NSMenu* app = [[NSMenu alloc] initWithTitle:name];
        NSMenuItem* about = [app addItemWithTitle:[@"About " stringByAppendingString:name] action:@selector(showAbout:) keyEquivalent:@""];
        about.target = target_;
        [app addItem:[NSMenuItem separatorItem]];

        settingsNode_ = std::make_shared<Node>();
        settingsNode_->item = menu::action("Settings...", spec_.openSettings);
        NSMenuItem* settings = [app addItemWithTitle:@"Settings..." action:@selector(fire:) keyEquivalent:@","];
        settings.target = target_;
        attach(settings, settingsNode_);
        [app addItem:[NSMenuItem separatorItem]];

        NSMenu* services = [[NSMenu alloc] initWithTitle:@"Services"];
        NSMenuItem* servicesItem = [app addItemWithTitle:@"Services" action:nil keyEquivalent:@""];
        servicesItem.submenu = services;
        if (spec_.install) NSApp.servicesMenu = services;
        [app addItem:[NSMenuItem separatorItem]];

        [app addItemWithTitle:[@"Hide " stringByAppendingString:name] action:@selector(hide:) keyEquivalent:@"h"];
        NSMenuItem* others = [app addItemWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
        others.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagOption;
        [app addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
        [app addItem:[NSMenuItem separatorItem]];

        quitNode_ = std::make_shared<Node>();
        quitNode_->item = menu::action("Quit", spec_.quit);
        NSMenuItem* quit = [app addItemWithTitle:[@"Quit " stringByAppendingString:name] action:@selector(fire:) keyEquivalent:@"q"];
        quit.target = target_;
        attach(quit, quitNode_);

        appItem.submenu = app;
        [root_ addItem:appItem];
    }

    void attach(NSMenuItem* mi, const std::shared_ptr<Node>& n) {
        FANodeBox* box = [[FANodeBox alloc] init];
        box->node = n;
        mi.representedObject = box;
        n->ns = mi;
    }

    void open(NSMenu* m) {
        if ([m isKindOfClass:[FAMenu class]]) will_open(static_cast<FAMenu*>(m));
    }

    std::vector<NativeItemInfo> describe(NSMenu* m) {
        open(m);  // like opening it: a lazy menu builds its items
        std::vector<NativeItemInfo> out;
        for (NSMenuItem* mi in m.itemArray) {
            NativeItemInfo i;
            i.separator = mi.isSeparatorItem;
            i.title = mi.title ? mi.title.UTF8String : "";
            i.keyEquivalent = mi.keyEquivalent ? mi.keyEquivalent.UTF8String : "";
            i.command = (mi.keyEquivalentModifierMask & NSEventModifierFlagCommand) != 0;
            i.shift = (mi.keyEquivalentModifierMask & NSEventModifierFlagShift) != 0;
            i.option = (mi.keyEquivalentModifierMask & NSEventModifierFlagOption) != 0;
            i.control = (mi.keyEquivalentModifierMask & NSEventModifierFlagControl) != 0;
            i.enabled = mi.enabled;
            i.checked = mi.state == NSControlStateValueOn;
            i.tooltip = mi.toolTip ? mi.toolTip.UTF8String : "";
            i.hasSubmenu = mi.hasSubmenu;
            if (mi.hasSubmenu) i.children = describe(mi.submenu);
            out.push_back(std::move(i));
        }
        return out;
    }

    NativeAppMenuSpec spec_;
    FATarget* target_ = nil;
    NSMenu* root_ = nil;
    std::string shape_;
    bool textInput_ = false;
    bool tracking_ = false;  // the user is in the menu bar (the mouse or the keyboard)
    std::vector<id> observers_;
    std::vector<std::shared_ptr<Node>> tops_;
    std::shared_ptr<Node> settingsNode_, quitNode_;
    mutable std::mutex mu_;
    std::vector<std::shared_ptr<Node>> queue_;
};

std::unique_ptr<NativeMenu> make_native_menu(const NativeAppMenuSpec& spec) {
    return std::make_unique<NativeMenuImpl>(spec);
}

}  // namespace fa::editor

@implementation FATarget
- (void)fire:(id)sender {
    FANodeBox* box = [sender representedObject];
    if (self.owner && box && box->node) self.owner->enqueue(box->node);
}
- (void)showAbout:(id)sender {
    if (self.owner) self.owner->show_about();
}
- (void)menuNeedsUpdate:(NSMenu*)menu {
    if (self.owner && [menu isKindOfClass:[FAMenu class]]) self.owner->will_open(static_cast<FAMenu*>(menu));
}
// Implementing this keeps AppKit from calling menuNeedsUpdate: (which lists the scene files...) for every key pressed with
// Command held: NO means "I have no dynamic key equivalent", the items' own are still searched.
- (BOOL)menuHasKeyEquivalent:(NSMenu*)menu forEvent:(NSEvent*)event target:(id*)target action:(SEL*)action {
    return NO;
}
@end
