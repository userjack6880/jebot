# -----------------------------------------------------------------------------
#
# JEBot - a Perl-based Discord Bot
# Copyright (C) 2022 - John Bradley (userjack6880)
#
# dclient
#   A modification of the AnyEvent Discord Client by Eric Wastl
#
#   Original, or "Standard Version" Copyright (C) 2019 Eric Wastl
#     The Standard Version is licensed under Artistic License 2.0
#     Available at: https://github.com/topaz/perl-AnyEvent-Discord-Client
#
#     For documentation on how this Modified Version differs from the
#     Standard Version, please read README.md
#
# Available at: https://github.com/userjack6880/jebot
#
# -----------------------------------------------------------------------------
#
# Thie file is part of the JEBot, a Perl-based Discord bot.
#
# JEBot is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# -----------------------------------------------------------------------------

package dclient;
use warnings;
use strict;

use AnyEvent::WebSocket::Client;
use LWP::UserAgent;
use JSON;
use URI;
use HTTP::Request;
use HTTP::Headers;
use AnyEvent::HTTP;

my $debug = 0;

sub new {
  my ($class, %args) = @_;

  my $self = {
    token => delete($args{token}),
    api_root => delete($args{api_root}) // 'https://discordapp.com/api',
    prefix => delete($args{prefix}) // "!",
    commands => delete($args{commands}) // {},
    status => delete($args{status}) // "nothing!",

    ua => LWP::UserAgent->new(),
    api_useragent => "DiscordBot (https://github.com/topaz/perl-AnyEvent-Discord-Client, 0)",

    user => undef,
    guilds => {},
    channels => {},
    roles => {},

    gateway => undef,
    conn => undef,
    websocket => undef,
    heartbeat_timer => undef,
    last_seq => undef,
    reconnect_delay => 1,
  };

  die "cannot construct new $class without a token parameter" unless defined $self->{token};
  die "unrecognized extra parameters were given to $class->new" if %args;

  return bless $self, $class;
}

sub commands { $_[0]{commands} }
sub user     { $_[0]{user}     }
sub guilds   { $_[0]{guilds}   }
sub channels { $_[0]{channels} }
sub roles    { $_[0]{roles}    }

my %event_handler = (
  READY => sub {
    my ($self, $d) = @_;
    $self->{user} = $d->{user};
    print "logged in as $self->{user}{username}.\n";
    print "ready!\n\n";

    # automatically set status
    print "setting status...\n";
    print " - \"Playing $self->{status}\"\n\n";
    $self->websocket_send(3, {
      since => undef,
      game => {
        name => $self->{status},
        type => 0
      },
      status => "online",
      afk => "false"
    });
  },
  GUILD_CREATE => sub {
    my ($self, $d) = @_;
    $self->{guilds}{$d->{id}} = $d;
    $self->{channels}{$_->{id}} = {%$_, guild_id=>$d->{id}} for @{$d->{channels}};
    $self->{roles}{$_->{id}}    = {%$_, guild_id=>$d->{id}} for @{$d->{roles}};
    print "created guild $d->{id} ($d->{name})\n";
  },
  CHANNEL_CREATE => sub {
    my ($self, $d) = @_;
    $self->{channels}{$d->{id}} = $d;
    push @{$self->{guilds}{$d->{guild_id}}{channels}}, $d if $d->{guild_id};
    print "created channel $d->{id} ($d->{name}) of guild $d->{guild_id} ($self->{guilds}{$d->{guild_id}}{name})\n";
  },
  CHANNEL_UPDATE => sub {
    my ($self, $d) = @_;
    %{$self->{channels}{$d->{id}}} = %$d;
    print "updated channel $d->{id} ($d->{name}) of guild $d->{guild_id} ($self->{guilds}{$d->{guild_id}}{name})\n";
  },
  CHANNEL_DELETE => sub {
    my ($self, $d) = @_;
    @{$self->{guilds}{$d->{guild_id}}{channels}} = grep {$_->{id} != $d->{id}} @{$self->{guilds}{$d->{guild_id}}{channels}} if $d->{guild_id};
    delete $self->{channels}{$d->{id}};
    print "deleted channel $d->{id} ($d->{name}) of guild $d->{guild_id} ($self->{guilds}{$d->{guild_id}}{name})\n";
  },
  GUILD_ROLE_CREATE => sub {
    my ($self, $d) = @_;
    $self->{roles}{$d->{role}{id}} = $d->{role};
    push @{$self->{guilds}{$d->{guild_id}}{roles}}, $d->{role} if $d->{guild_id};
    print "created role $d->{role}{id} ($d->{role}{name}) of guild $d->{guild_id} ($self->{guilds}{$d->{guild_id}}{name})\n";
  },
  GUILD_ROLE_UPDATE => sub {
    my ($self, $d) = @_;
    %{$self->{roles}{$d->{role}{id}}} = %{$d->{role}};
    print "updated role $d->{role}{id} ($d->{role}{name}) of guild $d->{guild_id} ($self->{guilds}{$d->{guild_id}}{name})\n";
  },
  GUILD_ROLE_DELETE => sub {
    my ($self, $d) = @_;
    @{$self->{guilds}{$d->{guild_id}}{roles}} = grep {$_->{role}{id} != $d->{role}{id}} @{$self->{guilds}{$d->{guild_id}}{roles}} if $d->{guild_id};
    delete $self->{roles}{$d->{role}{id}};
    print "deleted role $d->{role}{id} ($d->{role}{name}) of guild $d->{guild_id} ($self->{guilds}{$d->{guild_id}}{name})\n";
  },
  TYPING_START => sub {},
  MESSAGE_CREATE => sub {
    my ($self, $msg) = @_;
    my $channel = $self->{channels}{$msg->{channel_id}};
    my $guild = $self->{guilds}{$channel->{guild_id}};

    #(my $hrcontent = $msg->{content) =~ s/[\x00-\x
    print "[$guild->{name} ($guild->{id}) / $channel->{name} ($channel->{id})] <$msg->{author}{username}> $msg->{content}\n";
    #print STDERR join(",",unpack("U*", $msg->{content}))."\n";
    return if $msg->{author}{id} == $self->{user}{id};

    if ($msg->{content} =~ /^\Q$self->{prefix}\E(\S+)(?:\s+(.*?))?\s*$/) {
      my ($cmd, $args) = (lc $1, defined $2 ? $2 : "");
      if (exists $self->{commands}{$cmd}) {
        $self->{commands}{$cmd}($self, $args, $msg, $channel, $guild);
      }
    }
  },
);

sub connect {
  my ($self) = @_;

  if (!defined $self->{gateway}) {
    # look up gateway url
    my $gateway_data = $self->api_sync(GET => "/gateway");
    my $gateway = $gateway_data->{url};
    die 'invalid gateway' unless $gateway =~ /^wss\:\/\//;
    $gateway = new URI($gateway);
    $gateway->path("/") unless length $gateway->path;
    $gateway->query_form(v=>6, encoding=>"json");
    $self->{gateway} = "$gateway";
  }

  print "- Connecting to $self->{gateway}...\n";

  $self->{reconnect_delay} *= 2;
  $self->{reconnect_delay} = 5*60 if $self->{reconnect_delay} > 5*60;

  $self->{websocket} = AnyEvent::WebSocket::Client->new(max_payload_size => 1024*1024);
  $self->{websocket}->connect($self->{gateway})->cb(sub {
    $self->{conn} = eval { shift->recv };
    if($@) {
      print "$@\n";
      return;
    }

    print "- Websocket connected to $self->{gateway}.\n";
    $self->{reconnect_delay} = 1;

    # send "identify" op
    $self->websocket_send(2, {
      token => $self->{token},
      properties => {
        '$os' => "linux",
        '$browser' => "zenbotta",
        '$device' => "zenbotta",
        '$referrer' => "",
        '$referring_domain' => ""
      },
      compress => JSON::false,
      large_threshold => 250,
      shard => [0, 1],
    });

    $self->{conn}->on(each_message => sub {
      my($connection, $message) = @_;
      my $msg = decode_json($message->{body});
      die "invalid message" unless ref $msg eq 'HASH' && defined $msg->{op};

      $self->{last_seq} = 0+$msg->{s} if defined $msg->{s};

      if ($msg->{op} == 0) { #dispatch
        print "\e[1;30mdispatch event $msg->{t}:".Dumper($msg->{d})."\e[0m\n" if $debug;
        $event_handler{$msg->{t}}($self, $msg->{d}) if $event_handler{$msg->{t}};
      } elsif ($msg->{op} == 10) { #hello
        $self->{heartbeat_timer} = AnyEvent->timer(
          after => $msg->{d}{heartbeat_interval}/1e3,
          interval => $msg->{d}{heartbeat_interval}/1e3,
          cb => sub {
            $self->websocket_send(1, $self->{last_seq});
          },
        );
      } elsif ($msg->{op} == 11) { #heartbeat ack
        # ignore for now; eventually, notice missing ack and reconnect
      } else {
        print "\e[1;30mnon-event message op=$msg->{op}:".Dumper($msg)."\e[0m\n" if $debug;
      }
    });

    $self->{conn}->on(parse_error => sub {
      my ($connection, $error) = @_;
      print "parse_error: $error\n";
      exit;
    });

    $self->{conn}->on(finish => sub {
      my($connection) = @_;
      print "Disconnected! Reconnecting in five seconds...\n";
      my $reconnect_timer; $reconnect_timer = AnyEvent->timer(
        after => $self->{reconnect_delay},
        cb => sub {
          $self->connect();
          $reconnect_timer = undef;
        },
      );
    });
  });
}

sub add_commands {
  my ($self, %commands) = @_;
  $self->{commands}{$_} = $commands{$_} for keys %commands;
}

sub api_sync {
  my ($self, $method, $path, $data) = @_;

  my $resp = $self->{ua}->request(HTTP::Request->new(
    uc($method),
    $self->{api_root} . $path,
    HTTP::Headers->new(
      Authorization => "Bot $self->{token}",
      User_Agent => $self->{api_useragent},
      ($data ? (Content_Type => "application/json") : ()),
      (
          !defined $data ? ()
        : ref $data ? ("Content_Type" => "application/json")
        : ("Content_Type" => "application/x-www-form-urlencoded")
      ),
    ),
    (
        !defined $data ? undef
      : ref $data ? encode_json($data)
      : $data
    ),
  ));

  if (!$resp->is_success) {
    return undef;
  }
  if ($resp->header("Content-Type") eq 'application/json') {
    return JSON::decode_json($resp->decoded_content);
  } else {
    return 1;
  }
}

sub websocket_send {
  my ($self, $op, $d) = @_;
  die "no connection!" unless $self->{conn};

  $self->{conn}->send(encode_json({op=>$op, d=>$d}));
}

sub say {
  my ($self, $channel_id, $message) = @_;
  $self->api(POST => "/channels/$channel_id/messages", {content => $message});
}

sub typing {
  my ($self, $channel) = @_;
  return AnyEvent->timer(
    after => 0,
    interval => 5,
    cb => sub {
      $self->api(POST => "/channels/$channel->{id}/typing", '');
    },
  );
}

sub api {
  my ($self, $method, $path, $data, $cb) = @_;
  http_request(
    uc($method) => $self->{api_root} . $path,
    timeout => 5,
    recurse => 0,
    headers => {
      referer => undef,
      authorization => "Bot $self->{token}",
      "user-agent" => $self->{api_useragent},
      (
          !defined $data ? ()
        : ref $data ? ("content-type" => "application/json")
        : ("content-type" => "application/x-www-form-urlencoded")
      ),
    },
    (
        !defined $data ? ()
      : ref $data ? (body => encode_json($data))
      : (body => $data)
    ),
    sub {
      my ($body, $hdr) = @_;
      return unless $cb;
      $cb->(!defined $body ? undef : defined $hdr->{"content-type"} && $hdr->{"content-type"} eq 'application/json' ? decode_json($body) : 1, $hdr);
    },
  );
}

1;