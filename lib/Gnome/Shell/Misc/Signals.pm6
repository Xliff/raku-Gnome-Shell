use v6.c;

use Gnome::Shell::Raw::Types;

class Gnome::Shell::Misc::Signals::EventEmitter {

  method connectObject (*@args) {
    SignalTracker.connectObject(self, |@args);
  }

  method disconnectObject(*@args) {
    SignalTracker.disconnectObject(self, |@args);
  }

  method connect_object (*@args) is also<connect-object> {
    self.connectObject(|@args);
  }

  method disconnect_object (*@args) is also<disconnect-object> {
    self.disconnectObject(|@args);
  }

}

# cw: Don't exactly know the intent of the last line:
#Signals.addSignalMethods(EventEmitter.prototype)
