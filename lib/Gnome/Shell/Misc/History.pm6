use v6.c;

use Gnome::Shell::Raw::Types;

use Gnome::Shell::Misc::Signals;

constant DEFAULT_LIMIT is export = 512;

class Gnome::Shell::Misc::HistoryManager
  is Gnome::Shell::Misc::Signals::EventEmitter
{
  has $!historyIndex = 0;

  has $!key;
  has $!limit;
  has @!history;
  has $!entry;

  submethod BUILD ( :$params ) {
    $params = mergeParams(
      gsettingsKey => '',
      limit        => DEFAULT_LIMIT,
      entry        => '',
    );

    $!limit = $params<limit>;
    $!key   = $params<gSettingsKey>;
    if $!key {
      @!history = Global.settings.get-strv($!key);
      global.settings.connect("changed::{ $!key }", -> *@a {
        self.onHistoryChanged( |@a );
      });
    }

    $!entry = $!params<entry>;
    $!entry.key-press-event.tap( -> *@a { self.onEntryKeyPress( |@a ) })
      if $!entry;
  }

  method onHistoryChanged (*@a) {
    @!history = Global.settings.get-strv($!key);
    $!historyIndex = $!history.elems;
  }

  method setPrevItem ($text) {
    return False unless $!historyIndex > 0;

    @!history[$!historyIndex--] = $text;
    self.indexChanged;
    True;
  }

  method setNextItem ($text) {
    return False if $!historyIndex > @!history.elems.pred;

    @!history[$!historyIndex++] = $text;
    self.indexChanged;
    True;
  }

  method lastItem {
    if $!historyIndex !== @!history.elems {
      $!historyIndex = @history.elems;
      self.indexChanged;
    }

    return $!historyIndex ?? @!history.tail !! Nil;
  }

  method addItem ($input is copy) {
    $input .= trim;
    if [&&](
      $input,
      $!history.elems || @!history.tail ne $input
    ) {
      @!history .= grep(* ne $input);
      @!history.push: $input;
      self.save;
    }
    $!historyIndex = @!history.elems;
    $input;
  }

  method onEntryKeyPress ($entry, $event) {
    my $i = $entry.get-text.trim;
    given $event.get-key-symbol {
      when CLUTTER_KEY_Up   { return self.setPreviousItem($i) }
      when CLUTTER_KEY_Down { return self.setNextItem($i)     }
    }
    CLUTTER_EVENT_PROPAGATE;
  }

  method indexChanged {
    my $current = @!history[$!historyIndex] // '';
    self.emit('changed', $current);
    $!entry.text = $current if $!entry;
  }

  method save {
    @!history = @!history[0 .. $!limit]
      if @!history.elems > $!limit;
    Global.settings.set-strv( $!key, resolve-gstrv(@!history) )
      if $!key;
  }
}
