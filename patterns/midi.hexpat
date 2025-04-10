#pragma description Standard MIDI file (SMF)
#pragma author Raphaël Doursenaud <rdoursenaud@free.fr>

#pragma magic [ 4D 54 68 64 ] @ 0x00
#pragma MIME audio/midi

#pragma endian big

//#pragma pattern_limit 256000

import std.core;
import type.base;
import type.byte;
import type.magic;

/*!
    Standard MIDI Files 1.0

    Official specification at https://midi.org
*/

#define SEVEN_BITS    0x7F
#define EIGHTH_BIT    0x80
#define FIRST_NIBBLE  0xF0
#define SECOND_NIBBLE 0x0F

/**
    Type used to decode a Variable Length Quantity (VLQ).

    VLQs are used to store large numbers as space efficiently as possible.
    They are very similar to LEB128 except for the endianness.

    The MIDI variant supports up to 4 coding bytes.

    TODO: contribute separately? May be useful to other patterns.
*/
namespace auto type {

        /**
            Base VLQ type.

            Use `VLQ` instead.
        */
        struct VLQBase {
            u8 array[while($ == addressof(this) || std::mem::read_unsigned($-1, 1) & EIGHTH_BIT != 0)] [[hidden]];
        } [[sealed]];

        /**
            A VLQ number.
        */
        using VLQ = VLQBase [[format("type::impl::format_vlq"), transform("type::impl::transform_vlq")]];

        namespace impl {

            fn transform_vlq_array(ref auto array) {
                u32 res = array[0] & SEVEN_BITS;
                for(u8 i = 1, array[i - 1] & EIGHTH_BIT != 0, i+=1) {
                    res = (res << 7) | (array[i] & SEVEN_BITS);
                }
                return res;
            };

            fn format_vlq(ref auto vlq) {
                u32 res = type::impl::transform_vlq_array(vlq.array);
                return std::format("{} ({:X})", res, res);
            };

            fn transform_vlq(ref auto vlq) {
                return type::impl::transform_vlq_array(vlq.array);
            };

        }

}

/*------------
  Alien chunk
 ------------*/

/**
    An alien chunk.

    Unknown chunks are allowed per specification but can't be decoded.
*/

struct AlienChunk {
    char type[4];
    u32  length;
    u8   data[length];
};

/*------------
  MTrk Events
 ------------*/

// Workaround to use an enum range in a match.
// See: https://github.com/WerWolv/PatternLanguage/issues/69#issuecomment-2585462855
#define MIDI_CHANNEL_VOICE_MESSAGES_RANGE 0x80 ... 0xEF
#define SYSEX_EVENT_BYTE                  0xF0
#define SYSEX_EVENT_CONTINUE_ESCAPE_BYTE  0xF7
#define META_EVENT_BYTE                   0xFF

/// Specified track event types
enum TrackEventType : u8 {
    MIDI   = MIDI_CHANNEL_VOICE_MESSAGES_RANGE,
    SYSEX  = SYSEX_EVENT_BYTE,
    ESCAPE = SYSEX_EVENT_CONTINUE_ESCAPE_BYTE,
    META   = META_EVENT_BYTE,
};

/*-----------
  MIDI Event
 -----------*/

/// Running status support
u128  running_status_addr = null;

/**
    MIDI data types.

    TODO: contribute separately?
*/

enum ChannelVoiceMessage : u8 { // u4 really
    NOTE_OFF                = 0x8,
    NOTE_ON                 = 0x9,
    POLYPHONIC_KEY_PRESSURE = 0xA, // aka polyphonic aftertouch
    CONTROL_CHANGE          = 0xB,
    PROGRAM_CHANGE          = 0xC,
    CHANNEL_PRESSURE        = 0xD, // aka channel aftertouch
    PITCH_BEND_CHANGE       = 0xE,
};

/**
    A MIDI status bytes.

    First nibble is the MIDI message.
    Second nibble is the MIDI channel.
*/
bitfield StatusByte {
        ChannelVoiceMessage message : 4 [[name("MIDI message")]];
        unsigned            channel : 4 [[name("MIDI channel")]];
};

enum ControlChange : u8 {
    // MSB if optional LSB controllers are used
    BANK_SELECT                         =   0,
    MODULATION_DEPTH                    =   1, // Amended by RP-024. Formerly "Modululation wheel or lever".
    BREATH_CONTROLLER                   =   2,
    UNDEFINED                           =   3,
    FOOT_CONTROLLER                     =   4,
    PORTAMENTO_TIME                     =   5,
    DATA_ENTRY                          =   6,
    CHANNEL_VOLUME                      =   7, // Amended by RP-024. Was "Volume" under RP-003 and formerly "Main Volume".
    BALANCE                             =   8,
    UNDEFINED_9                         =   9,
    PAN                                 =  10,
    EXPRESSION                          =  11, // Amended by RP-003. Formerly "Expression Controller".
    EFFECT_CONTROL_1                    =  12,
    EFFECT_CONTROL_2                    =  13,
    UNDEFINED                           =  14,
    UNDEFINED                           =  15,
    GENERAL_PURPOSE_1                   =  16,
    GENERAL_PURPOSE_2                   =  17,
    GENERAL_PURPOSE_3                   =  18,
    GENERAL_PURPOSE_4                   =  19,
    UNDEFINED                           =  20 ... 31,

    // LSB for controllers 0-31
    BAN_SELECT_LSB                      =  32,
    MODULATION_DEPTH_LSB                =  33, // Amended by RP-024. Formerly "Modulation wheel or lever LSB".
    BREATH_CONTROLLER_LSB               =  34,
    UNDEFINED_LSB_3                     =  35,
    FOOT_CONTROLLER_LSB                 =  36,
    PORTAMENTO_TIME_LSB                 =  37,
    DATA_ENTRY_LSB                      =  38,
    CHANNEL_VOLUME_LSB                  =  39, // Amended by RP-024. Was "Volume LSB" under RP-003 and formerly "Main Volume LSB".
    BALANCE_LSB                         =  40,
    UNDEVINED_LSB_9                     =  41,
    PAN_LSB                             =  42,
    EXPRESSION_LSB                      =  43, // Amended by RP-003. Formerly "Expression Controller LSB".
    EFFECT_CONTROL_1_LSB                =  44,
    EFFECT_CONTROL_2_LSB                =  45,
    UNDEFINED_LSB_14                    =  46,
    UNDEFINED_LSB_15                    =  47,
    GENERAL_PURPOSE_1_LSB               =  48,
    GENERAL_PURPOSE_2_LSB               =  49,
    GENERAL_PURPOSE_3_LSB               =  50,
    GENERAL_PURPOSE_4_LSB               =  51,
    UNDEFINED_LSB_20                    =  52,
    UNDEFINED_LSB_21                    =  53,
    UNDEFINED_LSB_22                    =  54,
    UNDEFINED_LSB_23                    =  55,
    UNDEFINED_LSB_24                    =  56,
    UNDEFINED_LSB_25                    =  57,
    UNDEFINED_LSB_26                    =  58,
    UNDEFINED_LSB_27                    =  59,
    UNDEFINED_LSB_28                    =  60,
    UNDEFINED_LSB_29                    =  61,
    UNDEFINED_LSB_30                    =  62,
    UNDEFINED_LSB_31                    =  63,

    HOLD_1_DAMPER                       =  64, // Amended by RP-024. Was "Sustain" under RP-003. Formerly "Damper pedal (sustain)".
    PORTAMENTO_ON_OFF                   =  65,
    SOSTENUTO                           =  66,
    SOFT                                =  67, // Amended by RP-024. Was "Soft pedal".
    LEGATO_FOOTSWITCH                   =  68,
    HOLD_2                              =  69,
    SOUND_CONTROLLER_1                  =  70,
    SOUND_CONTROLLER_2                  =  71,
    SOUND_CONTROLLER_3                  =  72,
    SOUND_CONTROLLER_4                  =  73,
    SOUND_CONTROLLER_5                  =  74,
    SOUND_CONTROLLER_6                  =  75,
    SOUND_CONTROLLER_7                  =  76,
    SOUND_CONTROLLER_8                  =  77,
    SOUND_CONTROLLER_9                  =  78,
    SOUND_CONTROLLER_10                 =  79,
    GENERAL_PURPOSE_CONTROLLER_5        =  80,
    GENERAL_PURPOSE_CONTROLLER_6        =  81,
    GENERAL_PURPOSE_CONTROLLER_7        =  82,
    GENERAL_PURPOSE_CONTROLLER_8        =  83,
    PORTAMENTO_CONTROL                  =  84,
    UNDEFINED                           =  85 ... 87,
    HIGH_RESOLUTION_VELOCITY_PREFIX     =  88, // Amended by CA-031. Was "Undefined".
    UNDEFINED                           =  89 ... 90,
    REVERB_SEND_LEVEL                   =  91, // Amended by RP-023. Was "Effects 1 Depth". Formerly and recommended default: External Effects Depth.
    EFFECT_2_DEPTH                      =  92, // Formerly and recommended default: Tremolo Depth.
    CHORUS_SEND_LEVEL                   =  93, // Amended by RP-024. Was "Effects 3 Depth". Formerly and recommended default: Chorus Depth.
    EFFECT_4_DEPTH                      =  94, // Formerly and recommended default: Celeste (Detune) Depth.
    EFFECT_5_DEPTH                      =  95, // Formerly and recommended default: Phaser Depth.
    DATA_INCREMENT                      =  96,
    DATA_DECREMENT                      =  97,
    NON_REGISTERED_PARAMETER_NUMBER_LSB =  98,
    NON_REGISTERED_PARAMETER_NUMBER_MSB =  99,
    REGISTERED_PARAMETER_NUMBER_LSB     = 100,
    REGISTERED_PARAMETER_NUMBER_MSB     = 101,
    UNDEFINED                           = 102 ... 119,

    // Reserved for Channel Mode Messages
    ALL_SOUND_OFF                       = 120,
    RESET_ALL_CONTROLLERS               = 121,
    LOCAL_CONTROL                       = 122,
    ALL_NOTES_OFF                       = 123,
    OMNI_MODE_OFF                       = 124,
    OMNI_MODE_ON                        = 125,
    MONO_MODE_ON                        = 126,
    POLY_MODE_ON                        = 127,
};


#define MIDDLE_C 60
#define NUM_NOTES 12
#define OCTAVE_OFFSET 1
/**
    MIDI note formatter.

    Formats notes in a human readable form.
    The octave offset of midi notes is debated and can change between instrument manufacturers.
    Here we use the convention of the physical the center
    of a 88 note piano-style keyboard being middle C which is denoted C4.
*/
fn note(u8 n) {
    match (n % NUM_NOTES) {
        ( 0): return std::format("C {:d}",     (n / NUM_NOTES) - OCTAVE_OFFSET);
        ( 1): return std::format("C#/Db {:d}", (n / NUM_NOTES) - OCTAVE_OFFSET);
        ( 2): return std::format("D {:d}",     (n / NUM_NOTES) - OCTAVE_OFFSET);
        ( 3): return std::format("D#/Eb {:d}", (n / NUM_NOTES) - OCTAVE_OFFSET);
        ( 4): return std::format("E {:d}",     (n / NUM_NOTES) - OCTAVE_OFFSET);
        ( 5): return std::format("F {:d}",     (n / NUM_NOTES) - OCTAVE_OFFSET);
        ( 6): return std::format("F#/Gb {:d}", (n / NUM_NOTES) - OCTAVE_OFFSET);
        ( 7): return std::format("G {:d}",     (n / NUM_NOTES) - OCTAVE_OFFSET);
        ( 8): return std::format("G#/Ab {:d}", (n / NUM_NOTES) - OCTAVE_OFFSET);
        ( 9): return std::format("A {:d}",     (n / NUM_NOTES) - OCTAVE_OFFSET);
        (10): return std::format("A#/Bb {:d}", (n / NUM_NOTES) - OCTAVE_OFFSET);
        (11): return std::format("B {:d}",     (n / NUM_NOTES) - OCTAVE_OFFSET);
    }
};

/**
    Pitch bend change value formatter.

    Converts 2 MIDI data bytes to a signed 14-bit value in range -8192 ... 8191.

    Note that MIDI data bytes have their first (most significant) bit clear (0),
    thus each byte is in range 0 ... 127.
*/
#define PITCH_CENTER 0x2000
fn signed14(u16 n) {
    s16 r;
    r = ((n & SEVEN_BITS) << 7) | ((n >> 8) & SEVEN_BITS);
    if (r >= 0) {
        r -= PITCH_CENTER;  // FIXME: why the magic?
    }
    return r;
};

/**
    A MIDI event.
*/
struct MidiEvent {
    if (running_status_addr) {
        // Reuse stored status byte in running status
        StatusByte status_byte @ running_status_addr [[name("(Running status)")]];
    } else {
        StatusByte status_byte                       [[name("Status byte")]];
        // Store the status byte for running status
        running_status_addr = addressof(status_byte);
    }
    match (status_byte.message) {
        (ChannelVoiceMessage::NOTE_OFF |
         ChannelVoiceMessage::NOTE_ON): {
            u8            note     [[name("Note"), format("note")]];
            u8            velocity [[name("Velocity")]];
        }
        (ChannelVoiceMessage::POLYPHONIC_KEY_PRESSURE): {
            u8            note     [[name("Note"), format("note")]];
            u8            amount   [[name("Key pressure amount")]];
        }
        (ChannelVoiceMessage::CONTROL_CHANGE): {
            ControlChange cc       [[name("Control change number")]];
            u8            value    [[name("Control change value")]];
        }
        (ChannelVoiceMessage::PROGRAM_CHANGE): {
            u8            program  [[name("Program change number")]]; // TODO: decode GM1/GS
        }
        (ChannelVoiceMessage::CHANNEL_PRESSURE): {
            u8            amount   [[name("Channel pressure amount")]];
        }
        (ChannelVoiceMessage::PITCH_BEND_CHANGE): {
            // TODO: custom type
            u16           value    [[name("Value"), format("signed14")]];
        }
        (_): {
            std::warning(std::format("Unknown status byte: {:02X}", status_byte));
        }
    }
};

/*------------
  Sysex Event
 ------------*/

enum SystemCommonMessages : u8 {
    MIDI_TIME_CODE_QUARTER_FRAME = 0xF1,
    SONG_POSITION_POINTER        = 0xF2,
    SONG_SELECT                  = 0xF3,

    TUNE_REQUEST                 = 0xF6,
    EOX                          = 0xF7,
};

enum SystemRealTimeMessages : u8 {
    TIMING_CLOCK                 = 0xF8,

    START                        = 0xFA,
    CONTINUE                     = 0xFB,
    STOP                         = 0xFC,

    ACTIVE_SENSING               = 0xFE,
    SYSTEM_RESET                 = 0xFF,
};

/**
    A Sysex event.
*/
struct SysexEvent {
    TrackEventType flag;
    type::VLQ      length;
    type::Hex<u8>  data[length];
    // FIXME: Escape Should be used for System common messages & System real time messages
    // TODO: decode defined sysex?
    // TODO: decode system realtime messages, song pointer or select, MTC…
    // TODO: contribute decoder separately for SYX files
};


/*-----------
  Meta Event
 -----------*/

#define META_EVENT_TYPE_RESERVED_TEXT_RANGE 0x0A ... 0x1F

/**
    Known types of meta events.

    From RP-001 (SMF spec), RP-019, RP-026 and RP-032.
*/
enum MetaEventType : u8 {
    SEQUENCE_NUMBER       = 0x00,
    TEXT                  = 0x01,
    COPYRIGHT_NOTICE      = 0x02,
    SEQUENCE_TRACK_NAME   = 0x03,
    INSTRUMENT_NAME       = 0x04,
    DISPLAY_LYRIC         = 0x05, // Renamed by RP-026. Was "Lyric" in RP-001.
    MARKER                = 0x06,
    CUE_POINT             = 0x07,
    PROGRAM_NAME          = 0x08, // Added by RP-019.
    DEVICE_NAME           = 0x09, // Added by RP-019.
    RESERVED_TEXT         = META_EVENT_TYPE_RESERVED_TEXT_RANGE,

    MIDI_CHANNEL_PREFIX   = 0x20,

    END_OF_TRACK          = 0x2F,

    SET_TEMPO             = 0x51,

    SMPTE_OFFSET          = 0x54,

    TIME_SIGNATURE        = 0x58,
    KEY_SIGNATURE         = 0x59,
    XMF_PATCH_TYPE_PREFIX = 0x60, // Added by RP-032.

    SEQUENCER_SPECIFIC    = 0x7F,
};

/**
    A meta event.
*/
struct MetaEvent {
    TrackEventType flag          [[name("Meta event flag")]];
    MetaEventType  type          [[name("Meta event type")]];
    type::VLQ      length        [[name("Meta event data length")]];
    u8             bytes[length] [[hidden]];

    if (type > SEVEN_BITS) {
        std::warning("Meta event type outside of specification!");
    }

    // Rewind to decode the bytes
    $ -= length;

    // TODO: ignore supplemmentary bytes per spec
    match (type) {
            (MetaEventType::SEQUENCE_NUMBER): {
                std::assert(length==2, "Not the expected length.");
                u16 ssss [[name("Sequence number")]];
            }
            (MetaEventType::TEXT):
            char text[length] [[name("Text")]];
            (MetaEventType::COPYRIGHT_NOTICE):
            char text[length] [[name("Copyright notice")]];
            (MetaEventType::SEQUENCE_TRACK_NAME):
            char text[length] [[name("Sequence/track name")]];
            (MetaEventType::INSTRUMENT_NAME):
            char text[length] [[name("Instrument name")]];
            (MetaEventType::DISPLAY_LYRIC):
            char text[length] [[name("Display/lyric")]];
            (MetaEventType::MARKER):
            char text[length] [[name("Marker")]];
            (MetaEventType::CUE_POINT):
            char text[length] [[name("Cue point")]];
            (MetaEventType::PROGRAM_NAME):
            char text[length] [[name("Program name")]];
            (MetaEventType::DEVICE_NAME):
            char text[length] [[name("Device name")]];
            (META_EVENT_TYPE_RESERVED_TEXT_RANGE): {
                std::warning("Range reserved for text use but unspecified at this time.");
                char text[length] [[name("Text (Reserved area)")]];
            }
            (MetaEventType::MIDI_CHANNEL_PREFIX): {
                std::assert(length==1, "Not the expected length.");
                u8   cc;
            }
            (MetaEventType::END_OF_TRACK):
            std::assert(length==0, "Not the expected length.");
            (MetaEventType::SET_TEMPO): {
                std::assert(length==3, "Not the expected length.");
                u24  tttttt [[name("Tempo"), comment("in microseconds per MIDI quarter-note")]];
            }
            (MetaEventType::SMPTE_OFFSET) : {
                std::assert(length==5, "Not the expected length.");
                // TODO: decode?
                u8   hr [[name("Hours"), comment("encoded in SMPTE time (ie. contains framerate)")]];
                u8   mn [[name("Minutes")]];
                u8   se [[name("Seconds")]];
                u8   fr [[name("Frames")]];
                u8   ff [[name("Fractional frames"), comment("in 100th of a frame")]];
            }
            (MetaEventType::TIME_SIGNATURE): {
                std::assert(length==4, "Not the expected length.");
                u8   nn [[name("Numerator")]];
                u8   dd [[name("Denominator"),comment("Negative power of two")]];
                u8   cc [[name("Number of MIDI clocks in a metronome click"), comment("aka ticks per click")]];
                u8   bb [[name("Number of notated 32nd notes in MIDI quarter-note")]];
            }
            (MetaEventType::KEY_SIGNATURE): {
                std::assert(length==2, "Not the expected length.");
                s8   sf [[name("Number of sharps of flats (negative)"), comment("0 is key of C")]];
                u8   mi [[name("Minor or Major")]];
            }
            (MetaEventType::XMF_PATCH_TYPE_PREFIX): {
                std::assert(length==1, "Not the expected length.");
                u8   value; // TODO
                std::unimplemented();
            }
            (MetaEventType::SEQUENCER_SPECIFIC):
            u8   data[length];
            (_):
            u8   unknown_meta_data[length];
    }
};

/*------
  Track
 ------*/

/**
    A Track Event.
*/
struct MTrkEvent {
    type::VLQ      delta_time [[name("Delta time"), Comment("in ticks as specified in the header chunk")]];

    if (std::mem::read_unsigned($, 1) > SEVEN_BITS) {
        running_status_addr = null; // Event resets running status
        match (std::mem::read_unsigned($, 1)) {
            (SYSEX_EVENT_BYTE |
             SYSEX_EVENT_CONTINUE_ESCAPE_BYTE): {
                SysexEvent event [[name("SysEx Event")]];
            }
            (META_EVENT_BYTE): {
                MetaEvent event [[name("Meta Event")]];
            }
            (MIDI_CHANNEL_VOICE_MESSAGES_RANGE): {
                MidiEvent  event [[name("MIDI Event")]]; // Stores running status
            }
            (_): {
                u8 junk [[color("000000")]];
                std::warning(std::format("Unknown event type: {:02X} @ {:02X}", junk, addressof(junk)));
            }
        }
    } else if (running_status_addr) {
        // Running status reuses the previous status
        MidiEvent event [[name("MIDI Event (Running)")]];
    } else {
        u8 junk [[color("000000")]];
        std::warning(std::format("MIDI data found without running status! {:02X} @ {:02X}", junk, addressof(junk)));

    }

    std::core::set_display_name(this, std::format("MTrk event {:d}", std::core::array_index()));
};

/**
    A Track Chunk.
*/
struct TrackChunk {
    std::assert_warn(!std::core::has_attribute(parent, "header"), "Track chunk found before header!");

    std::core::set_display_name(parent, std::format("Track {:d}", std::core::array_index()));

    type::Magic<"MTrk"> chunk_type   [[name("Chunk type: Track"), comment("Track magic")]];
    u32                 length       [[name("Chunk data length")]];
    u8                  data[length] [[hidden]];

    // Decode chunk data
    MTrkEvent mtrk_events[while(!std::mem::reached(addressof(data) + length))] @ addressof(data) [[name("MTrk Events")]];
};

/*-------
  Header
--------*/

/// Delta-time division formats
enum DivisionFormat : bool {
    TICKS_PER_QUARTER_NOTE = 0,
    TICKS_PER_FRAME        = 1,
};

u8 TWOS_COMPLEMENT_8_TO_7_BITS = 0x80;
/// Negative SMPTE framerate format
enum NegativeSMPTEFormat : s8 {
    _24FPS    = -24 + TWOS_COMPLEMENT_8_TO_7_BITS,
    _25FPS    = -25 + TWOS_COMPLEMENT_8_TO_7_BITS,
    _30FPSDF  = -29 + TWOS_COMPLEMENT_8_TO_7_BITS,
    _30FPSNDF = -30 + TWOS_COMPLEMENT_8_TO_7_BITS,
};

/// Delta-time division specification
bitfield Division {
        DivisionFormat format           :  1 [[name("Format")]];
        match (format) {
            (DivisionFormat::TICKS_PER_QUARTER_NOTE) : {
                ticks_per_quarter_note  : 15 [[name("Ticks per quarter-note")]];
            }
            (DivisionFormat::TICKS_PER_FRAME) : {
                NegativeSMPTEFormat nsf :  7 [[name("Negative SMPTE Format")]];
                ticks_per_frame         :  8 [[name("Ticks per frame")]];
            }
        }
};

/// Overall organization of the file
enum Format : u16 {
    ZERO        = 0, // Single multi-channel track
    ONE         = 1, // One or more simultaneous tracks of a sequence
    TWO         = 2, // One or more sequentially independent single-track patterns
    OUT_OF_SPEC = 3 ... 0xFF,
};

const u8 SMF_HEADER_LEN = 6;

/**
    A header chunk.
*/
struct HeaderChunk {
    std::assert_warn(std::core::array_index() == 0, "Header should have been the first chunk!");

    type::Magic<"MThd"> type     [[name("Chunk type: Header"), comment("Header magic")]];

    u32                 length   [[name("Chunk data length"),comment("Should be 6 by specification")]];
    // Standard MIDI Files should have a length of 6
    if (length < SMF_HEADER_LEN) {
        std::error("Header too short! Can't decode further.");
    }
    std::assert_warn(length == SMF_HEADER_LEN, "Non-standard file: extra data in header. May not decode correctly.");

    // --- Start of chunk data
    Format               format    [[name("File format"), comment("Also known as MIDI File Type.")]];
    if (Format::OUT_OF_SPEC == format) {
        std::warning(std::format("Format {:d} is outside of specification.", format));
    }

    u16                  ntrks     [[name("Number of tracks")]];
    std::assert_warn(ntrks > 0, "No track declared! Should be at least 1.");
    if (Format::ZERO == format) {
        std::assert_warn(ntrks == 1, std::format("Format 0 file should contain a single track. {:d} declared!", ntrks));
    }

    Division             division  [[name("Delta-time division")]];

    if (length > SMF_HEADER_LEN) {
        // We have unknown data
        u8               unknown_data[length - SMF_HEADER_LEN] [[name("Unknown data"), comment("Non-standard data allowed by specification")]];
    }
    // --- End of chunk data

    std::core::set_display_name(parent, "Header");
};

/**
    A file chunk.

    Chunks are the basic data structure of Standard MIDI Files.
    Similar to Electronic Arts' IFF format.
*/
struct Chunk {
    std::core::set_pattern_comment(this, std::format("Chunk[{:d}]", std::core::array_index()));

    char type[4]       [[hidden]];
    u32  length        [[hidden]];
    u8   data[length]  [[hidden]];

    // Now that we know the chunk is correct, rewind to decode.
    $ = addressof(this);

    match (type) {
            ("MThd"): {
                std::print("Found header");
                HeaderChunk header [[inline]];
                expected_tracks = header.ntrks;
            }
            ("MTrk"): {
                found_tracks += 1;
                std::print("Found track {}", found_tracks);
                TrackChunk  track  [[inline]];
            }
            (_): {
                std::warning("Found alien chunk!");
                AlienChunk  alien  [[inline, color("000")]];
            }
    }
};

/*-------------------------
  Standard MIDI File (SMF)
 -------------------------*/

u16 expected_tracks = 0;
u16 found_tracks    = 0;

Chunk chunks[while(!std::mem::eof())] @ 0x00 [[inline]];

if (found_tracks < expected_tracks) {
std::warning(std::format("Tracks missing. Expected {:d}, found {:d}.", expected_tracks, found_tracks));
}
if (found_tracks > expected_tracks) {
std::warning(std::format("Found more tracks ({:d}) than expected ({:d})!", found_tracks, expected_tracks));
}
