use v6.c;

use ATSPI::EventListener;
use Gnome::Shell::Misc::Signals;

constant CARETMOVED   is export = 'object:text-caret-moved';
constant STATECHANGED is export = 'object:state-changed';

### /home/cbwood/Projects/gnome-shell/js/ui/focusCaretTracker.js

class Gnome::Shell::UI::FocusCaretTracker
  is Gnome::Shell::Misc::Signals::EventEmitter
{
  has $!atspiListener;
  has $!atspiInited;
  has $!focusListenerRegistered;
  has $!caretListenerRegistered;

  submethod BUILD {
    $!atspiListener = ATSPI::EventListener.new( -> *@a {
      self.onChanged( |@a );
    });
  }

  method onChanged ($e) {
    if $e.type.indexOf(STATECHANGED) == 0 {
      self.emit('focus-changed', $e);
    } elsif $e.type == CARETMOVED {
      self.emit('caret-moved', $e);
    }
  }

  method initAtspi {
    if $!atspiInited.not && (Atspi.init == 0) {
      Atspi.set_timeout(250, 250);
      $!atspiInited = True;
    }

    $!atspiInited;
  }

  method registerFocusListener {
    return if self.initAtspi.not || $!focusListenerRegistered;

    $!atspiListener.register("{ STATECHANGED }:focused");
    $!atspiListener.register("{ STATECHANGED }:selected");
    $!focusListenerRegistered = True;
  }

  method registerCaretListener {
    return if self.initAtspi.not || $!caretListenerRegistered;

    $!atspiListener.register(CARETMOVED);
    $!caretListenerRegistered = True;
  }

  method deregisterFocusListener {
    return unless $!focusListenerRegistered;

    $!atspiListener.deregister("{ STATECHANGED }:focused");
    $!atspiListener.deregister("{ STATECHANGED }:selected");
    $!focusListenerRegistered = False;
  }

  method deregisterCaretListener {
    return unless $!caretListenerRegistered;

    $!atspiListener.register(CARETMOVED);
    $!caretListenerRegistered = False;
  }

}
