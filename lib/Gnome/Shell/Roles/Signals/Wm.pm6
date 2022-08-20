use v6.c;

use NativeCall;

use GLib::Raw::ReturnedValue;
use Gnome::Shell::Raw::Types;

role Gnome::Shell::Roles::Signals::Wm {
  has %!signals-swm;

  #  MutterMetaWindow *window --> MutterMetaInhibitShortcutsDialog *
  method connect-create-inhibit-shortcuts-dialog (
    $obj,
    $signal = 'create-inhibit-shortcuts-dialog',
    &handler?
  ) {
    my $hid;
    %!signals-swm{$signal} //= do {
      my \𝒮 = Supplier.new;
      $hid = g-connect-create-inhibit-shortcuts-dialog($obj, $signal,
        -> $, $mw {
          CATCH {
            default { 𝒮.note($_) }
          }

          my $r = ReturnedValue.new;
          𝒮.emit( [self, $mw, $r] );
          $r.r;
        },
        Pointer, 0
      );
      [ 𝒮.Supply, $obj, $hid ];
    };
    %!signals-swm{$signal}[0].tap(&handler) with &handler;
    %!signals-swm{$signal}[0];
  }

  #  MutterMetaWindow *window,  MutterMetaRectangle *tile_rect,  int tile_monitor --> void
  method connect-show-tile-preview (
    $obj,
    $signal = 'show-tile-preview',
    &handler?
  ) {
    my $hid;
    %!signals-swm{$signal} //= do {
      my \𝒮 = Supplier.new;
      $hid = g-connect-show-tile-preview($obj, $signal,
        -> $, $mw, $mr, $i {
          CATCH {
            default { 𝒮.note($_) }
          }

          𝒮.emit( [self, $mw, $mr, $i] );
        },
        Pointer, 0
      );
      [ 𝒮.Supply, $obj, $hid ];
    };
    %!signals-swm{$signal}[0].tap(&handler) with &handler;
    %!signals-swm{$signal}[0];
  }

  #  MutterMetaWindowActor *actor,  MutterMetaSizeChange which_change,  MutterMetaRectangle *old_frame_rect,  MutterMetaRectangle *old_buffer_rect --> void
  method connect-size-change (
    $obj,
    $signal = 'size-change',
    &handler?
  ) {
    my $hid;
    %!signals-swm{$signal} //= do {
      my \𝒮 = Supplier.new;
      $hid = g-connect-size-change($obj, $signal,
        -> $, $mwa, $msc, $mr1, $mr2 {
          CATCH {
            default { 𝒮.note($_) }
          }

          𝒮.emit( [self, $mwa, $msc, $mr1, $mr2] );
        },
        Pointer, 0
      );
      [ 𝒮.Supply, $obj, $hid ];
    };
    %!signals-swm{$signal}[0].tap(&handler) with &handler;
    %!signals-swm{$signal}[0];
  }

  #  MutterMetaWindow *window,  MutterMetaWindowMenuType menu,  int x,  int y --> void
  method connect-show-window-menu (
    $obj,
    $signal = 'show-window-menu',
    &handler?
  ) {
    my $hid;
    %!signals-swm{$signal} //= do {
      my \𝒮 = Supplier.new;
      $hid = g-connect-show-window-menu($obj, $signal,
        -> $, $mw, $mwmt, $i1, $i2 {
          CATCH {
            default { 𝒮.note($_) }
          }

          𝒮.emit( [self, $mw, $mwmt, $i1, $i2] );
        },
        Pointer, 0
      );
      [ 𝒮.Supply, $obj, $hid ];
    };
    %!signals-swm{$signal}[0].tap(&handler) with &handler;
    %!signals-swm{$signal}[0];
  }

  #  gint from,  gint to, MutterMetaMotionDirection direction --> void
  method connect-switch-workspace (
    $obj,
    $signal = 'switch-workspace',
    &handler?
  ) {
    my $hid;
    %!signals-swm{$signal} //= do {
      my \𝒮 = Supplier.new;
      $hid = g-connect-switch-workspace($obj, $signal,
        -> $, $g1, $g2, $mmd {
          CATCH {
            default { 𝒮.note($_) }
          }

          𝒮.emit( [self, $g1, $g2, $mmd] );
        },
        Pointer, 0
      );
      [ 𝒮.Supply, $obj, $hid ];
    };
    %!signals-swm{$signal}[0].tap(&handler) with &handler;
    %!signals-swm{$signal}[0];
  }

  #  MutterMetaKeyBinding *binding --> gboolean
  method connect-filter-keybinding (
    $obj,
    $signal = 'filter-keybinding',
    &handler?
  ) {
    my $hid;
    %!signals-swm{$signal} //= do {
      my \𝒮 = Supplier.new;
      $hid = g-connect-filter-keybinding-rbool($obj, $signal,
        -> $, $mkb {
          CATCH {
            default { 𝒮.note($_) }
          }

          my $r = ReturnedValue.new;
          𝒮.emit( [self, $mkb, $r] );
          $r.r
        },
        Pointer, 0
      );
      [ 𝒮.Supply, $obj, $hid ];
    };
    %!signals-swm{$signal}[0].tap(&handler) with &handler;
    %!signals-swm{$signal}[0];
  }

  #  MutterMetaWindow *window --> MutterMetaCloseDialog *
  method connect-create-close-dialog (
    $obj,
    $signal = 'create-close-dialog',
    &handler?
  ) {
    my $hid;
    %!signals-swm{$signal} //= do {
      my \𝒮 = Supplier.new;
      $hid = g-connect-create-close-dialog($obj, $signal,
        -> $, $mw {
          CATCH {
            default { 𝒮.note($_) }
          }

          my $r = ReturnedValue.new;
          𝒮.emit( [self, $mw, $r] );
          $r.r;
        },
        Pointer, 0
      );
      [ 𝒮.Supply, $obj, $hid ];
    };
    %!signals-swm{$signal}[0].tap(&handler) with &handler;
    %!signals-swm{$signal}[0];
  }
}

# ShellWM *wm,  MutterMetaWindow *window --> MutterMetaInhibitShortcutsDialog *
sub g-connect-create-inhibit-shortcuts-dialog (
  Pointer $app,
  Str     $name,
          &handler (
            ShellWM,
            MutterMetaWindow
            --> MutterMetaInhibitShortcutsDialog
          ),
  Pointer $data,
  uint32  $flags
)
  returns uint64
  is native(gobject)
  is symbol('g_signal_connect_object')
{ * }


# ShellWM *wm, MutterMetaWindowActor *actor
sub g-connect-meta-actor (
 Pointer $app,
 Str     $name,
         &handler (ShellWM,  MutterMetaWindowActor),
 Pointer $data,
 uint32  $flags
)
  returns uint64
  is native(gobject)
  is symbol('g_signal_connect_object')
{ * }

# ShellWM *wm,  MutterMetaWindow *window,  MutterMetaRectangle *tile_rect, int tile_monitor
sub g-connect-show-tile-preview (
  Pointer $app,
  Str     $name,
          &handler (ShellWM, MutterMetaWindow, MutterMetaRectangle, gint),
  Pointer $data,
  uint32  $flags
)
  returns uint64
  is native(gobject)
  is symbol('g_signal_connect_object')
{ * }

# ShellWM *wm,  MutterMetaWindowActor *actor,  MutterMetaSizeChange which_change,  MutterMetaRectangle *old_frame_rect,  MutterMetaRectangle *old_buffer_rect
sub g-connect-size-change (
  Pointer $app,
  Str     $name,
          &handler (
            ShellWM,
            MutterMetaWindowActor,
            MutterMetaSizeChange,
            MutterMetaRectangle,
            MutterMetaRectangle
          ),
  Pointer $data,
  uint32  $flags
)
  returns uint64
  is native(gobject)
  is symbol('g_signal_connect_object')
{ * }

# ShellWM *wm,  MutterMetaWindow *window,  MutterMetaWindowMenuType menu,  int x,  int y
sub g-connect-show-window-menu (
  Pointer $app,
  Str     $name,
          &handler (ShellWM, MutterMetaWindow, MutterMetaWindowMenuType, gint, gint),
  Pointer $data,
  uint32  $flags
)
  returns uint64
  is native(gobject)
  is symbol('g_signal_connect_object')
{ * }

# ShellWM *wm,  gint from,  gint to,  MutterMetaMotionDirection direction
sub g-connect-switch-workspace (
  Pointer $app,
  Str     $name,
          &handler (ShellWM, gint, gint, MutterMetaMotionDirection),
  Pointer $data,
  uint32  $flags
)
  returns uint64
  is native(gobject)
  is symbol('g_signal_connect_object')
{ * }

# ShellWM *wm,  MutterMetaKeyBinding *binding --> gboolean
sub g-connect-filter-keybinding-rbool (
  Pointer $app,
  Str     $name,
          &handler (ShellWM, MutterMetaKeyBinding --> gboolean),
  Pointer $data,
  uint32  $flags
)
  returns uint64
  is native(gobject)
  is symbol('g_signal_connect_object')
{ * }

# ShellWM *wm,  MutterMetaWindow *window --> MutterMetaCloseDialog *
sub g-connect-create-close-dialog (
  Pointer $app,
  Str     $name,
          &handler (ShellWM, MutterMetaWindow --> MutterMetaCloseDialog),
  Pointer $data,
  uint32  $flags
)
  returns uint64
  is native(gobject)
  is symbol('g_signal_connect_object')
{ * }
