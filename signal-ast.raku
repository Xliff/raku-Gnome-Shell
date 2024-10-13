use NativeCall;
use experimental :rakuast;

class ShellWM is repr<CPointer> { }
class MutterMetaWindiw is repr<CPointer> { }
class MutterMetaInhibitShortcutsDialog is repr<CPointer> { }

constant gobject = 'gobject',v0;


my $a = q:to/SUB/.AST;
sub g-connect-create-inhibit-shortcuts-dialog (
  Pointer $app,
  Str     $name,
          &handler (
            Pointer,
            Pointer
            --> Pointer
          ),
  Pointer $data,
  uint32  $flags
)
  returns uint64
  is native('gobject')
  is symbol('g_signal_connect_object')
  { * }
SUB

$a.^name.say;
$a.say;
$a.DEPARSE.say;
