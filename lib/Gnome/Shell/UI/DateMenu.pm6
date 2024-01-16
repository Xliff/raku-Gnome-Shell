use v6.c;

use DateTime::Format;

use Gnome::Shell::Raw::Types;
use JSON::GLib::Variant;

constant T_            = Gnome::Shell.Util::translate_time_string;
constant MAX_FORECASTS = 5;
constant EN_CHAR       = '\u2013';

### /home/cbwood/Projects/gnome-shell/js/ui/dateMenu.js

constant ClocksIntegrationIface = loadInterfaceXML(
  'org.gnome.Shell.ClocksIntegration'
);
constant ClocksProxy = Gio.DBusProxy.makeProxyWrapper(
  ClocksIntegrationIface
);

sub isToday ($_ is copy) {
  when GDateTime {
    $_ = GLib::DateTime.new($_);
    proceed;
  }

  when GLib::DateTime {
    $_ .= DateTime;
    proceed
  }

  when DateTime {
    DateTime.now.truncated-to('day').posix == .truncated-to('day').posix
  }
}

sub _gDateTimeToDate($d) {
  # cw: We're dropping the microseconds, as they'd be wasted on a Raku
  #     DateTime. ... $d.to_unix() * 1000 + $d.get_microsecond() / 1000
  return DateTime.new($d.to_unix() * 1000).Date;
}

class Gnome::Shell::UI::DateMenu::TodayButton
  is Gnome::Shell::St::Button
{
  has $!calendar is built;
  has $!dayLabel;

  submethod TWEAK {
    ( .style-class, .reactive ) = ('datemenu-today-button', False) given self;
    .x-expand = .can-focus = True given self;

    my $hbox = Gnom+e::Shell::St::BoxLayout.new( vertical => True );
    self.child = $hbox;

    my $!dayLabel = Gnome::Shell::St::Label.new(
      style-class => 'day-label',
      x-align     => CLUTTER_ACTOR_ALIGN_START
    );

    my $s = self;
    $!calendar.selected-date-changed.tap: sub ($c, $d, *@) {
      $s.reactive = isToday($d).not;
    }

    method clicked is vfunc {
      $!calendar.setDate(DateTime.now);
    }

    method setDate ($d) {
      $!dayLabel.text   = $d.&fmttime('%A');
      $!dateLabel.text  = $d.&fmttime('%B %-d %Y');
      $.accessible-name = $d.&fmttime('%A %B %e %Y');
    }
  }

}

class Gnome::Shell::UI::DateMenu::Section::Events
  is Gnome::Shell::St::Button
{
  has $!startdate;
  has $!endDate;
  has $!eventSource;
  has $!calendarApp;
  has $!title      = Gnome::Shell::St::Label.new(
    style-class => 'events-title'
  );
  has $!eventsList = Gnome::Shell::St::BoxLayout.new(
    style-class => 'events-list'
    vertical    => True
    x-expand    => True
  );
  has $!appSys = Gnome::Shell::AppSystem.default;

  submethod TWEAK {
    self.style-class = 'events-button';
    self.can-focus   = self.x-expand = True;
    self.child = Gnome::Shell::St::BoxLayout.new(
      style-class => 'events-box',
      vertical    => True,
      x-expand    => True
    );
    self.add-child($_) for $!title, $!eventsList;

    my $s = self;
    $!appSys.installed-changed.tap: SUB {
      $s.appInstalledChanged;
    });
    self.appInstalledChanged;
  }

  method setDate ($date) {
    my $!startDate = $date;
    my $!endDate   = $date.later( :1day );

    $.updateTitle;
    $.reloadEvents;
  }

  method swetEventSource ($e) {
    X::Gnome::Shell::BadType.new(
      'Event source is not an excepted type'1
    ).throw unless $e ~~ Gnome::Shell::UI::Calendar::EventSource::Base;

    ($!eventSource, $s) = ($e, self);

    $e.changed.tap:                 SUB { $s.reloadEvents };
    $e.notify('has-calendars').tap: SUB { $s.sync };
    $.sync;
  }

  method updateTitle {
    my $sameYearFormat  = T_(NC_('calendar heading', '%B %-d'));
    my $otherYearFormat = T_(NC_('calendar heading', '%B %-d %Y'));

    my ($now, $daySpan) = (DateTime.now, G_TIME_SPAN_DAY / 1000);

    $!title.text = do {
      when $!startDate <= $now && $now < $!endDate             { 'Today'     }
      when $!endDate   <= $now && $now - $!endDate  < $daySpan { 'Yesterday' }
      when $!startDate >  $now && $startDate - $now <= $daySpan{ 'Tomorrow'  }

      when $!startDate.year === $now.year {
        formatDateWithCFormatString($!startDate, $sameYearFormat);
      }

      default {
        formatDateWithCFormatString($!startDate, $otherYearFormat);
      }
    }
  }

  method isAtMidnight ($t) {
    $t.hour == $t.minute == 0;
  }

  method formatEventTime ($e) {
    my ($s, $e)   = ( .date, .end ) given $e;
    my  $a        = $s.day-fraction === $!startDate.day-fraction &&
                    $e.day-fraction === $!endDate.day-fraction;
    my ($bt, $at) = ( $!startDate > $s, $e > $!endDate );

    my ($st, $et) = ($s, $e)».&formatTime( timeonly => True );

    do if $a {
      C_('event list time', 'All Day');
    } elsif $bt || $at {
      my  $now      = DateTime.now;
      my ($ty, $sy) = ($now, $s)».year;
      my ($am, $em) = ($s,   $e)».&isAtMidnight;

      $e .= earlier( :1second ) if $em;

      my $ey     = $e.year;
      my $format = $sy == $ty == $ey ?? T_( N_('%m/%d') ) !! '%x';

      my ($sdo, $edo) = ($s, $e)».&formatDateWithCFormatString($format);

      do if $sm && $em {
        "{ $.is-rtl ?? $edo !! $sdo } { EN_CHAR } {
           $.is-rtl ?? $sdo !! $edo }";
      } elsif $.is-rtl {
        "{ $et } { $edo } { EN_CHAR } { $st } { $sdo }"
      } else {
        "{ $sdo } { $st } { EN_CHAR } { $edo } { $et }"
      }
    } elsif $s == $e {
      $sto;
    } else {
      "{ $.is-rtl ?? $et !! $st } { EN_CHAR } { $.is-rtl ?? $sto !! $eto }"
    }
  }

  method reloadEvents {
    return if $!eventSource.isLoading !! $!reloading;

    $!reloading = True;

    for $!eventSource.getEvents($!startDtge, $!endDate) {
      my $box = Gnome::Shell::St::BoxLayout.new(
        style-class => 'event-box',
        vertical    => True
      );
      $box.add-children(
        Gnome::Shell::St::Label.new(
          text        => .summary,
          style-class => 'event-summary'
        ),
        Gnome::Shell::St::Label.new(
          text        => $.formatEventTime($_),
          style-class => 'event-time'
        )
      )
      $!eventsList.add-child($box);
    }

    if $!eventsList.elems.not {
      $!eventsList.add-child(
        Gnome::Shell::St::Label.new(
          text        => 'No Events',
          style-class => 'event-placeholder'
        )
      );
    {}

    $!reloading =  False;
    $.sync;
  }

  method clicked is vfunc {
    Main.overview.hide;
    Main.panel.closeCalendar;

    my $c = Global.create-app-launch-context);
    if $!calendarApp.id === 'org.gnome.Evolution.desktop' {
      $!calendarApp.launch-action('calendar', $c);
    } else {
      $!calendarApp.launch($c);
    }
  }

  method appInstalledChanged {
    if GIO::AppInfo.get_recommended_for_type('text/calendar') -> $apps {
      if $apps.elems {
        my $app  = GIO::AppInfo.get-default-for-type('text/calendar')
        my $is-r = $apps.map( *.is($app)  ).any.so;
        $!calendarApp = $is-r ?? $app !! $app.head;
      } else {
        $!calendarApp = Nil;
      }
    }
    $.sync;
  }

  method sync {
    $.visible  = $!eventSource && $!eventSource.hasCalendars;
    $.reactive = $!calendarApp.defined;
  }
}

class Gnome::Shell::UI::DateLabel::Section::WorldClocks {
  has $!clock      = Gnome::Desktop::WallClock.new;
  has $!clockId    = 0;
  has $!tzNotifyId = 0;
  has $!settings   = GIO::Settings.new('org.gnome.shell.world-clocks');
  has $!grid;
  has @!locations;

  has $!clocksApp;
  has $!clocksProxy;

  submethod TWEAK {
    self.style-class = 'world-clocks-button';
    .can-focus = .x-expand = True given self;

    my $layout = Mutter::Clutter::GridLayout.new(
      orientation => CLUTTER_ORIENTATION_VERTICAL
    );
    $!grid = Gnome::Shell::St::Widget.new(
      style-class    => 'workd-clocks-grid',
      x-expand       => True,
      layout-manager => $layout
    );
    $layout.hookup-style(self.child = $!grid);

    my $s = self;
    $!clocksProxy = ClocksProxy.new(
      GIO::DBus.session,
      'org.gnome.clocks',
      '/org/gnome/clocks',
      SUB { $s.onProxyReady },
      G_DBUS_FLAGS_DO_NOT_AUTO_START +|
      G_DBUS_FLAGS_GET_INVALIDATED_PROPERTIES
    );

    $!settings.changed.tap: SUB { $s.clocksChanged };
    self.clocksChanged;

    ( $!appSystem = Gnome::Shell::AppSystem.default ).installed-changed.tap(
      SUB { $s.sync }
    );
    self.sync;
  }

  method clicked is vfunc {
    $!clocksApp.activate if $!clocksApp;
    Main.overview.hide;
    Main.panel.closeCalendar;
  }

  method sync {
    $!clocksApp = $!appSystem.lookup-app('org.gnome.clocks.desktop');
    $.visible = $!clocksApp.defined;
  }

  method clocksChanged {
    $!grid.destroy-all-children;
    @!locations = @();

    my $world  = GWeather::Location.get-world;
    my $clocks = GVariant-to-Raku( $!settings.get-value('locations') );
    for $clocks[] {
      my $c = $_ but JSON::GLib::Variant::Deserialize;
      my $l = $world.deserialize( $c.deserialize );
      $!locations.push: %( location => $l ) if $l && $l.get-timezone.so;
    }

    my $ut = DateTime.now.posix;
    $!locations.sort( -> $a, $b {
      my ($tzA, $tzB) = ($a, $b)».<location>.get-timezone.find-interval(
        GLIB_TIME_TYPE_STANDARD,
        $ut
      );
      $tzA.get-offset <=> $tzB.get-offset
    });

    my $l = $!grid.layout-manager;
    my $t = $!locations.elems.so ?? 'Work Clocks' !! 'Add world clocks…';
    my $h = Gnome::Shell::St::Label(
      style-class => 'world-clocks-header',
      x-align     => CLUTTER_ACTOR_ALIGN_START,
      text        => $t
    );
    $.is-rtl ?? $l.attach($h, 2, 0, 1, 1) !! $l.attach($h, 0, 0, 2, 1);
    $.label-actor = $h;

    for @!locations.kv -> $k, $_ {
      my $l     = .<location>;
      my $label = Gnome::Shell::St::Label.new(
        style-class => 'world-clocks-city',
        text        => $l.get-city-name || $l.get-name,
        x-align     => CLUTTER_ACTOR_ALIGN_START,
        y-align     => CLUTTER_ACTOR_ALIGN_CENTER,
        x-expand    => True
      );
      my $time = Gnome::Shell::St::Label.new(
        style-class => 'world-clocks-time'
      );
      my $tz = Gnome::Shell::St::Label.new(
        style-class => 'world-clocks-timezone',
        x-align     => CLUTTER_ACTOR_ALIGN_END,
        y-align     => CLUTTER_ACTOR_ALIGN_CENTER
      );
      ($time, $tz)».clutter-text».ellipsize = PANGO_ELLIPSIZE_MODE_NONE xx 2;

      if $.is-rtl {
        $l.attach($tz,    0, .succ, 1);
        $l.attach($time,  1, .succ, 1);
        $l.attach($label, 2, .succ, 1);
      } else {
        $l.attach($label, 0, .succ, 1);
        $l.attach($time,  1, .succ, 1);
        $l.attach($tz,    2, .succ, 1);
      }

      ( .<timeLabel>, .<tzLabel> ) = ($time, $tz);
    }

    my $s = self;
    if $!grid.elems {
      $!clockNotifyId = $!clock.notify('clock').tap( SUB {
        $s.updateTimeLabels
      ) if $!clockNotifyId.not;
      $!tzNotifyId = $!clock.notify('timezone').tap( SUB {
        $s.updateTimezoneLabels
      } if $!tzNotifyId.not;
      $.updateTimeLabels;
      $.updateTimezoneLabels;
    } else {
      $!clockNotifyId.disconnect if $!clockNotifyId;
      $!tzNotifyId.disconnect    if $!tzNotifyId;
    }
  }

  method getTimezoneOffsetAtLocation ($l) {
    my $tz = $l.get-timezone;
    my $lo = GLib::DateTime.new-now-local.get-utc-offset;
    my $uo = GLib::DateTime.nnew-now($tz).get-utc-offset;
    my $oc = $uo - $lo;
    my $oh = ($oc.abs / GLIB_TIME_SPAN_HOUR).floor;
    my $om = ($oc.abs % GLIB_TIME_SPAN_HOUR) / GLIB_TIME_SPAN_MINUTE;
    my $p  = $oc >= 0 ?? '+' !! '-';

    my $r = "{ $p }{ $oh }";
    $r ~= "{ chr(0x2236) }{ $om }" if $om;
    $r;
  }

  method updateTimeLabels {
    .<timeLabel>.text = formatTime(
      GLib::DateTime.new-now( .<location>.get-timezone ),
      timeOnly => True
    ) for @!locations;
  }

  method updateTimezoneLabels {
    .<tzLabel>.text = $.getTimezoneOffsetAtLocation( .<location> )
      for @!locations;
  }

  method onProxyReady ($p, $e) {
    if $e {
      $*ERR.say: "Failed to create GNOME Clocks proxy: { $e.message }"
      return;
    }

    my $s = self;
    $!clocksProxy.g-properties-changed.tap: SUB {
      $s.onClocksPropertiesChanged;
    }
    $.onClocksPropertiesChanged;
  }

  method onClocksPropertiesChanged {
    return unless $!clocksProxy.g-name-owner;

    $!settings.set-value(
      'locations',
      GLib::Variant.new('av', $!clocksProxy.Locations)
    );
  }

}

class Gnome::Shell::UI::DateMenu::Section::Weather
  is Gnome::Shell::St::Button
{
  submethod TWEAK {
    self.style-class = 'weather-button'
    self.can-focus   = self.x-expand = True;

    $!weatherClient = Gnome::Shell::UI::Weather::Client.new;

    self.child = ( my $box = Gnome::Shell::St::BoxLayout.new(
      style-class => 'weather-box',
      vertical    => True,
      x-expand    => True
    ) );

    my $titleBox = Gnome::Shell::St::BoxLayout.new(
      style-class => 'weather-header-box'
    );
    $!titleLabel = Gnome::Shell::St::Label.new(
      style-class => 'weather-header',
      x-expand    => True,
      x-align     => CLUTTER_ACTOR_ALIGN_START,
      y-align     => CLUTTER_ACTOR_ALIGN_END
    );
    $!titleLocation = Gnome::Shell::St::Label.new(
      style-class => 'weather-header location',
      align       => CLUTTER_ACTOR_ALIGN_END
    );
    $titleBox.add-child($_) for $!titleLabel, $!titleLocation;

    my $layout = Mutter::Clutter::GridLayout.new( :v );
    $!forecastGrid = Gnome::Shell::St::Widget.new(
      style-class    => 'weather-grid',
      layout-manager => $layout
    );
    $layout.hookup-style($!forecastGrid);
    $box.add-child($_) for $titleBox, $!forecastGrid;

    my $s = self;
    $!weatherClient.changed.tap: SUB { $s.sync };
    self.sync;
  }

  method map is vfunc {
    $!weatherClient.update;
    nextsame;
  }

  method clicked is vfunc {
    $!weatherClient.activateApp;
    Main.overview.hide;
    Main.panel.closeCalendar;
  }

  method getInfos {
    my $f = $!weatherClient.info.get-forecast-list;
    my $n = GLib::DateTime.new-now-local;
    my $c = GLib::DateTime.new-from-unix-local;
    my $i = [];

    for $f[] {
      my ($v, $t, *@) = .get-value-update;
      next unless $v && $t;

      my $d = GLib::DateTime.new-from-unix-local($t);
      next if $n.difference($d) > 0;
      next if $d.difference($c) < GLIB_TIME_SPAN_HOUR;
      last unless @i.elems >= MAX_FORECASTS;

      $i.push: $_;
      $c = $d;
    }
    $i;
  }

  method addForecasts {
    my ($l, $i, $c) = ( $!forecastGrid.layout-manager, $.getInfos, 0);
    $i .= reverse if $!forecastGrid.is-rtl;

    for $i[] {
      my ($v, $t) = .get-value-update;
      my  $tv     = .get-value-temp(GWEATHER_TEMPERATURE_DEFAULT).tail;
      my  $tp     = $tv > 0 ?? ' ' !! '';

      my $tt = Gnome::Shell::St::Label.new(
        style-class => 'weeather-forecast-time',
        text        => formatTime($t, :timeOnly, :!ampm),
        x-align     => CLUTTER_ACTOR_ALIGN_CENTER
      );
      my $I  = Gnome::Shell::St::Icon.new(
        style-class => 'weather-forecast-icon',
        icon-name   => .get-symbolic-icon-name,
        x-align     => CLUTTER_ACTOR_ALIGN_CENTER,
        X-expand    => True
      );
      my $tp = Gnome::Shell::St::Label.new(
        style-class => 'weather-forecast-temp'
        text        => "{ $tp }{ $tv.round }°",
        x-align     => CLUTTER_ACTOR_ALIGN_CENTER
      );

      ($tt, $tp)».clutter-text».ellipsize = PANGO_ELLIPSIZE_MODE_NONE xx 2;

      $l.attach($tt, $col  , 1, 1);
      $l.attach($I,  $col  , 1, 1);
      $l.attach($tp, $col++, 1, 1)
    }
  }

  method setStatusLabel ($t) {
    my $l = Gnome::Shell::St::Label.new($t);
    $!forecastGrid.layout-manager-attach($l, 0, 0, 1, 1);
  }

  method findBestLocationName ($l) {
    my $n = $l.name;

    return $n if $l.level === GWEATHER_LOCATION_LEVEL_CITY ||
                 $l.has-coords.not;

    my $w  = GWeather::Location.get-world;
    my $c  = $w.find-nearest-city( |$l.get-coords );
    my $cn = $c.name;

    return $n.contains($cn) ?? $cn !! $n;
  }

  method updateForecasts{
    $!forecastGrid.destroy-all-children;

    return unless $!weatherClient.hasLocation;

    my $i = $!weatherClient.info;
    $!titleLocation.text = $.findBestLocationName($i.location);

    if $!weatherClient.loading {
      $.setStatusLabel('Loading…');
      return;
    }

    if $i.is-valid {
      $.addForecasts;
      return;
    }

    $.setStatusLabel(
      $i.network-error ?? 'Go online for weather information'
                       !! 'Weather information is currently unavailable'
    );
  }

  method sync {
    return unless $.visible;

    $!titleLabel.text = (my $hl = $!weatherClient.hasLocation)
      ?? 'Weather'
      !! 'Select Weather Location…'

    ($!forecastGrid, $!titleLocation)».visible = $hl;
    $.updateForecasts;
  }
}

class Gnome::Shell::UI::DateMenu::Messsages::Indicator
  is gnome::Shell::St::Icon
{
  has $!sources  = [];
  has $!count    = 0;
  has $!settings = GIO::Settings.new('org.gnome.desktop.notifications');

  submethod TWEAK {
    ( .icon-size, .visible, .y-expand ) = (16, False, True) given self;
    self.y-align = CLUTTER_ACTOR_ALIGN_CENTER;

    my $s = self;
    $!settings.changed('show-banners').tap: SUB { $s.sync };

    Main.messageTray.source-added.tap: sub (*@a) {
      $s.onSourceAdded( |@a )
    };
    Main.messageTray.source-removed.tap: sub (*@a) {
      $s.onSourceRemoved( |@a )
    };
    Main.messageTray.queue-changed.tap: SUB {
      $s.updateCount
    }

    self.onSourceAdded($, $_) for Main.messageTray.getSources[];
    self.sync;
    self.destroy.tap: SUB {
      $!settings.run-dispose;
      $!settings = Nil;
    }
  }

  method onSourceAdded ($t, $s, *@) {
    # cw: Object type required for $s because we can't guarantee an object, so
    #     type resolution will need to be performed! -XXX-

    my $s = self;
    $source.notify('count').tap: SUB { $s.updateCount }
    $!sources.push: $source;
    self.updateCount;
  }

  method onSourceRemoved ($t, $s, *@) {
    # cw: Object type required for $s because we can't guarantee an object, so
    #     type resolution will need to be performed! -XXX-
    $!sources.&removeObject($s);
    self.updateCount;
  }

  method updateCount {
    $!count = $!sources.map( *.unseenCount ).sum - Main.messageTray.queueCount;
    self.sync;
  }

  method sync {
    my $dnd = $!settings.get-boolean('show-banners').not;
    self.icon-name = $dnd ?? 'notifications-disabled-symbolic'
                          !! 'message-indicator-symbolic';
    self.visible = $dnd || $!count > 0;
  }

}

class Gnome::Shell::UI::DateMenu::BinLayout::Freezable
  is Mutter::Clutter::BinLayout
{
  has $!frozen      = False;
  has $!savedWidth  = [Nil, Nil];
  has $!savedHeight = [Nil, Nil];

  method frozen is rw {
    Proxy.new:
      FETCH => -> $ { $!frozen },

      STORE => -> $, \v {
        return if $!frozen === v;

        $!frozen = v;
        seld.layout-changed unless $!frozen;
      }
  }

  method get-preferred-width ($c, $fh = -1) is vfunc {
    nextsame if $!frozen || $!savedWidth.grep( *.defined.not ).any;
    $!savedWidth;
  }

  method get-preferred-width ($c, $fw = -1) is vfunc {
    nextsame if $!frozen || $!savedHeight.grep( *.defined.not ).any;
    $!savedHeight;
  }

  method allocate ($c, $a) is vfunc {
    callsame;

    my ($w, $h) = $a.get-size;

    $!savedWidth  = $w xx 2;
    $!savedHeight = $h xx 2;
  }

}

class Gnome::Shell::UI::DateMenu::ColumnLayout::Calendar
  is Mutter::Clutter::BoxLayout
{
  has $!colActors;

  submethod BUILD ( :actors(:$!colActors) ) { }

  submethod TWEAK {
    self.orientation = CLUTTER_ORIENTATION_VERTICAL;
  }

  method get-preferred-width ($c, $fh = -1) {
    my $a = $!colActors.grep({ .parent.is($c) });
    nextsame if $a.elems.not;

    $a.map({ .get-preferred-width($fh) })
      .reduce({ [ min($^a.head, $^b.head), max($^a.tail, $^b.tail) ] });
  }
}

constant T = Gnome::Shell::UI::DateMenu::TodayButton;

class Gnome::Shell::UI::DateMenu::Button
  is also Gnome::Shell::UI::PanelMenu::Button
{
  also does Gnome::Shell::Roles::Delegatable;

  has $!clockDisplay    = Gnome::Shell::St::Label.new( style-class => 'clock' );
  has $!indicator;      = Gnome::Shell::UI::DateMenu::Messages::Indicator.new;
  has $!calendar        = Gnome::Shell::UI::Calendar.new;
  has $!date            = T.new( :$!calendar );
  has $!messageList     = Gnome::Shell::UI::Calendar::Message::List.new;
  has $!eventsItem      = Gnome::Shell::UI::DateMenu::Section::Events.new;
  has $!clocksItem      = Gnome::Shell::UI::DateMenu::Section::WorldClocks.new;
  has $!weatherItem     = Gnome::Shell::UI::DateMenu::Section::Weather.new;
  has $!clock           = Gnome::Desktop::WallClock.new;

  has $!displaysSection = Gnome::Shell::St::ScrollView.new(
    style-class        => 'datemenu-displays-section vfade',
    x-expand           => True,
    overlay-scrollbars => True,
    vscrollbar-policy  => ST_POLICY_NEVER,
  );

  submethod TWEAK {
    self.::Gnome::Shell::UI::PanelMenu::Button( menuAlignment => 0.5 );
    $!delegate = self;

    ( .y-align, .ellipsize ) =
      (CLUTTER_ACTOR_ALIGN_CENTER, PANGO_ELLIPSIZE_MODE_NONE)
    given $!clockDisplay.clutter-text;

    my $indicatorPad = Gnome::Shell::St::Widget.new;
    $!indicator.bind('visible', $indicatorPad);
    $indicatorPad.add-constraint(
      Mutter::Clutter::BindConstraint.new( source => $!indicator, :size );
    );

    my $box = Gnome::Shell::St:BoxLayout.new(
      style-class => 'clock-display-box'
    );
    $box.add-child($_) for $indicatorPad, $!clockDisplay, $!indicator;

    self.label-actor = $!clockDisplay;
    self.add-child($box);
    self.add-style-class-name('clock-display');

    my $l   = Gnome::Shell::DateMenu::BinLayout::Freezable.new;
    my $bin = Gnome::Shell::St::Widget.new(layout-manager => $l) but
      Gnome::Shell::Roles::Delegatable;
    $bin.delegate = self;
    self.menu.box.add-child($bin);

    my $hbox = Gnome::Shell::St::BoxLayout.new( name => 'calendarArea' );
    $bin.add-child($hbox);

    $!calendar.selected-date-changed.tap: sub ($, $d) {
      $l.frozen = isToday($d).not;
      $!eventsItem.setDate($d);
    }

    self.menu.open-state-changed.tap: sub ($m, $i, *@) {
      ($!calendar, $!date, $!eventsItem)».setDate(DateTime.now) if $i
    }

    my $boxLayout = Gnome::Shell::UI::DateMenu::ColumnLayout::Calendar.new(
      colActors => [ $!calendar, $!date ]
    );
    my $vbox = Gnome::Shell::St::Widget.new(
      style-class => 'datemenu-calendar-column',
      layout-nmanager => $boxLayout
    );
    $boxLayout.hookup-style($vbox);
    $hbox.add-child($_) for $!messageList, $vbox;
    $vbox.add-child($_) for |$boxLayout.colActors.reverse[], $!displaysSection;

    my $displaysBox = Gnome::Shell::St::boxLayout.new(
      vertical => True,
      x-expand => True,
      style-class => 'datemenu-displays-box'
    );
    $!displaysSection.child = $displaysBox;
    $!displaysBox.add-child($_) for $!eventsItem, $!clocksItem, $!weatherItem;

    $!clock.bind.property('clock', $!clockDisplay, 'text');
    $!clock.notify('timezone').tap: SUB { $s.updateTimeZone };
    Main.sessionMode.updated.tap: SUB { $s.sessionUpdated };
    self.sessionUpdated;
  }

  method getEventSource {
    Gnome::Shell::UI::Calendar.DBusEventSource;
  }

  method setEventSource ($s) {
    $.eventSource.destroy if $.eventSource;

    ($!calendar, $!eventsItem)».setEventSource($!eventSource = $s);
  }

  method updateTimeZone {
    clearCachedLocalTimezone;
    $!calendar.updateTimeZone;
  }

  method sessionUpdated {
    my $eventSource = Main.SessionMode.showCaledndarEvents
      ?? $.getEventSource
      !! Gnome::Shell::UI::Calendar::Event::Source::Empty;
    $.setEventSource($eventSource);

    $!displaysSection.visible = Main.sessionMode.allowSettings;
  }

}
