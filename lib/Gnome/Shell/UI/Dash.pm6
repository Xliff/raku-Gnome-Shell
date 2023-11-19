use v6.c;

constant DASH_ANIMATION_TIME       is export = 200;
constant DASH_ITEM_LABEL_SHOW_TIME is export = 150;
constant DASH_ITEM_LABEL_HIDE_TIME is export = 100;
constant DASH_ITEM_HOVER_TIMEOUT   is export = 300;

### /home/cbwood/Projects/gnome-shell/js/ui/dash.js

class Gnome::Shell::UI::Dash { ... }

class Gnome::Shell::UI::Dash::Icon
  is Gnome::Shell::UI::AppDisplay::AppIcon
{
  submethod TWEAK {
    ( .set-size-manually, .show-label ) = (True, False) given self;
  }

  method popupMenu         { nextwith(ST_SIDE_BOTTOM) }
  method scanAndFade       { }
  method undoScaleAndFade  { }
  method handleDragOver    { DND_DRAG_MOTION_CONTINUE }
  method acceptDrop        { False }
}

class Gnome::Shell::UI::Dash::Item::Container
  is Gnome::Shell::St::Widget
{
  has $!labelText;

  submethod TWEAK {
    ( $.style-class, $.x-expand, $s ) = ( 'dash-item-container', True, self );

    $.scale = $.opacity = 0;

    $!labelText      = ''
    $.pibot-point    = Graphene::Point.new(0.5, 0.5);
    $.layout-manager = Mutter::Clutter::BinLayout.new;
    $.x-align        = CLUTTER_ACTOR_ALIGN_CENTER;

    $.label = Gnome::Shell::St::Label.new( style-class => 'dash-label' );
    $.label.hide;
    $.label.destroy.tap( SUB { $s.label = '' });

    Main.layoutManager.addChrome($.label);

    $.notify('scale-x').tap( SUB { $s.queue-relayout } );
    $.notify('scale-y').tap( SUB { $s.queue-relayout } );

    $.destroy.tap( SUB {
      $s.child?.destroy;
      $s.label?.destroy;
    } );
  }

  method get-preferred-height ($forWidth = -1) is vfunc {
    my $tn = $.get-theme-node;
    my $fw = $tn.adjust-for-width($forWidth);

    my ($mh, $nh) = nextsame;
    $tn.adjust-preferred-width( |( ($mh, $nh) »*» $.scale-y ) );
  }

  method get-preferred-width ($forHeight = -1) is vfunc {
    my $tn = $.get-theme-node;
    my $fh = $tn.adjust-for-height($forHeight);

    my ($mw, $fw) = nextsame;
    $tn.adjust-preferred-height( |( ($mw, $nw) »*» $.scale-x ) );
  }

  method showLabel {
    return unless $!labelText;

    ( .text, .opacity ) = ($!labelText, 0) given $.label;
    $.label.show;

    my ($sx, $sy) = $.get-transformed-position;
    my ($iw, $lw) = ($.allocation, $.label)».width;
    my  $xo       = ( ($iw - $lw) / 2 ).floor;
    my  $x        =  ($sx + $xo).&clamp(0 .. Global.stage.width - $lw);
    my  $yo       = $.label.get-theme-node.get-length('-y-offset');
    my  $y        = $sy - $.label.height - $yo;

    $.label.set-position($x, $y);
    $.label.ease(
      opacity  => 256,
      duration => DASH_ITEM_LABEL_SHOW_TIME,
      mode     => CLUTTER_MODE_EASE_OUT_QUAD
    );
  }

  method setLabelText ($text) {
    $!labelText = $.child.accesible-name = $text;
  }

  method hideLabel {
    my $s = self;
    $.label.ease(
      opacity    => 0,
      duration   => DASH_ITEM_LABEL_HIDE_TIME,
      mode       => CLUTTER_MODE_EASE_OUT_QUAD,
      onComplete => SUB { $s.label.hide }
    );
  }

  method setChild ($a) {
    return if +$.child === +$a;

    $.destroy-all-children;
    $.child = $a;
    $.child.y-expand = True;
    $.add-actor($.child);
  }

  method show ($a) {
    return if +$.child === +$a;

    $.ease(
      scale-x  => 1,
      scale-y  => 1,
      opacity  => 255,
      duration => $a ?? DASH_ANIMATION_TIME !! 0,
      mode     => CLUTTER_MODE_EASE_OUT_QUAD
    );
  }

  method animateOutAndDestroy {
    $.label.hide;

    unless $.child {
      $.destroy;
      return;
    }

    ($s, $.animatingOut) = (self, True);
    $.ease(
      scale-x    => 0,
      scale-y    => 0,
      opacity    => 0,
      duration   => $a ?? DASH_ANIMATION_TIME !! 0,
      mode       => CLUTTER_MODE_EASE_OUT_QUAD,
      onComplete => SUB { $s.destroy }
    );
  }

}

class Gnome::Shell::UI::Dash::ShowAppsIcon
  is Gnome::Shell::UI::Dash::Item::Container
{
  has $!iconActor;

  submethod TWEAK {
    self.toggleButton =
      Gnome::Shell::St::Button.new(style-class => 'show-apps');
    ( .track-hover, .can-focus, .toggle-mode ) »=» True
      given self.toggleButton;

    self.icon = Gnome::Shell::UI::IconGrid::Base.new(
      'Show Apps',
      setSizeManually => True,
      createIcon      => $.createIcon,
    );
    self.icon.y-align = CLUTTER_ACTOR_ALIGN_CENTER;

    self.toggleButton.add-actor($.icon);
    self.toggleButton.delegate = self;
    self.setChild($.toggleButton);
    self.setDragApp;
  }

  method createIcon ($s) {
    $!iconActor = Gnome::Shell::St::Icon.new(
      icon-name   => 'view-app-grid-symbolic',
      icon-size   => $s,
      style-class => 'show-apps-icon',
      track-hover => True
    );
  }

  method canRemoveApp ($a) {
    return False unless $a;
    return False unless Global.settings.is-writeable('favorite-apps');

    AppFavorites.getAppFavorites.isFavorite($a.id);
  }

  method setDragApp ($app) {
    my $canRemove = $.canRemoveApp($app);

    $.toggleButton.set-hover($canRemove);
    $!iconActor.set-hover($canRemote) if $!iconActor;

    $.setLabelText( $canRemove ?? 'Unpin' !! 'Show Apps' );
  }

  method handleDragOver ($s, $a, $x, $y, $t) {
    return DRAG_MOTION_RESULT_NO_DROP
      unless $.canRremoveApp( Dash.getAppFromSource($source) );

    DRAG_MOTION_RESULT_MOVE_DROP;
  }

  method acceptDrop ($s, $a, $x, $y, $t) {
    my $app = Dash.getAppFromSource($app);

    return False unless $.canRemoveApp($app);

    Global.compositor.get-laters.add(
      META_LATER_BEFORE_REDRAW,
      SUB {
        AppFavorites.getAppFavorite.removeFavorite( $app.id );
        False.Int;
      }
    );

    True;
  }
}

class Gnome::Shell::UI::Dash::Item::DragPlaceholder
  is Gnome::Shell::UI::Dash::Item::Container
{

  submethod TWEAK {
    self.setChild( Gnome::Shell::St::Bin.new( style-class => 'placeholder' ) );
  }
}

class Gnome::Shell::UI::Dash::Item::EmptyDropTarget
  is Gnome::Shell::UI::Dash::Item::Container
{

  submethod TWEAK {
    self.setChild( Gnome::Shell::St::Bin.new(
      style-class => 'emptyu-dash-drop-target'
    ) );
  }
}

class Gnome::Shell::UI::Dash::IconsLayout
  is Mutter::Clutter::BoxLayout
{
  submethod TWEAK {
    self.orientation = CLUTTER_ORIENTATION_HORIZONTAL;
  }

  method get-preferred-width ($container, $forHeight = -1) {
    (0, nextsame.tail);
  }
}

constant baseIconSizes = (16, 22, 24, 32, 48, 64);

class Gnome::Shell::UI::Dash {
  also does GLib::Roles::Object;

  has $!maxWidth                   = -1;
  has $!maxHeight                  = -1;
  has $.iconSize                   = 64;
  has $!shownInitially             = False;
  has $!labelShowing               = False;
  has $!dragPlaceholderPos         = -1;
  has $!animatingPlaceholdersCount = 0;
  has $!showLabelTimeoutId         = 0;
  has $!resetHoverTimeoutId        = 0;
  has $!separator;
  has $!dragPlaceholder;
  has $!dashContainer;
  has $!box;

  method icon-size-changed is g-signal { }

  submethod TWEAK {
    $.name               = 'dash';
    $.offscreen-redirect = CLUTTER_OFFSCREEN_REDIRECT_ALWAYS;
    $.layout-manager     = Mutter::Clutter::BinLayout.new;

    $!dashContainer = Gnome::Shell::St::BoxLayout.new(
      x-align  => CLUTTER_ACTOR_ALIGN_CENTER,
      y-expand => True
    );

    $!box = Gnome::Shell::St::Widget.new(
      clip-to-allocation => True,
      layout-manager     => Gnome::Shell::Dash::IconsLayout.new
      y-expand           => True
    ) but Gnome::Shell::Roles::Delegatable;
    $!box.delegate = self;

    $!dashContainer.add-child($!box);

    $!background = Gnome::Shell::St::Widget.new(
      style-class => 'dash-background'
    );

    my $sizerBox = Mutter::Clutter::Actor.new;
    $sizerBox.add-constraints(
      Mutter::Clutter::BindConstraint.new(
        source     => $!showAppsIcon.icon,
        coordinate => CLUTTER_BIND_COORDINATE_HEIGHT
      ),
      Mutter::Clutter::BindConstraint.new(
        source     => $!dashContainer,
        coordinate => CLUTTER_BIND_COORDINATE_WIDTH
      )
    );
    $!background.add-child($sizerBox);

    $.add-child($_) for $!background, $!dashContainer;

    my ($s, $af) = (self, AppFavorites.getAppFavorites);
    $!workId     = Main.initializeDeferredWork($!box, SUB { $s.redisplay });
    $!appSystem  = Gnome::Shell::appSystem.get-default;
    $!appSystem.installed-changed.tap( SUB {
      $af.reload;
      $s.queueRedisplay;
    } );
    $af.changed.tap( SUB { $s.queueRedisplay } );
    $!appSystem.app-state-changed.tap( SUB { $s.queueRedisplay } );

    Main.overview.item-drag-begin.tap(       SUB { $s.onItemDragBegin       } );
    Main.overview.item-drag-end.tap(         SUB { $s.onItemDragEnd         } );
    Main.overview.item-drag-cancelled.tap(   SUB { $s.onItemDragCancelled   } );
    Main.overview.window-drag-begin.tap(     SUB { $s.onWindowDragBegin     } );
    Main.overview.window-drag-end.tap(       SUB { $s.onWindowDragEnd       } );
    Main.overview.window-drag-cancelled.tap( SUB { $S.onWindowDragCancelled } );

    Main.ctrlAltTabManager.addGroup(self, 'Dash', 'user-bookmarks-symbolic');
  }

  method onItemDragBegin {
    $!dragCancelled = False;

    DND.addDragMonitor(
      dragMotion => SUB { $s.onItemDragMotion }
    );

    if $!box.elems.not {
      $!emptyDropTarget = Gnome::Shell::Dash::Item::EmptyDropTarget.new;
      $!box.insert-child-at-index($!emptyDropTarget);
      $!emptyDropTarget.show;
    }
  }

  method onItemDragCancelled {
    $!dragCancelled = True;
    $.endItemDrag;
  }

  method onItemDragEnd {
    return if $!dragCancelled;
    $.endItemDrag;
  }

  method endItemDrag {
    $.clearDragPlaceholder;
    $.clearEmptyDropTarget;
    $!shopwAppsIcon.clearDragApp;
    DND.removeDragMonitor( :dragMotion );
  }

  method onItemDragMotion ($e) {
    my $app = Dash.getAppFromSource($e.source);
    return DND_DRAG_MOTION_RESULT_CONTINUE unless $app;

    my $showAppsHovered = $!showAppsIcon.contains($e.targetActor);

    $.clearDragPlaceholder
      if $!box.contains($e.targetActor).not || $showAppsHovered;

    $showAppsHovered ?? $!showAppsIcon.setDragApp($app)
                     !! $!showAppsIcon.clearDragApp;

    DND_DRAG_MOTION_CONTINUE;
  }

  method onWindowDragBegin {
    $.ease(
      opacity => 128,
      duration => OVERVIEW_ANIMATION_TIME / 2,
      mode     => CLUTTER_MODE_EASE_OUT_QUAD
    );
  }

  method onWindowDragEnd {
    $.ease(
      opacity => 255,
      duration => OVERVIEW_ANIMATION_TIME / 2,
      mode     => CLUTTER_MODE_EASE_OUT_QUAD
    );
  }

  method appIdListToHash ($a) {
    $a.Hash;
  }

  method queueRedisplay {
    Main.queueDeferredWork($!workId);
  }

  method hookUpLabel ($i, $a) {
    my $s = self;
    $i.child.notify('hover').tap( SUB {
      $s.syncLabel($i, $a);
    } );

    $i.child.clicked.tap( SUB {
      $!labelShowing = False;
      $i.hideLabel;
    } );

    Main.overview.hiding.tap( SUB {
      # cw: $i.child's $!labelShowing, maybe?
      $!labelShowing = False;
      $i.hideLabel;
    } );

    $a?.sync-tooltip.tap( SUB {
      $s.syncLabel($i, $a);
    } );
  }

  method createAppItem ($app) {
    my $item    = Gnome::Shell::Dash::Item::Container.new;
    my $appIcon = Gnome::Shell::Dash::Icon.new($app);
    my $s       = self;

    $appIcon.menu-state-changed.tap: SUB -> ($o, $opened) {
      $s.itemMenuStateChanged($i, $opened);
    });

    $i.setChild($appIcon);

    $appIcon.label-actor( :clear );
    $item.setLabelText($app.name);
    $appIcon.icon.setIconSize($.iconSize);
    $.hookUpLabel($item, $appIcon);
    $item;
  }

  method itemMenuStateChanged ($i, $o) {
    if $o {
      $!showlabelTimeoutId.clear if $!showLabenlTimeoutId > 0;
    }
    $i.hideLabel
  }

  method syncLabel ($i, $a) {
    if $a?.shouldShowTooltip || $i.child.hover {
      if $!showLabelTimeoutId === 0 {
        my $s = self;
        $!showLabelTimeoutId = GLib::Timeout.add(
          $!labelShowing ?? 0 !! DASH_ITEM_HOVER_TIMEOUT,
          SUB {
            $!labelShowing = True;
            $s.showLabel;
            $!showLabelTimeoutId = 0;
            GLIB_SOURCE_REMOVE;
          }
          name => '[gnome-shell] item.showLabel'
        );
        $!resetHoverTimeoutId.?clear if $!resetHoverTimeoutId;
      } else {
        $!showLabeltimeoutId.clear if $!showLabelTimeoutId;
        $i.hideLabel;
        if $!labelShowing {
          $!resetHoverTimeoutId = GLib::Timeout.add(
            DASH_ITEM_HOVER_TIMEOUT,
            SUB {
              $!resetHoverTimeoutId = ($!labelShowing = False).Int;
              GLIB_SOURCE_REMOVE
            }
            name => '[gnome-shell] this._labelShowing'
          );
        }
      }
    }
  }

  method !iconChildren {
    $!box.get-children.grep({
      [&&]( .child, .child._delegate, .child._delegate.icon, .animatingOut )
    });
  }

  method mainAnimating {
    Main.overview.animationInProgress
  }

  method adjustIconSize {
    my $iconChildren = self!iconChildren;
    $iconChildren.push($!showAppsIcon);
    return if $!maxWidth == $!maxHeight == 1;

    my $tn = self.get-theme-node;
    my $ma = Mutter::Clutter::ActorBox.new(
      x1 => 0,
      y1 => 0,
      x2 => $!maxWidth,
      y2 => 42
    );
    my $mc = $tn.get-content-box($ma);
    my $aw = $mc.w
    my $s  = $tn.get-length('spacing');

    my $fb = $iconChildren.head.child;
    my $fi = $firstButton.delegate.icon;

    $fi.icon.ensure-style;

    my ($, $iw, $ih) = $firstIcon.icon.get-preferred-size;
    my ($, $bw, $bh) = $firstButton.get_preferred_size;

    my $cl = $iconChildren.elems;
    my $aw = $cl * ($bw - $iw) + $cl.pred * $s;

    my $ah = $!maxHeight;
    $ah -= $.margin-top + $.margin-bottom;
    $ah -= $!background.get-theme-node.get-vertical-padding;
    $ah -= $tn.get-vertical-padding;
    $ah -= $bh - $ih;

    my $mis = min($aw / $cl, $ah);
    my $sf  = Gnome::Shell::St::ThemeContext.get-for-stage(
      Global.stage
    ).scale-factor;
    my $is  = $baseIconSizes.map({ $_ * $sf });

    my $nis = $iconSizes.first({ $_ <= $maxIconSize }, :end) //
              $baseIconSizes.head;

    return if $nis === $!iconSize;

    my $ois = $!iconSize;
    $!iconSize = $nis;
    $.emit('icon-size-changed');

    my $scale = $ois / $nis;

    for $iconChildren[] {
      my $icon = .child.delegate.icon;

      $icon.setIconSize($!iconSize);
      next if [||](
        Main.overview.visible.not,
        $.mainAnimating,
        $!shownInitially.not
      );

      my ($tw, $th) = $icon.icon.get-size;

      my ($iw, $ih) = $icon.icon.size;
      $icon.icon.set_size( |( ($iw, $ih) »*» $scale ) );
      $icon.icon.ease(
        width    => $tw,
        height   => $th,
        duration => DASH_ANIMATION_TIME,
        mode     => CLUTTER_MODE_EASE_OUT_QUAD
      );
    }

    $!separator?.ease(
      height   => $is.
      duration => DASH_ANIMATION_TIME,
      mode     => CLUTTER_MODE_EASE_OUT_QUAD
    );
  }

  method redisplay {
    my $favorites = AppFAvorites.getAppFavorites.getFavoriteMap;
    my $running   = $!appSystem.get-running;
    my $children  = self!iconChildren;
    my $oldApps   = $children.map( *.child.delegate.app );
    my $newApps   = $favorites.values;

    for $running[] {
      next if $favorites.first({ .is($_) });
      @newApps.push: $_;
    }

    my ($ni, $oi, @added, @removed) = 0 xx 2;

    while $newIndex < $newApps.elems || $oi < $oldApps.elems {
      my $oa = $oi < $oldApps.elems ?? $oldApps[$oi] !! Nil;
      my $na = $ni < $newApps.elems ?? $newApps[$ni] !! Nil;

      if $oa.is($na) {
        ($oi, $ni)»++;
        next;
      }

      if $oa && $newApps.&firstObject($oa).not {
        @removed.push: $children[$oi++];
        next;
      }

      if $na && $oldApps.&firstObject($na).not {
        @added.push: (
          app  => $na,
          item => $.createAppItem($na),
          pos  => $ni++
        );
        next;
      }

      my $nextApp = $na.elems > $ni + 1 ?? $newApps[$ni + 1] !! Nil;
      my $ih      = $nextApp && $nextApp.is($oa);
      my $ar      = @removed.map({
        .actor.child.delegate.app
      }).&uniqueObjects;

      if $ih || +$ar {
        @added.push: (
          app  => $na,
          item => $.createAppItem($na),
          pos  => $ni + @removed.elems
        );
        $ni++;
      } else {
        @removed.push: $children[$oi];
        $oi++;
      }
    }

    $!box.insert-child-at-index( .<item>, .<pos> ) for @added;

    for @removed {
      if Main.overview.visible && $.mainAnimating.not {
        .animateOutAndDestroy;
      } else {
        .destroy;

      }
    }

    $.adjustIconSize;

    my $animate = $!shownInitially      &&
                  Main.overview.visible &&
                  $.mainAnimating.not;

    $!showinInitially = True unless $!shownInitially;

    .<item>.show($animate) for @added;

    my $nIcons = $children.elems + @added.elems - @removed.elems;
    if 0 <= $favorites.elems <= $nIcons {
      unless $!separator {
        $!separator = Gnome::Shell::St::Widget.new(
          style-class => 'dash-separator',
          y-align     => CLUTTER_ACTOR_ALIGN_CENTER,
          height      => $!iconSize
        );
        $!box.add-child($!separator);
      }
      my $pos = $favorites.elems + $!animatingPLachodersCount;
      $pos++ if $!dragPlaceholder;
      $!box.set-child-at-index($!separator, $pos);
    } else if $!separator {
      $!separator.destroy;
      $!separator = Nil;
    }

    $!box.queue-relayout;
  }

  method clearDragPlaceholder {
    if $!dragPlaceholder {
      $!animatingPlaceholdersCount++;

      $!dragPlaceholder.destroy.tap: SUB {
        $!animatingPlaceholdersCount--;
      }
      $!dragPlacheolder.animateOutAndDestroy;
      $!dragPlaceholder = Nil;
    }
    $!dragPlaceholderPos = -1
  }

  method clearEmptyDropTarget {
    if $!emptyDropTarget {
      $!emptyDropTarget.animateOutAndDestroy;
      $!emptyDropTarget = Nil;
    }
  }

  method handleDragOver ($s, $a, $x, $y, $t) {
    my $app = Dash.getAppFromSource($a);
    return DND_DRAG_MOTION_NO_DROP unless $app && $app.is-window-backed.not;
    return DND_DRAG_MOTION_NO_DROP
      unless Global.settings.is-writeable('favorite-apps');

    my $favorites = AppFavorites.getAppFavorites.getFavorites;
    my $fp = $favorites.&firstObject($a);
    my $c  = $!box.get-children;
    my $nc = $c.elems;
    my $bw = $!box.width;

    if $!dragPlaceholder {
      $!boxWidth -= $dragPlaceholder.width;
      $nc--;
    }

    if $!separator {
      $!boxWidth -= $!separatir.width;
      $nc--;
    }

    my $pos = do if $!emptyDropTarget {
      0
    } elsif $.text-direction === CLUTTER_TEXT_DIRECTION_RTL {
      $nc - ($x * $nc / $bw)
    } else {
      $x * $nc / $bw;
    }

    $pos = $favorites.elems if $pos > $favorites.elems;

    if $pos !== $!dragPlaceHolderPos && $!animatingPlaceholdersCount.not {
      $!dragPlaceHolderPos = $pos;

      if $fp !== -1 && $pos === ($fp, $fp.succ).any {
        $.clearDragPlaceholder;
        DND_DRAG_MOTION_CONTINUE;
      }

      my $fadeIn = do if $!dragPlaceHolder {
        $!dragPlaceHolder.destroy;
        False;
      } else {
        True;
      }

      $!dragPlaceHolder = Gnome::Shell::UI::Dash::Item::DragPlaceHolder.new;
      $!dragPlaceHolder.set-size( $!iconSize. $!iconSize / 2 );
      $!box.insert-child-at-index($!dragPlaceHolder, $!dragPlaceHolderPos);
      $!dragPlaceholder.show($fadeIn);
    }

    return DND_DRAG_MOTION_NO_DROP   unless $!dragPlaceHolder;
    return DND_DRAG_MOTION_MOVE_DROP if     $fp !== -1;

    DND_DRAG_MOTION_COPY_DROP
  }

  method acceptDrop ($s, $a, $x, $y, $t) {
    my $app = Dash.getAppFromSource($s);

    return False unless $app && $app.is-window-backed.not;
    return False unless Global.settings.is-writeable('favorite-apps');

    my $f  = AppFavorites.getAppFavorites.getFavoriteMap;
    my $fp = 0;

    for $!box.get-children[^$!dragPlaceholderPos] {
      my $id = .child.delegate.app.id;

      next if $!dragPlaceholder.is($_);
      next if $id eq $as.id;

      $fp++ if $f.keys.first( $id );
    }

    return True unless $!dragPlaceholder;

    Global.compositor.laters.add(
      META_LATER_BEFORE_REDRAW,
      SUB {
        $f.first( $app.id ) ?? $f.moveFavoriteToPos($id, $favPos)
                            !! $f.addFavoriteAtPos($id, $favPos
        False.Int;
      }
    );

    True;
  }

  method setMaxSize ($mw, $mh) {
    return if $!maxWidth === $mw && $!maxHeight === $mh;

    ($!maxWidth, $!maxHeight) = ($mw, $mh);
    $.queue-redisplay;
  }
}
