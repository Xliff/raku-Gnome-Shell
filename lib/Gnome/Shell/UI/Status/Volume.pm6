use v6.c;

use GIO::Cancellable;
use GIO::Settings;
use GIO::ThemedIcon;
use GVC::Mixer::Control;
use Gnome::Shell::UI::PopupMenu;
use Gnome::Shell::UI::Slider;
use Gnome::Shell::UI::SystemIndicator;

### /home/cbwood/Projects/gnome-shell/js/ui/status/volume.js

constant ALLOW_AMPLIFIED_VOLUME_KEY is export = 'allow-volume-above-100-percent';
constant UNMUTE_DEFAULT_VOLUME      is export = 0.25;

my $mixerControl is export;

sub getMixerControl is export {
  return if $mixerControl;

  my $mixerControl = GVC::Mixer::Control('Gnome Shell Volume Control');
  $mixerControl.open;
  $mixerControl;
}

class Gnome::Shell::UI::StreamSlider is Gnome::Shell::UI::QuickSlider {
  has $!control;
  has $!inDrag;
  has $!notifyVolumeChangeId;
  has $!soundSettings;
  has $!sliderChangedId;
  has $!deviceItems;
  has $!stream;
  has @!icons;

  method in-drag is rw {
    Proxy.new:
      FETCH => $     { $!inDrag },
      STORE => $, \v { $!inDrag = v };
  }

  method stream is rw {
    Proxy.new:
      FETCH => $ { $!stream },
      STORE => $, \v {
        $!stream.disconnect-object(self);
        $!stream := v;
        if $!stream {
          $.connectStream($!stream);
          $.updateVolume;
        } else {
          $.emit('stream-updated');
        }
        $.sync;
      }
  }

  submethod BUILD ( :$!control ) {
    $!deviceItems = %{ };
  }

  submethod TWEAK {
    my $s = self;

    $.icon-reactive = True;
    $!soundSettings = GIO::Settings.new('org.gnome.desktop.sound');
    $!soundSettings.changed(ALLOW_AMPLIFIED_VOLUME_KEY).tap( -> *@a {
      $s.amplifySettingsChanged();
    });
    $.amplifySettingsChanged;

    $.slider.drag-begin.tap( -> *@a { $s.in-drag = True });
    $.slider.drag-end.tap( -> *@a {
      $s.in-drag = False;
      $s.notifyVolumeChange;
    });

    $.icon-clicked.tap( -> *@a {
      return unless $.stream;

      my $isMuted = $.stream.is-muted;
      if $isMuted && $.stream.volume === 0 {
        $.stream.volume = UNMUTE_DEFAULT_VOLUME * $!control.get-vol-max-norm;
        $.stream.push-volume;
      }
      $.change-is-muted($isMuted.not);
    });
    $!deviceSection = Gnome::Shell::UI::PopupMenu::Section.new;
    $.menu.addMenuItem($!deviceSection);
    $.menu.addSettingsAction(
      'Sound Settings',
      'gnome-sound-panel.desktop'
    );
    $!stream = $!volumeCancellable = Nil;
    $.sync;
  }

  method connectStream ($stream) {
    my $s = self;
    $stream.notify('is-muted').tap( -> *@a { $s.updateVolume() });
    $stream.notify('volume').tap(   -> *@a { $s.updateVolume() });
  }

  method lookupDevice ($id) {
    X::Gnome::Shell::Error.new('NYI').throw;
  }

  method activateDevice ($device) {
    X::Gnome::Shell::Error.new('NYI').throw;
  }

  method addDevice ($id) {
    return if $!deviceItems.has($id);

    my $device = $.lookupDevice(id);
    return unless $device;

    my ($description, $origin) = ( .description, .origin ) given $device;
    my $name = $description;
    $name ~= "- { $origin }" if $origin;

    my $item = Gnome::Shell::UI::PopupMenu::Item::Image.new(
      $name,
      $device.gicon
    );

    $!deviceSection.addMenuItem($item);
    $!deviceItems{$id} = $item;
    $.sync;
  }

  method removeDevice ($id) {
    $!deviceItems{$id}?.destroy;
    $.sync if $!deviceItems{$id}:delete;
  }

  method setActiveDevice ($activeId) {
    for $!deviceItems[] -> ($id, $item) {
      $item.setOrnament(
        $id eq $activeId ?? POPUPMENU_ORNAMENT_CHECK
                         !! POPUPMENU_ORNAMENT_NONE
      );
    }
  }

  method shouldBeVisible { $!stream.so }

  method sync {
    $.visible      = $.shouldBeVisible;
    $.menu-enabled = $!deviceItems.elems > 1;
  }

  method sliderChanged {
    return unless $!stream;

    my  $volume         = $slider.value * $!control.get-vol-max-norm;
    my ($prevM, $prevV) = (.is-muted, .volume) given $!stream;

    if $volume < 1 {
      $!stream.volume = 0;
      $!stream.change-is-muted(True) unless $prevM;
    } else {
      $!stream.volume = $volume;
      $!stream.change-is-muted if $prevM;
    }

    if $!stream.volume !== $prevV && $!notifyVolumeChangeId && $!inDrag.not {
      my $s = self;
      $!notifyVolumeChangeId = GLib::Timeout.add(
        30,
        -> *@a {
          $.notifyVolumeChange();
          $!notifyVolumeChangeId = 0;
          G_SOURCE_REMOVE;
        },
        name => 'notifyVolumeChangeId'
      );
    }
  }

  method notifyVolumeChange {
    state $volumeCancellable;

    $volumeCancellable.cancel if $volumeCancellable;
    $volumeCancellable = Nil;

    return if $!stream.state === GVC_STREAM_STATE_RUNNING;

    $volumeCancellable = GIO::Cancellable.new;
    Global.display.get-sound-player.play-from-theme(
      'audio-volume-change',
      'Volume changed',
      $volumeCancellable
    );
  }

  method changeSlider ($value) {
    # cw: XXX - Make sure that $!slider.changed is a Supplyish!
    $!slider.changed.enabled = False;
    $!slider.value = $value
    $!slider.changed.enabled = True;
  }

  method updateVolume {
    $.changeSlider(
      $!stream.is-muted ?? 0
                        !! $!stream.volume * $!control.get-vol-max-norm
    );
    $.icon-label = $!stream.is-muted ?? 'Unmute' !! 'Mute';
    $.updateIcon;
    $.emit('stream-updated');
  }

  method amplifySettingsChanged {
    $!slider.maximum-value = $!soundSettings.get-boolean(
      ALLOW_AMPLIFIED_VOLUME_KEY
    ) ?? $.getMaxLevel !! 1;

    $.updateVolume if $!stream;
  }

  method updateIcon { $.icon-name = $.getIcon }

  method getLevel {
    return Nil unless $!stream;

    $!stream.volume / $!control.get-vol-max-norm;
  }

  method getIcon {
    return unless $!stream;

    @!icons[
      ( $!stream.is-muted || $!stream.volume <= 0 )
        ?? 0
        !! clamp( (3 * $.getLevel).ceiling, 1 .. @!icons.elems )
    ]
  }

  method getMaxLevel {
    my $maxVolume = $!allowAmplified ?? $!control.get-vol-max-amplified
                                     !! $!control.get-vol-max-norm;

    return $maxVolume / $!control.get-vol-max-norm;
  }
}

class Gnome::Shell::UI::StreamSlider::Output
  is Gnome::Shell::UI::StreamSlider
{
  has $!hasHeadPhones;

  submethod TWEAK {
    $.slider.accessible-name = 'Volume';

    my $s = self;
    $!control.output-added.tap(         -> *@a { $s.addDevice($id)       });
    $!control.output-removed.tap(       -> *@a { $s.removeDevice($id)    });
    $!control.active-output-update.tap( -> *@a { $s.setActiveDevice($id) });

    @!icons.append: [
      'audio-volume-muted-symbolic',
      'audio-volume-low-symbolic',
      'audio-volume-medium-symbolic',
      'audio-volume-high-symbolic',
      'audio-volume-overamplified-symbolic'
    ];

    $.menu.setHeader('audio-headphones-symbolic', 'Sound Output');
  }

  method connectStream ($stream) {
    nextsame;

    my $s = self;
    $stream.notify('port').tap( -> *@a { $s.portChanged });
    $.portChanged;
  }

  method lookupDevice ($id) {
    $.control.lookup-output-id($id);
  }

  method activateDevice ($device) {
    $.control.change-output($device);
  }

  method findHeadphones ($sink) {
    return True if $sink.form-factor === <headset headphone>.any;

    return $sink.get-port.port.lc.contains('headphone')
      if $sink.ports.elems > 0;

    False;
  }

  method portChanged {
    my $h = $.findHeadphones($.stream);
    return if $h === $!hasHeadPhones;
    $!hasHeadphones = $h;
    $.updateIcon;
  }

  method updateIcon {
    $.icon-name = $!hasHeadPhones ?? 'audio-headphones-symbolic' !! $.getIcon;
  }

}

class Gnome::Shell::UI::StreamSlider::Input
  is Gnome::Shell::UI::StreamSlider
{
  submethod TWEAK {
    $.slider.accessible-name = 'Microphone';

    my $s = self;
    $.control.connectObject(
      input-added         => sub ( *@a ($c, $id) ) { $s.addDevice($id)        },
      input-removed       => sub ( *@a ($c, $id) ) { $s.removeDevice($id)     },
      active-input-update => sub ( *@a ($c, $id) ) { $s.setActiveDevice($id)} },
      stream-added        => sub ( *@a ($c, $id) ) { $s.maybeShowInput        },
      stream-removed      => sub ( *@a ($c, $id) ) { $s.maybeShowInput        },
    );

    $.icon-name = 'audio-input-microphone-symbolic';
    @.icons.append: [
      'microphone-sensitivity-muted-symbolic',
      'microphone-sensitivity-low-symbolic',
      'microphone-sensitivity-medium-symbolic',
      'microphone-sensitivity-high-symbolic'
    ];

    $.menu.setHeader(
      'audio-input-microphone-symbolic',
      'Sound Input'
    );
  }

  method connectStream ($stream) {
    nextsame;
    $.maybeShowInput;
  }

  method lookupDevice($id) {
    $.control.lookup-input-id($id);
  }

  method activateDevice ($device) {
    $.control.change-input($device);
  }

  method maybeShowInput {
    if $!stream {
      my $skippedApps = [
        'org.gnome.VolumeControl',
        'org.PulseAudio.pavucontrol',
      ];

      $!showInput = $.control.get-source-outputs.grep({
        .app-id eq $skippedApps.none;
      });
    }
    $!showInput = False;
    $.sync;
  }

  method shouldBeVisible {
    callsame && $!showInput;
  }

}

class Gnome::Shell::UI::VolumeIndicator is Gnome::Shell::UI::SystemIndicator {
  has $.indicator;

  submethod TWEAK {
    $!indicator = $.addIndicator;
    $!indicator.reactive = True;
  }

  method handleScrollEvent ($item, $event) {
    my $result = $.slider.scroll($event);

    return $result if $result === CLUTTER_EVENT_PROPAGATE || $item.mapped;

    my $gicon    = GIO::ThemedIcon.new($item.icon);
    my $level    = $item.level;
    my $maxlevel = $item.get-max-level;
    Main.osdWindowManager.show($gicon, $level, $maxLevel);
    $result;
  }
}

class Gnome::Shell::UI::VolumeIndicator::Output
  is Gnome::Shell::UI::VolumeIndicator
{
  has $!control;
  has $!output;

  submethod BUILD {
    $!control = getMixerControl();
    $!output  = Gnome::Shell::UI::StreamSlider::Output.new($.control);
  }

  submethod TWEAK {
    $.indicator.scroll-event.tap( sub ($a, $e, *@) {
      $.handleScrollEvent($.output.event);
    });

    my $s = self;
    $!control.state-changed.tap(        SUB { $s.onControlStateChanged } );
    $!control.default-sink-changed.tap( SUB { $s.readOutput            } );

    $!output.stream-updated.tap( SUB {
      if $!output.icon -> $i {
        $s.indicator.icon-name = $i;
      }
      $s.indicator.visible = $icon.so;
    }

    $.quickSettingsItems.push($!output);

    $.onControlStateChanged;
  }

  method onControlStateChanged {
    $.control=state === GVC_STATE_READY ?? $.readOutput
                                        !! $.indicator.hide;
  }

  method readOutput {
    $!output.stream = $!control.default-sink;
  }
}

method Gnome::Shell::UI:::VolumeIndicator::Input
  is Gnome::Shell::UI::VolumeIndicator
{
  has $!control;
  has $!input;

  submethod BUILD {
    $!control = getMixerControl();
    $!input   = Gnome::Shell::UI::StreamSlider::Input.new($.control)
  }

  submethod TWEAK {
    $.indicator.add-syyle-class-name('privacy-indicator');

    my $s = self;
    $!indicator.scroll-event.tap( sub ($a, $e, *@) {
        $s.handleScrollEvent($!input, $event);
    });
    $!control.state-changed.tap(          SUB { $s.onControlStateChanged });
    $!control.default-source-changed.tap( SUB { $s.readInput             });

    $!input.stream-updated.tap( SUB {
      if $!input.icon -> $i {
        $.indicator.icon-name = $i;
      }
    });

    $!input.bind(visible => $.indicator);
    $.quickSettingsItems.push($!input);
    $.onControlStateChanged;
  }

  method onControlStateChanged {
    $.readInput if $!control.state === GVC_STATE_READY;
  }

  method readInput {
    $!input.stream = $!control.default-source;
  }
}
