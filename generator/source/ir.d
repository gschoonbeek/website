module ir;

import definition;

struct Record {
  string year;
  string title;
  string content;
}

struct Items {
  Record[] nl;
  Record[] en;
  string html;
}

Items toIr(Definition def) {
  import std.array : Appender, array;
  import std.algorithm : sort;
  auto nls = Appender!(Record[])();
  auto ens = Appender!(Record[])();
  foreach(pair; def.items.byKeyValue.array.sort!((a,b) => a.key > b.key)) {
    bool first = true;
    foreach(item; pair.value) {
      nls.put(Record(first ? pair.key : "", item.title.nl, item.content.nl));
      ens.put(Record(first ? pair.key : "", item.title.en, item.content.en));
      first = false;
    }
  }
  return Items(nls.data, ens.data, def.html);
}
