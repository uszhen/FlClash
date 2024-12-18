import 'dart:async';

class Debouncer {
  Map<dynamic, Timer> operators = {};

  call(
    dynamic tag,
    Function func, {
    List<dynamic>? args,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    final timer = operators[tag];
    if (timer != null) {
      timer.cancel();
    }
    operators[tag] = Timer(
      duration,
      () {
        operators.remove(tag);
        Function.apply(
          func,
          args,
        );
      },
    );
  }
}

final debouncer = Debouncer();

// debounce<F extends Function>(F func, {int milliseconds = 600}) {
//   Timer? timer;
//
//   return ([List<dynamic>? args, Map<Symbol, dynamic>? namedArgs]) {
//     if (timer != null) {
//       timer!.cancel();
//     }
//     timer = Timer(Duration(milliseconds: milliseconds), () async {
//       await Function.apply(func, args ?? [], namedArgs);
//     });
//   };
// }
