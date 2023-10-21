use v6.c;

use Gnome::Shell::Raw::Types;
use Mutter::Raw::Clutter::Keysyms;

use GIO::Settings;
use Mutter::Clutter::Event;
use Mutter::Meta;

use Gnome::Shell::UI::Global;
use Gnome::Shell::UI::Main;
use Gnome::Shell::UI::ModalDialog;

use GLib::Roles::Object;

### /home/cbwood/Projects/gnome-shell/js/ui/runDialog.js

constant DISABLE_COMMAND_LINE_KEY = 'disable-command-line';
constant EXEC_ARG_KEY             = 'exec-arg';
constant EXEC_KEY                 = 'exec';
constant HISTORY_KEY              = 'command-history';

constant LOCKDOWN_SCHEMA =
  'org.gnome.desktop.lockdown';
constant TERMINAL_SCHEMA =
  'org.gnome.desktop.default-applications.terminal';

class Gnome::Shell::UI::RunDialog is Gnome::Shell::UI::ModalDialog {
  has $!lockdownSettings;
  has $!terminalSettings;
  has %!internalCommands;
  has $!entryText;
  has $!descriptionLabel;
  has $!content;
  has $!commandError;
  has $!pathCompleter;
  has $!history;
  has $!enableInternalCommands;

  method enable-internal ($e) {
    $!enableInternalCommands = $e;
  }


  submethod TWEAK {
    self.style-class = 'run-dialog';
    self.destroy-on-close = False;

    $!lockdownSettings = GIO::Settings.new(LOCKDOWN_SCHEMA);
    $!terminalSettings = GIO::Settings.new(TERMINAL_SCHEMA);

    my $s  = self;
    Global.Settings.changed('development-tools').tap( -> *@a {
      $s.enable-internal( Global.settings.get-boolean('development-tools') );
    });
    $s.enable-internal( Global.settings.get-boolean('development-tools') );

    %!internalCommands = (
      r         => { self!restart },
      restart   => { self!restart },

      lg        => sub () { Main.createLookingGlass.open },
      debugexit => sub () { Global.context.terminate },

      rt        => sub () {
        Main.reloadThemeResource;
        Main.loadTheme;
      },

      check_cloexec_fds => sub () {
        Gnome::Shell::Utils.check-cloexec-fds;
      }
    );

    my $content = Gnome::Shell::Dialog::Message::Content(
      title => 'Run a Command'
    );
    self.contentLayout.add-actor($content);

    my $entry = Gnome::Shell::St::Entry.new.setAttributes(
      style-class => 'run-dialog-entry',
      can-focus   => True
    );

    Gnome::Shell::UI::ShellEntry.addContextMenu($entry);
    $!entryText = $entry.clutter-text;
    $content.add-child($entry);
    self.setInitialKeyFocus($!entryText);

    my $defaultDescriptionText = 'Press ESC to close';

    $!descriptionLabel = Gnome::Shell::St::Label.new.setAttributes(
      style-class => 'run-dialog-description',
      text        => 'Press ESC to close'
    );
    $!content.add-child($!descriptionLabel);

    $!commandError  = False;
    $!pathCompleter = GIO::FileNameCompleter;
    $!history       = Gnome::Shell::History::Manager.new(
      gsettingsKey  => HISTORY_KEY,
      entry         => $!entryText
    );

    my $et = $!entryText;
    my $ce = $!commandError;
    $!entryText.activate.tap( -> *@a {
      $s.popModel;
      $s.run(
        $et.get-text,
        Clutter::Event.get-current-event.state +&
          CLUTTER_CONTROL_MASK
      );
      $s.close unless $ce && $s.pushModal;
    });

    $!entryText.key-press-event.tap( -> *@a {
      my $symbol = Mutter::Clutter::Event.new( @a[1] ).get-key-symbol;

      if $symbol == MUTTER_CLUTTER_KEY_Tab {
        my ($text, $prefix) = ($!entryText.text);
        if $text.contains(' ').not {
          $prefix = $text;
        } else {
          $prefix = $text.substr(
            $text.comb.first(' ', :end, :k).succ
          );
        }
        if self!getCompletion($prefix) -> $postfix {
          $!entryText.insert-text($postfix);
          $!entryText.set-cursor-position($text.length + $postfix.chars);
        }
        @a.tail.r = CLUTTER_EVENT_STOP;
      } else {
        @a.tail.r = CLUTTER_EVENT_PROPAGATE;
      }
    });

    my $dl = $!descriptionLabel;
    $!entryText.text-changed.tap( -> *@a {
      $dl.text = $defaultDescriptionText;
    });
  }

  method key-release-event ($event) is vfunc {
    my $e = Mutter::Clutter::Event.new($event);

    do if $e.get-key-symbol == MUTTER_CLUTTER_KEY_Escape {
      self.close;
      CLUTTER_EVENT_STOP.Int;
    } else {
      CLUTTER_EVENT_PROPAGATE.Int;
    }
  }

  method !getCommandCompletion ($text) {

    sub getCommon($s1, $s2) {
      return $s2 unless $s1;

      my @c;
      for $s1.comb [Z] $s2.comb {
        last if [ne]( |$_ );
        @c.push: .head
      }
      @c.join;
    }

    my @paths = %*ENV<PATH>.split(':');
    @paths.push: $*HOME.absolute;
    my @results = do gather for @paths -> $p {
      CATCH {
        when X::GLib::GError {
          when .code ==
               (G_IO_ERROR_NOT_FOUND, G_IO_ERROR_NOT_DIRECTORY).any
          {
            $*ERR.say: "Exception occured while checking path: {
                        .message }";
          }
        }
        default { .rethrow }
      }

      # cw: Must be able to turn on GError Exceptions, here!
      #     The dynamic is the mechanism, but it isn't wired
      #     to anything, yet!
      my $*GERROR-EXCEPTIONS = True;
      my $file     = GIO::File.new-for-path($p);
      my $fileEnum = $file.enumerate-children(
        'standard::name',
        G_FILE_QUERY_INFO_NONE
      );

      while $fileEnum.next-file -> $i {
        my $name = $i.name;
        take $name if $name.starts-with($text);
      }
    }

    @results = @results.rotor(2).map({ [~]( |$_ ) })
      if +@results;

    return unless +@results;
    return @results.reduce(&getCommon);
  }

  method !getCompletion ($text) {
    $text.contains('/')
      ?? $!pathCompleter.get-completion-suffix($text)
      !! self.getCommandCompletion($text);
  }

  method run ($input is copy, $inTerminal) {
    $input = $!history.addItem($input);
    my $command = $input;

    $!commandError = False;
    if $!enableInternalCommands {
      if %!internalCommands{$input} -> &f {
        return &f();
      }
    }

    {
      CATCH {
        default {
          my $path;
          my $firstInputChar = $input.comb.head;
          if $firstInputChar eq '/' {
            $path = $input.IO;
          } elsif $firstInputChar eq '~' {
            $path = $*HOME.add( $input.substr(1) );
          }

          if $path && $path.r {
            my $file = GIO::File.new-for-path($path);
            try {
              CATCH {
                default {
                  my $msg = .message;
                  $msg ~~ s/<-[:]>*:\s+(.+)/$0/;
                  self!showError($msg);
                }
              }

              GIO::AppInfo.launch_default_for_uri(
                $file.uri,
                Global.create-app-launch-context
              );
            }
          } else {
            self!showError( .message );
          }
        }
      }

      if $inTerminal {
        my $exec = $!terminalSettings.get-string(EXEC_KEY);
        my $arg  = $!terminalSettings.get-string(EXEC_ARG_KEY);
        run "{$exec} {$arg} {$input}";
      }
    }
  }

  method !showError ($message) {
    $!commandError = True;
    $!descriptionLabel.text= $message;
  }

  method !restart {
    if Mutter::Meta.is-wayland-compositor {
      self!showError('Restart is not available on Wayland');
      return;
    }
    self.shouldFadeOut = False;
    self.close;

    Meta.restart('Restarting…', Global.context);
  }

  method open {
    $!history.lastItem();
    ($!entryText.text, $!commandError) = ('', False);

    return False if $!lockdownSettings.get-boolean(DISABLE_COMMAND_LINE_KEY);
    nextsame;
  }

}
