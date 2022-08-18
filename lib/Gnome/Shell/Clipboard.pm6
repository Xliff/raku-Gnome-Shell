use v6.c;

use GLib::Raw::Traits;
use Method::Also;

use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::Clipboard;

use GLib::GList;

use GLib::Roles::Implementor;
use GLib::Roles::Object;


our subset StClipboardAncestry is export of Mu
  where StClipboard | GObject;

class Gnome::Shell::Clipboard {
  also does GLib::Roles::Object;

  has StClipboard $!stc is implementor;

  submethod BUILD ( :$st-clipboard ) {
    self.setStClipboard($st-clipboard)
      if $st-clipboard
  }

  method setStClipboard (StClipboardAncestry $_) {
    my $to-parent;

    $!stc = do {
      when StClipboard {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(StClipboard, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Structs::StClipboard
    is also<StClipboard>
  { $!stc }

  multi method new (StClipboardAncestry $st-clipboard, :$ref = True)
    is static
  {
    return unless $st-clipboard;

    my $o = self.bless( :$st-clipboard );
    $o.ref if $ref;
    $o;
  }
  multi method new is static {
    self.get_default;
  }

  method get_default is static is also<get-default> {
    my $st-clipboard = st_clipboard_get_default();

    $st-clipboard ?? self.bless( :$st-clipboard ) !! Nil;
  }

  method get_content (
    Int()    $type,
    Str()    $mimetype,
             &callback,
    gpointer $user_data = gpointer
  )
    is also<get-content>
  {
    my StClipboardType $t = $type;

    st_clipboard_get_content($!stc, $t, $mimetype, &callback, $user_data);
  }

  method get_mimetypes (Int() $type, :$raw = False, :$glist = False)
    is also<get-mimetypes>
  {
    my StClipboardType $t = $type;

    returnGList(
      st_clipboard_get_mimetypes($!stc, $t),
      $raw,
      $glist,
      Str
    );
  }

  method get_text (
    Int()    $type,
             &callback,
    gpointer $user_data = gpointer;
  )
    is also<get-text>
  {
    my StClipboardType $t = $type;

    st_clipboard_get_text($!stc, $t, &callback, $user_data);
  }

  method set_content (Int() $type, Str() $mimetype, GBytes() $bytes)
    is also<set-content>
  {
    my StClipboardType $t = $type;

    st_clipboard_set_content($!stc, $t, $mimetype, $bytes);
  }

  method set_selection (MutterMetaSelection() $selection)
    is static
    is also<set-selection>
  {
    st_clipboard_set_selection($selection);
  }

  method set_text (Int() $type, Str() $text) is also<set-text> {
    my StClipboardType $t = $type;

    st_clipboard_set_text($!stc, $t, $text);
  }

}
