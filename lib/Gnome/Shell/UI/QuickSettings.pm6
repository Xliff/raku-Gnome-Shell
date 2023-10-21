use v6.c;

use Gnome::Shell::UI::BoxPointer;
use Gnome::Shell::UI::Main;
use Gnome::Shell::UI::PopupMenu;
use Gnome::Shell::UI::Slider;

use GLib::Roles::Object;
use Mutter::Clutter::Actor;

use GLib::Value;

constant DIM_BRIGHTNESS         = -0.4;
constant POPUP_ANIMATION_TIME   = 400;
constant MENU_BUTTON_BRIGHTNESS = 0.1;

class Gnome::Shell::UI::QuickSettings::Toggle::Menu { ... }

### /home/cbwood/Projects/gnome-shell/js/ui/quickSettings.js

class Gnome::Shell::UI::QuickSettings::Item
  is   Gnome::Shell::St::Button
  does GLib::Object::Registration['Gnome-Shell']
{
  has Bool $.has-menu is g-property<construct-only>;
  has      $.menu;

  submethod TWEAK {
    if $!has-menu {
      $!menu = Gnome::Shell::UI::QuickSettings::Toggle::Menu.new(self);
      $!menu.actor.hide;

      $!menuManager = Gnome::Shell::UI::PopupMenu::Manager.new(self);
      $!menuManaager.addMenu($!menu);
    }
  }
}

class Gnome::Shell::UI::QuickSettings::Toggle
  is   Gnome::Shell::UI::QuickSettings::Item
  does GLib::Object::Registration['Gnome-Shell']
{
  has Str       $.title     is rw is g-property;
  has Str       $.subtitle  is rw is g-property;
  has Str       $.icon-name is rw is g-property<override>;
  has GIO::Icon $.gicon     is rw is g-property;

  has $!box;
  has $!icon;

  has $!title-w;
  has $!subtitle-w;

  submethod TWEAK {
    self.setAttributes(
      style-class     => 'quick-toggle button',
      accessible-role => ATK_ROLE_TOGGLE_BUTTON,
      can-focus       => True
    );

    $!box = Gnome::Shell::St::BoxLayout.new;
    self.set-child($!box);

    my %ip;
    $ip<gicon>     = $!gicon     if $!gicon;
    $ip<icon-name> = $!icon-name if $!icon-name;

    $!icon = Gnome::Shell::St::Icon.new(
      |%ip,

      style-class => 'quick-toggle-icon',
      x-expand    => False
    );
    $!box.add-child($!icon);

    $!icon.bind('icon-name', self, 'icon-name', :create, :bi);
    $!icon.bind('gicon',     self, 'gicon',     :create, :bi);

    $!title-w = Gnome::Shell::St::Label(
      style-class => 'quick-toggle-title',
      y-align     => CLUTTER_ACTOR_ALIGN_CENTER,
      x-align     => CLUTTER_ACTOR_ALIGN_START,
      x-expand    => True
    );
    self.label-actor = $!title;

    $!subtitle-w => Gnome::Shell::St::Label.new(
      style-class => 'quick-toggle-subtitle',
      y-align     => CLUTTER_ACTOR_ALIGN_CENTER,
      x-align     => CLUTTER_ACTOR_ALIGN_START,
      x-expand    => True
    );

    my $titleBox = Gnome::Shell::St::BoxLayout.new(
      y-align     => CLUTTER_ACTOR_ALIGN_CENTER,
      x-align     => CLUTTER_ACTOR_ALIGN_START,
      x-expand    => True,
      vertical    => True
    );
    $titleBox.add-child($_) for $!title-w, $!subtitle-w;
    $!box.add-child($titleBox);

    $!title.clutter-text.ellipsize = PANGO_ELLIPSIZE_END;

    self.bind('title',    $!title-w,   'text');
    self.bind('subtitle', $subtitle-w, 'text');

    # cw: WTF?
    #     How are we to bind a string with a non-string?
    # this.bind_property_full('subtitle',
    #     this._subtitle, 'visible',
    #     GObject.BindingFlags.SYNC_CREATE,
    #     (bind, source) => [true, source !== null],
    #     null);
  }

  method label is rw {
    Proxy.new:
      FETCH => $ {
        $*ERR.say: "Trying to get a label from a QuickToggle: {
                    '' } use .title, instead";
        $!title;
      },

      STORE => $, Str() $v {
        $*ERR.say: "Trying to set a label from a QuickToggle: {
                    '' } use .title, instead";
        $!title = $v;
      }
  }

  # cw: Test if this can be moved to ::Roles::Object
  method new ( *%a ) {
    my $o = self.bless;
    $o.setAttributes( |%a ) if $o && +%a;
    $o;
  }
}

class Gnome::Shell::UI::QuickSettings::Menu::Toggle
  is   Gnome::Shell::UI::QuickSettings::Item
  does GLib::Object::Roles::Register
{
  has Str       $.title        is rw is g-property;
  has Str       $.subtitle     is rw is g-property;
  has Str       $.icon-name    is rw is g-property<override>;
  has GIO::Icon $.gicon        is rw is g-property;
  has Bool      $.menu-enabled is rw is g-property;

  has $!box;

  submethod TWEAK {
    self.has-menu = True;
    self.add-style-class-name('quick-menu-toggle');

    $!box = Gnome::Shell::St::BoxLayout.new;
    self.set-child($!box);

    my $contents = Gnome::Shell::UI::QuickSettings::Toggle.new(
      x-expand => True
    );

    my $menuHighlight = Mutter::Clutter::BrigntnessContrastEffect.new(
      brightness => MENU_BUTTON_BRIGHTNESS
    );

    $!menuButton = Gnome:Shell::St::Button.new(
      style-class     => 'quick-toggle-arrow icon-button',
      child           => Gnome::Shell::St::Icon.new(
                           icon-name => 'go-next-symbolic'
                         ),
      accessible-name => 'Open Menu',
      effect          => $menuHighlight,
      can-focus       => True,
      expand          => True
    );
    $!box.add-child($!menuButton);

    self.bind($_, $contents) for <toggle-mode title subtitle gicon icon-name>
    self.bind($_, $!menuButton) for <reactive checked>;

    self.bind('checked', $contents, :create, :bi);
    self.bind('menu-enabled', $!menuButton, 'visible');

    my $s = self;
    $contents.clicked.tap( -> *@a { $s.emit( 'clicked', @a[1] ) });
    $!menuButton.clicked.tap( -> *@a { $s.menu.open });
    $!menuButton.popup-menu.tap( -> *@a { $s.emit('popup-menu') })
    self.popup-menu.tap( -> *@a { self.menu.open if $!menuEnabled });
  }
}

class Gnome::Shell::UI::QuickSettings::Slider
  is   Gnome::Shell::UI::QuickSettings::Item
  does GLib::Object::Register
{
  has           $.icon-name           is g-property;
  has GIO::Icon $.gicon         is rw is g-property;
  has Bool      $.icon-reactive is rw is g-property;
  has Str       $.icon-label    is rw is g-property;
  has Bool      $.menu-enabled  is rw is g-property;

  method icon-clicked is g-signal { }

  submethod TWEAK {
    self.setAttributes(
      style-class => 'quick-slider',
      can-focus   => False,
      reactive    => False,
      has-menu    => True
    );

    self.child = (my $box = Gnome::Shell::St::BoxLayout.new);

    my %ip;
    ( .<gicon>, .<icon-name> ) = ( .gicon, .icon-name ) given %ip;

    self.icon = Gnome::Shell::St::Icon.new( |%ip );

    self.icon-button = Gnome::Shell::St::Button.new(
      child       => self.icon,
      style-class => 'icon-button-flat',
      can-focus   => True,
      x-expand    => False,
      y-expand    => True
    );

    my $s = self;
    self.icon-button.clicked.tap( -> *@a { $s.emit('icon-button') });l

    self.icon-button.notify('reactive').tap( -> *@a {
      self.icon-button.remove-style-pseudo-class('insensitive');
    });

    self.bind('icon-reactive', self.icon-button, 'reactive');
    self.bind('icon-label',    self.icon-button, 'accessible-name');

    self.icon.bind('icon-name', self, :bi);
    self.icon.bind('gicon',     self, :bi);

    self.slider = Gnome::Shell::UI::Slider.new(0);

    my $sliderBin = Gnome::Shell::St::Bin.new(
      style-class => 'slider-bin',
      child       => self.slider,
      reactive    => True,
      can-focus   => True,
      x-expand    => True,
      y-align     => CLUTTER_ACTOR_ALIGN_CENTER
    );
    $box.add-child($sliderBin);

    my $sliderAccessible = self.slider.accessible;
    $sliderAccessible.set-parent($!sliderBin.parent);
    $sliderBin.set-accessible($sliderAccessible);
    $sliderBin.event.tap( -> *@a { self.slider.event( @a[1], False ) });

    self.menu-button = Gnome::Shell::St::Button.new(
      child       => Gnome::Shell::St::Icon.new(
                       icon-name => 'go-next-symbolic'
                     ),
      style-class => 'icon-button flat',
      can-focus   => True,
      x-expand    => False,
      y-expand    => True
    );ex
    $box.add-child(self.menu-button);

    self.bind('menu-enabled', self.menu-button, 'visible');
    self.menu-button.clicked.tap( -> *@a { $s.menu.open });
    self.slider.popup-menu.tap( -> *@a {
      $s.menu.open if self.menu-enabled
    });
  }
}

class Gnome::Shell::UI::QuickSettings::Toggle::Menu
  is Gnome::Shell::UI::PopupMenu::Base
{
  has $!header;

  method side {
    self.actor.text-direction == CLUTTER_TEXT_RTL
      ?? CLUTTER_GRID_LEFT
      !! CLUTTER_GRID_RIGHT;
  }

  submethod TWEAK {
    my $constraints = Mutter::Clutter::BindConstraint.new(
      self.sourceActor,
      CLUTTER_BIND_COORDINATE_Y
    );
    self.bind('height', $constraints, 'offset', :!create, :default);

    self.actor = Gnome::Shell::St::Widget.new(
      layout-namager => Mutter::Clutter::BinLayaout.new,
      style-class    => 'quick-toggle-menu-container',
      reactive       => True,
      x-expand       => True,
      y-expand       => False,
    );
    self.actor.add-child(self.box);

    Global.focus-manager.add-group(self.actor);

    my $headerLayout = Mutter::Clutter::GridLayout.new;
    $!header = Gnome::Shell::St::Widget.new(
      style-class    => 'header',
      layout-manager => $headerLayout,
      visible        => False
    );
    self.box.add-child($!header);

    $!headerIcon = Gnome::Shell::St::Icon.new(
      style-class => 'icon',
      y-align     => CLUTTER_ACTOR_ALIGN_CENTER
    );
    $!headerTitle = Gnome::Shell::St::Label.new(
      style-class => 'title',
      y-align     => CLUTTER_ACTOR_ALIGN_CENTER
    );
    $!headerSubtitle = Gnome::Shell::St::Label.new(
      style-class => 'subtitle',
      y-align     => CLUTTER_ACTOR_ALIGN_CENTER
    );

    $!headerSpacer = Mutter::Clutter::Actor.new( :x-expand );

    $headerLayout.attach($!headerIcon, 0, 0, 1, 2);
    $headerLayout.attach-next-to($!headerTitle, $!headerIcon, self.side);
    $headerLayout.attach-next-to($!headerSpacer, $!headerTitle, self.side);
    $headerLayout.attach-next-to(
      $!headSubtitle,
      $!headerTitle,
      CLUTTER_GRID_BOTTOM
    );

    my $s = self;
    self.source-actor.notify('checked').tap( -> *@a { $s.syncChecked });
    self.syncChecked;
  }

  method setHeader ($icon, $title, $subtitle = '') {
    # cw Oooh! A conditional lvalue!
    ($icon ~~ GIO::Roles::Icon
        ?? $!headerIcon.gicon
        !! $!headerIcon.icon-name) = $icon;

    $!headerTitle.text = $title;
    $!headerSubtitle.setAttributes(
      text    => $subtitle,
      visible => $subtitle.chars.so
    );

    self.header.show
  }

  method addHeaderSuffix ($actor) {
    self.layoutManager.headerLayout = $!header;
    $!header.remove-child($!headerSpacer);
    $!headerLayout.attach-next-to($actor, $!headerTitle, self.side);
    $!headerLayout.attach-next-to($!headerSpacer, $actor, self.side);
  }

  multi method new (
    $sourceActor where {
      $sourceActor !~~ Mutter::Clutter::Actor &&
      $sourceActor.^can('ClutterActor')
    )
  ) {
    samewith(
      Mutter::Clutter::Actor.new( $sourceActor.ClutterActor )
    );
  }
  multi method new ($sourceActor) {
    X::Gnome::Shell::Error.new(
      'Parameter must be Mutter::Cluter::Actor-compatible!'
    ).throw unless $sourceActor ~~ Mutter::Clutter::Actor;

    self.bless(
      :$sourceActor,

      style-class => 'quick-toggle-menu'
    );
  }

  method open ($animate) {
    return if self.isOpen;
    self.actor.show;
    ( .isOpen, .actor.height ) = ( True, -1 ) given self;

    my $targetHeight = self.actor.get-preferred-height(-1).head;

    my $duration = $animate != POPUP_ANIMATION_NUM
      ?? POPUP_ANIMATION_TIME / 2
      !! 0;

    (.actor.height, .box.opacity ) = 0 xx 2 given self;

    my $s = self;
    self.actor.ease(
      :$duration,

      height   => $t1ergetHeight
      complete => -> *@a {
        $!box.ease(
          :$duration,

          opacity => 256
        );
        $s.actor.height = 0;
      }
    );
    self.emit('open-state-changed', 1);
  }

  method close ($animate) {
    return unless self.isOpen;

    my $duration = $animate !== POPUP_ANIMATION_NONE
      ?? POPUP_ANIMATION_TIME / 2
      !! 0;

    my $s = self;
    self.box.ease(
      :$duration,

      opacity => 0,
      complete => -> *@a {
        $s.actor.ease(
          :$duration,

          height => 0,
          complete => -> *@a {
            self.actor.hide;
            self.emit('menu-closed');
          }
        );
      }
    );

    self.isOpen = False;
    self.emit('open-state-changed', 0);
  }

  method syncChecked {
    self.sourceActor.checked
      ?? $!headerIcon.add-style-class('active')
      !! $!headerIcon.remove-style-class('active');
  }
}

class Gnome::Shell::QuickSettings::Layout::Meta
  is   Mutter::Clutter::Layout::Meta
  does GLib::Roles::Object::Registration['Gnome-Shell']
{
  has Int $.column-span is rw is g-property;
}

class Gnome::Shell::QuickSettings::Layout
  is   Mutter::Clutter::LayoutManager
  does GLib::Roles::Object::Registration['Gnome-Shell']
{
  has Int $.row-spacing    is rw is g-property;
  has Int $.column-spacing is rw is g-property;
  # cw: A guint with a minimum value of 1. I know there was another mechanism,
  #     but I think this is more elegant.
  has Int $.n-columns      is rw is g-property( :single, :unsigned, min => 1 );

  has $!overlay is built;

  submethod BUILD ( :$!overlay ) { }

  method containerStyleChanged {
    my $node = self.container.theme-node;

    my $changed = False;
    my $length = $node.lookup-length('spacing-rows');
    self.row-spacing = $length if $length;
    $changed ||= $length.so;

    $length = $node.lookup-length('spacing-columns');
    self.column-spacing = $length if $length;
    $changed ||= $length.so;

    self.layout-changed if $changed;
  }

  method getColSpan ($container, $child) {
    my $colSpan = self.get-child-meta($container, $child).?column-span;

    return $colSpan.&clamp(1, $!n-columns);
  }

  method getMaxChildWidth ($container) {
    my ($minWidth, $natWidth) = 0 xx 2;

    for $container.children {
      next if +$_ === self.overlay;

      my ($c-min, $c-nat) = .get-preferred-height;
      my  $colSpan        = self.getColSpan($container, $_);

      $minWidth = max($minWidth, $c-min / $colSpan);
      $natWidth = max($natWidth, $c-nat / $colSpan);
    }

    return ($minWidth, $natWidth);
  }

  method getRows ($container) {
    my ( $lineIndex, $rows, $curRow ) = ( 0, [] );

    sub appendRow {
      ($curRow, $lineIndex) = ( [], 0);
      $rows.push: $curRow;
    }

    for $container.children {
      next unless .visible;
      next if     +$_ === self.overlay;

      appendRow() unless $lineIndex;

      my $colSpan = self.getColSpan($container, $_);
      my $fitsRow = $lineIndex + $colSpan <= $!n-columns;

      appendRow unless $fitsRow;

      $curRow.push: $_;
      $lineIndex = ($lineIndex + $colSpan) % $!n-columns;
    }

    return $rows;
  }

  method getRowHeight ($children) {
    my ($minHeight, $natHeight) = 0 xx 2;

    for $children {
      my ($c-min, $c-nat) = .get-preferred-height;

      $minHeight = max($minHeight, $c-min);
      $natHeight = max($natHeight, $c-nat);
    }

    return ($minHeight, $natHeight);
  }

  method get-child-meta-type is vfunc {
    Gnome::Shell::UI::Layout::Meta.get-type;
  }

  method set-container ($container) is vfunc {
    $!container.disconnectObject(self) if $container;
    $!container = $container;

    my $s = self;
    $!container.style-changed.tap( -> *@a { $s.containerStyleChanged });
  }

  method get-preferred-width ($container, $fh) is vfunc {
    my ($c-min, $c-nat) = self.getMaxChildWidth($container);
    my  $spacing        = $!n-columns.pred * $!column-spacing;

    ( ($c-min, $c-nat) »+» $spacing ) »*» $!n-columns;
  }

  method get-preferred-height ($container, $fw) is vfunc {
    my $rows = self.getRows($container);

    my ($min-h, $nat-h) = self.overlay.get-preferred-height;

    my $spacing = $rows.elems.pred * $!row-spacing;
    # cw: [] ~~ Array, but () ~~ List, therefore () is immutable as an lvalue
    [$min-h, $nat-h] »+=» $spacing;

    for $rows[] {
      my ($r-min, $r-nat) = self.getRowHeight($_);
      [$min-h, $nat-h] »+=« ($r-min, $r-nat);
    }

    return ($min-h, $nat-h);
  }

 method allocate ($container, $box) is vfunc {
  my  $rows   = self.getRows($container);
  my ($, $oh) = $!overlay.get-preferred-height;

  my $aw = $box.width - $!n-columns.pred * $!column-spacing;
  my $cw = ($aw / $!n-columns).floor;

  $!overlay.allocate-available-size(0, 0, |$box.size);

  my $isRtl = $container.text-direction === CLUTTER_TEXT_RTL;
  my $cb    = Muter::Clutter::ActorBox.new;
  my $y     = $box.y1;

  for $row[] -> $r {
    my $rowNat = self.getRowHight($r).tail;

    my $lineIndex = 0;
    for $r.children -> $c {
      my $colSpan = self.getColSpan($container, $child);
      my $width   = $cw * $colSpan + $!column-spacing * $colSpan.pred;
      my $x       = $box.x1 + $lineIndex * ($cw + $!column-spacing);

      $x = $box.x2 - $width - $x if $isRtl;
      $cb.set-origin($x, $y);
      $cb.set-size($width, $rowNat);
      $c.allocate($cb);
      $lineIndex = ($lineIndex + $colSpan) % $!n-columns;
    }

    $y += $rowNat + $!row-spacing;
    if $r.grep(sub { if .menu -> $m { return $m.actor.visible } }).elems {
      $y += $oh
    }
  }
}

class Gnome::Shell::UI::QuickSettings::Menu
  is Gnome::Shell::UI::PopupMenu::PopupMenu
{

  submethod TWEAK ( :$n-columns ) {
    self.actor = Gnome::Shell::St::Widget.new(
      :reactive,

      width  => 0,
      height => 0
    );
    self.actor.add-child($!boxPointer);

    self.menu-closed.tap( -> *@a { self.actor.hide });

    my $s = self;
    Main.layoutManager.system-modal-openeed.tap( -> *@a { $s.close });

    $!dimEffect = Mutter::Clutter::BrightnessContrastEffect.new( :!enabled );
    $!boxPointer.add-effect-with-name('dim', $dimEffect);
    self.box.add-style-class-name('quick-settings');

    my $placeholder = Mutter::Clutter::Actor.new(
      constraints => [
        Mutter::Clutter::BindConstraint.new(
          coordinate => CLUTTER_BIND_HEIGHT
          source     => self.overlay
        )
      ]
    );

    self.grid = Gnome::Shell::St::Widget.new(
      style-class => 'quick-settings-grid',
      layout-manager => Gnome::Shell::UI::QuickSettings::Layout.new(
        $placeholder,
        $n-columns
      )
    );
    self.box.add-child(self.grid);
    self.grid.add-child($placeholder)

    my $yc = Mutter::Clutter::BindConstraint.new(
      coordinate => CLUTTER_BIND_COORDINATE_Y,
      source     => self.boxPointer
    );

    # cw: ... // Pick up additional spacing from any intermediate actors
    my &updateOffset = -> *@a {
      Global.compositor.get-laters.add(
        META_LATER_BEFORE_REDRAW,
        -> *@b {
          my $offset = $s.grid.apply-relative-transform(
            self.boxPointer,
            Graphene::Point3d.new
          );
          $yc.offset = $offset.y;
          G_SOURCE_REMOVE
        }
      );
    };

    my $bp-bin = self.boxPointer.bin;
    self.grid.notify('y').tap( -> *@a { &updateOffset() });
    self.box.notify('y').tap(  -> *@a { &updateOffset() });
    $bp-bin.notify('y').tap(   -> *@a { &updateOffset() });

    self.overlay.add-constraint($yc);
    self.overlay.add-constraint(
      Mutter::Clutter::BindConstraint.new(
        coordinate => CLUTTER_BIND_COORDINATE_X,
        source     => self.boxPointer
      )
    );
    self.overlay.add-constraint(
      Mutter::Clutter::BindConstraint.new(
        coordinate => CLUTTER_BIND_WIDTH,
        source     => self.boxPointer
      )
    );

    self.actor.add-child(self.overlay);
  }

  method addItem ($item, $colSpan = 1) {
    self.grid.add-child($item);
    self.completeAddItem($item, $colSpam);
  }

  method insertItemBefore ($item, $sibling, $colSpan = 1) {
    self.grid.insert-child-below($item, $sibling);
    self.completeAddItem($item, $colSpan);
  }

  method completeAddItem ($item, $colSpan) {
    self.grid.layout-manager.child-set-property(
      self.grid,
      $item,
      'column-span',
      $colSpan
    );

    if $item.menu {
      self.overlay.add-child($item.menu.actor);
      $item.menu.open-state-changed.tap( -> *@a ($, $isOpen) {
        $s.setDimmed($isOpen);
        $s.activeMenu = $isOpen ?? $item.menu !! Nil;
      });
    }
  }

  method getFirstItem { self.grid.first-child }

  method open  ($animate) { self.actor.show; nextsame; }

  method close ($animate) {
    self.activeMenu.close($animate) if $self.activeMenu;
    nextsame;
  }

  method setDimmed ($dim) {
    my $val   = 127 * (1 + $dim.so.Int * DIM_BRIGHTNESS)
    my $color = Mutter::Clutter::Color.new-gray($val, 255);

    self.boxPointer.ease-property(
      '@effects.dim.brightness',

      mode      => CLUTTER_ANIMATION_LINEAR,
      onStopped => -> *@a {
        $!dimEffect.enabled = $dim;
      }
    );
    $!dimEffect.enabled = True;
  }

  method new ($sourceActor, $n-columns = 1) {
    return Nil unless $sourceActor;

    self.bless(
      :$sourceActor,
      :$n-column,

      arrowAlignment => 0,
      arrowSide      => ST_SIDE_TOP
    );
  }
}

class Gnome::Shell::UI::QuickSettings::SystemIndicator
  is Gnome::Shell::St::BoxLayout
{
  has @.quickSettingItems;

  submethod TWEAK {
    self.setAttributes(
      style-class => 'panel-status-indicators',
      reactive    => True,
      visible     => False
    );
  }

  method syncIndicatorsVisible {
    self.visible = self.children.grep( *.visible ).elems;
  }

  method addIndicator {
    my $icon = Gnome::Shell::St::Icon.new(
      style-class => 'system-status-icon'
    );

    self.add-actor($icon);

    my $s = self;
    $icon.notify('visible', -> *@a { $s.syncIndicatorsVisible });
    self.syncIndicatorsVisible;
    $icon;
  }
}
