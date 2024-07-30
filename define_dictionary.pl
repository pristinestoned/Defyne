#!/usr/bin/env perl
# This is a simple IRC bot that just rot13 encrypts public messages.
# It responds to "rot13 <text to encrypt>".
use warnings;
use strict;
use POE;
use POE::Component::IRC;
sub CHANNEL () { "#icqchat" }

# Create the component that will represent an IRC network.
my ($irc) = POE::Component::IRC->spawn();

# Create the bot session.  The new() call specifies the events the bot
# knows about and the functions that will handle those events.
POE::Session->create(
  inline_states => {
    _start     => \&bot_start,
    irc_001    => \&on_connect,
    irc_public => \&on_public,
  },
);

# The bot session has started.  Register this bot with the "magnet"
# IRC component.  Select a nickname.  Connect to a server.
sub bot_start {
  $irc->yield(register => "all");
  my $nick = 'rot13' . $$ % 1000;
  $irc->yield(
    connect => {
      Nick     => $nick,
      Username => 'rotchef',
      Ircname  => 'IRC Multifunction Robot',
      Server   => 'irc.icqchat.net',
      Port     => '6667',
    }
  );
}

# The bot has successfully connected to a server.  Join a channel.
sub on_connect {
  $irc->yield(join => CHANNEL);
}

# The bot has received a public message.  Parse it for commands, and
# respond to interesting things.
sub on_public {
  my ($kernel, $who, $where, $msg) = @_[KERNEL, ARG0, ARG1, ARG2];
  my $nick    = (split /!/, $who)[0];
  my $channel = $where->[0];
  my $ts      = scalar localtime;
  print " [$ts] <$nick:$channel> $msg\n";

  if (my ($rot13) = $msg =~ /rot13 (.+)/) {
    $rot13 =~ tr[a-zA-Z][n-za-mN-ZA-M];

    # Send a response back to the server.
    $irc->yield(privmsg => CHANNEL, $rot13);
  }
  elsif ($rot13 = $msg =~ /define: (.+)/) {
    my @rot13new = `wn $1 -over`;
    if (!@rot13new) {
      $irc->yield(privmsg => CHANNEL, "Term: $1 not found in the database.");
    }
    else {
      foreach (@rot13new) {
        chomp($_);
        $irc->yield(privmsg => CHANNEL, $_);
        sleep(1);
      }
    }
  }
}

# Run the bot until it is done.
$poe_kernel->run();
exit 0;
