use GLib::Timeout;
use GTK::Main;
use GTK::Window;

sub nextTitle {
  ('a'..'z').pick( (1..20).pick ).join;
}

GTK::Main.init;

my $win = new GTK::Window.new( nextTitle() );
$win.destroy.tap({
    GTK::Main.quit();
});
$win.show-all;

GLib::Timeout.add(5000, -> *@a {
    $win.title = nextTitle;
    G_SOURCE_CONTINUE;
});

GTK::Main.run;
