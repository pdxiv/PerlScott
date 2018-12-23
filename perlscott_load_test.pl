#!/usr/bin/perl
use strict;
use warnings;
use Readonly;
use Carp;
use English qw( -no_match_vars );
our $VERSION = '1.0.0';

Readonly::Scalar my $ACTION_ENTRIES => 8;

# my $game_file = '1_baton.dat';
# my $game_file = '2_timemachine.dat';
# my $game_file = '3_arrow1.dat';
# my $game_file = '4_arrow2.dat';
# my $game_file = '5_pulsar7.dat';
# my $game_file = '6_circus.dat';
# my $game_file = '7_feasibility.dat';
# my $game_file = '8_akyrz.dat';
# my $game_file = '9_perseus.dat';
# my $game_file = 'A_tenlittleindians.dat';
# my $game_file = 'adv01.dat';
# my $game_file = 'adv02.dat';
# my $game_file = 'adv03.dat';
# my $game_file = 'adv04.dat';
# my $game_file = 'adv05.dat';
# my $game_file = 'adv06.dat';
# my $game_file = 'adv07.dat';
# my $game_file = 'adv08.dat';
# my $game_file = 'adv09.dat';
# my $game_file = 'adv10.dat';
# my $game_file = 'adv11.dat';
# my $game_file = 'adv12.dat';
# my $game_file = 'adv13.dat';
# my $game_file = 'adv14a.dat';
# my $game_file = 'B_waxworks.dat';
# my $game_file = 'BOND.DAT';
# my $game_file = 'BURGLAR.DAT';
# my $game_file = 'CONQUEST.DAT';
# my $game_file = 'desert.dat';
# my $game_file = 'GAMMA.DAT';
# my $game_file = 'MAROONED.DAT';
# my $game_file = 'MINER.DAT';
# my $game_file = 'quest1.dat';
# my $game_file = 'romulan.dat';
# my $game_file = 'sampler1.dat';
# my $game_file = 'secret.dat';

open my $handle, '<', $game_file or croak;
my $file_content = do { local $INPUT_RECORD_SEPARATOR; <$handle> };
close $handle or croak;

# Define pattern for finding three types of newlines
my $unix            = qr/(?<![\x0d])[\x0a](?![\x0d])/msx;
my $apple           = qr/(?<![\x0a])[\x0d](?![\x0a])/msx;
my $dos             = qr/(?<![\x0d])[\x0d][\x0a](?![\x0a])/msx;
my $newline_pattern = qr/$unix|$apple|$dos/msx;

# Replace newline in file with whatever the current system uses
$file_content =~ s/$newline_pattern/$INPUT_RECORD_SEPARATOR/msxg;

print $file_content;

# extract fields from room entry from data file
my $room_pattern = qr{
\s+(-?\d+)
\s+(-?\d+)
\s+(-?\d+)
\s+(-?\d+)
\s+(-?\d+)
\s+(-?\d+)
\s*"([^"]*)"
(.*)
}msxs;

# extract fields from object entry
my $object_pattern = qr{
\s*"([^"]*?)(?:/([^/]+)/)?"
\s*(-?\d+)
(.*)
}msxs;

# extract data from a verb or a noun
my $word_pattern = qr{
\s*"([*]?\S*?)"
(.*)
}msxs;

# extract data from an action comment
my $comment_pattern = qr{
\s*"([^"]*)"
(.*)
}msxs;

# extract a numerical value
my $number_pattern = qr{
\s*(-?\d+)
(.*)
}msxs;

my $next = $file_content;
my $game_bytes;
my $number_of_objects;
my $number_of_actions;
my $number_of_words;
my $number_of_rooms;
my $max_objects_carried;
my $starting_room;
my $number_of_treasures;
my $word_length;
my $time_limit;
my $number_of_messages;
my $treasure_room_id;
my @action_data;
my @list_of_verbs_and_nouns;
my @room_exit;
my @room_description;
( $game_bytes,          $next ) = $next =~ /$number_pattern/msxs;
( $number_of_objects,   $next ) = $next =~ /$number_pattern/msxs;
( $number_of_actions,   $next ) = $next =~ /$number_pattern/msxs;
( $number_of_words,     $next ) = $next =~ /$number_pattern/msxs;
( $number_of_rooms,     $next ) = $next =~ /$number_pattern/msxs;
( $max_objects_carried, $next ) = $next =~ /$number_pattern/msxs;
( $starting_room,       $next ) = $next =~ /$number_pattern/msxs;
( $number_of_treasures, $next ) = $next =~ /$number_pattern/msxs;
( $word_length,         $next ) = $next =~ /$number_pattern/msxs;
( $time_limit,          $next ) = $next =~ /$number_pattern/msxs;
( $number_of_messages,  $next ) = $next =~ /$number_pattern/msxs;
( $treasure_room_id,    $next ) = $next =~ /$number_pattern/msxs;

# Actions
{
    my $action_id = 0;
    while ( $action_id <= $number_of_actions ) {
        my $action_id_entry = 0;
        while ( $action_id_entry < $ACTION_ENTRIES ) {

            # $action_data[$action_id][$action_id_entry] =
            #   read_number($handle);
            ( $action_data[$action_id][$action_id_entry], $next ) =
              $next =~ /$number_pattern/msxs;
            $action_id_entry++;
        }
        $action_id++;
    }
}

# Words
{
    my $word = 0;
    while ( $word < ( ( $number_of_words + 1 ) * 2 ) ) {
        my $input;
        ( $input, $next ) = $next =~ /$word_pattern/msxs;
        $list_of_verbs_and_nouns[ int( $word / 2 ) ][ $word % 2 ] = $input;
        $word++;
    }
}

# Rooms
{
    my $room = 0;
    while ( $room <= $number_of_rooms ) {
        ( $room_exit[$room][0], $room_exit[$room][1], $room_exit[$room][2], $room_exit[$room][3], $room_exit[$room][4], $room_exit[$room][5], $room_description[$room], $next ) = $next =~ /$room_pattern/msxs;
        print "%%% $room/$number_of_rooms $room_description[$room]\n";
        $room++;
    }
}

