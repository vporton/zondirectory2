export function take<T>(iterable: Iterable<T>, n) {
    const iterator = iterable[Symbol.iterator]();
    const results = [];
    for (let i = 0; i < n; i++) {
      if (!iterator.next().done) {
        results.push(iterator.next().value);
      } else {
        break;
      }
    }
    return results;
  }
  