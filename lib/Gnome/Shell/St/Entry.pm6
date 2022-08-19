use v6.c;

use Method::Also;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::St::Entry;

use Gnome::Shell::St::Widget;

use GLib::Roles::Implementor;

our subset StEntryAncestry is export of Mu
  where StEntry | StWidgetAncestry;

class Gnome::Shell::St::Entry is Gnome::Shell::St::Widget {
  has StEntry $!ste is implementor;

  submethod BUILD ( :$st-entry ) {
    self.setStEntry($st-entry) if $st-entry
  }

  method setStEntry (StEntryAncestry $_) {
    my $to-parent;

    $!ste = do {
      when StEntry {
        $to-parent = cast(StWidget, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StEntry, $_);
      }
    }
    self.setStWidget($to-parent);
  }

  method Mutter::Cogl::Raw::Definitions::StEntry
    is also<StEntry>
  { $!ste }

  multi method new (StEntryAncestry $st-entry, :$ref = True) {
    return unless $st-entry;

    my $o = self.bless( :$st-entry );
    $o.ref if $ref;
    $o;
  }
  multi method new (Str() $text) {
    my $st-entry = st_entry_new($text);

    $st-entry ?? self.bless( :$st-entry ) !! Nil;
  }

  # Type: MutterClutterText
  method clutter-text ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Muitter::Clutter::Text.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('clutter-text', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Clutter::Text.getTypePair
        );
      },
      STORE => -> $,  $val is copy {
        warn 'clutter-text does not allow writing'
      }
    );
  }

  # Type: MutterClutterActor
  method primary-icon ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Mutter::Clutter::Actor.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('primary-icon', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Clutter::Actor.getTypePair
        );
      },
      STORE => -> $, MutterClutterActor() $val is copy {
        $gv.object = $val;
        self.prop_set('primary-icon', $gv);
      }
    );
  }

  # Type: StActor
  method secondary-icon ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Mutter::Clutter::Actor.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('secondary-icon', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Clutter::Actor.getTypePair
        );
      },
      STORE => -> $, MutterClutterActor() $val is copy {
        $gv.object = $val;
        self.prop_set('secondary-icon', $gv);
      }
    );
  }

  # Type: string
  method hint-text is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('hint-text', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        $gv.string = $val;
        self.prop_set('hint-text', $gv);
      }
    );
  }

  # Type: MutterClutterActor
  method hint-actor ( :$raw = False ) is rw  is g-property {
    my $gv = GLib::Value.new( Mutter::Clutter::Actor.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('hint-actor', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Clutter::Actor.getTypePair
        );
      },
      STORE => -> $, MutterClutterActor() $val is copy {
        $gv.object = $val;
        self.prop_set('hint-actor', $gv);
      }
    );
  }

  # Type: string
  method text is rw  is g-property {
    my $gv = GLib::Value.new( G_TYPE_STRING );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('text', $gv);
        $gv.string;
      },
      STORE => -> $, Str() $val is copy {
        $gv.string = $val;
        self.prop_set('text', $gv);
      }
    );
  }

  # Type: StInputContentPurpose
  method input-purpose is rw  is g-property {
    my $gv = GLib::Value.new(
      GLib::Value.typeFromEnum(MutterClutterInputContentPurpose)
    );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('input-purpose', $gv);
        MutterClutterInputContentPurposeEnum(
          $gv.valueFromEnum(MutterClutterInputContentPurpose)
        )
      },
      STORE => -> $, Int() $val is copy {
        $gv.valueFromEnum(MutterClutterInputContentPurpose) = $val;
        self.prop_set('input-purpose', $gv);
      }
    );
  }

  # Type: MutterClutterInputContentHintFlags
  method input-hints is rw is g-property {
    my $gv = GLib::Value.new(
      GLib::Value.typeFromEnum(MutterClutterInputContentHintFlags)
    );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('input-hints', $gv);
        $gv.valueFromEnum(MutterClutterInputContentHintFlags)
      },
      STORE => -> $, Int() $val is copy {
        $gv.valueFromEnum(MutterClutterInputContentHintFlags) = $val;
        self.prop_set('input-hints', $gv);
      }
    );
  }

  method primary-icon-clicked {
    self.connect($!ste, 'primary-icon-clicked');
  }

  method secondary-icon-clicked {
    self.connect($!ste, 'secondary-icon-clicked');
  }

  method get_clutter_text ( :$raw = False ) is also<get-clutter-text> {
    propReturnObject(
      st_entry_get_clutter_text($!ste),
      $raw,
      |Mutter::Clutter::Text.getTypePair
    );
  }

  method get_hint_actor ( :$raw = False ) is also<get-hint-actor> {
    propReturnObject(
      st_entry_get_hint_actor($!ste),
      $raw,
      |Mutter::Clutter::Actor.getTypePair
    );
  }

  method get_hint_text is also<get-hint-text> {
    st_entry_get_hint_text($!ste);
  }

  method get_input_hints is also<get-input-hints> {
    MutterClutterInputContentHintFlags( st_entry_get_input_hints($!ste) );
  }

  method get_input_purpose is also<get-input-purpose> {
    MutterClutterInputContentPurposeEnum( st_entry_get_input_purpose($!ste) );
  }

  method get_primary_icon ( :$raw = False ) is also<get-primary-icon> {
    propReturnObject(
      st_entry_get_primary_icon($!ste),
      $raw,
      |Mutter::Clutter::Actor.getTypePair
    )
  }

  method get_secondary_icon ( :$raw = False ) is also<get-secondary-icon> {
    propReturnObject(
      st_entry_get_secondary_icon($!ste),
      $raw,
      |Mutter::Clutter::Actor.getTypePair
    )
  }

  method get_text is also<get-text> {
    st_entry_get_text($!ste);
  }

  method set_cursor_func (&func, gpointer $user_data)
    is static
    is also<set-cursor-func>
  {
    st_entry_set_cursor_func(&func, $user_data);
  }

  method set_hint_actor (MutterClutterActor() $hint_actor)
    is also<set-hint-actor>
  {
    st_entry_set_hint_actor($!ste, $hint_actor);
  }

  method set_hint_text (Str() $text) is also<set-hint-text> {
    st_entry_set_hint_text($!ste, $text);
  }

  method set_input_hints (Int() $hints) is also<set-input-hints> {
    my MutterClutterInputContentHintFlags $h = $hints;

    st_entry_set_input_hints($!ste, $hints);
  }

  method set_input_purpose (Int() $purpose) is also<set-input-purpose> {
    my MutterClutterInputContentPurpose $p = $purpose;

    st_entry_set_input_purpose($!ste, $purpose);
  }

  method set_primary_icon (MutterClutterActor() $icon)
    is also<set-primary-icon>
  {
    st_entry_set_primary_icon($!ste, $icon);
  }

  method set_secondary_icon (MutterClutterActor() $icon)
    is also<set-secondary-icon>
  {
    st_entry_set_secondary_icon($!ste, $icon);
  }

  method set_text (Str() $text) is also<set-text> {
    st_entry_set_text($!ste, $text);
  }

}
