#!/usr/bin/perl
use strict;
use warnings;
use Readonly;
use Carp;
use English qw( -no_match_vars );
use Getopt::Long;
our $VERSION = '1.0.0';

Readonly::Scalar my $ACTION_COMMAND_OFFSET    => 6;
Readonly::Scalar my $ACTION_ENTRIES           => 8;
Readonly::Scalar my $AUTO                     => 0;
Readonly::Scalar my $COMMAND_CODE_DIVISOR     => 150;
Readonly::Scalar my $COMMANDS_IN_ACTION       => 4;
Readonly::Scalar my $CONDITION_DIVISOR        => 20;
Readonly::Scalar my $CONDITIONS               => 5;
Readonly::Scalar my $COUNTER_TIME_LIMIT       => 8;
Readonly::Scalar my $DIRECTION_NOUNS          => 6;
Readonly::Scalar my $FALSE                    => 0;
Readonly::Scalar my $FALSE_VALUE              => 0;
Readonly::Scalar my $FLAG_LAMP_EMPTY          => 16;
Readonly::Scalar my $FLAG_NIGHT               => 15;
Readonly::Scalar my $LIGHT_SOURCE_ID          => 9;
Readonly::Scalar my $LIGHT_WARNING_THRESHOLD  => 25;
Readonly::Scalar my $MESSAGE_1_END            => 51;
Readonly::Scalar my $MESSAGE_2_START          => 102;
Readonly::Scalar my $PAR_CONDITION_CODE       => 0;
Readonly::Scalar my $PERCENT_UNITS            => 100;
Readonly::Scalar my $ROOM_INVENTORY           => -1;
Readonly::Scalar my $ROOM_STORE               => 0;
Readonly::Scalar my $ROUNDING_OFFSET          => 0.5;
Readonly::Scalar my $TRUE                     => -1;
Readonly::Scalar my $VERB_CARRY               => 10;
Readonly::Scalar my $VERB_DROP                => 18;
Readonly::Scalar my $VERB_GO                  => 1;
Readonly::Scalar my $ALTERNATE_ROOM_REGISTERS => 6;
Readonly::Scalar my $ALTERNATE_COUNTERS       => 9;
Readonly::Scalar my $STATUS_FLAGS             => 32;
Readonly::Scalar my $MINIMUM_COUNTER_VALUE    => -1;
Readonly::Array my @DIRECTION_NOUN_TEXT => qw( NORTH SOUTH EAST WEST UP DOWN );

my $game_file;    # Filename of game data file
my ( $keyboard_input, $keyboard_input_2 );
my (
    $carried_objects,     $command_or_display_message,
    $command_parameter,   $command_parameter_index,
    $cont_flag,           $counter_register,
    $current_room,        $global_noun,
    $max_objects_carried, $number_of_actions,
    $number_of_messages,  $number_of_objects,
    $number_of_rooms,     $number_of_treasures,
    $number_of_words,     $starting_room,
    $stored_treasures,    $time_limit,
    $treasure_room_id,    $word_length,
    $adventure_version,   $adventure_number,
    $game_bytes,
);
my ( @alternate_counter, @alternate_room );

my ( @object_description, @message, @extracted_input_words,
    @list_of_verbs_and_nouns, @room_description );

my ( @action_data, @action_description, @object_original_location,
    @object_location, @found_word, @room_exit, @status_flag );

my ( $command_in_handle, $command_out_handle );
my $flag_debug;

$cont_flag = 0;

# Debugging information
my @condition_name = (
    'Par', 'HAS',  'IN/W',  'AVL',  'IN',   '-IN/W', '-HAVE', '-IN',
    'BIT', '-BIT', 'ANY',   '-ANY', '-AVL', '-RM0',  'RM0',   'CT<=',
    'CT>', 'ORIG', '-ORIG', 'CT=',
);
my @command_name = (
    'GETx',  'DROPx',  'GOTOy', 'x->RM0', 'NIGHT', 'DAY',
    'SETz',  'x->RM0', 'CLRz',  'DEAD',   'x->y',  'FINI',
    'DspRM', 'SCORE',  'INV',   'SET0',   'CLR0',  'FILL',
    'CLS',   'SAVE',   'EXx,x', 'CONT',   'AGETx', 'BYx<-x',
    'DspRM', 'CT-1',   'DspCT', 'CT<-n',  'EXRM0', 'EXm,CT',
    'CT+n',  'CT-n',   'SAYw',  'SAYwCR', 'SAYCR', 'EXc,CR',
    'DELAY',
);

# Code for all the action conditions
my @condition_function = (

    #  0 Par
    sub {
        my $parameter = shift;
        return $TRUE;
    },

    #  1 HAS
    sub {
        my $parameter = shift;
        my $result    = $FALSE;
        if ( $object_location[$parameter] == $ROOM_INVENTORY ) {
            $result = $TRUE;
        }
        return $result;
    },

    #  2 IN/W
    sub {
        my $parameter = shift;
        return ( $object_location[$parameter] == $current_room );
    },

    #  3 AVL
    sub {
        my $parameter = shift;
        my $result;
        $result = ( $object_location[$parameter] == $ROOM_INVENTORY );
        $result = $result
          || ( $object_location[$parameter] == $current_room );
        return $result;
    },

    #  4 IN
    sub {
        my $parameter = shift;
        return ( $current_room == $parameter );
    },

    #  5 -IN/W
    sub {
        my $parameter = shift;
        return ( $object_location[$parameter] != $current_room );
    },

    #  6 -HAVE
    sub {
        my $parameter = shift;
        my $result    = $FALSE;
        if ( $object_location[$parameter] != $ROOM_INVENTORY ) {
            $result = $TRUE;
        }
        return $result;
    },

    #  7 -IN
    sub {
        my $parameter = shift;
        return ( $current_room != $parameter );
    },

    #  8 BIT
    sub {
        my $parameter = shift;
        my $result;

        $result = $status_flag[$parameter];
        return $result;
    },

    #  9 -BIT
    sub {
        my $parameter = shift;
        my $result;

        $result = ( !$status_flag[$parameter] );
        return $result;
    },

    # 10 ANY
    sub {
        my $parameter = shift;
        my $result    = $FALSE;
        foreach my $location (@object_location) {
            if ( $location == $ROOM_INVENTORY ) {
                $result = $TRUE;
            }
        }
        return $result;
    },

    # 11 -ANY
    sub {
        my $parameter = shift;
        my $result    = $FALSE;
        foreach my $location (@object_location) {
            if ( $location == $ROOM_INVENTORY ) {
                $result = $TRUE;
            }
        }
        return ( !$result );
    },

    # 12 -AVL
    sub {
        my $parameter = shift;
        my $result;
        $result = ( $object_location[$parameter] == $ROOM_INVENTORY );
        $result = $result
          || ( $object_location[$parameter] == $current_room );
        return ( !$result );
    },

    # 13 -RM0
    sub {
        my $parameter = shift;
        return ( $object_location[$parameter] != $ROOM_STORE );
    },

    # 14 RM0
    sub {
        my $parameter = shift;
        return ( $object_location[$parameter] == $ROOM_STORE );
    },

    # Newer post-1978 conditions below

    # 15 CT<=
    sub {
        my $parameter = shift;
        return $counter_register <= $parameter;
    },

    # 16 CT>
    sub {
        my $parameter = shift;
        return $counter_register > $parameter;
    },

    # 17 ORIG
    sub {
        my $parameter = shift;
        return $object_original_location[$parameter] ==
          $object_location[$parameter];
    },

    # 18 -ORIG
    sub {
        my $parameter = shift;
        return !( $object_original_location[$parameter] ==
            $object_location[$parameter] );
    },

    # 19 CT=
    sub {
        my $parameter = shift;
        return $counter_register == $parameter;
    },
);

# Code for all the action commands
my @command_function = (

    #  0 GETx
    sub {
        my $action_id = shift;
        $carried_objects = 0;

        foreach my $location (@object_location) {
            if ( $location == $ROOM_INVENTORY ) {
                $carried_objects++;
            }
        }
        if ( $carried_objects >= $max_objects_carried ) {
            if ( $max_objects_carried >= 0 ) {
                print "I've too much too carry. try -take inventory-\n"
                  or croak;

                # Stop processing later commands if this one fails
                my $continue = shift;
                ${$continue} = $FALSE;
            }
        }

        get_command_parameter($action_id);
        $object_location[$command_parameter] = $ROOM_INVENTORY;
    },

    #  1 DROPx
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        $object_location[$command_parameter] = $current_room;
    },

    #  2 GOTOy
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        $current_room = $command_parameter;
    },

    #  3 x->RM0
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        $object_location[$command_parameter] = 0;
    },

    #  4 NIGHT
    sub {
        my $action_id = shift;
        $status_flag[$FLAG_NIGHT] = $TRUE;
    },

    #  5 DAY
    sub {
        my $action_id = shift;
        $status_flag[$FLAG_NIGHT] = $FALSE;
    },

    #  6 SETz
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        $status_flag[$command_parameter] = 1;
    },

    #  7 x->RM0
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        $object_location[$command_parameter] = 0;
    },

    #  8 CLRz
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        $status_flag[$command_parameter] = 0;
    },

    #  9 DEAD
    sub {
        my $action_id = shift;
        print "I'm dead...\n" or croak;
        $current_room = $number_of_rooms;
        $status_flag[$FLAG_NIGHT] = $FALSE;
        show_room_description();
    },

    # 10 x->y
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        my $temporary_1 = $command_parameter;
        get_command_parameter($action_id);
        $object_location[$temporary_1] = $command_parameter;
    },

    # 11 FINI
    sub {
        my $action_id = shift;
        exit 0;
    },

    # 12 DspRM
    sub {
        my $action_id = shift;
        show_room_description();
    },

    # 13 SCORE
    sub {
        my $action_id = shift;
        $stored_treasures = 0;
        {
            my $object = 0;
            foreach my $location (@object_location) {
                if ( $location == $treasure_room_id ) {
                    if ( substr( $object_description[$object], 0, 1 ) eq q{*} )
                    {
                        $stored_treasures++;
                    }
                }
                $object++;
            }
        }

        print "I've stored $stored_treasures treasures. "
          . "ON A SCALE OF 0 TO $PERCENT_UNITS THAT RATES A "
          . int( $stored_treasures / $number_of_treasures * $PERCENT_UNITS )
          . "\n"
          or croak;
        if ( $stored_treasures == $number_of_treasures ) {
            print "Well done.\n" or croak;
            exit 0;
        }
    },

    # 14 INV
    sub {
        my $action_id = shift;
        print "I'm carrying:\n" or croak;
        my $carrying_nothing_text = 'Nothing';
        my $object_text;
        {
            my $object = 0;
            foreach my $location (@object_location) {
                if ( $location != $ROOM_INVENTORY ) {
                    $object++;
                    next;
                }
                else {
                    $object_text = strip_noun_from_object_description($object);
                }
                print "$object_text. " or croak;
                $carrying_nothing_text = q{};
                $object++;
            }
        }
        print "$carrying_nothing_text\n\n" or croak;
    },

    # 15 SET0
    sub {
        my $action_id = shift;
        $command_parameter = 0;
        $status_flag[$command_parameter] = 1;

    },

    # 16 CLR0
    sub {
        my $action_id = shift;
        $command_parameter = 0;
        $status_flag[$command_parameter] = 0;
    },

    # 17 FILL
    sub {
        my $action_id = shift;
        $alternate_counter[$COUNTER_TIME_LIMIT] = $time_limit;
        $object_location[$LIGHT_SOURCE_ID]      = $ROOM_INVENTORY;
        $status_flag[$FLAG_LAMP_EMPTY]          = $FALSE;
    },

    # 18 CLS
    sub {
        my $action_id = shift;
        cls();

    },

    # 19 SAVE
    sub {
        my $action_id = shift;
        save_game();
    },

    # 20 EXx,x
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        my $temporary_1 = $command_parameter;
        get_command_parameter($action_id);
        my $temporary_2 = $object_location[$command_parameter];
        $object_location[$command_parameter] = $object_location[$temporary_1];
        $object_location[$temporary_1]       = $temporary_2;
    },

    # 21 CONT
    sub {
        $cont_flag = 1;
    },

    # 22 AGETx
    sub {
        my $action_id = shift;
        $carried_objects = 0;
        get_command_parameter($action_id);
        $object_location[$command_parameter] = $ROOM_INVENTORY;
    },

    # 23 BYx<-x
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        my $first_object = $command_parameter;
        get_command_parameter($action_id);
        my $second_object = $command_parameter;
        $object_location[$first_object] = $object_location[$second_object];
    },

    # 24 DspRM
    sub {
        my $action_id = shift;
        show_room_description();
    },

    # Newer post-1978 commands below

    # 25 CT-1
    sub {
        my $action_id = shift;
        $counter_register--;
    },

    # 26 DspCT
    sub {
        my $action_id = shift;
        print "$counter_register" or croak;

    },

    # 27 CT<-n
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        $counter_register = $command_parameter;
    },

    # 28 EXRM0
    sub {
        my $action_id = shift;
        my $temp      = $current_room;
        $current_room = $alternate_room[0];
        $alternate_room[0] = $temp;
    },

    # 29 EXm,CT
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        my $temp = $counter_register;
        $counter_register = $alternate_counter[$command_parameter];
        $alternate_counter[$command_parameter] = $temp;
    },

    # 30 CT+n
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        $counter_register += $command_parameter;
    },

    # 31 CT-n
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        $counter_register -= $command_parameter;

        # According to ScottFree source, the counter has a minimum value of -1
        if ( $counter_register < $MINIMUM_COUNTER_VALUE ) {
            $counter_register = $MINIMUM_COUNTER_VALUE;
        }
    },

    # 32 SAYw
    sub {
        my $action_id = shift;
        print $global_noun or croak;
    },

    # 33 SAYwCR
    sub {
        my $action_id = shift;
        print "$global_noun\n" or croak;
    },

    # 34 SAYCR
    sub {
        my $action_id = shift;
        print "\n" or croak;
    },

    # 35 EXc,CR
    sub {
        my $action_id = shift;
        get_command_parameter($action_id);
        my $temp = $current_room;
        $current_room = $alternate_room[$command_parameter];
        $alternate_room[$command_parameter] = $temp;
    },

    # 36 DELAY
    sub {
        my $action_id = shift;
        sleep 1;
    },

);

$command_or_display_message = 0;

# Get commandline options
( $command_in_handle, $command_out_handle, $flag_debug ) =
  commandline_options();

# Load game data file, if specified
if ( scalar @ARGV ) {
    $game_file = shift @ARGV;
    load_game_data_file();
}
else {
    commandline_help();
}

# Initialize values
$current_room = $starting_room;    # Set current room to starting room
@alternate_room           = (0) x $ALTERNATE_ROOM_REGISTERS;
@alternate_counter        = (0) x $ALTERNATE_COUNTERS;
$counter_register         = 0;
@status_flag              = (0) x $STATUS_FLAGS;
$status_flag[$FLAG_NIGHT] = $FALSE;                            # Day flag???
$alternate_counter[$COUNTER_TIME_LIMIT] = $time_limit;  # Set time limit counter

show_intro();                                           # Show intro
show_room_description();                                # Show room

# Process auto action_data before starting main keyboard input loop
$found_word[0] = 0;

run_actions( $found_word[0], 0 );

# Main keyboard command input loop
while (1) {
    print_debug( join( q{ }, @status_flag ),       37 );
    print_debug( join( q{ }, @alternate_counter ), 37 );

    print "Tell me what to do\n" or croak;

    $keyboard_input_2 = get_command_input();
    chomp $keyboard_input_2;
    print "\n" or croak;

    if ( $keyboard_input_2 =~ /^\s*LOAD\s*GAME/msxi ) {
        if ( load_game() ) {
            show_room_description();
        }
    }
    else {
        extract_words();

        my $undefined_words_found = ( $found_word[0] < 1 )
          || ( length( $extracted_input_words[1] ) > 0 )
          && ( $found_word[1] < 1 );

        if (   ( $found_word[0] == $VERB_CARRY )
            or ( $found_word[0] == $VERB_DROP ) )
        {
            $undefined_words_found = $FALSE;
        }

        if ($undefined_words_found) {
            print "You use word(s) i don't know\n" or croak;
        }
        else {
            run_actions( $found_word[0], $found_word[1] );
            check_and_change_light_source_status();
            $found_word[0] = 0;
            run_actions( $found_word[0], $found_word[1] );
        }
    }
}

sub get_command_input {
    my $input_data;

    # If command file has ended, return control to STDIN
    if ( eof $command_in_handle ) {
        $command_in_handle = *STDIN;
    }

    $input_data = <$command_in_handle>;

    # If a command output file is open, write to it
    if ( defined $command_out_handle ) {
        print $command_out_handle $input_data;
    }
    return $input_data;
}

sub commandline_help {
    print <<'END_MESSAGE';
Usage: perlscott.pl [OPTION]... game_data_file
Scott Adams adventure game interpreter

-i, --input    Command input file
-o, --output   Command output file
-d, --debug    Show game debugging info
-h, --help     Display this help and exit
END_MESSAGE
    exit 0;
}

sub commandline_options {
    my $in_handle;
    my $out_handle;
    my $input;
    my $output;
    my $flag_help;
    my @return;    # Return input and output handles as an array
    GetOptions(
        'i|input=s'  => \$input,
        'o|output=s' => \$output,
        'd|debug'    => \$flag_debug,
        'h|help'     => \$flag_help
    ) or croak "Error in commandline arguments\n";

    if ($flag_help) {
        commandline_help();
    }

    # If no command input file defined, use STDIN for input
    if ( !defined $input ) {
        $in_handle = *STDIN;
    }
    else {
        if ( -e $input ) {
            open $in_handle, q{<}, $input or croak;
        }
        else {
            croak "file \"$input\" not found";
        }
    }
    push @return, $in_handle;

    # If command output file defined, write output to it
    if ( defined $output ) {
        open $out_handle, q{>}, $output or croak;
    }
    push @return, $out_handle, $flag_debug;
    return @return;
}

sub strip_noun_from_object_description {
    my $object_number = shift;
    my $stripped_text = $object_description[$object_number];
    $stripped_text =~ s/\/.*\///msx;
    return $stripped_text;
}

sub check_and_change_light_source_status {
    if ( exists $object_location[$LIGHT_SOURCE_ID] ) {
        if ( $object_location[$LIGHT_SOURCE_ID] == $ROOM_INVENTORY ) {
            $alternate_counter[$COUNTER_TIME_LIMIT]--;
            if ( $alternate_counter[$COUNTER_TIME_LIMIT] < 0 ) {
                print "Light has run out\n" or croak;
                $object_location[$LIGHT_SOURCE_ID] = 0;
            }
            elsif ( $alternate_counter[$COUNTER_TIME_LIMIT] <
                $LIGHT_WARNING_THRESHOLD )
            {
                print 'Light runs out in '
                  . $alternate_counter[$COUNTER_TIME_LIMIT]
                  . " turns!\n"
                  or croak;
            }
        }
    }
    return 1;
}

sub show_intro {
    cls();
    my $intro_message = <<'END_MESSAGE';
     *** Welcome ***

 Unless told differently you must find *treasures* and-return-them-to-their-proper--place!

I'm your puppet. Give me english commands that
consist of a noun and verb. Some examples...

To find out what you're carrying you might say: TAKE INVENTORY to go into a hole you might say: GO HOLE to save current game: SAVE GAME

You will at times need special items to do things: But i'm sure you'll be a good adventurer and figure these things out.

     Happy adventuring... Hit enter to start
END_MESSAGE
    print $intro_message or croak;

    $keyboard_input = get_command_input();
    cls();
    return 1;
}

# Show room description
sub show_room_description {
    if ( $status_flag[$FLAG_NIGHT] )
    {    # Is the day flag true? (is this correct??)

      # Check that item #9 (light source) is either in inventory or current room
        if ( $object_location[$LIGHT_SOURCE_ID] != $ROOM_INVENTORY ) {
            if ( $object_location[$LIGHT_SOURCE_ID] != $current_room ) {
                print "I can't see: Its too dark.\n" or croak;
                return;
            }
        }
    }

    # Show general description
    if ( substr( $room_description[$current_room], 0, 1 ) eq q{*} ) {
        print( substr $room_description[$current_room], 1 ) . "\n" or croak;
    }
    else {
        print "I'm in a $room_description[$current_room]" or croak;
    }

    # List objects
    my $objects_found = $FALSE;
    {
        my $object = 0;
        foreach my $location (@object_location) {
            if ( $location == $current_room ) {
                if ( $objects_found == $FALSE ) {
                    print ". Visible items here: \n" or croak;
                    $objects_found = $TRUE;
                }
                print strip_noun_from_object_description($object) . '. '
                  or croak;
            }
            $object++;
        }
    }
    print "\n" or croak;

    # List exits
    my $exit_found = $FALSE;
    {
        my $direction = 0;
        foreach my $exit ( @{ $room_exit[$current_room] } ) {
            if ( $exit != 0 ) {
                if ( $exit_found == $FALSE ) {
                    print 'Obvious exits: ' or croak;
                    $exit_found = $TRUE;
                }
                print $DIRECTION_NOUN_TEXT[$direction] . q{ }
                  or croak;
            }
            $direction++;
        }
    }
    print "\n\n" or croak;
    return 1;
}

sub handle_go_verb {
    my $room_dark = $status_flag[$FLAG_NIGHT];
    if ($room_dark) {
        $room_dark = $status_flag[$FLAG_NIGHT];
        $room_dark = $room_dark
          && ( $object_location[$LIGHT_SOURCE_ID] != $current_room );
        $room_dark = $room_dark
          && ( $object_location[$LIGHT_SOURCE_ID] != $TRUE );

        if ($room_dark) {
            print "Dangerous to move in the dark!\n" or croak;
        }
    }
    if ( $found_word[1] < 1 ) {
        print "Give me a direction too.\n" or croak;
        return 1;
    }
    my $direction_destination = $room_exit[$current_room][ $found_word[1] - 1 ];
    if ( $direction_destination < 1 ) {
        if ($room_dark) {
            print "I fell down and broke my neck.\n" or croak;
            $direction_destination = $number_of_rooms;
            $status_flag[$FLAG_NIGHT] = $FALSE;
        }
        else {
            print "I can't go in that direction\n" or croak;
            return 1;
        }
    }
    $current_room = $direction_destination;
    show_room_description();    # Show room description
    return 1;
}

sub get_command_parameter {
    my $current_action = shift;

    if ( !defined $current_action ) {
        croak 'Couldn\'t get command for unspecified action';
    }
    my $condition_code = 1;
    while ( $condition_code != $PAR_CONDITION_CODE ) {
        my $condition_line =
          $action_data[$current_action][$command_parameter_index];
        $command_parameter = int( $condition_line / $CONDITION_DIVISOR );
        $condition_code =
          $condition_line - $command_parameter * $CONDITION_DIVISOR;
        $command_parameter_index++;
    }
    return 1;
}

sub decode_command_from_data {
    my $command_number = shift;
    my $action_id      = shift;
    my $command_code;
    my $merged_command_index =
      int( $command_number / 2 + $ACTION_COMMAND_OFFSET );

    # Even or odd command number?
    if ( $command_number % 2 ) {
        $command_code =
          $action_data[$action_id][$merged_command_index] -
          int( $action_data[$action_id][$merged_command_index] /
              $COMMAND_CODE_DIVISOR ) *
          $COMMAND_CODE_DIVISOR;
    }
    else {

        $command_code = int( $action_data[$action_id][$merged_command_index] /
              $COMMAND_CODE_DIVISOR );
    }
    return $command_code;
}

sub load_game_data_file {
    open my $handle, '<', $game_file or croak;
    my $file_content = do { local $INPUT_RECORD_SEPARATOR; <$handle> };
    close $handle or croak;
    my $next = $file_content;

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
            (
                $room_exit[$room][0],     $room_exit[$room][1],
                $room_exit[$room][2],     $room_exit[$room][3],
                $room_exit[$room][4],     $room_exit[$room][5],
                $room_description[$room], $next
            ) = $next =~ /$room_pattern/msx;
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
            ( $object_description[$object], $object_location[$object], $next )
              = $next =~ /$object_pattern/msx;
            $object_original_location[$object] = $object_location[$object];
            $object++;
        }
    }

    # Action descriptions
    {
        my $action_counter = 0;
        while ( $action_counter <= $number_of_actions ) {
            ( $action_description[$action_counter], $next ) =
              $next =~ /$text_pattern/msx;
            $action_counter++;
        }
    }

    ( $adventure_version, $next ) =
      $next =~ /$number_pattern/msx;    # Interpreter version
    ( $adventure_number, $next ) =
      $next =~ /$number_pattern/msx;    # Adventure number

    # Replace Ascii 96 with Ascii 34 in output text strings
    foreach ( ( @object_description, @message, @room_description ) ) {
        s/`/"/msxg;
    }

    return 1;
}

sub cls {
    print "\e[2J"   or croak;           # Clear the screen
    print "\e[0;0H" or croak;           # Jump to coordinate 0,0
    return $TRUE;
}

sub read_number {                       # Clear away garbage
    my $handle = shift;
    my $temp   = <$handle>;
    $temp += 0;                         # Cast the string to a number
    return $temp;
}

sub read_string {
    my $handle = shift;
    my $input  = <$handle>;
    $input =~ s/\"//msxg;
    chomp $input;
    return $input;
}

sub extract_words {

    # Input:
    # $keyboard_input_2           : Input string
    # $word_length                : Character length
    # @list_of_verbs_and_nouns    : List of verbs and nouns
    # Output:
    # @found_word : Identified verbs and nouns
    # @extracted_input_words      : Extracted words from input
    undef @extracted_input_words;
    $keyboard_input_2 =~ s/^\s*//msx;
    @extracted_input_words = split /\s+/msx, $keyboard_input_2;
    if ( !defined $extracted_input_words[0] ) {
        $extracted_input_words[0] = q{};
    }

    # Set noun to blank, if not defined
    if ( scalar @extracted_input_words < 2 ) {
        $extracted_input_words[1] = q{};
    }
    $global_noun = $extracted_input_words[1];

    {
        # Iterate over verbs and nouns
        my $verb_or_noun = 0;
        while ( $verb_or_noun <= 1 ) {

            # Reset identified word id
            $found_word[$verb_or_noun] = 0;

            # Last non-synonym word id
            my $non_synonym;
            {
                # Iterate through words
                my $word_id = 0;
                foreach my $word (@list_of_verbs_and_nouns) {
                    if ( substr( ${$word}[$verb_or_noun], 0, 1 ) ne q{*} ) {
                        $non_synonym = $word_id;
                    }
                    my $temp_word = ${$word}[$verb_or_noun];
                    $temp_word =~ s/^[*]//msx;
                    $temp_word = substr $temp_word, 0, $word_length;
                    if (
                        $temp_word eq uc
                        substr $extracted_input_words[$verb_or_noun],
                        0, $word_length
                      )
                    {
                        $found_word[$verb_or_noun] = $non_synonym;
                        last;
                    }
                    $word_id++;
                }
            }
            $verb_or_noun++;
        }
    }
    return 1;
}

sub save_game {

    print "Name of save file:\n" or croak;
    my $save_filename = get_command_input();
    chomp $save_filename;
    my @save_data;

    # A bit of extra precaution
    push @save_data, $adventure_version;
    push @save_data, $adventure_number;

    push @save_data, $current_room;
    foreach (@alternate_room) { push @save_data, $_; }
    push @save_data, $counter_register;
    foreach (@alternate_counter) { push @save_data, $_; }
    foreach (@object_location)   { push @save_data, $_; }
    foreach (@status_flag)       { push @save_data, $_; }

    open my $save_file, '>', $save_filename or croak;
    foreach (@save_data) { print {$save_file} "$_\n" or croak; }
    close $save_file or croak;

    return $TRUE;
}

sub load_game {
    print "Name of save file:\n" or croak;
    my $save_filename = get_command_input();
    chomp $save_filename;
    if ( !-e $save_filename ) {
        print "Couldn't load \"$save_filename\". Doesn't exist!\n" or croak;
        return $FALSE;
    }
    my @save_data;

    open my $save_file, '<', $save_filename or croak;
    while (<$save_file>) { push @save_data, $_; }
    close $save_file or croak;

    chomp @save_data;

    # A bit of extra precaution
    my $save_adventure_version = shift @save_data;
    if ( $save_adventure_version != $adventure_version ) {
        print "Invalid savegame version\n" or croak;
        return $FALSE;
    }
    my $save_adventure_number = shift @save_data;
    if ( $save_adventure_number != $adventure_number ) {
        print "Invalid savegame adventure number\n" or croak;
        return $FALSE;
    }

    $current_room = shift @save_data;
    foreach (@alternate_room) { $_ = shift @save_data }
    $counter_register = shift @save_data;
    foreach (@alternate_counter) { $_ = shift @save_data }
    foreach (@object_location)   { $_ = shift @save_data }
    foreach (@status_flag)       { $_ = shift @save_data }

    return $TRUE;
}

sub run_actions {
    my $input_verb = shift;
    my $input_noun = shift;

    # If verb is 'GO' and noun is a direction
    if ( $input_verb == $VERB_GO && $input_noun <= $DIRECTION_NOUNS ) {
        handle_go_verb();
        return 1;
    }

    my $found_word = 0;

    $cont_flag = 0;
    my $current_action = 0;
    my $word_action_done = $FALSE;
    foreach (@action_data) {
        my $action_verb = get_action_verb($current_action);
        my $action_noun = get_action_noun($current_action);

        # CONT action
        if ( $cont_flag && ( $action_verb == 0 ) && ( $action_noun == 0 ) ) {
            print_debug(
"Action $current_action. verb $action_verb, noun $action_noun (CONT $cont_flag), \"$action_description[$current_action]\"",
                31
            );
            if ( evaluate_conditions($current_action) ) {
                execute_commands($current_action);
            }
        }
        else {
            # "CONT" condition failures won't reset the CONT flag!
            $cont_flag = 0;
        }

        # AUT action
        if ( $input_verb == 0 ) {
            if ( ( $action_verb == 0 ) && ( $action_noun > 0 ) ) {
                print_debug(
"Action $current_action. verb $action_verb, noun $action_noun (CONT $cont_flag), \"$action_description[$current_action]\"",
                    31
                );
                $cont_flag = 0;
                if ( ( int rand $PERCENT_UNITS ) <= $action_noun ) {
                    if ( evaluate_conditions($current_action) ) {
                        execute_commands($current_action);
                    }
                }
            }
        }

        # Word action
        if ( $input_verb > 0 ) {
            if ( $action_verb == $input_verb ) {
                if ( $word_action_done == $FALSE ) {
                    print_debug(
                        "Action $current_action. "
                          . "verb $action_verb ("
                          . $list_of_verbs_and_nouns[$action_verb][0] . "), "
                          . "noun $action_noun ("
                          . $list_of_verbs_and_nouns[$action_noun][1]
                          . ") (CONT $cont_flag), "
                          . "\"$action_description[$current_action]\"",
                        31
                    );
                    $cont_flag = 0;
                    if ( $action_noun == 0 ) {
                        $found_word = 1;
                        if ( evaluate_conditions($current_action) ) {
                            execute_commands($current_action);
                            $word_action_done = $TRUE;
                            return 1;
                        }
                    }
                    elsif ( $action_noun == $input_noun ) {
                        $found_word = 1;
                        if ( evaluate_conditions($current_action) ) {
                            execute_commands($current_action);
                            $word_action_done = $TRUE;
                            if ( $cont_flag == 0 ) { return 1; }
                        }
                    }
                }
            }
        }

        $current_action++;
    }

    if ( $input_verb == 0 ) { return 1; }

    if ( handle_carry_and_drop_verb( $input_verb, $input_noun ) ) {
        return $TRUE;
    }

    if ( $word_action_done == $TRUE ) { return $TRUE; }

    if ($found_word) {
        print "I can't do that yet\n" or croak;
    }
    else {
        print "I don't understand your command\n" or croak;
    }
    return $TRUE;
}

# Subroutine for optionally printing debug messages
sub print_debug {
    my $message = shift;
    my $color   = shift;
    if ($flag_debug) {
        print chr(27) . '[' . $color . "mDEBUG: $message" . chr(27) . "[0m\n";
    }
}

sub noun_is_in_object {
    my $truncated_noun = substr $global_noun, 0, $word_length;
    foreach my $description (@object_description) {
        if ( $description =~ /\/(.*)\/$/msx ) {
            my $object_noun = lc($1);
            if ( $object_noun eq $truncated_noun ) {
                return $TRUE;
            }
        }
    }
    return $FALSE;
}

sub handle_carry_and_drop_verb {
    my $input_verb = shift;
    my $input_noun = shift;

    # Exit subroutine if the verb isn't carry or drop
    if ( !( $input_verb == $VERB_CARRY ) && !( $input_verb == $VERB_DROP ) ) {
        return 0;
    }

    # If noun is undefined, return with an error text
    if ( $input_noun == 0 and not noun_is_in_object() ) {
        print "What?\n" or croak;
        return 1;
    }

    # If verb is CARRY, check that we're not exceeding weight limit
    if ( $input_verb == $VERB_CARRY ) {
        $carried_objects = 0;

        foreach my $location (@object_location) {
            if ( $location == $ROOM_INVENTORY ) {
                $carried_objects++;
            }
        }
        if ( $carried_objects >= $max_objects_carried ) {
            if ( $max_objects_carried >= 0 ) {
                print "I've too much too carry. try -take inventory-\n"
                  or croak;
                return 1;
            }
        }
        else {
            if ( get_or_drop_noun( $input_noun, $current_room, $ROOM_INVENTORY )
              )
            {
                return $TRUE;
            }
            else {
                print "I don't see it here\n" or croak;
                return $TRUE;
            }
        }
    }
    else {
        if ( get_or_drop_noun( $input_noun, $ROOM_INVENTORY, $current_room ) ) {
            return $TRUE;
        }
        else {
            print "I'm not carrying it\n" or croak;
            return $TRUE;
        }
    }
    return 0;
}

sub get_or_drop_noun {
    my $input_noun       = shift;
    my $room_source      = shift;
    my $room_destination = shift;
    my @objects_in_room;
    my $object_counter = 0;

    # Identify all objects in current room
    foreach my $location (@object_location) {
        if ( $location == $room_source ) {
            push @objects_in_room, $object_counter;
        }
        $object_counter++;
    }

    # Check if any of the objects in the room has a matching noun
    foreach my $room_object (@objects_in_room) {

        # Only proceed if the object has a noun defined
        if ( $object_description[$room_object] =~ /\/(.*)\/$/msx ) {

            # Pick up the first object we find that matches and return
            if (   ( $list_of_verbs_and_nouns[$input_noun][1] eq $1 )
                or ( $1 eq uc( substr $global_noun, 0, $word_length ) ) )
            {
                $object_location[$room_object] = $room_destination;
                print "OK\n" or croak;
                return $TRUE;
            }
        }
    }
    return $FALSE;
}

sub get_action_verb {
    my $action_id = shift;
    return int( $action_data[$action_id][0] / $COMMAND_CODE_DIVISOR );
}

sub get_action_noun {
    my $action_id = shift;
    return $action_data[$action_id][0] % $COMMAND_CODE_DIVISOR;
}

sub execute_commands {
    my $action_id = shift;
    $command_parameter_index = 1;
    {
        my $command                     = 0;
        my $continue_executing_commands = $TRUE;
        while ( $command < $COMMANDS_IN_ACTION && $continue_executing_commands )
        {
            $command_or_display_message =
              decode_command_from_data( $command, $action_id );
            $command++;

            # Code above 102? it's printable text!
            if ( $command_or_display_message >= $MESSAGE_2_START ) {
                print_debug(
                    'Command print message ' . $command_or_display_message,
                    32 );
                print
                  "$message[$command_or_display_message - $MESSAGE_1_END + 1]\n"
                  or croak;
            }

            # Do nothing
            elsif ( $command_or_display_message == 0 ) { }

            # Code below 52? it's printable text!
            elsif ( $command_or_display_message <= $MESSAGE_1_END ) {
                print_debug(
                    'Command print message ' . $command_or_display_message,
                    32 );
                print "$message[$command_or_display_message]\n"
                  or croak;
            }

            # Code above 52 and below 102? We got some command code to run!
            else {
                my $command_code =
                  $command_or_display_message - $MESSAGE_1_END - 1;

                # Launch execution of action commands
                print_debug(
                    "Command code $command_code "
                      . $command_name[$command_code],
                    32
                );
                &{ $command_function[$command_code] }
                  ( $action_id, \$continue_executing_commands );
            }
        }
    }

    return 1;
}

sub evaluate_conditions {
    my $action_id         = shift;
    my $evaluation_status = 1;
    my $condition         = 1;
    while ( $condition <= $CONDITIONS ) {
        my $condition_code = get_condition_code( $action_id, $condition );
        my $condition_parameter =
          get_condition_parameter( $action_id, $condition );
        print_debug(
            "Condition $condition_code "
              . $condition_name[$condition_code]
              . " with parameter $condition_parameter",
            33
        );
        if ( !&{ $condition_function[$condition_code] }($condition_parameter) )
        {

            # Stop evaluating conditions if false. One fails all.
            $evaluation_status = 0;
            last;
        }
        $condition++;
    }
    return $evaluation_status;
}

sub get_condition_code {
    my $action_id      = shift;
    my $condition      = shift;
    my $condition_raw  = $action_data[$action_id][$condition];
    my $condition_code = $condition_raw % $CONDITION_DIVISOR;
    return $condition_code;
}

sub get_condition_parameter {
    my $action_id           = shift;
    my $condition           = shift;
    my $condition_raw       = $action_data[$action_id][$condition];
    my $condition_parameter = int( $condition_raw / $CONDITION_DIVISOR );
    return $condition_parameter;
}
