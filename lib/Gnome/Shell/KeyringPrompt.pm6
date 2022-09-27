use v6.c;

use Method::Also;

use GLib::Raw::Traits;
use Gnome::Shell::Raw::Types;
use Gnome::Shell::Raw::KeyringPrompt;

use GLib::Roles::Implementor;
use GLib::Roles::Object;

our subset ShellKeyringPromptAncestry is export of Mu
  where ShellKeyringPrompt | GObject;

class Gnome::Shell::KeyringPrompt {
  also does GLib::Roles::Object;

  has ShellKeyringPrompt $!skp is implementor;

  submethod BUILD ( :$shell-keyring-prompt ) {
    self.setShellKeyringPrompt($shell-keyring-prompt) if $shell-keyring-prompt;
  }

  method setShellKeyringPrompt (ShellKeyringPromptAncestry $_) {
    my $to-parent;

    $!skp = do {
      when ShellKeyringPrompt {
        $to-parent = cast(GObject, $_);
        $_;
      }

      default {
        $to-parent = $_;
        cast(ShellKeyringPrompt, $_);
      }
    }
    self!setObject($to-parent);
  }

  method Gnome::Shell::Raw::Definitions::ShellKeyringPrompt
    is also<ShellKeyringPrompt>
  { $!skp }

  multi method new (ShellKeyringPromptAncestry $shell-keyring-prompt, :$ref = True) {
    return unless $shell-keyring-prompt;

    my $o = self.bless( :$shell-keyring-prompt );
    $o.ref if $ref;
    $o;
  }

  multi method new {
    my $shell-keyring-prompt = shell_keyring_prompt_new();

    $shell-keyring-prompt ?? self.bless( :$shell-keyring-prompt ) !! Nil;
  }

  # Type: boolean
  method password-visible is rw  is g-property is also<password_visible> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('password-visible', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'password-visible does not allow writing'
      }
    );
  }

  # Type: boolean
  method confirm-visible is rw  is g-property is also<confirm_visible> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('confirm-visible', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'confirm-visible does not allow writing'
      }
    );
  }

  # Type: boolean
  method warning-visible is rw  is g-property is also<warning_visible> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('warning-visible', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'warning-visible does not allow writing'
      }
    );
  }

  # Type: boolean
  method choice-visible is rw  is g-property is also<choice_visible> {
    my $gv = GLib::Value.new( G_TYPE_BOOLEAN );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('choice-visible', $gv);
        $gv.boolean;
      },
      STORE => -> $, Int() $val is copy {
        warn 'choice-visible does not allow writing'
      }
    );
  }

  # Type: MutterClutterText
  method password-actor ( :$raw = False )
    is rw
    is g-property
    is also<password_actor>
  {
    my $gv = GLib::Value.new( Mutter::Clutter::Text.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('password-actor', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Clutter::Text.getTypePair
        );
      },
      STORE => -> $, MutterClutterText() $val is copy {
        $gv.object = $val;
        self.prop_set('password-actor', $gv);
      }
    );
  }

  # Type: StText
  method confirm-actor ( :$raw = False )
    is rw
    is g-property
    is also<confirm_actor>
  {
    my $gv = GLib::Value.new( Mutter::Clutter::Text.get_type );
    Proxy.new(
      FETCH => sub ($) {
        self.prop_get('confirm-actor', $gv);
        propReturnObject(
          $gv.object,
          $raw,
          |Mutter::Clutter::Text.getTypePair
        );
      },
      STORE => -> $, MutterClutterText() $val is copy {
        $gv.object = $val;
        self.prop_set('confirm-actor', $gv);
      }
    );
  }

  method show-password is also<show_password> {
    self.connect($!skp, 'show-password');
  }

  method show-confirm is also<show_confirm> {
    self.connect($!skp, 'show-confirm');
  }

  method cancel {
    shell_keyring_prompt_cancel($!skp);
  }

  method complete {
    shell_keyring_prompt_complete($!skp);
  }

  method get_confirm_actor ( :$raw = False ) is also<get-confirm-actor> {
    propReturnObject(
      shell_keyring_prompt_get_confirm_actor($!skp),
      $raw,
      |Mutter::Clutter::Text.getTypePair
    );
  }

  method get_password_actor ( :$raw = False ) is also<get-password-actor> {
    propReturnObject(
      shell_keyring_prompt_get_password_actor($!skp),
      $raw,
      |Mutter::Clutter::Text.getTypePair
    );
  }

  method set_confirm_actor (MutterClutterText() $confirm_actor)
    is also<set-confirm-actor>
  {
    shell_keyring_prompt_set_confirm_actor($!skp, $confirm_actor);
  }

  method set_password_actor (MutterClutterText() $password_actor)
    is also<set-password-actor>
  {
    shell_keyring_prompt_set_password_actor($!skp, $password_actor);
  }

}
