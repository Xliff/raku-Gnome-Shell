use v6.c;

use Gnome::Shell::Raw::Types;

class Gnome::Shell::Misc::Signals::EventEmitter {

  method connectObject ( *@args ) {
    SignalTracker.connectObject(self, |@args);
  }

  method disconnectObject ( *@args ) {
    SignalTracker.disconnectObject(self, |@args);
  }

  method connect_object ( *@args ) is also<connect-object> {
    self.connectObject( |@args );
  }

  method disconnect_object ( *@args ) is also<disconnect-object> {
    self.disconnectObject( |@args );
  }

}

# cw: A role needs to be created from gjs/modules/core/_signals.js
#     and added to any class mentioned like this:
#       Signals.addSignalMethods(EventEmitter.prototype)
#
#     NONE of them should be a descendant of GObject!
