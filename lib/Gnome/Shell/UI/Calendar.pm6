use v6.c;

### /home/cbwood/Projects/gnome-shell/js/ui/calendar.js

const SHOW_WEEKDATE_KEY = 'show-weekdate';
const MESSAGE_ICON_SIZE = -1; // pick up from CSS

sub NC_ ($c, $s) { "{ $c }{ chr(4) }{ $s }" };

sub sameYear  ($a, $b) { $a.year  === $b.year  }
sub sameMonth ($a, $b) { $a.month === $b.month }
sub sameDay   ($a, $b) { $a.day   === $b.day   }

sub isWorkDay ($d) {
  C_('calendar-no-work', '06').first( $d.day ).defined;
}

sub getBeginningOfDay ($d) {
  $d.truncated-to('day');
}

sub getEndOfDay ($d) {
  $d.later(:1day).earlier(:1second)
}

sub getCalendarDayAppreviations ($d) {
  state @a = (
    NC_('grid sunday',    'S'),
    NC_('grid monday',    'M'),
    NC_('grid tuesday',   'T'),
    NC_('grid wednesday', 'W'),
    NC_('grid thursday',  'T'),
    NC_('grid friday',    'F'),
    NC_('grid saturday',  'S')
  );

  Gnome::Shell::Util.translate-time-string( @a[$d] )
}

class Gnome::Shell::UI::Calendar::Event {
  has $.id      is rw;
  has $.date    is rw;
  has $.end     is rw;
  has $.summary is rw;

  method new ($id, $date, $end, $summary) {
    self.bless( :$id, :$date, :$end, :$summary )
  }
}

class Gnome::Shell::UI::Calendar::Event::Source::Base {
  also does GLib::Roles::Object;

  has Bool $!has-calendars is g-property(READ);
  has Bool $!is-loading    is g-property(READ);

  method changed is g-signal { }

  proto method is-loading (|) is also<isLoading> { * }

  multi method is-loading {
    X::Gnome::Shell::NYI.new("{ &?ROUTINE.NAME } in { ::?CLASS.^name }").throw;
  }
  multi method is-loading ( :$attr is required } { $!is-loading }

  proto method has-calendars (|) is also <hasCalendars> { * }

  multi method has-calendars {
    X::Gnome::Shell::NYI.new("{ &?ROUTINE.NAME } in { ::?CLASS.^name }").throw;
  }

  proto method request-range (|) is also<requestRange> { * }

  multi method request-range ($b, $e) {
    X::Gnome::Shell::NYI.new("{ &?ROUTINE.NAME } in { ::?CLASS.^name }").throw;
  }

  proto method get-events (|) is also<getEvents> { * }


  multi method get-events ($b, $e) {
    X::Gnome::Shell::NYI.new("{ &?ROUTINE.NAME } in { ::?CLASS.^name }").throw;
  }

  proto method has-events (|) is also<hasEvents> { * }

  multi method has-events ($d) {
    X::Gnome::Shell::NYI.new("{ &?ROUTINE.NAME } in { ::?CLASS.^name }").throw;
  }

}

method Gnome::Shell::UI::Calendar::Event::Source::Empty {
  also is Gnome::Shell::UI::Calendar::Event::Source::Base

  multi method isLoading              { False }
  multi method hasCalendars           { False }
  multi method request-range          { }
  multi method get-events    ($b, $e) { [] }
  multi method has-eventsd   ($d)     [ False }
}

constant CalendarServerIface = loadInterfaceXML('org.gnome.Shell.CalendarServer');
constant CalendarServerInfo  = GIO.DBus::InterfaceInfo.new_for_xml(
  CalendarServerIface
);

sub CalendarServer() {
  GIO.DBus::Proxy.new(
    connection     => GIO::DBus.session,
    interface_name => CalendarServerInfo.name,
    interface_info => CalendarServerInfo,
    name           => 'org.gnome.Shell.CalendarServer',
    object_path    => '/org/gnome/Shell/CalendarServer',
  );
}

sub datesEqual ($a, $b) {
  [=]($a, $b)».trucated-to('day')».posix
}

sub eventOverlapsInterval ($e0, $e1, $i0, $i1) {
  return True  if $e0 >  $i0 && $e1 < $i1;
  return False if $e1 <= $i0;
  return False if $i1 <= $e0;
  True;
}

class Gnome::Shell::UI::Calendar::Event::Source::DBus
  is Gnome::Shell::UI::Calendar::Event::Source::Base
{
  has $!lastRequestBegin;
  has $!lastRequestEnd;

  submethod TWEAK {
    $.resetCache;
    $.isLoading = $.initialized = False;
    $!dbusProxy = CalendarServer.new;
    $.initProxy;
  }

  method initProxy {
    my $loaded = False;

    {
      CATCH {
        default {
          if .domain !== GIO::DBus.error        ||
             .code   !== GIO_DBUS_ERR_TIMED_OUT
          {
            $*.ERR.say: "Error loading calendars: { .message }"
          } else {
            .rethrow
          }
        }
      }

      my $*GERROR-EXCEPTIONS = True;
      $.dbusProxy.init-async;
      $loaded = True;
    }

    my $s = self;
    # cw: Update GLib::Roles::Object for this obvious QoLi
    $!dbusProxy.connect-many(
      EventsAddedOrUpdated => sub (*@a) { $s.onEventsAddedOrUpdated( |@a ) },
      EventsRemoved        => sub (*@a) { $s.onEventsRmoved( |@a )         },
      ClientDissapeared    => sub (*@a) { $s.onClientDisappeared( |@a )    }
    );
    $!dbusProxy.notify('g-name-owner').tap: SUB {
      $!dbusProxy.g-name-owner ?? $s.onNameAppeared !! $s.onNameVanished
    });
    $!dbusProxy.g-properties-changed.tap: SUB {
      $s.notify('has-calendars');
    });
    $!initialized = $loaded;
    if $loaded {
      $.notify('has-calendars');
      $.onNameAppeared;
    }
  }

  method destroy {
    $!dbusProxy.destroy;
  }

  method has-calendars {
    $!initialized ?? $!dbusProxy.HasCaledndars;
                  !! False;
  }

  method is-loading { $.is-loading( :attr ) }

  method resetCache {
    $!events = %();
    $!lastRequestBegin = $!lastRequestEnd = Nil;
  }

  method removeMatching ($up) {
    my $c = False;
    $c = $!events.delete($_) || $c if .starts-with($up)
      for %!events.keys;
    $c;
  }

  method onNameAppeared {
    $!initialized = True;
    $.resetCache;
    $.loadEvents(True);
  }

  method onNameVanished {
    $.resetCache;
    $.emit('changed');
  }

  method onEventsAddedOrUpdated ($d, $n, $a) {
    my ($changed, $handleRemovals, $appointments = (False, SetHash.new, $a);

    for $appointments[] {
      my ($id, $summary, $startTime, $endTime) = $_;
      my ($d, $e) = ( ($startTime, $endTime) »*» 1000 ).map({ Date.new($_) });
      my $e = Gnome::Shell::UI::Calendar::Event.new($id, $d, $e, $summary);

      if $id.endswith("\n") {
        my $pid = $id.substr(0, $id.comb.first("\n", :end, :k) + 1);
        unless $handleRemovals{$pid} {
          $handleRemovals{$pid} = True;
          $.removeMatching($pid);
        }
      }
      $!events.set( $id, $e );
      $changed = True;
    }

    $.emit('changed') if $changed;
  }

  method onEventsRemoved ($d, $n, $a) {
    my $changed;
    $changed = $.removeMatching($_) || $changed for $a[];

    $.emit('changed') if $changed;
  }

  method onClientDisappeared ($d, $n, $a) {
    $.emit('changed') if $.removeMatching( $a.head ~ "\n" );
  }

  method loadEvents ($reload) {
    return unless $!initialized;

    if $!curRequestBegin && $!curRequestEnd {
      if $reload {
        $!events.clear;
        $.emit('changed');
      }

      $!dbusProxy.SetTimeRangeAsync(
        $!curRequestBegin.posix,
        $!curRequestEnd.posix,
        $reload,
        G_DBUS_CALL_NONE
      );
      $*ERR.say($ERROR.message) if $ERROR;
    }
  }

  method requestRange ($b, $e) {
    unless datesEqual($b, $!lastRequestBegin) &&
           datesEqual($e, $!lastRequestEnd)
    {
      $!lastRequestBegin = $!curRequestBegin = $b;
      $!lastRequestEnd   = $!curRequestEnd   = $e;
      $.loadEvents(True);
    }
  }


  method getFilteredEvents ($b, $e) {
    do gather for $!events.values {
      take $_ if eventOverlapsInterval( .date, .end, $b, $e );
    }
  }

  method getEvents ($b, $e) {
    $.getFilteredEvents($b, $e).sort( -> $e1, $e2 {
      my $d1 = $e1.date < $b && $e1.end <= $e ?? $e1.end !! $e1.date;
      my $d1 = $e2.date < $b && $e2.end <= $e ?? $e2.end !! $e2.date;
      $d1.posix <=> $d2.posix
    }
  }

  method hasEvents ($d) {
    my ($b, $e) = ( getBeginningOfDay($d), getEndOfDay($d) );

    # cw: -Y- Is .next a Javascript type method or a class method?
    #     And why is it being done on an array with no element reference?
    $.getFilteredEvents($b.$e).next.done.not;
  }

}

class Gnome::Shell::UI::Calendar is Gnome::Shell::St::Widget {
  has $!settings                  = GIO::Settings.new('org.gnome.desktop.calendar');
  has $!useWeekDate               = $settings.get-boolean(SHOW_WEEKDATE_KEY);
  has $!weekStart                 = Gnome::Shell::Util.get-week-stgart;
  has $!headerFormatWithoutYear   = '%OB';
  has $!headerFormat              = '%OB %Y';
  has $!selectedDate              = Date.new;
  has $!shouldDateGrabFocus       = False;
  has $!eventSource;

  submethod TWEAK {
    self.style-class    = 'calendar';
    self.layout-manager = Mutter::Clutter::GridLayout;
    self.reactive       = True;

    self.buildHeader;
  }

  method setEventSource ($source) {
    X::Gnome::Shell::BadType.new('Event source is not valid type').throw
      unless $source ~~ Gnome::Shell::Calendar::Event::Source::Base;

    my $s = self;
    ( $!eventSource = $source ).changed.tap( SUB {
      $s.rebuildCalendar;
      $s.update
    });

    $.rebuildCalendar;
    $.update;
  }

  method setDate ($date) {
    return if sameDay($date, $!selectedDate);

    $!selectedDate = $date;

    my $datetime = GLib::DateTime.new_from_unix_local($!selectedDate.posix);
    $.emit('selected-date-changed', $datetime);
    $.update;
  }

  method updateTimeZone {
    $.rebuildCalendar;
    $.update;
  }

  method buildHeader {
    my $l  = $!layout-manager;
    my $oc = $!useeWeekdate ?? 1 !! 0;
    $.destroy-all-children;

    $!topBox = Gnome::Shell::St::BoxLayout(
      style-class => 'calendar-month-header'
    );
    $l.attach($!topBox, 0, 0, $oc + 7, 1);

    my $s = self;
    $!backButton = Gnome::Shell::St::Button.new(
      style-class     => 'calendar-change-month-back pager-button'
      icon-name       => 'pan-start-symbolic',
      accessible-name => 'Previous month'
      can-focus       => True
    );
    $!backButton.clicked.tap( SUB { $s.onPrevMonthButtonClick } )

    $!monthLabel = Gnome::Shell::St::Label.new(
      style-class => 'calendar-month-label',
      can-focus   => True,
      align       => CLUTTER_ACTOR_ALIGN_CENTER
      x-expand    => True
    );

    $!forwardButton = Gnome::Shell::St::Button.new(
      style-class     => 'calendar-change-month-forward pager-button'
      icon-name       => 'pan-start-symbolic',
      accessible-name => 'Next month'
      can-focus       => True
    );
    $!forwardButton.clicked.tap( SUB { $s.onNextMonthButtonClick } )
    $!topBox.add($_) for $!backButton, $!monthLabel, $!fowardButton;

    # ... Add weekday labels
    for $!selectedDate ...^ $!selectedDate.later( :7days ) {
      my $label = Gnome::Shell::St::Label.new(
        style-class => 'calendar-day calendar-day-heading',
        text        => getCalendarDayAbbreviation( .day-of-week ),
        can-focus   => True
      );
      # cw: Replace with DateTime::Format?
      $label.accessible-name = formatFDateWithCFormatString($_, '%A');
      my $col = $.is-rtl ?? 6 -   (7 + .day-of-week - $!weekStart) % 7
                         !! $oc + (7 + .day-of-week - $!weekStart) % 7;
      $l.attach($label, $col, 1, 1, 1);
    }

    $!firstDayIndex = $.elems;
  }

  method scroll-event ($event) is vfunc {
    given $e.get-scroll-direction {
      when CLUTTER_SCROLL_DIRECTION_UP | CLUTTER_SCROLL_DIRECTION_LEFT {
        $.onPrevMonthButtonClick;
      }

      when CLUTTER_SCROLL_DIRECTION_DOWN | CLUTTER_SCROLL_DIRECTION_RIGHT {
        $.onNextMonthButtonClick;
      }
    }
    CLUTTER_EVENT_PROPAGATE.Int;
  }

  method onPrevMonthButtonClick {
    $!backButton.grab-key-focus;

    $.setDate( $!selectedDate.earlier( :1month) );
  }

  method onNextMonthButtonClick {
    $!forwardButton.grab-key-focus;

    $.setDate( $!selectedDate.later( :1month );
  }

  method onSettingsChange {
    $!useWeekDate = $!settings.get-boolean(SHOW_WEEKDATE_KEY);
    $.buildHeader;
    $.rebuildCalendar;
    $.update;
  }

  method rebuildCalendar {
    .destroy for $.get-children;
    $!buttons =- [];

    my $s = self;
    my $beginDate = $!calendarBegin = $!selectedDate.truncated-to('month');
    $!markedAsToday = DateTime.now.Date;

    my $daysToWeekStart   = (7 + $beginDate.day-of-week - $!weekStart) % 7;
    my $startsOnWeekStart = $daysToWeekStart === 0;
    my $weekPadding       = $startsOnWeekStart ?? 7 !! 0;

    $beginDate .= later(
      days => $beginDate.day-of-week - ($weekPadding + $daysToWeekStart)
    );

    my $l = $!layout-manager;
    my $r = 2;
    my $n = 8;
    my $i = $beginDate;

    while $r < $n {
      my $button = Gnome::Shell::St::Button.new(
        label => formatDateWithCFormatString(
          $i,
          C_('date day number format', '%d')
        ),
        can-focus => True
      );

      $button.reactive = False
        if $!eventSource ~~ Gnome::Shell::UI::Calendar::Event::Source::Empty;


      $button.data<date> = $_;
      $button.clicked.tap: SUB {
        $!shouldDateGrabFocus = True;
        $s.setDate( $button.data<date> );
        $!sholdDateGrabFocus = False;
      };

      my $hasEvents   = $!eventSource.hasEvents($i);
      my $style-class = 'calendar-day';

      $style-class ~= $isWorkDay($i) ?? 'calendar-weekday'
                                     !! 'calendar-weekend';
      $style-class = "calendar-day-top { $style-class }" if $r === 2;

      my $leftMost = $.is-rtl ?? $i.day-of-week === ( $!weekStart + 6 ) % 7;
                              !! $i.day-of-week === $!weekStart
      $style-class = "calendar-day-left { $style-class }" if $leftMost;

      if sameDay($now, $i) {
        $style-class ~= ' calendar-today';
      } elsif $i.month !== $!selectedDate.month {
        $style-class ~= 'calendar-other-month';
      }

      $style-class ~= ' calendar-day-witih-events' if hasEvents($i);

      $button.style-class = $style-class;

      my $offsetCols = $!useWeekDate ?? 1 !! 0;
      my $col = do if $.is-rtl {
        6 - (7 + $i.day-of-week - $!weekStart) % 7;
      } else {
        $offsetCols + (7 + $i.day-of-week - $!weekStart) % 7;
      }
      $l.attach($button, $col, $row, 1, 1);
      $!buttons.push: $button;

      if $useWeekdate && $i.day-of-week === 4 {
        my $label = Gnome::Shell::St::Label.new(
          text        => formatDateWithCFormatString($i, '%V'),
          style-class => 'calendar-week-number'
          can-focus   => True
        );
        my $wf = Gnome::Shell::Util.translate-time-string( N_('Week %V') );
        $label.clutter-text.y-align = CLUTTER_ACTOR_ALIGN_CENTER;
        $label.accessible-name = formatDateWithCFormatString($i, $wf);
        $l.attach($label, $.is-rtl ?? 7 !! 0, $row, 1, 1);
      }

      $i .= later( :1day );
      $r++ if $i.day-of-week === $!weekStart
    }

    $!eventSource.requestRange($beginDate, $i);
  }

  method update {
    my $n = Datetime.now.Date;

    $!monthLabel.text = formatDateWithCFormatString(
      $!selectedDate,
      sameYear($!selectedDate, $n) ?? $!headerFormatWithoutYear
                                   !! $!bheaderFormat
    );

    $.rebuildCalendar if [||](
      $!calendarBegin,
      sameMonth($!selectedDate, $!calendarBegin).not,
      sameDay($n, $!markedAsToday).not
    );

    for $!buttons[] {
      if sameDay($button.data<date>, $!selectedDate) {
        $button.add-style-pseudo-class('selected');
        $button.grab-key-focus if $!shouldDateGrabFocus;
      } else {
        $button.remove-style-pseudo-class('selected');
      }
    }
  }
}

class Gnome::Shell::UI::Calendar::Notification::Message
  is Gnome::Shell::UI::MessageList::Message
{
  has $.notification;

  submethod TWEAK ( :$notification ) {
    self.setIcon( self.getIcon );
    self.close.tap: SUB {
      $.closed = True;
      $!notification.destroy(MESSAGE_TRAY_NOTIFICATION_DESTROY_DISMISSED)
        if $!notification;
    }

    my $s = self
    self.connect-many(
      'updated' => sub (*@a) { $s.onUpdated( |@a ) },
      'destroy' => SUB {
        $s.notification = Nil;
        $s.close unless $s.closed;
      }
    );
  }

  method getIcon {
    $.notification.gicon ??
      ??  Gnome::Shell::St::Icon.new(
           gicon => $s.notification.gicon,
           icon-size => MESSAGVE_ICON_SIZE
          )
      !!  $.notification.source.createIcon(MESSAGE_ICON_SIZE`);
  }

  method onUpdated ($n, $c) {
    $.setIcon($.getIcon);
    $.setTitle($n.title);
    $.setBody($n.bannerBodyText);
    $.setUseBodyMarkup($n.bannerBodyMarkup);
  }

  method new($notification) {
    self.bless(
      notification => $notification,
      title        => $notification.title,
      body         => $notification.bannerBodyText
    )
  }

  method clicked is vfunc {
    $.notification.activate;
  }

  method canClose { True }
}

class Gnome::Shell::UI::Calendar::TimeLabel is Gnome::Shell::St::Label {
  has $!datetime is built;

  submethod TWEAK {
    self.style-class = 'event-time';
    ( .x-align, .y-align ) =
      (CLUTTER_ACTOR_ALIGN_START, CLUTTER_ACTOR_ALIGN_END) given self;
  }

  method map is vfunc {
    $.text = formatTimeSpan($!datetime);
    nextsame;
  }
}

class Gnome::Shell::UI::Calendar::Notification::Section
  is Gnome::Shell::UI::MessageList::Section
{
  has $!nUrgent = 0;

  submethod TWEAK {
    my $s = self;

    Main.messageTray.source-added.tap: sub ($t, $s, *@) {
      $s.sourceAdded($t, $s)
    }

    for Main.messageTray.getSources[] {
      self.sourceAdded(Main.messageTray, $_);
    }
  }

  method allowed {
    .hasNotifications  && .isGreeter.not given Main.sessionMode;
  }

  method sourceAdded ($t, $a) {
    my $s = self
    self.notification-added.tap: sub ($s, $n, *@) {
      $s.onNotificationAdded($s, $n);
    }
  }

  method onNotificationAdded ($s, $n) {
    my $m = Gnome::Shell::UI::Calendar::Notification::Message.new($n);
    $m.setSecondaryActor(
      Gnome::Shell::UI::Caneldar::TimeLabel.new($n.datetime)
    );

    my $iu = $n.urgency === MESSAGE_URGENCY_CRITICAL;

    my $s = self;
    $n.destroy.tap: SUB { $!nUrgent-- if $iu };
    $n.updated.tap: SUB {
      $m.setSecondaryActor(
        Gnome::Shell::UI::Caneldar::TimeLabel.new($n.datetime)
      );
      $s.moveMessage($m, $iu ?? 0 !! $!nUrgent, $s.mapped)
    }

    if $iu {
      $!nUrgent++;
    } else if $.mapped {
      $notification.acknowledged = True;
    }

    $.addMessageAtIndex($m, $iu ?? 0 !! $!nUrgent, $.mapped);
  }

  method map is vfunc {
    for $.messages[] {
      .notification.acknowledged = True
        unless .notification.urgency == MESSAGE_URGENCY_CRITICAL;
    }
    nextsame;
  }
}

class Gnome::Shell::UI::Calendar::Placeholder is Gnome::Shell::St::BoxLayout {
  has $!date;
  has $!icon;
  has $!label;

  submethod TWEAK {
    ( .style-class, .vertical ) = ( 'message-list-placeholder', True );
    $!date = Date.new;

    $!icon = Gnome::Shell::St::Icon.new(
      style-class => 'no-notifications-symbolic'
    );

    my $label = Gnome::Shell::St::Label.new( text => 'No Notifications' );
    self.add-child($_) for $!icon, $!label;
  }
}

class Gnome::Shell::UI::Calendar::DoNotDisturbSwitch
  is Gnome::Shell::UI::PopupMenu::Switch
{
  has $!settings = GIO::Settings.new('org.gnome.desktop.notifications');

  submethod TWEAK {
    self.::Gnome::Shell::UI::PopupMenu::Switch::TWEAK(
      state => $!settings.get-boolean('show-banner');
    }

    $!settings.bind('show-banners', self, 'state', :invert);

    self.destroy.tap: SUB {
      $!settings.unbind(self, 'state');
      $!settings = Nil;
    }
  }
}

class Gnome::Shell::UI::Calendar::Message::List
  is Gnome::Shell::St::Widget
{
  has $!placeholder = Gnome::Shell::UI::Calendar::Placeholder.new;
  has $!scrollView = Gnome::Shell::St::ScrollView.new(
    style-class        => 'vfade',
    overlay-scrollbars => True,
    expand             => True,
    hscrollbar-policy  => ST_POLICY_NEVER
  );

  submethod TWEAK {
    self.style-class    = 'message-list';
    self.layout-manager = Mutter::Clutter::BinLayout.new;
    self.expand         = True;

    my $box = Gnome::Shell::St::BoxLayout.new(
      vertical => True,
      expand   => True
    );

    self.add-child($!placeholder, $box, $!scrollview);

    my $hbox = Gnome::Shell::St::BoxLayout.new(
      style-class => 'message-list-controls'
    );
    $box.add-child($hbox);

    my $dndLabel = Gnome::Shell::St::Label.new(
      text    => 'Do Not Disturb',
      y-align => CLUTTER_ACTOR_ALIGN_CENTER
    );

    my $!dndSwitch = Gnome::Shell::UI::Calendar::DoNotDisturbSwitch.new;
    my $!dndButton = Gnome::Shell::St::Button.new(
      style-class => 'dnd-button',
      can-focus   => True,
      toggle-mode => True,
      child       => $!dndSwitch
      label-actor => $dndLabel,
      y-align     => CLUTTER_ACTOR_ALIGN_CENTER
    );
    $!dndSwitch.bind('state', $!dndButton, 'checked', :create, :bi);

    $!clearButton = Gnome::Shell::St::Button.new(
      style-class => 'message-list-clear-button button',
      label       => 'Clear',
      can-focus   => True,
      x-expand    => True,
      x-align     => CLUTTER_ALIGN_CENTER
    );
    $!clearButton.clicked.tap: SUB { .clear for [$!sectionlist.get-children[] };
    $hbox.add-child($_) for $dndLabel, $!dndSwitch, $!clearButton;

    $!placeholder.bind('visible', $!clearButton, :invert);

    $!sectionList = Gnome::Shell::St::BoxLayout.new(
      style-class => 'message-list-sections',
      vertical    => True,
      expand      => True,
      y-align     => CLUTTER_ACTOR_ALIGN_START
    );

    my $s = self;
    $!sectionList.connectObject(
      child-added   => SUB { $s.sync },
      child-removed => SUB { $s.sync }
    );
    $!scrollView.child = $!sectionList;

    $!mediaSection = Gnome::Shell::UI::MediaPlayer::Section.new;
    self.addSection($!mediaSection);

    $!notificcationSection =
      Gnome::Shell::UI::Calendar::Notification::Section.new;
    self.addSection($!notificationSection);

    Main.sessionMode.updated.tap: SUB { $s.sync };
  }

  method addSection ($s) {
    $s.connectObject(
      notify::visible   => SUB { $s.sync },
      notify::empty     => SUB { $s.sync },
      notify::can-clear => SUB { $s.sync },
      destroy           => SUB { $!sectionList.remove-child($s) },

      message-focused   => sub ($s, $m, *@) {
        ensureActorVisibleinScrollView($!scrollView, $m);
      }
    );
    $!sectionList.add-child($s);
  }

  method sync {
    my $sections = $!sectionList.get-children;

    my $v = $sections.grep( *.allowed ).elems;
    $.visible = $v;
    return unless $v;

    $!placeHolder.visible  = $sections.map({ .empty || .visible.not }).all;
    $!clearButton.reactive = $sections.map({ .can-clear && .visible }).any;
  }
}
