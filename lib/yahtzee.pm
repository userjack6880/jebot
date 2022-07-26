#!/usr/bin/perl -w

# -----------------------------------------------------------------------------
#
# JEBot - a Perl-based Discord Bot
# Copyright (C) 2022 - John Bradley (userjack6880)
#
# yahtzee
#   implementation of Yahtzee for JEBot
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

package yahtzee;

use strict;
use warnings;
use List::Util qw(sum);

# create yahtzee object
sub new{
	my $class = shift;

	my $self = bless {}, $class;
}

# create new game
sub create_game{
	my ($self, $userID, $username, $gameID) = @_;

	return 1 if $self->{$gameID};

	# initialize the new game with an ID and the ID of the user that initiated the game creation
	$self->{$gameID}{gamestatus} = 1;

	$self->{$gameID}{$userID} = { 
	  'username'  => $username,
	  'filled'    => 0,
	  'lastRoll'  => '',
	  'numRoll'   => 0,
	  'scoreCard' => {
	    'ones'   => { status => 0, score => 0 },
	    'twos'   => { status => 0, score => 0 },
	    'threes' => { status => 0, score => 0 },
	    'fours'  => { status => 0, score => 0 },
	    'fives'  => { status => 0, score => 0 },
	    'sixes'  => { status => 0, score => 0 },
	    '3ofk'   => { status => 0, score => 0 },
	    '4ofk'   => { status => 0, score => 0 },
	    'sstra'  => { status => 0, score => 0 },
	    'lstra'  => { status => 0, score => 0 },
	    'fh'     => { status => 0, score => 0 },
		  'yaht'   => { status => 0, score => 0, elig => 1 },
	    'chance' => { status => 0, score => 0 }
	  }
	};
	return 0;
}

# add user
sub add_user{
	my ($self, $userID, $username, $gameID) = @_;

	return 2 if !$self->{$gameID};
	return 1 if $self->{$gameID}{$userID};

	print "\nadding user\n";
	$self->{$gameID}{$userID} = { 
	  'username'  => $username,
	  'filled'    => 0,
	  'lastRoll'  => '',
	  'numRoll'   => 0,
	  'scoreCard' => {
	    'ones'   => { status => 0, score => 0 },
	    'twos'   => { status => 0, score => 0 },
	    'threes' => { status => 0, score => 0 },
	    'fours'  => { status => 0, score => 0 },
	    'fives'  => { status => 0, score => 0 },
	    'sixes'  => { status => 0, score => 0 },
	    '3ofk'   => { status => 0, score => 0 },
	    '4ofk'   => { status => 0, score => 0 },
	    'sstra'  => { status => 0, score => 0 },
	    'lstra'  => { status => 0, score => 0 },
	    'fh'     => { status => 0, score => 0 },
		  'yaht'   => { status => 0, score => 0, elig => 1 },
	    'chance' => { status => 0, score => 0 }
	  }
	};
	return 0;
}

# remove user
sub remove_user{
	my ($self, $userID, $gameID) = @_;

	return 2 if !$self->{$gameID};
	return 1 if !$self->{$gameID}{$userID};

	print "\nremoving user\n";
	delete($self->{$gameID}{$userID}) if $self->{$gameID}{$userID};
	return 0;
}

# end game
sub end_game{
	my ($self, $gameID) = @_;

	return 1 if !$self->{$gameID};

	delete($self->{$gameID});
	return 0;
}

# user roll
sub roll{
	my ($self, $gameID, $userID, $hold) = @_;
	my $roll;

	return 1 if !$self->{$gameID}{$userID};

	# if user has already rolled 3 times or has filled all 13 categories, don't let them roll again and return a 0
	if ($self->{$gameID}{$userID}{numRoll} == 3 || $self->{$gameID}{$userID}{filled} == 13 ) { return 2; }	

	if (!$hold) {
		$roll = int(rand(6))+1;
		for (1..4) { $roll = join(",", $roll, int(rand(6))+1); }
		$self->{$gameID}{$userID}{lastRoll} = $roll;
	} else {
		my @rsplit = split(",", $self->{$gameID}{$userID}{lastRoll});

		for (my $i = 0; $i < 5; $i++) {
			my $die = $i+1;
			next if($hold =~ /$die/);
			$rsplit[$i] = int(rand(6))+1;
		}
		$roll = join(",", @rsplit);
		$self->{$gameID}{$userID}{lastRoll} = $roll;
	}
	$self->{$gameID}{$userID}{numRoll}++;

	return 0;
}

# apply roll to score
sub apply{
	my ($self, $gameID, $userID, $category) = @_;
	my @roll = split(",", $self->{$gameID}{$userID}{lastRoll});

	# don't let the user try to apply a roll if they haven't rolled at all
	return 2 if $self->{$gameID}{$userID}{numRoll} == 0;

	# sort the roll, it'll help later
	for (my $i = 1; $i < 5; $i++) {
		for (my $j = $i; $j > 0; $j--) {
			($roll[$j], $roll[$j-1]) = ($roll[$j-1], $roll[$j]) if $roll[$j-1] > $roll[$j];
		}
	}

	# upper scores
	if ($category eq 'ones' && $self->{$gameID}{$userID}{scoreCard}{ones}{status} == 0) {
		foreach (@roll) { $self->{$gameID}{$userID}{scoreCard}{ones}{score}++ if $_ eq '1'; }
		$self->{$gameID}{$userID}{scoreCard}{ones}{status} = 1;
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}
	if ($category eq 'twos' && $self->{$gameID}{$userID}{scoreCard}{twos}{status} == 0) {
		foreach (@roll) { $self->{$gameID}{$userID}{scoreCard}{twos}{score} += 2 if $_ eq '2'; }
		$self->{$gameID}{$userID}{scoreCard}{twos}{status} = 1;
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}
	if ($category eq 'threes' && $self->{$gameID}{$userID}{scoreCard}{threes}{status} == 0) {
		foreach (@roll) { $self->{$gameID}{$userID}{scoreCard}{threes}{score} += 3 if $_ eq '3'; }
		$self->{$gameID}{$userID}{scoreCard}{threes}{status} = 1;
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}
	if ($category eq 'fours' && $self->{$gameID}{$userID}{scoreCard}{fours}{status} == 0) {
		foreach (@roll) { $self->{$gameID}{$userID}{scoreCard}{fours}{score} += 4 if $_ eq '4'; }
		$self->{$gameID}{$userID}{scoreCard}{fours}{status} = 1;
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}
	if ($category eq 'fives' && $self->{$gameID}{$userID}{scoreCard}{fives}{status} == 0) {
		foreach (@roll) { $self->{$gameID}{$userID}{scoreCard}{fives}{score} += 5 if $_ eq '5'; }
		$self->{$gameID}{$userID}{scoreCard}{fives}{status} = 1;
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}
	if ($category eq 'sixes' && $self->{$gameID}{$userID}{scoreCard}{sixes}{status} == 0) {
		foreach (@roll) { $self->{$gameID}{$userID}{scoreCard}{sixes}{score} += 6 if $_ eq '6'; }
		$self->{$gameID}{$userID}{scoreCard}{sixes}{status} = 1;
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}

	# lower scores

	# chance
	if ($category eq 'chance' && $self->{$gameID}{$userID}{scoreCard}{chance}{status} == 0) {
		$self->{$gameID}{$userID}{scoreCard}{chance}{score} = sum(@roll);
		$self->{$gameID}{$userID}{scoreCard}{chance}{status} = 1;
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}

	# count how many cards are the same
	my $count = 1;
	my @max   = (0,0);
  my @max2  = (0,0);
	
	for (my $i = 1; $i < 5; $i++) {
		if ($roll[$i] == $roll[$i-1]) { $count++; }
		else {
			if ($count > $max[0]) {           # if the count is the biggest number, move all down
				@max2 = @max;
				$max[0] = $count;
				$max[1] = $roll[$i-1];
				$count = 1;
			} elsif ($count > $max2[0]) {     # if it's not, see if it's the second biggest, move all down
				$max2[0] = $count;
				$max2[1] = $roll[$i-1];
				$count = 1;
			} else { $count = 1; }         # and if it's bigger than nothing, just zero the count
		}
	}
	if ($count > $max[0]) {           # if the count is the biggest number, move all down
		@max2 = @max;
		$max[0] = $count;
		$max[1] = $roll[4];
	} elsif ($count > $max2[0]) {     # if it's not, see if it's the second biggest, move all down
		$max2[0] = $count;
		$max2[1] = $roll[4]
	}

	# joker check
	if ($category eq '3ofk' || 
	    $category eq '4ofk' || 
	    $category eq 'sstra' || 
	    $category eq 'lstra' ||
	    $category eq 'fh') {
		return 0 if ($max[0] == 5 && $self->{$gameID}{$userID}{scoreCard}{yaht}{status} == 0); # without a yahtzee score
		return 0 if ($max[0] == 5 && $roll[0] == 1 && $self->{$gameID}{$userID}{scoreCard}{ones}{status} == 0); # without upper score
		return 0 if ($max[0] == 5 && $roll[0] == 2 && $self->{$gameID}{$userID}{scoreCard}{twos}{status} == 0); # without upper score
		return 0 if ($max[0] == 5 && $roll[0] == 3 && $self->{$gameID}{$userID}{scoreCard}{threes}{status} == 0); # without upper score
		return 0 if ($max[0] == 5 && $roll[0] == 4 && $self->{$gameID}{$userID}{scoreCard}{fours}{status} == 0); # without upper score
		return 0 if ($max[0] == 5 && $roll[0] == 5 && $self->{$gameID}{$userID}{scoreCard}{fives}{status} == 0); # without upper score
		return 0 if ($max[0] == 5 && $roll[0] == 6 && $self->{$gameID}{$userID}{scoreCard}{sixes}{status} == 0); # without upper score
	}

	# 3-of-a-kind
	if ($category eq '3ofk' && $self->{$gameID}{$userID}{scoreCard}{'3ofk'}{status} == 0 && ($max[0] == 3 ||
	                                                                                        ($max[0] == 5 && $self->{$gameID}{$userID}{scoreCard}{yaht}{elig} == 0))) {
		$self->{$gameID}{$userID}{scoreCard}{'3ofk'}{score} = sum(@roll);
		$self->{$gameID}{$userID}{scoreCard}{'3ofk'}{status} = 1;
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}

	# 4-of-a-kind
	if ($category eq '4ofk' && $self->{$gameID}{$userID}{scoreCard}{'4ofk'}{status} == 0 && ($max[0] == 4 ||
	                                                                                        ($max[0] == 5 && $self->{$gameID}{$userID}{scoreCard}{yaht}{elig} == 0))) {
		$self->{$gameID}{$userID}{scoreCard}{'4ofk'}{score} = sum(@roll);
		$self->{$gameID}{$userID}{scoreCard}{'4ofk'}{status} = 1;
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}

	# full house
	if ($category eq 'fh' && $self->{$gameID}{$userID}{scoreCard}{fh}{status} == 0 && (($max[0] == 3 && $max2[0] == 2) ||
	                                                                                   ($max[0] == 2 && $max2[0] == 3) ||
	                                                                                   ($max[0] == 5 && $self->{$gameID}{$userID}{scoreCard}{yaht}{elig} == 0))) {
		$self->{$gameID}{$userID}{scoreCard}{fh}{score} = 25;
		$self->{$gameID}{$userID}{scoreCard}{fh}{status} = 1;
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}

	# count consecutive cards
	$count = 1;
	for (my $i = 1; $i < 5; $i++) {
		if ($roll[$i] == $roll[$i-1]+1) { $count++; }
		elsif ($roll[$i] == $roll[$i-1]) { next; }
		else { $count = 1; }
	}

	# small straight
	if ($category eq 'sstra' && $self->{$gameID}{$userID}{scoreCard}{sstra}{status} == 0 && ($count == 4 ||
	                                                                                        ($max[0] == 5 && $self->{$gameID}{$userID}{scoreCard}{yaht}{elig} == 0))) {
		$self->{$gameID}{$userID}{scoreCard}{sstra}{score} = 30;
		$self->{$gameID}{$userID}{scoreCard}{sstra}{status} = 1;
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}

	# large straight
	if ($category eq 'lstra' && $self->{$gameID}{$userID}{scoreCard}{lstra}{status} == 0 && ($count == 5 ||
	                                                                                        ($max[0] == 5 && $self->{$gameID}{$userID}{scoreCard}{yaht}{elig} == 0))) {
		$self->{$gameID}{$userID}{scoreCard}{lstra}{score} = 40;
		$self->{$gameID}{$userID}{scoreCard}{lstra}{status} = 1;
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}

	# yahtzee
	if ($category eq 'yaht' && $self->{$gameID}{$userID}{scoreCard}{yaht}{status} == 0 && $max[0] == 5) {
		$self->{$gameID}{$userID}{scoreCard}{yaht}{score} = 50;
		$self->{$gameID}{$userID}{scoreCard}{yaht}{status} = 1;
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}

	if ($category eq 'yaht' && $self->{$gameID}{$userID}{scoreCard}{yaht}{elig} == 1 && $max[0] == 5) {
		$self->{$gameID}{$userID}{scoreCard}{yaht}{score} = 100;
		$self->{$gameID}{$userID}{scoreCard}{yaht}{elig} = 0;
		return 2;
	}

	if ($category eq 'lost' || $category eq 'lose' || $category eq 'none') {
		$self->{$gameID}{$userID}{filled}++;
		$self->{$gameID}{$userID}{numRoll} = 0;
		return 0;
	}

	return 1;
}

# return values

sub get_roll{
	my ($self, $gameID, $userID) = @_;
	return $self->{$gameID}{$userID}{lastRoll};
}

sub get_users{
	my ($self, $gameID) = @_;
	my @userlist;

	foreach my $userID (keys %{$self->{$gameID}}) {
		next if $userID eq 'gamestatus';
		push(@userlist, $userID);
	}
	return \@userlist;
}

sub get_gameStatus{
	my ($self, $gameID) = @_;

	return 1 if !$self->{$gameID};
	return 0 if $self->{$gameID}{gamestatus};
}

sub get_scoreCard{
	my ($self, $gameID, $userID) = @_;
	return $self->{$gameID}{$userID}{scoreCard};
}

sub get_filled{
	my ($self, $gameID, $userID) = @_;
	return $self->{$gameID}{$userID}{filled};
}

sub calculate_score{
	my ($self, $gameID, $userID) = @_;
	print "gameID: $gameID\nuserID: $userID\n\n";
	# add upper scores first
	my $upperscore = sum($self->{$gameID}{$userID}{scoreCard}{ones}{score},
	                     $self->{$gameID}{$userID}{scoreCard}{twos}{score},
	                     $self->{$gameID}{$userID}{scoreCard}{threes}{score},
	                     $self->{$gameID}{$userID}{scoreCard}{fours}{score},
	                     $self->{$gameID}{$userID}{scoreCard}{fives}{score},
	                     $self->{$gameID}{$userID}{scoreCard}{sixes}{score});
	# add bonus if greater than 63
	$upperscore += 35 if $upperscore > 62;

	my $totalscore = sum($upperscore,
	                     $self->{$gameID}{$userID}{scoreCard}{chance}{score},
	                     $self->{$gameID}{$userID}{scoreCard}{'3ofk'}{score},
	                     $self->{$gameID}{$userID}{scoreCard}{'4ofk'}{score},
	                     $self->{$gameID}{$userID}{scoreCard}{fh}{score},
	                     $self->{$gameID}{$userID}{scoreCard}{sstra}{score},
	                     $self->{$gameID}{$userID}{scoreCard}{lstra}{score},
	                     $self->{$gameID}{$userID}{scoreCard}{yaht}{score});
	return $totalscore;
}

# debug subroutines
sub print_scoreCard{
	my ($self, $gameID, $userID) = @_;
	my $scoreCard = $self->get_scoreCard($gameID,$userID);
	my $score = $self->calculate_score($gameID,$userID);
	my $filled = $self->get_filled($gameID,$userID);
	print "Category       | Score\n";
	print "Ones           | $scoreCard->{ones}{score}\n" if $scoreCard->{ones}{status} == 1;
	print "Twos           | $scoreCard->{twos}{score}\n" if $scoreCard->{twos}{status} == 1;
	print "Threes         | $scoreCard->{threes}{score}\n" if $scoreCard->{threes}{status} == 1;
	print "Fours          | $scoreCard->{fours}{score}\n" if $scoreCard->{fours}{status} == 1;
	print "Fives          | $scoreCard->{fives}{score}\n" if $scoreCard->{fives}{status} == 1;
	print "Sixes          | $scoreCard->{sixes}{score}\n" if $scoreCard->{sixes}{status} == 1;
	print "---------------|-------\n";
	print "3-of-a-kind    | $scoreCard->{'3ofk'}{score}\n" if $scoreCard->{'3ofk'}{status} == 1;
	print "4-of-a-kind    | $scoreCard->{'4ofk'}{score}\n" if $scoreCard->{'4ofk'}{status} == 1;
	print "Full House     | $scoreCard->{fh}{score}\n" if $scoreCard->{fh}{status} == 1;
	print "Small Straight | $scoreCard->{sstra}{score}\n" if $scoreCard->{sstra}{status} == 1;
	print "Large Straight | $scoreCard->{lstra}{score}\n" if $scoreCard->{lstra}{status} == 1;
	print "Yahtzee        | $scoreCard->{yaht}{score}\n" if $scoreCard->{yaht}{status} == 1;
	print "Chance         | $scoreCard->{chance}{score}\n" if $scoreCard->{chance}{status} == 1;
	print "---------------|-------\n";
	print "Score          | $score\n";
	print "Filled Categories: $filled\n";
}

sub roll_perfect{
	my ($self, $gameID, $userID, $perfect) = @_;
  $self->{$gameID}{$userID}{lastRoll} = $perfect;
	$self->{$gameID}{$userID}{numRoll} = 1;
	return 0;
}

1;
