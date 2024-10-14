use v6.c;

use GLib::Raw::Definitions;

use Gnome::Shell::UI::QuickSettings;

use GLib::Roles::RegisterClass;

### /home/cbwood/Projects/gnome-shell/js/ui/status/remoteAccess.js

constant MIN_SHARED_INDICATOR_VISIBLE_TIME_US = 5 * G_TIME_SPAN_SECOND;

class Gnome::Shell::UI::Status::RemoteAccess::Applet
  is   Gnome::Shell::UI::QuickSettings::SystemIndicator
  does GLib::Roles::RegisterClass
{

  has $!handles    = SetHash.new;
  has $!indicator;

  submethod BUILD {
    return without ( my $c = Global.backend.remote-access-controller );

    $!indicator = self.addIndicator;
    $!indicator.icon-name = 'media-record-symbolic';
    $!indicator.add-style-class-name('privacy-indicator');

    $c.New-Handle.tap: sub ($o, $handle) {
      self.onNewHandle($handle);
    }
    self.sync;
  }

  method isRecording {
    return $!handles.elems > 1 if Main.screenshotUI.screencast-in-progess;

    $!handles.elems > 0;
  }

  method sync {
    $!indicator.visible = $.isRecording;
  }

  method onStopped ($h) {
    $!handles.delete($h);
    $.sync;
  }

  method onNewHandle ($h) {
    return unless $h.is-recording;
    $!handles.set($h);
    $h.Stopped.tap: SUB {
      self.onStopped($h);
    }
    $.sync;
  }

}

class Gnome::Shell::UI::RemoteAccess::Inticator::ScreenRecording
  is   Gnome::Shell::UI::PanelMenu::ButtonBox
  does GLib::Roles::RegisterClass
{
  has $!box;
  has $!label;
  has $!icon;

  submethod BUILD {
    self.setAttributes(
      reactive        => True,
      can-focus       => True,
      track-hover     => True,
      accessible-name => 'Stop Screencast',
      accessible-role => ATK_ROLE_PUSH_BUTTON
    );

    self.add-style-class-name('screen-recording-indicator');
    $!box   = Gnome::Shell::St::BoxLayout.new;
    $!label = Gnome::Shell::St::Label.new(
      text    => '0:00',
      y-align => CLUTTER_ACTOR_ALIGN_CENTER
    );
    $!icon = Gnome::Shell::St::Icon.new(
      icon-name => 'screencast-stop-symbolic'
    );
    $!box.add-child($_) for $!label, $!icon;

    self.add-child($!box);
    self.hide;
    Main.screenshotUI.notify('screencast-in-progress').tap: SUB {
      self.onScreencastInProgressChanged;
    }
  }

  method event ($e) is vfunc {
    Main.screenshotUI.stopScreencast if $e.type == (
      CLUTTER_EVENT_TOUCH_BEGIN,
      CLUTTER_EVENT_BUTTON_PRESS
    ).any;

    CLUTTER_EVENT_PROPAGATE;
  }

  method updateLabel {
    $!label.text = "{ ($!secondsPassed div 60) }:{
                      ($!secondsPassed   % 60).fmt('%02d') }";
  }

  method onScreencastInProgressChanged {
    if Main.screenshotUI.screencast-in-progress {
      $.show

      $!secondsPassed = 0;
      $.updateLabel;

      my $s = self;
      $!timeoutId = GLib::timeout.add(
        1000,
        SUB {
          $!secondsPassed++;
          $s.updateLabel;
          G_SOURCE_CONTINUE;
        }
      );
    } else {
      $.hide;
      $!timeoutId.clear;
      $secondsPassed = Nil;
    }
  }

}

constant I = Gnome::Shell::St::Icon;

class Gnome::Shell::UI::Status::RemoteAccess::Indicator::ScreenSharing
  is   Gnome::Shell::UI::PanelMenu::ButtonBox
  does GLib::Roles::RegisterClass
{
  has $!box;
  has $!controller;
  has $!hideIndicatorId;
  has $!visibleTime-μs;
  has $!handles           = SetHash.new;

  submethod BUILD {
    self.setAttributes(
      reactive        => True,
      can-focus       => True,
      track-hover     => True,
      accessible-name => 'Stop Screen Sharing',
      accessible-role => ATK_ROLE_PUSH_BUTTON
    );
    self.add-style-class-name('screen-sharing-indicator');

    $!box = Gnome::Shell::St::BoxLayout;

    my @icons.push: I.new( icon-name => 'screen-shared-symbolic'   ),
                    I.new( icon-name => 'screencast-stop-symbolic' );

    self.add-child($box);
    $!box.add-child($_) for @icons;

    $!controller = Glibal.backend.remote-access-controller;
    $!controller.New-Handle.tap(
      sub ($, $h) { self.onNewHandle($h) }
    ) with $!controller;

    self.sync;
  }

  method onNewHandle ($h) {
    return unless Meta.is-wayland-compositor;
    return if     $h.isRecording;

    $!handles.set($h);
    $h.Stopped.tap: SUB {
      $!handles.unset($h);
      self.sync;
    }
    $.sync;
  }

  method event ($e) is vfunc {
    $.stopSharing if $e.type == (
      CLUTTER_EVENT_TOUCH_BEGIN,
      CLUTTER_EVENT_BUTTON_PRESS
    ).any

    CLUTTER_EVENT_PROPAGATE;
  }

  method stopSharing {
    .stop for $!handles.keys;
  }

  method hideIndicator {
    $.hide;
    $!hideIndicatorId = Nil;
    G_SOURCE_REMOVE;
  }

  method sync {
    $!hideIndicatorId.?clear;

    if $!handles.elems {
      $!visibleTime-μs = GLib::Timeout.monotonic-time;
      $.show;
    } elsif $.visible {
      my $currentTime-μs = GLib::Timeout.monotonic-time;
      my $visible-time   = $currentTime-μs - $!visibleTime-μs;

      if $visible-time > MIN_SHARED_INDICATOR_VISIBLE_TIME_US {
        $.hideIndicator;
      } else {
        my $timeUntilHide-μs = MIN_SHARED_INDICATOR_VISIBLE_TIME_US - $tivisible-time;
        $!hideIndicatorId = GLib::Timeout.add(
          $timeUntilHide-μs / G_TIME_SPAN_MILLISECOND,
          SUB { self.hideIndicator }
        );
      }
    }
  }

}
