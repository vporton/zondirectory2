export function take<T>(iterable: Iterable<T>, n) {
    const iterator = iterable[Symbol.iterator]();
    const results = [];
    for (let i = 0; i < n; i++) {
      const value = iterator.next();
      if (!value.done) {
        results.push(value.value);
      } else {
        break;
      }
    }
    console.log(results)
    return results;
  }
  