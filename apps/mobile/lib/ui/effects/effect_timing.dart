/// One number that sets how long the clear effects live on screen.
///
/// The effects were first written short: a 0.32 s flash, a 0.8 s shockwave,
/// 0.8 s for the score number, particles gone in half a second. Played on a
/// device they read as a flicker rather than as a moment - the owner's words
/// were that they are three to five times too fast - and a clear fires four or
/// five of them at once, so the whole burst was over before the eye settled on
/// any part of it.
///
/// This scales the effects' own clock rather than only their durations. For
/// anything with physics that distinction matters: stretching a particle's
/// lifetime without slowing its gravity just rains it further off the board,
/// where scaling time slows the whole motion the way a slow-motion replay
/// does.
///
/// It deliberately does not touch input-driven motion - the rack piece tween,
/// the camera shake - because those are feedback on a touch, and a slow
/// response to a touch reads as lag, not as weight.
const double kEffectTimeScale = 3.5;
