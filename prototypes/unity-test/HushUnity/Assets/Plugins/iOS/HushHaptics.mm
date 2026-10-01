// Core Haptics for the Unity test: the same patterns as the Swift version (P2.5 spec A.3).
#import <CoreHaptics/CoreHaptics.h>

static CHHapticEngine *engine = nil;
static id<CHHapticAdvancedPatternPlayer> charging = nil;

static CHHapticEngine *Engine(void) {
    if (!CHHapticEngine.capabilitiesForHardware.supportsHaptics) return nil;
    if (!engine) {
        engine = [[CHHapticEngine alloc] initAndReturnError:nil];
        engine.autoShutdownEnabled = YES;
        engine.resetHandler = ^{ [engine startAndReturnError:nil]; };
    }
    [engine startAndReturnError:nil];
    return engine;
}

static CHHapticEvent *Tap(float i, float s, NSTimeInterval t) {
    return [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticTransient parameters:@[
        [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:i],
        [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticSharpness value:s]] relativeTime:t];
}
static CHHapticEvent *Hum(float i, float s, NSTimeInterval t, NSTimeInterval d) {
    return [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticContinuous parameters:@[
        [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:i],
        [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticSharpness value:s]] relativeTime:t duration:d];
}
static void Play(NSArray *events, NSArray *curves) {
    CHHapticEngine *e = Engine(); if (!e) return;
    CHHapticPattern *p = [[CHHapticPattern alloc] initWithEvents:events parameterCurves:curves ?: @[] error:nil];
    if (!p) return;
    id<CHHapticPatternPlayer> player = [e createPlayerWithPattern:p error:nil];
    [player startAtTime:CHHapticTimeImmediate error:nil];
}
static CHHapticParameterCurve *Curve(NSArray<NSArray<NSNumber *> *> *pts) {
    NSMutableArray *cps = [NSMutableArray array];
    for (NSArray<NSNumber *> *p in pts)
        [cps addObject:[[CHHapticParameterCurveControlPoint alloc] initWithRelativeTime:p[0].doubleValue value:p[1].floatValue]];
    return [[CHHapticParameterCurve alloc] initWithParameterID:CHHapticDynamicParameterIDHapticIntensityControl controlPoints:cps relativeTime:0];
}

extern "C" {
void HushHapticsTap(float intensity, float sharpness) { Play(@[Tap(intensity, sharpness, 0)], nil); }

void HushHapticsCharge(float seconds) {
    CHHapticEngine *e = Engine(); if (!e) return;
    NSMutableArray *events = [NSMutableArray arrayWithObject:Hum(0.8, 0.5, 0, seconds)];
    for (NSTimeInterval t = 0.12; t < seconds; t += 0.12) [events addObject:Tap(0.15 + 0.5 * t / seconds, 0.4, t)];
    CHHapticPattern *p = [[CHHapticPattern alloc] initWithEvents:events parameterCurves:@[Curve(@[@[@0, @0.2], @[@(seconds), @1]])] error:nil];
    charging = [e createAdvancedPlayerWithPattern:p error:nil];
    [charging startAtTime:CHHapticTimeImmediate error:nil];
}

void HushHapticsStop(void) { [charging stopAtTime:CHHapticTimeImmediate error:nil]; charging = nil; }

void HushHapticsIgnite(void) {
    Play(@[Tap(1.0, 0.6, 0), Hum(0.5, 0.3, 0.02, 0.4)], @[Curve(@[@[@0.02, @1], @[@0.42, @0]])]);
}

void HushHapticsRise(void) {
    Play(@[Hum(0.4, 0.1, 0, 1.5)], @[Curve(@[@[@0, @0.25], @[@0.8, @1], @[@1.5, @0]])]);
}
}
