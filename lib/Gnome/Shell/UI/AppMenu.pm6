use v6.c;

### /home/cbwood/Projects/gnome-shell/js/ui/appMenu.js


class Gnome::Shell::UI::AppMenu is Gnome::Shell::UI::Popup::Menu {

  submethod TWEAK ( :$params ) {
    if Clutter::Main.is-rtl {
      $side = do given $side {
        when    ST_SIDE_LEFT  { ST_SIDE_RIGHT }
        when    ST_SIDE_RIGHT { ST_SIDE_LEFT  }
        default               { $_ }
      }
    }

    self.actor.add-style-class-name('app-menu');

    my ($favoritesSection, $showSingleWindows) =
      $params<favoritesSection showSingleWindows>;

    $!appSystem        = Gnome::Shell::AppSystem.get-default;
    $!parentalControls = Gnome::Shell::ParentalControlsManager.get-default;
    $!appFavorites     = Gnome::Shell::AppFavorites.getAppFavorites;

    ($!enableFavorites, $!showSingleWindows) =
      ($favoritesSection, $showSingleWindows)s

    $!windowsChangedId = $!updateWindowsLaterId = 0;

    $!openWindowsHeader = Gnome::Shell::UI::PopupMenu::Item::Sepoarator.new(
      'Open Windows'
    );
    $!windowSection = Gnome::Shell::UI::PopupMenu::Section.new;

    $.addMenuItem($_) for $!openWindowsHeader, $!windowsSection;
    $.addMenuItem( Gnome::Shell::UI::PopupMenu::Item::Separator.new );

    my $s = self;
    $!newWindowItem = self.addAction('New Window', -> *@a {
      $s.animateLaunch;
      $!app.open-new-window;
      Main.overview.hide;
    });

    my $!actionSection = Gnome::Shell::UI::PopupMenu::Section.new;
    $.addMenuItem($!actionSection);
    $.addMenuItem( Gnome::Shell::UI::PopupMenu::Item::Separator.new );

    $!onGpuMenuItem = $.addAction('', -> *@a {
      $s.animateLaunch;
      $!app.launch(0, -1, $.getNonDefaultLaunchGpu);
      Main.overview.hide;
    });

    $.addMenuItem( Gnome::Shell::UI::PopupMenu::Item::Separator.new );

    $!toggleFavoriteItem = $.addAction('', -> *@a {
        my $ai = $!app.id;

        .isFavorite($ai) ?? .removeFavorite($ai) !! .addFavorite($ai)
          given $!appFavorites;
    });

    $.addMenuItem( Gnome::Shell::UI::PopupMenu::Item::Separator.new );

    # cw: The callback is marked 'async' in the original code, which seems
    #     a bit redundant. Must look into what tha means!
    $!detailsItem = $.addAction('App Details', -> *@a {
      my $args = GLib::Variant.new( [ $!app.id, '' ] );
      my $bus  = await GIO::DBus.get(GIO_BUS_TYPE_SESSION);

      $bus.call(
        'org.gnome.Software',
        '/org/gnome/Software',
        'org.gtk.Actions',
        'Activate',
        GLib::Variant.new( '(sava{sv})', ['details', [$args], Nil] ),
        Nil, 0, -1, Nil
      );

      Main.overview.hide();
    });

    $.addMenuItem( Gnome::Shell::UI::PopupMenu::Item::Separator.new );

    $!quitItem = $.addAction('Quit', -> *@a { $!app.request-quit });

    $!appSystem.install-changed.tap(   -> *@a { $s.updateDetailsVisibility });
    $!appSystem.app-state-changed.tap( -> *@a { $s.onAppStateChanged });

    my $ufi = -> *@a { $s.updateFavoriteItem };
    $!parentalControls.app-filter-changed.tap($ufi);
    $!appFavorites.changed.tap($ufi);
    Global.settings.writable-changed('favorite-apps').tap($ufi);

    Global.notify('switcheroo-control').tap( -> *@a { $s.updateGpuItem });

    $.updateQuitItem;
    $.updateFavoriteItem;
    $.updateGpuItem;
    $.updateDetailsVisibility;
  }

  method new ($sourceActor, $side = ST_SIDE_TOP, $params) {
    self.bless( :$sourceActor, :$side, :$params );
  }

  method onAppStateChanged ($sys, $app) {
    return unless +$!app === +$app;

    $s.updateQuitItem;
    $s.updateNewWindowItem;
    $s.updateGpuItem;
  });

  method updateQuitItem {
    $!quitItem.visible = $!app ?? $!app.state == SHELL_APP_STATE_RUNNING
                               !! False;
  }

  method updateNewWindowItem {
    return unless $!app && $!app.appInfo;

    my $actions = $!app.AppInfo.list-actions // [];
    $!newWindowItem.visible = $!app.can-open-new-window &&
                              $actions.first('new-window');
  }

  method updateFavoriteItem {
    my $appInfo = $!app ?? $!app.appInfo !! Nil;
    $!toggleFavoriteItem.visible = [&&](
      $appInfo,
      $!enableFavorites,
      Global.settings.is-writeable('favorite-apps'),
      $!parentalControls.shouldShowApp($appInfo)
    );

    return unless $!toggleFavoriteItem.visible;

    my $id = $!app ?? $!app.id !! Nil;
    $!toggleFavoriteItem.label.text = $!appFavorites.isFavorite($id)
      ?? 'Unpin'
      !! 'Pin to Dash'
  }

  method updateGpuItem {
    my $proxy      = Global.switcheroo-control;
    my $hasDualGpu = $proxy?.get-cached-property('HasDualGpu')?.unpack;

    $!onGpuMenuItem.visible =
      $!app?.state === SHELL_APP_STATE_STOPPED && $hasDualGpu;

    return unless $!onGpuMenuItem;

    $!onGpuMenuItem.label.text =
      $.getNonDefaultLaunchGpu == SHELL_APP_LAUNCH_DEFAULT
        ?? 'Launch using Integrated Graphics Card'
        !! 'Launch using Discrete Graphics Card';
  }

  method updateDetailsVisibility {
    $!detailsItem.visible =
      $!appSystem.lookup-app('org.gnome.Software.desktop').so;
  }

  method animateLaunch {
    $.sourceActor.animateLaunch if $!sourceActor.^can('animateLaunch');
  }

  method getNonDEfaultLaunchGpu {
    $!app.appInfo.get-boolean('PrefersNonDefaultGPU')
      ?? SHELL_APP_LAUNCH_GPU_DEFAULT
      !! SHELL_APP_LAUNCH_GPU_DISCRETE;
  }

  method destroy {
    callsame;
    $.setApp(Nil);
  }

  method isEmpty {
    return unless $!app;
    nextsame;
  }

  method setApp ($app) {
    return if +$!app === +$app;

    $!app?.disconnectObject(self);

    $!app = $app;

    my $s = self;
    $!app?.windows-changed.tap( -> *@a { $s.queueUpdateWindowsSection });
    $.updateWindowsSection;

    my $actions = $!app?.app-info?.list-actions // [];

    $!actionSection.removeAll;
    for $actions[] -> $a {
      $!actionSection.addAction(
        $!appInfo.get-action-name($a),
        -> *@a ($e) {
          $.animateLaunch if $a === 'new-window';

          $!app.launch-action($action, $e.time);
          Main.overview.hide;
        }
      );
    }

    $.updateQuitItem;
    $.updateNewWindowItem;
    $.updateFavoriteItem;
    $.updateGpuItem;
  }

  method queueUpdateWindowsSection {
    return if $!updateWindowsLaterId;

    my $s = self;
    $!updateWindowsLaterId = Global.compositor.get-laters.add(
      META_LATER_BEFORE_REDRAW,
      -> *@a {
        $s.updateWindowsSection;
        G_SOURCE_REMOVE;
      }
    );
  }

  method updateWindowsSection {
    Global.compositor.get-laters-remove($!updateWindowsLaterId)
      if $!updateWindowsLaterId;

    $!updateWindowsLaterId = 0;

    $!windowsSection.removeAll;
    $!openWindowsHeader.hide;
    return unless $!app;

    my $minWindows = $!showSingleWindows ?? 1 !! 2;
    my $windows    = $!app.windows.grep( *.skip-taskbar );
    return if $windows.elems < $minWindows;

    for $windows[] {
      my $w = $_;
      my $t = .title || $!app.name,
      my $item = $!windowSection.addAction(
        $t,
        -> *@a ($e) {
          Main.activateWindow( $w, $e.time() );
        }
      );
      $window.notify('title').tap( -> *@a {
        $item.label.text = $t;
      });
    }
  }

}
