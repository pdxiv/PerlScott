#!/usr/bin/perl
use strict;
use warnings;
use Readonly;
use Carp;
use English qw( -no_match_vars );
our $VERSION = '1.0.0';

Readonly::Scalar my $ACTION_ENTRIES => 8;

my $game_file = shift @ARGV;

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
}msx;

# extract fields from object entry
my $object_pattern = qr{
\s*\"([^"]*)"
\s*(-?\d+)
(.*)
}msx;

# extract data from a verb or a noun
my $word_pattern = qr{
\s*"([*]?[^"]*?)"
(.*)
}msx;

# extract data from a general text field
my $text_pattern = qr{
\s*"([^"]*)"
(.*)
}msx;

# extract a numerical value
my $number_pattern = qr{
\s*(-?\d+)
(.*)
}msx;

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
my @message;
my @object_description;
my @object_location;
my @object_original_location;
my @action_description;
my $adventure_version;
my $adventure_number;

( $game_bytes,          $next ) = $next =~ /$number_pattern/msx;
( $number_of_objects,   $next ) = $next =~ /$number_pattern/msx;
( $number_of_actions,   $next ) = $next =~ /$number_pattern/msx;
( $number_of_words,     $next ) = $next =~ /$number_pattern/msx;
( $number_of_rooms,     $next ) = $next =~ /$number_pattern/msx;
( $max_objects_carried, $next ) = $next =~ /$number_pattern/msx;
( $starting_room,       $next ) = $next =~ /$number_pattern/msx;
( $number_of_treasures, $next ) = $next =~ /$number_pattern/msx;
( $word_length,         $next ) = $next =~ /$number_pattern/msx;
( $time_limit,          $next ) = $next =~ /$number_pattern/msx;
( $number_of_messages,  $next ) = $next =~ /$number_pattern/msx;
( $treasure_room_id,    $next ) = $next =~ /$number_pattern/msx;

# Actions
{
    my $action_id = 0;
    while ( $action_id <= $number_of_actions ) {
        my $action_id_entry = 0;
        while ( $action_id_entry < $ACTION_ENTRIES ) {

            # $action_data[$action_id][$action_id_entry] =
            #   read_number($handle);
            ( $action_data[$action_id][$action_id_entry], $next ) =
              $next =~ /$number_pattern/msx;
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
        ( $input, $next ) = $next =~ /$word_pattern/msx;
        $list_of_verbs_and_nouns[ int( $word / 2 ) ][ $word % 2 ] = $input;
        $word++;
    }
}

# Rooms
{
    my $room = 0;
    while ( $room <= $number_of_rooms ) {
        ( $room_exit[$room][0], $room_exit[$room][1], $room_exit[$room][2], $room_exit[$room][3], $room_exit[$room][4], $room_exit[$room][5], $room_description[$room], $next ) = $next =~ /$room_pattern/msx;
        $room++;
    }
}

# Messages
{
    my $current_message = 0;
    while ( $current_message <= $number_of_messages ) {
        ( $message[$current_message], $next ) = $next =~ /$text_pattern/msx;
        $current_message++;
    }
}

# Objects
{
    my $object = 0;
    while ( $object <= $number_of_objects ) {
        ( $object_description[$object], $object_location[$object], $next ) = $next =~ /$object_pattern/msx;
        $object_original_location[$object] = $object_location[$object];
        $object++;
    }
}

# Action descriptions
{
    my $action_counter = 0;
    while ( $action_counter <= $number_of_actions ) {
        ( $action_description[$action_counter], $next ) = $next =~ /$text_pattern/msx;
        $action_counter++;
    }
}

( $adventure_version, $next ) = $next =~ /$number_pattern/msx;    # Interpreter version
( $adventure_number,  $next ) = $next =~ /$number_pattern/msx;    # Adventure number

# Replace Ascii 96 with Ascii 34 in output text strings
foreach ( ( @object_description, @message, @room_description ) ) {
    s/`/"/msxg;
}
