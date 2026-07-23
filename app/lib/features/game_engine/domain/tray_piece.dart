import 'package:bb_block/features/board/domain/entities/piece_shape.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tray_piece.freezed.dart';

/// One of the pieces offered in the player's tray for the current batch.
/// A used piece stays in the tray (so the UI can render the emptied slot)
/// until all three are consumed and the whole batch is refilled at once —
/// the GDD's rule that the random order does not change until every piece
/// of the batch is placed.
@freezed
abstract class TrayPiece with _$TrayPiece {
  const factory TrayPiece({
    required PieceShape shape,
    @Default(false) bool isUsed,
  }) = _TrayPiece;
}
