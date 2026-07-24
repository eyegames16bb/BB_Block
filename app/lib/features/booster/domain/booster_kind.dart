/// Identifies one of the three booster types, independent of any specific
/// charge count. Used wherever code needs to name *which* booster rather
/// than act on a session's live charge — e.g. picking one to refill.
enum BoosterKind { rotate, swap, singleCellRemove }
