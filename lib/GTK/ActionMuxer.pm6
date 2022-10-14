use v6.c;

use Method::Also;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use GTK::Raw::ActionMuxer;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset GtkActionMuxerAncestry is export of Mu
  where GtkActionMuxer | GObject;

class GTK::ActionMuxer {
  also does GLib::Roles::Object;

  has GtkActionMuxer $!am is implementor;

  submethod BUILD ( :$gtk-action-muxer ) {
    self.setGtkActionMuxer($gtk-action-muxer) if $gtk-action-muxer
  }

  method setGtkActionMuxer (GtkActionMuxerAncestry $_) {
    my $to-parent;

    $!am = do {
      when GtkActionMuxer {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(GtkActionMuxer, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::GtkActionMuxer
    is also<GtkActionMuxer>
  { $!am }

  multi method new (GtkActionMuxerAncestry $gtk-action-muxer, :$ref = True) {
    return unless $gtk-action-muxer;

    my $o = self.bless( :$gtk-action-muxer );
    $o.ref if $ref;
    $o;
  }
  multi method new {
    my $gtk-action-muxer = gtk_action_muxer_new();

    $gtk-action-muxer ?? self.bless( :$gtk-action-muxer ) !! Nil;
  }

  # Type: GtkActionMuxer
  method parent ( :$raw = False) is rw is g-property {
    my $gv = GLib::Value.new( self.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('parent', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |self.getTypePair
        );
      },
      STORE => -> $, GtkActionMuxer() $val is copy {
        $gv.object = $val;
        self.prop_set('parent', $gv);
      }
    );
  }

  method primary-accel-changed is also<primary_accel_changed> {
    self.connect-strstr($!am, 'primary-accel-changed');
  }

  method get_parent ( :$raw = False ) is also<get-parent> {
    propReturnObject(
      gtk_action_muxer_get_parent($!am),
      $raw,
      |self.getTypePair
    );
  }

  method get_primary_accel (Str() $action_and_target)
    is also<get-primary-accel>
  {
    gtk_action_muxer_get_primary_accel($!am, $action_and_target);
  }

  method get_type is also<get-type> {
    state ($n, $t);

    unstable_get_type( self.^name, &gtk_action_muxer_get_type, $n, $t );
  }

  method print_action_and_target (
    Str()      $action_name,
    GVariant() $target
  )
    is static

    is also<print-action-and-target>
  {
    gtk_print_action_and_target($action_name, $target);
  }

  method insert (Str() $prefix, GActionGroup() $action_group) {
    gtk_action_muxer_insert($!am, $prefix, $action_group);
  }

  method remove (Str() $prefix) {
    gtk_action_muxer_remove($!am, $prefix);
  }

  method set_parent (GtkActionMuxer() $parent) is also<set-parent> {
    gtk_action_muxer_set_parent($!am, $parent);
  }

  method set_primary_accel (Str() $action_and_target, Str() $primary_accel)
    is also<set-primary-accel>
  {
    gtk_action_muxer_set_primary_accel(
      $!am,
      $action_and_target,
      $primary_accel
    );
  }

}
