use v6.c;

use Method::Also;
use NativeCall;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset StSettingsAncestry is export of Mu
  where StSettings | GObject;

class Gnome::St::Settings {
  also does GLib::Roles::Object;

  has StSettings $!sts is implementor;

  submethod BUILD ( :$st-settings ) {
    self.setStSettings($st-settings) if $st-settings
  }

  method setStSettings (StSettingsAncestry $_) {
    my $to-parent;

    $!sts = do {
      when StSettings {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StSettings, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::StSettings
    is also<StSettings>
  { $!sts }

  multi method new (StSettingsAncestry $st-settings, :$ref = True) {
    return unless $st-settings;

    my $o = self.bless( :$st-settings );
    $o.ref if $ref;
    $o;
  }
  multi method new {
    self.get
  }

  multi method get
    is also<
      get_default
      get-default
    >
  {
    st_settings_get();
  }

  # Type: boolean
  method enable-animations is rw  is g-property is also<enable_animations> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('enable-animations', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'enable-animations does not allow writing'
      }
    );
  }

  # Type: boolean
  method primary-paste is rw  is g-property is also<primary_paste> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('primary-paste', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'primary-paste does not allow writing'
      }
    );
  }

  # Type: int
  method drag-threshold is rw  is g-property is also<drag_threshold> {
    my $gv = GLib::Value.new( G_TYPE_INT );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('drag-threshold', $gv);
        $gv.int;
      },
      STORE => -> $, Int() $val is copy {
        warn 'drag-threshold does not allow writing'
      }
    );
  }

  # Type: string
  method font-name is rw  is g-property is also<font_name> {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('font-name', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        warn 'font-name does not allow writing'
      }
    );
  }

  # Type: boolean
  method high-contrast is rw  is g-property is also<high_contrast> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('high-contrast', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'high-contrast does not allow writing'
      }
    );
  }

  # Type: string
  method gtk-icon-theme is rw  is g-property is also<gtk_icon_theme> {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('gtk-icon-theme', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        warn 'gtk-icon-theme does not allow writing'
      }
    );
  }

  # Type: boolean
  method magnifier-active is rw  is g-property is also<magnifier_active> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('magnifier-active', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'magnifier-active does not allow writing'
      }
    );
  }

  # Type: double
  method slow-down-factor is rw  is g-property is also<slow_down_factor> {
    my $gv = GLib::Value.new( G_TYPE_DOUBLE );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('slow-down-factor', $gv);
        $gv.double;
      },
      STORE => -> $, Num() $val is copy {
        $gv.double = $val;
        self.prop_set('slow-down-factor', $gv);
      }
    );
  }

  # Type: boolean
  method disable-show-password
    is rw
    is g-property
    is also<disable_show_password>
  {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('disable-show-password', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'disable-show-password does not allow writing'
      }
    );
  }

  method inhibit_animations is also<inhibit-animations> {
    st_settings_inhibit_animations($!sts);
  }

  method uninhibit_animations is also<uninhibit-animations> {
    st_settings_uninhibit_animations($!sts);
  }

}

### /home/cbwood/Projects/gnome-shell/src/st/st-settings.h

sub st_settings_get ()
  returns StSettings
  is native(gnome-shell-st)
  is export
{ * }

sub st_settings_inhibit_animations (StSettings $settings)
  is native(gnome-shell-st)
  is export
{ * }

sub st_settings_uninhibit_animations (StSettings $settings)
  is native(gnome-shell-st)
  is export
{ * }
