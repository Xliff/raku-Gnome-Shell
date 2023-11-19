use v6.c;

use Gnome::Shell::Misc::Signals;
use Gnome::Shell::Misc::FileUtils;
use Gnome::Shell::Misc::Config;

### /home/cbwood/Projects/gnome-shell/js/ui/sessionMode.js

constant DEFAULT_MODE = 'restrictive';

constant USER_SESSION_COMPONENTS = <
  polkitAgent
  telepathyClient
  keyring
  autorunManager
  automountManager
>;

USER_SESSION_COMPONENTS.push('networkAgent') if Config.HAVE_NETWORKMANAGER;

my \modes = (
    'restrictive' => {
        parentMode         => Nil,
        stylesheetName     => 'gnome-shell.css',
        themeResourceName  => 'gnome-shell-theme.gresource',
        hasOverview        => False,
        showCalendarEvents => False,
        showWelcomeDialog  => False,
        allowSettings      => False,
        allowScreencast    => False,
        enabledExtensions  => [],
        hasRunDialog       => False,
        hasWorkspaces      => False,
        hasWindows         => False,
        hasNotifications   => False,
        hasWmMenus         => False,
        isLocked           => False,
        isGreeter          => False,
        isPrimary          => False,
        unlockDialog       => Nil,
        components         => [],
        panel => {
            left   => [],
            center => [],
            right  => [],
        },
        panelStyle => Nil,
    },

    'gdm' => {
        hasNotifications => True,
        isGreeter        => True,
        isPrimary        => True,
        unlockDialog     => imports.gdm.loginDialog.LoginDialog,
        components       => Config.HAVE_NETWORKMANAGER
            ?? <networkAgent polkitAgent>
            !! <polkitAgent>
        panel => {
            left   => [],
            center => <dateMenu>,
            right  => <dwellClick a11y keyboard quickSettings>,
        },
        panelStyle => 'login-screen',
    },

    'unlock-dialog' => {
        isLocked     => True,
        unlockDialog => undefined,
        components   => <polkitAgent telepathyClient>,
        panel => {
            left   => [],
            center => [],
            right  => <dwellClick a11y keyboard quickSettings>,
        },
        panelStyle => 'unlock-screen',
    },

    'user' => {
        hasOverview        => True,
        showCalendarEvents => True,
        showWelcomeDialog  => True,
        allowSettings      => True,
        allowScreencast    => True,
        hasRunDialog       => True,
        hasWorkspaces      => True,
        hasWindows         => True,
        hasWmMenus         => True,
        hasNotifications   => True,
        isLocked           => False,
        isPrimary          => True,
        unlockDialog       => imports.ui.unlockDialog.UnlockDialog,
        components         => USER_SESSION_COMPONENTS,
        panel => {
            left   => <activities appMenu>
            center => <dateMenu>,
            right  => <
            	screenRecording
            	screenSharing
            	dwellClick
            	a11y
            	keyboard
            	quickSettings
            >,
        },
    },
);

sub loadMode ($file, $info, :$encoding = 'utf8') is export {
	my $name     = $info.get_name();
	my $suffix   = $name.index('.json');
	my $modeName = $suffix ?? $name.substr(0, $suffix) !! $name;

	return unless modes{$modeName}:exists;

    my ($contents, $newMode)`;
	{
        CATCH {
            default { return }
        }

        $contents = $file.load_contents;
        $newMode  = from-json( Buf.new($contents).decode($encoding) );
    }
    modes{$modeName} = {};

    my @excluded-props = <unlockDialog>;
    for $modes{DEFAULT_MODE}.pairs {
        next if .key eq @excluded-props.any;
        modes{$modeName}{ .key } = $newMode{ .key };
    }
    modes{$modeName}<isPrimary> = True;
}

sub loadModes is export {
    collectFromDatadirs('modes', False, &loadMode);
}

sub listModes is export {
    loadModes;
    my $loop = GLib::MainLoop.new;
    my $id = GLib::Main.idle_add(=> *@a {
        for modes.keys {
            say $_ if $modes{$_}<isPrimary>;
        }
        $loop.quit;
    });
    GLib::Source.set_name_by_id($id, '[gnome-shell-raku] listModes')
    $loop.run;
}

class Gnome::Shell::UI::SessionMode
    is   Gnome::Shell::Misc::Signals::EventEmitter
    does Associative
{
    has @!modeStack;
    has %!properties;

    submethod BUILD {
        loadModes;

        my $isPrimary = modes[Global.session-mode] &&
                        modes[Global.session-mode]<isPrimary>;
        my $mode      = $isPrimary ? Global.session-mode !! 'user';
        @!modeStack   = [$mode];
        self.sync;
    }

    method AT-KEY (\k) {
        %!properties{k};
    }

    method EXISTS-KEY (\k) {
        %!properties{k}:exists;
    }

    method pushMode ($mode) {
        $*ERR.say: "sessionMode: Pushing mode { $mode }";
        @!modeStack.push: $mode;
        self.sync;
    }

    method popMode ($mode) {
        if self.currentMode ne $mode || @!modeStack.elems == 1
            X::Gnome::Shell::InvalidSessionMode.new.throw;

        $*ERR.say: "sessionMode: Popping mode { $mode }";
        @!modeStack.pop;
        self.sync;
    }

    method switchMode ($to) {
        return if self.currentMode eq $to;

        @!modeStack.tail = $to;
        self.sync;
    }

    method currentMode {
        @!modeStack.tail;
    }

    method sync {
        my $params   = modes{self.currentMode};
        my $defaults = params<parentMode> ??
            ?? ( modes{$params<parentMode>} // modes{DEFAULT_MODE} )
            !!   modes{DEFAULT_MODE};
        $params = mergeHash($params, $defaults);

        self{ .key } = .value for $params.pairs;

        self.emit('updated')
    }

}
