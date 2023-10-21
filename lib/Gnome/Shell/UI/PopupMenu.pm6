use v6.c;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::UI::BoxPointer;
use Gnome::Shell::UP::Global;

our enum Ornament is export <NONE DOT CHECK HIDDEN>;

### /home/cbwood/Projects/gnome-shell/js/ui/popupMenu.js

class X::Gnome::Shell::addMenuItem::InvalidItem is Exception {
  method message {
    'Invalid argument given to PopupMenu::Item::Base.addMenuItem!'
  }
}

sub arrowIcon ($side) is export {
  my $in = "pan-{
    do given $side {
      when ST_SIDE_TOP    { 'up'     }
      when ST_SIDE_RIGHT  { 'end'    }
      when ST_SIDE_BOTTOM { 'bottom' }
      when ST_SIDE_LEFT   { 'start'  }
    }
  }-symbolic";

  Gnome::Shell::St::Icon.new(
    style-class     => 'popup-menu-arrow',
    icon-name       => $in,
    accessible-role => ATK_ROLE_ARROW,
    y-expand        => True,
    y-align         => CLUTTER_ALIGN_CENTER
  );
}

class Gnome::Shell::UI::PopupMenu::Item::Base
  is Gnome::Shell::St::BoxLayout
{
  has Bool $.active    is rw is g-property;
  has Bool $.sensitive is rw is g-property;

  has $!active;
  has $!activatable;
  has $!sensitive;
  has $!parent;

  has $.clickAction;
  has $.ornamentIcon;

  method active is rw {
    Proxy.new:
      FETCH => -> $ { $!active },

      STORE => -> $, \v {
        if $!active != v {
          $!active = v;
          if $!active {
            $.add-style-class-name('selected');
            $.grab-key-focus if $.can-focus;
          } else {
            $.remove-style-class-name('selected');
            $.remove-style-pseudo-class('active');
          }
          self.emit-notify('active');
        }
      }
  }

  method sensitive is rw {
    Proxy.new:
      FETCH => -> $ {
        my $ps = $!parent ?? $.parent.sensitive !! True;
        $!activatable && $!sensitive && $ps;
      }

      STORE => -> $, Int() \v {
        my $ns = v.so;

        return unless $!sensitive != $ns;
        $!sensitive = $ns;
        self.syncSensitive;
      }
  }

  #has $!delegate;

  method Activate (MutterClutterEventAny) is signal { }

  method TWEAK (
    :$reactive    = True,
    :$activate    = True,
    :$hover       = True,
    :$can-focus   = True,
    :$style-class
  ) {
    self.setAttributes(
      :$reactive,
      :$activate,
      :$hover,
      :$can-focus,

      accessible-role => ATK_ROLE_MENU_ITEM
    );
    self.style-class = $style-class if $style-class;

    #$!delegate = self;

    $!ornamentIcon = Gnome::Shell::St::Icon.new(
      style-class => 'popup-menu-ornament'
    );
    self.add($!ornamentIcon);
    self.setOrnament(HIDDEN);

    ($!active, $!sensitive, $!parent) = (False, True);
    $!activatable = self.reactive && self.activate;

    $!clickAction = Mutter::Clutter::ClickAction.new(
      enabled => $!activatable
    );
    $!clickAction.clicked.tap( -> *@a {
      self.activate(Mutter::Clutter::Event.get-current-event);
    });

    my $s = self;
    $!clickAction.notify('pressed', -> *@a {
      $!clickAction.pressed
        ?? $s.add-style-pseudo-class('active')
        !! $s.remove-style-pseudo-class('active')
    });
    self.add-action($!clickAction);

    self.add-style-class-name('popup-inactive-menu-item')
      if $!activatable;

    self.add-style-class-name($style-class) if $style-class;

    self.bind('hover', 'active', :create) if $reactive && $hover;
  }

  method actor { self }

  method setParent ($p) {
    $!parent = $p;
  }

  # cw: C wrapper will create an object and pass it to
  #     this method using a mechanism for resolving the
  #     C pointer to the proper invocant instance.
  method key_press_event ($e) is vfunc {
    return CLUTTER_EVENT_STOP
      if Global.FocusManager.navigate-from-event($e);

    return callsame unless $!activatable;

    return CLUTTER_EVENT_PROPAGATE if [+&](
      $e.state,
      CLUTTER_MODIFIER_LOCK_MASK,
      CLUTTER_MODIFIER_MOD2_MASK,
      CLUTTER_MODIFIER_MODIFIER_MASK
    );

    if $e.get-key-symbol == (CLUTTER_KEY_Space, CLUTTER_KEY_Return).any {
      self.activate($e);
      return CLUTTER_EVENT_STOP;
    }
    CLUTTER_EVENT_PROPAGATE;
  }

  method key_focus_in is vfunc {
    callsame;
    $!active = True;
  }

  method key_focus_out is vfunc {
    callsame;
    $!active = False;
  }

  method activate ($e) {
    # cw: If GObject doesn't allow for case distinction
    #     then the signal name shall become 'activate-actual'
    # cw: The other possibility is that the signal name
    #     remains 'activate', and we will have to use another
    #     method (namely normal connect) to allow the signal
    #     'activate' to trigger the Suppy bound to 'Activate'
    self.emit('Activate', $e);
  }

  method syncSensitive {
    $.reactive = $.can-focus = $.sensitive;
    $.emit-notify('sensitive');
    $.sensitive;
  }

  method setOrnament (Int() $o) {
    return if $!ornament == $o;

    $!ornamentIcon.icon-name = do given ($!ornament = $o) {
      when DOT {
        $.add-accessible-state(ATK_STATE_CHECKED);
        'ornament-dot';
      }

      when CHECK {
        $.add-accessible-state(ATK_STATE_CHECKED);
        'ornament-check';
      }

      when NONE {
        $.remove-accessible-state(ATK_STATE_CHECKED);
        '';
      }

      default { '' }
    }

    $!ornamentIcon.visible = $o != HIDDEN;
    self!updateOrnamentStyle;
  }

  method !updateOrnamentStyle {
    $!ornament != HIDDEN
    ?? $.add-style-class-name('popup-ornamented-menu-item')
    !! $.remove-style-class-name('popup-ornamented-menu-item');
  }
}

constant Base = Gnome::Shell::UI::PopupMenu::Item::Base;

class Gnome::Shell::UI::PopupMenu::Item
  is Gnome::Shell::UI::PopupMenu::Item::Base
{
  submethod TWEAK ( :$text ) {
    self.label = Gnome::Shell::St::Label.new(
      y-expand => True,
      y-align  => CLUTTER_ACTOR_ALIGN_CENTER,

      :$text
    );
    self.add-child($self.label);
    self.label-actor = self.label;
  }
}

class Gnome::Shell::UI::PopupMenu::Item::Separator
  is Gnome::Shell::UI::PopupMenu::Item::Base
{
  has $!separator;

  submethod TWEAK ( :$text = '') {
    self.label = Gnome::Shell::St::Label.new( :$text );
    self.add(self.label);
    self.label-actor = self.label;

    self.label.notify('text').tap( -> *@a {
      @a.head.syncVisibility;
    });
    self.syncVisibility;

    $!separator = Gnome::Shell::St:Widget.new(
      style-class => 'popup-separator-menu-item-separator',
      x-expand    => True,
      y-expand    => True,
      y-align     => CLUTTER_ACTOR_ALIGN_CENTER
    );
    self.add-child($!separator);
  }

  method syncVisibility {
    $.label.visible = $.label.text.chars.so;
  }
}

class Gnome::Shell::UI::PopupMenu::Switch
  is Gnome::Shell::St::Bin
{
  has Bool $!state is g-propery;

  method state is rw {
    Proxy.new:
      FETCH => -> $ { $!state },

      STORE => -> $, \v {
        return if $!state == v;

        v ?? self.add-style-pseudo-class('checked')
          !! self.remove-style-pseudo-class('checked');
        $!state = v;
        self.emit-notify('state');
      }
  }

  submethod TWEAK ( :$state ) {
    $!state = False,
    self.setAttributes(
      style-class => 'toggle-switch',
      accessible-role => ATK_ROLE_CHECK_BOX,

      :$state
    );
  }

  multi method new ($state = False, *%a) {
    my $o = self.bless( :$state );
    $o.setAttributes( |%a ) if $o && +%a;
    $o;
  }

  method toggle {
    self.state = self.state.not;
  }
}

class Gnome::Shell::UI::PopupMenu::Item::Switch
  is Gnome::Shell::UI::Popup::Menu::Item::Base
{
  has $!switch;

  method toggled (Bool) is signal { }

  submethod TWEAK ( :$text, :$active ) {
    self.label = Gnome::Shell::St::Label.new(
      y-expand => True,
      y-align  => CLUTTER_ACTOR_ALIGN_CENTER,

      :$text
    );

    $!switch = Gnome::Shell::UI::PopupMenu::Switch.new($active);
    self.accessible-role = ATK_ROLE_CHECK_MENU_ITEM;
    self.checkAccessibleState;
    self.label_actor = self.label;
    self.add-child(self.label);

    $!statusBin = Gnome::Shell::St::Bin.new(
      x-align  => CLUTTER_ACTOR_ALIGN_END,
      x-expand => True
    );
    self.add-child($!statusBin);

    $!statusLabel = Gnome::Shell::St::Label.new(
      text        => '',
      style-class => 'popup-status-menu-item',
      x-expand    => True,
      y-align     => CLUTTER_ACTOR_ALIGN_CENTER
    );
    $!statusBin.child = $!switch;
  }

  method setStatus ($text) {
    if $text {
      $!statusLabel.text = $text;
      $!statusbin.child = $!statusLabel;
      $.reactive = False;
      $.accessible-role = ATK_ROLE_MENU_ITEM;
    } else {
      $!statusBin.child = $!switch;
      $.reactive = True,
      $.accessible-role = ATK_COLE_CHECK_MENU_ITEM;
    }
    $.checkAccessibleState;
  }

  method activate ($e) {
    $.toggle if $!switch.mapped;

    return
      if $e.type           == CLUTTER_EVENT_KEY_PRESS &&
         $e.get-key-symbol == CLUTTER_KEY_Space;

    nextsame;
  }

  method toggle {
    $!switch.toggle;
    self.emit('togled', $!switch.state);
    $.checkAccessibleState;
  }

  method setToggleState ($state) {
    $!switch.state = $state;
    $.checkAccessibleState;
  }

  method checkAccessibleState {
    given $.accessible-role {
      when ATK_ROLE_CHECK_MENU_ITEM {
        $!switch.state ?? $.add-accessible-state(ATK_STATE_CHECKED);
                       !! proceed;
      }

      default {
        $.remove-accessible-state(ATK_STATE_CHECKED);
      }
    }
  }
}

# ... Popup::Menu::Item::Image
class Gnome::Shell::UI::PopupMenu::Item::Image
  is Gnome::Shell::UI::PopupMenu::Item::Base
{
  has $!icon;

  submethod TWEAK ( :$text, :$icon ) {
    $!icon = Gnome::Shell::St::Icon.new(
      style-class => 'popup-menu-icon',
      x-align     => CLUTTER_ACTOR_ALIGN_END
    );
    self.add-child($!icon);
    self.label = Gnome::Shell::St::Label.new(
      y-expand => True,
      y-align   => CLUTTER_ACTOR_ALIGN_CENTER,

      :$text
    );
    self.add-child($!label);
    self.label_actor = $!label;
    self.set-child-above-sibling(self.ornamentIcon, $!label);
    self.setIcon($icon);
  }

  method setIcon ($icon) {
    if $icon ~~ GIO::Roles::Icon
      ?? ($!icon.gicon     = $icon);
      !! ($!icon.icon-name = $icon);
  }

  method !updateOrnamentStyle { }
}

class Gnome::Shell::UI::PopupMenu::Section       { ... }
class Gnome::Shell::UI::PopupMenu::Item::SubMenu { ... }

constant Section = Gnome::Shell::UI::PopupMenu::Section;

class Gnome::Shell::UI::PopupMenu::Base
  is Gnome::Shell::Misc::Signals::EventEmitter
{
  has $.sourceActor;
  has $.focusActor;
  has $!parent;
  has $!activeMenuItem;
  has $!settingsActions;
  has $!sensitive;

  has $.box    is rw;
  has $.isOpen is rw;
  has $.length is rw;

  method sensitive is rw {
    Proxy.new:
      FETCH => -> $ { $!sensitive },

      STORE => -> $, \v {
        $!sensitive = v;
        self.emit('notify::sensitive');
      }
  }

  submethod BUILD ( :$!sourceActor, :$styleClass ) {
    $!focusActor = $!sourceActor;

    $!box = Gnome::Shell::St::BoxLayout.new(
      vertical => True,
      x-expand => True,
      y-expand => True
    });
    $!box.style-class = $styleClass if $styleClass;
    ($!length, $!isOpen, $!sensitive) = (0, False, True)

    Main.sessionMode.updated.tap( -> *@a { @a.head.sessionUpdated });
  }

  method !getTopMenu {
    $!parent ?? $!parent.getTopMenu !! self;
  }

  method sessionUpdate {
    self!setSettingsVisible(Main.sessionMode.allowSettings);
    self.close;
  }

  multi method addAction ($title, &callaback, :$icon) {
    my $menuItem = $icon
      ?? Gnome::Shell::UI::PopupMenu::Item::Image.new($title, $icon)
      !! Gnome::Shell::UI::PopupMenu::Item.new($title);

    self.addMenuItem($menuItem);
    $menuItem.activate.tap( -> *@a {
      &callback( Mutter::Clutter::Event.new( @a[1] ) );
    });

    $menuItem;
  }

  method addSettingsAction ($title, $desktopFile) {
    my $menuItem = $.addAction($title, sub {
      my $app = Gnome::Shell::St::AppSystem.default.lookup-app(
        $desktopFile
      );
      return unless $app;
      Main.Overview.hide;
      Main.panel.closeQuickSettings;
      $app.activate();
    });

    $menuItem.visible = Main.sessionMode.allowSettings;
    $!settingsActions{ $desktopFile } = $menuItem;
    $menuItem;
  }

  method setSettngsVisible ($v) {
    .value.visible = $v for $!settingsActions.pairs;
  }

  method isEmpty {
    $!box.children.grep(
      $_ ~~ Gnome::Shell::PopupMenu::Item::Separator
        ?? False
        !! isPopupMenuItemVisible($_)
    ).elems.so
  }

  method itemActivated ($animate) {
    self!getTopMenu.close($animate // BOXPOINTER_ANIMATION_FULL);
  }

  method !subMenuActivateChange ($s, $i) {
    $!activeMenuItem.active = False
      if $!activeMenuItem && $!activeMenuItem != $s;
    $!activeMenuItem = $s;
    $.emit('active-changed', $s);
  }

  method connectItemSignals ($mi) {
    my ($s, $ami) = (self, $!activeMenuItem);

    $mi.notify('active').tap( -> *@a {
      my $active := $mi.active;
      if $active && +$ami != +$mi {
        $ami.active = False if $!activeMenuItem;
        $ami = $mi;
        $s.emit('active-changed', $mi);
      } elsif $active.not && +$ami == +$mi {
        $ami = Nil;
        $s.emit('active-changed', $mi);
      }
    });

    $mi.notify('sensitive').tap( -> *@a {
      my $sensitive = $mi.sensitive;
      if $sensitive.not && +$ami == +$mi {
        $s.actor.grab-key-focus
          if $s.actor.navigate-focus($mi.actor, ST_DIR_TAB_FORWARD, True);
      } elsif $sensitive && +$ami.not {
        $mi.actor.grab-key-focus if +Global.Stage.get-key-focus == +$s.actor;
      }
    });

    $mi.activate.tap( -> *@a {
      $s.emit('activate', $mi);
      $s.itemActivated(BOXPOINTER_ANIMATION_FULL);
    });

    $mi.destroy.tap( -> *@a { $ami = Nil if +$mi == $ami });

    self.notify('sensitive').tap( -> *@a { $mi.syncSensitive });
  }

  method updateSeparatorVisibility ($mi) {
    return if $mi.label.text;

    my @c = $!box.children
    my $i = @c.first({ +$_ == +$mi.actor }, :k);
    return unless $i.defined;

    my $cbi = $index - 1;
    while $cbi >= 0 && isPopupMenuItemVisible( @c[$cbi] ).not {
      $cbi--;
    }

    if $cbi < 0 ||
       ($cbi >= 0 && @c[$cbi] ~~ Gnome::Shell::PopupMenu::Item::Separator)
    {
      $mi.actor.hide;
      return;
    }

    my ($cai, $ce) = ($index + 1, @c.elems);
    while $cai < $ce && isPopupMenuItemVisible( @c[$cai ).not {
      $cai++
    }

    if $cai >= $ce ||
       ($cai < $ce && @c[$cai] ~~ Gnome::Shell::PopupMenu::Item::Separator)
    {
      $mi.actor.hide;
      return;
    }

    $mi.show;
  }

  method moveMenuItem ($mi, $position is copy) {
    my @i = self.getMenuItems;
    my $i = 0;

    while $i < @i.elems && $p > 0 {
      $position-- if +@i[$i] != +$mi;
      $i++;
    }

    if $i < @i.elems {
      $.box.set-child-below-sibling($mi.actor, @i[$i].actor)
        if +@i[$i] != +$mi;
    } else {
      $.box.set-child-above-sibling($mi.actor);
    }
  }

  method addMenuItem ($mi, $p) {
    my $biu;

    if $position {
      $.box.add($mi.actor);
    } else {
      my @items = self!getMenuItems;
      if $position < @items.elems {
        $bi = @items[$p].actor;
        $.box.insert-child-below($mi.actor, $beforeItem);
      }
    }

    my $s = self;
    given $mi {
      when Gnome::Shell::UI::PopupMenu::Section {
        $mi.active-changed.tap( -> *@a { $s.subMenuActiveChanged( |@a ) });
        $mi.destroy.tap( -> *@a { $s.length-- });

        self.open-state-changed.tap( -> *@a ($, $o) {
          $p ?? $mi.open !! $mi.close;
        });
        self.menu-closed.tap( -> *@a { $mi.emit('menu-closed') });
        self.notify('sensitive').tap( -> *@a {
          $mi.emit('notify::sensitive')
        });
      }

      when Gnome::Shell::UI::PopupMenu::Item::SubMenu {
        $bi.not ?? $.box.add($mi.menu.actor);
                !! $.box.insert-child-below($mi.menu.actor, $bi);
        self!connectItemSignals($mi);
        $mi.menu.active-changed.tap( -> *@a {
          $s.subMenuActiveChanged( |@a )
        });
        self.menu-closed.tap( -> *@a {
          $mi.menu.close(BOXPOINTER_ANIMATION_NONE)_
        });
      }

      when Gnome::Shell::UI::PopupMenu::Item::Separator {
        self!connectItemSignals($mi);
        self.open-state-changed.tap( -> *@a {
          @a.head.updateSeparatorVisibity($mi);
        });
      }

      when Gnome::Shell::UI::PopupMenu::Item::Base {
        self!connectItemSignals($mi);
      }

      default {
        X::Gnome::Shell::addMenuItem::InvalidItem.new.throw;
      }
    }
    $mi.setParent(self);
    $!length++;
  }

  method !getMenuItems {
    $.box.children.grep({ $_ ~~ (Base, Section.any) })
  }

  method firstMenuItem { self!getMenuItems.head  }
  method numMenuItems  { self!getMenuItems.elems }

  method removeAll     { .destroy for self!getMenuItems }

  method toggle {
    $.isOpen ?? self.close(BOXPOINTER_ANIMATION_FULL)
             !! self.open(BOXPOINTER_ANIMATION_FULL);
  }

  method destroy {
    self.close;
    self.removeAll;
    self.actor.destroy;
    self.emit('destroy');
    Main.sessionMode.disconnectObject(self);
  }
}

class Gnome::Shell::UI::PopupMenu is Gnome::Shell::UI::PopupMenu::Base {
  has $!arrowAlignment;
  has $!arrowSide;
  has $!systemModalOpenId;
  has $!openedSubMenu;

  has $!boxPointer handles<
    setArrowOrigin
    setSourceAlignment
  >;

  submethod BUILD ( :$!arrowAlignment, :$!arrowSide ) {
    self.style-class = 'popup-menu-content';
    self.actor = $!boxPointer = Gnome::Shell::UI::BoxPointer.new($arrowSide);
    self.actor.style-class = 'popup-menu-boxpointer';
    $!boxPointer.bin.set-child(self.box);
    self.actor.add-style-class-name('popup-menu');

    Global.FocusManager.add-group(self.actor);
    self.actor.reactive = True;

    if self.sourceActor {
      self.sourceActor.key-press-event.tap( -> *@a {
        @a.tail.r = @a.tail.onKeyPress( |@a )
      })
      self.notify('mapped').tap( -> *@a {
        @a.head.close if @a.head.sourceActor.mapped;
      });
    }

    $!systemModalOpenId = 0;
  }

  method new ($sourceActor, $arrowAlignment, $arrowSide) {
    self.bless( :$sourceActor, :$arrowAlignment, :$arrowSide );
  }

  method !setOpenedSubMenu ($s) {
    $!opendSubMenu.close(True) if $!openedSubMenu;
    $!openedSubMenm = $s;
  }

  method onKeyPress ($a, $e) {
    return CLUTTER_EVENT_PROPAGATE if $a.reactive.not;

    my $navKey = do given $!boxPointer.arrowSide {
      when ST_SIDE_TOP    { CLUTTER_KEY_Down  }
      when ST_SIDE_BOTTOM { CLUTTER_KEY_Up    }
      when ST_SIDE_LEFT   { CLUTTER_KEY_Right }
      when ST_SIDE_RIGHT  { CLUTTER_KEY_Left  }
    }

    return CLUTTER_EVENT_PROPAGATE if [+&](
      $e.state,
      +^CLUTTER_MODIFIER_LOCK_MASK,
      +^CLUTTER_MODIFIER_MOD2_MASK,
      CLUTTER_MODIFIER_MODIFIER_MASK
    );

    given $e.get-key-symbol {
      when CLUTTER_KEY_Space | CLUTTER_KEY_Return {
        self.toggle;
        return CLUTTER_EVENT_STOP;
      }

      when $navkey {
        self.toggle if $.isOpen;
        self.actor.navigate-focus(ST_DIR_TAB_FORWARD);
        return CLUTTER_EVENT_STOP;
      }
    }
    CLUTTER_EVENT_PROPAGATE;
  }

  method open ($a) {
    return if $.isOpen || $.isEmpty;

    my $s = self;
    unless $!systemModalOpenId {
      # cw: The result of the connect call is stored
      #     as $hid in most signals compunits, but I am
      #     unsure as to how signals would be implemented
      #     here, especially due to the fact that this
      #     signal is custom.
      Main.layoutManager.system-modal-opened.tap( -> *@a {
        $s.close
      });
      # cw: So... placeholder. See above comment.
      $!systemModalOpenId = Main.layoutManager.Signals<system-modal-opened>
                                              .tail;
    }

    $!isOpen = True;
    $!boxPointer.setPosition($!sourceActor, $!arrowAlignment);
    $!boxPoitner.open($a);
    $.actor.parent.set-child-above-sibling($.actor);
    $.emit('open-state-changed', True);
  }

  method close ($a) {
    $!activeMenuItem.active = False if $!activeMenuItem;

    my $s = self;
    $!boxPointer.close($a, -> *@a { $s.emit('menu-closed'); })
      if $!boxPointer.visible;

    return unless $.isOpen;
    $!isOpen = False;
    $.emit('open-state-changed', False);
  }

  method destroy {
    self.sourceActor.disconnectObject(self) if self.sourceActor;
    Main.layoutManager.disconnect( $!systemModalOpenId)
      if $!systemModalOpenId;
    nextsame;
  }
}

class Gnome::Shell::PopupMenu::Dummy {

  submethod TWEAK ( :$sourceActor ) {
    self.actor = $sourceActor;
  }

  method sensitive {
    Proxy.new:
      FETCH => -> $    { True },
      STORE => -> $, v {      }
    }
  }

  method open {
    return if $.isOpen;
    $.isOpen = True;
    $.emit('open-state-changed', True);
  }

  method close {
    return unless $.isOpen;
    $.isOpen = False;
    $.emit('open-state-changed', False);
  }

  method toggle  { }

  method destroy { $.emit('destroy') }
}

class Gnome::Shell::UI::PopupMenu::SubMenu
  is Gnome::Shell::UI::PopupMenu::Base
{
  has $!sourceArrow is built;

  submethod TWEAK {
    self.actor = Gnome::Shell::St::ScrollView.new(
      style-class        => 'popup-sub-menu',
      hscrollbar_policy  => ST_POLICY_NEVER,
      vscrollbar_policy  => ST_POLICY_NEVER,
      clip-to-allocation => True
    );

    self.actor.add-actor($.box);

    my $s = self;
    self.actor.key-press-event.tap( -> *@a {
      @a.tail.r = $s.onKeyPressEvent( |@a )
    });
    self.actor.hide;
  }

  method !needsScrollBar {
    my  $tm      = self!getTopMenu;
    my ($,  $nh) = $tm.actor.get-preferred-height;
    my  $tn      = $tm.actor.get-theme-node;
    my  $tmh     = $tn.get-max-height;

    $tmh >= 0 && $nh >= $tmh
  }

  my sensitive {
    Proxy.new:
      FETCH => -> $     { $.sensitive && $.sourceActor.sensitive },
      STORE => -> $, \v { }
  }

  # method open ($a)
  # method close ($a)

  method onKeyPressEvent ($a, $e) {
    my $ev = Mutter::Clutter::Event.new($e);
    if $.isOpen && $e.get-key-symbol == CLUTTER_KEY_Left {
      $.close(BOXPOINTER_ANIMATION_FULL);
      $.sourceActor.active = True;
      return CLUTTER_EVENT_STOP;
    }
    CLUTTER_EVENT_PROPAGATE
  }
}

class Gnome::Shell::UI::PopupMenu::Section {
  method TWEAK {
    ( .actor, .isOpen ) = ( .box, True ) given self;
    self.actor.add-style-class-name('popup-menu-section');
  }

  method open  { $.emit('open-state-changed', True) }
  method close { $.emit('open-state-change', False) }
}

class Gnome::Shell::UI::PopupMenu::SubMenu::Item
  is Gnome::Shell::UI::PopupMenu::Item::Base
{

  submethod TWEAK ( :$text, :$wantIcon ) {
    self.add-style-class-name('popup-submenu-menu-item');
    if $wantIcon {
      self.icon = Gnome::Shell::St::Icon.new(
        style-class => 'popup-menu-icon'
      );
      self.add-child(self.icon);
    }

    self.label = Gnome::Shell::St::Label.new(
      :$text,

      y-expand => True,
      y-align  => True
    );
    self.add-child(self.label);
    self.label-actor = self.label;

    my $expander = Gnome::Shell::St::Bin.new(
      style-class => 'popup-menu-item-expaner',
      x-expand    => True
    );
    my $!triangle = arrowIcon(ST_SIDE_RIGHT);
    $!triangle.pivot-point = Graphene::Point.new(0.5, 0.6);

    my $!triangleBin = Gnome::Shell::St::Widget.new(
      y-exand => True,
      y-align => CLUTTER_ACTOR_ALIGN_CENTER
    );
    $!triangleBin.add-child($!triangle);

    self.add-child($!triangleBin);
    self.accessible-state = ATK_STATE_EXPANDABLE;

    self.menu = Gnome::Shell::UI::PopupMenu::SubMenu.new($!triangle);
    self.menu.tap('open-state-changed').tap( -> *@a {
      $s.subMenuOpenStateChanged( |@a );
    });
    self.destroy( -> *@a { @a.head.menu.destroy });
  }

  method !setParent ($parent) {
    $!menu.setParent($parent);
    nextsame;
  }

  method subMenuOpenStateChanged ($m, $o) {
    if $o {
      $.add-style-pseudo-class('open');
      self!getTopMenu.setOpenedSubMenu($.menu);
      $.add-accessible-state(ATK_STATE_EXPANDED);
      $.add-style-pseudo-class('checked');
    } else {
      $.remove-style-pseudo-class('open');
      self!getTopMenu.setOpenedSubMenu(Nil);
      $.remove-accessible-state(ATK_STATE_EXPANDED);
      $.remove-style-pseudo-class('checked');
    }
  }

  method setSubMenuOpen ($o) {
    $o ?? self.menu.open(BOXPOINTER_ANIMATION_FULL)
       !! self.menu.close(BOXPOINTER_ANIMATION_FULL);
  }

  method setOpenState ($o) {
    $.setSubmenuOpen($o);
  }

  method getOpenState {
    $.menu.isOpen;
  }

  method activate ($e) {
    $.setOpenState($.getOpenState.not);
  }
}

class Gnome::Shell::UI::PopupMenu::Manager {
  has %!grabParams;

  submethod BUILD ( :$actionMode = SHELL_ACTION_POPUP ) [{
    %grabParams<actionMode> = $actionMode;
  }

  submethod TWEAK ( :$owner ) {
    my $s = self;
    Global.state.notify('key-focus').tap( -> *@a [
      return unless $s.activeMenu;

      if $.findMenuForSource( Global.state.get-key-focus ) -> $nm {
        $s.changeMenu($nm);
      }
    });
    @!menus = ();
  }

  method new ($owner) {
    self.bless( :$owner );
  }

  method addMenu ($m, $p) {
    return if $!menus.grep( +$_ === +$m).elems;

    my $s = self;
    $m.open-state-changed.tap( -> *@a { $s.openMenuState( |@a ));
    $m.destroy.tap(  -> *@a { self.removeMenu($m) });
    $m.actor.captured-event.tap( -> *@a { $s.onCapturedEvent( |@a ) });

    $position ?? @!menus.splice($p, 0, $m);
              !! @!menus.push(@m);
  }

  method removeMenu ($m) {
    if +$m === +$.activeMenu {
      Main.popupModal($!grab);
      $!grab = Nil;
    }

    my $p = @!menus.first({ +$_ === +$m }, :k);
    return unless $p;

    $m.disconnectObject(self);
    $.actor.disconenctObject(self);

    @!menus.splice($p, 1);
  }

  method ignoreRelease { }

  method onMenuOpenState ($m, $o) {
    return if $o && +$.activeMenu === +$m;

    if $o {
      my ($om, $og) = ($.activeMenu, $!grab);
      $!grab = Main.pushModel($m.actor, %!grabParams);
      $!activeMenu = $m;
      $oldMenu.close(BOXPOINTER_ANIMATION_FADE) if $oldMenu;
      Main.popModal($og) if $og;
    } else {
      Main.popModal($!grab);
      $!activeMenu = $!grab = Nil;
    }
  }

  method changeMenu ($nm) {
    $nm.open(
      $!activemenu ?? BOXPOINTER_ANIMATION_FADE !! BOXPOINTER_ANIMATION_FULL
    );
  }

  method onCapturedEvent ($m, $e) {
    my $ta = Global.state.get-event-actor;

    given $e.type {
      when CLITTER_KEY_PRESS {
        given $e.get-key-symbol {
          when CLUTTER_KEY_DOWN {
            if +Global.stage.get-key-focus === $m.actor {
              $a.nagivate-focus(ST_DIR_TAB_FORWARD);
            }
          }

          when CLUTTER_KEY_ESCAPE {
            $m.close(BOXPOINTER_ANIMATION_FULL) if $m.isOpen;
          }
          return CLUTTER_EVENT_STOP;
        }

        when CLITTER_EVENT_ENTER {
          when ($e.flags +& Clutter.EventFlags.FLAG_GRAB_NOTIFY).not {
            my $hm = $.findMenuForSource($ta);

            self.changerMenu($hm) if +$hm && +$hm !== $ +$m;
          }
        }

        when CLUTTER_BUTTON_PRESS | CLUTTER_TOUCH_BEGIN {
          menu.close(BOXPOINTER_ANIMATION_FULL if $a.contains($ta).not;
        }
      }
    }
    CLUTTER_EVENT_PROPAGATE
  }

  method findMenuForSource ($s) {
    my $m = $s;
    while $m {
      if $m.menus.first({ +.sourceActor === +$s }) -> $r {
        return $r;
      }
      $m .= parent;
    }
    Nil;
  }

  method closeMenu ($i, $m) {
    $m.close(BOXPOINTER_ANIMATION_FULL) if $i;
  }
}
