use v6.c;

use Method::Also;
use NativeCall;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::St::Widget;

use GLib::Roles::Implementor;

our subset StPasswordEntryAncestry is export of Mu
  where StPasswordEntry | StEntryAncestry;

class Gnome::Shell::St::PasswordEntry is Gnome::Shell::St::Entry {
  has StPasswordEntry $!stpe is implementor;

  submethod BUILD ( :$st-password-entry ) {
    self.setStPasswordEntry($st-password-entry) if $st-password-entry
  }

  method setStPasswordEntry (StPasswordEntryAncestry $_) {
    my $to-parent;

    $!stpe = do {
      when StPasswordEntry {
        $to-parent = cast(StEntry, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StPasswordEntry, $_);
      }
    }
    self.setStEntry($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::StPasswordEntry
    is also<StPasswordEntry>
  { $!stpe }

  multi method new (StPasswordEntryAncestry $st-password-entry, :$ref = True) {
    return unless $st-password-entry;

    my $o = self.bless( :$st-password-entry );
    $o.ref if $ref;
    $o;
  }

  method new {
    my $st-password-entry = st_password_entry_new();

    $st-password-entry ?? self.bless( :$st-password-entry ) !! Nil;
  }

  # Type: boolean
  method password-visible is rw  is g-property is also<password_visible> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('password-visible', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('password-visible', $gv);
      }
    );
  }

  # Type: boolean
  method show-peek-icon is rw  is g-property is also<show_peek_icon> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('show-peek-icon', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        $gv.boolean = $val;
        self.prop_set('show-peek-icon', $gv);
      }
    );
  }

  method get_password_visible is also<get-password-visible> {
    so st_password_entry_get_password_visible($!stpe);
  }

  method get_show_peek_icon is also<get-show-peek-icon> {
    so st_password_entry_get_show_peek_icon($!stpe);
  }

  method set_password_visible (Int() $value) is also<set-password-visible> {
    my gboolean $v = $value.so.Int;

    st_password_entry_set_password_visible($!stpe, $v);
  }

  method set_show_peek_icon (Int() $value) is also<set-show-peek-icon> {
    my gboolean $v = $value.so.Int;

    st_password_entry_set_show_peek_icon($!stpe, $v);
  }

}


### /home/cbwood/Projects/gnome-shell/src/st/st-password-entry.h

sub st_password_entry_get_password_visible (StPasswordEntry $entry)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_password_entry_get_show_peek_icon (StPasswordEntry $entry)
  returns uint32
  is native(gnome-shell-st)
  is export
{ * }

sub st_password_entry_new ()
  returns StEntry
  is native(gnome-shell-st)
  is export
{ * }

sub st_password_entry_set_password_visible (
  StPasswordEntry $entry,
  gboolean        $value
)
  is native(gnome-shell-st)
  is export
{ * }

sub st_password_entry_set_show_peek_icon (
  StPasswordEntry $entry,
  gboolean        $value
)
  is native(gnome-shell-st)
  is export
{ * }
