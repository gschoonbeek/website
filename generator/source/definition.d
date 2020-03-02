module definition;

import std.stdio;
import dyaml;
import std.datetime;
import std.array;
import std.conv;
import std.regex;
import std.string;
import std.traits;
import std.meta;
import std.file;
import std.format;

struct Content {
  string nl;
  string en;
}

struct Item {
  Content title;
  Content content;
}

struct Definition {
  Item[][string] items;
  Link[] links;
  string html;
}

struct Link {
  Content name;
  Content target;
}

auto decode(T)(ref Node node) {
  static if (is(T : Item[][string], Item)) {
    Item[][string] items;
    foreach(pair; node.mapping) {
      items[pair.key.as!string] ~= pair.value.decode!(Item[]);
    }
    return items;
  } else static if (is(T : Item[], Item)) {
    auto app = appender!(Item[]);
    foreach(Node i; node)
      app.put(i.decode!Item);
    return app.data;
  } else static if (is(T == Content)) {
    Content content;
    if (node.nodeID == NodeID.mapping) {
      content.nl = node["nl"].as!string;
      content.en = node["en"].as!string;
    } else {
      import std.exception : enforce;
      enforce(node.nodeID == NodeID.scalar, "Expected 'nl' or 'en' or plain string");
      content.nl = content.en = node.as!string;
    }
    return content;
  } else {
    T t;
    static foreach(idx, field; T.tupleof) {{
        enum string key = __traits(identifier, field);
        static if (!is(typeof(field) : string) && is(typeof(field) : A[], A)) {
          auto app = appender!(A[]);
          foreach(Node i; node[key])
            app.put(i.decode!A);
          t.tupleof[idx] = app.data;
        } else static if (is(typeof(field) : A[][string], A)) {
          t.tupleof[idx] = node[key].decode!(A[][string]);
        } else static if (isAggregateType!(typeof(field)))
          t.tupleof[idx] = node[key].decode!(typeof(field));
        else
          if (node.containsKey(key))
            t.tupleof[idx] = node[key].as!(typeof(field));
      }}
    return t;
  }
}

auto replaceLinks(Item[][string] items, Link[] links) {
  foreach(ref item; items) {
    item.replaceLinks(links);
  }
  return items;
}

auto replaceLinks(Item[] items, Link[] links) {
  foreach(link; links) {
    auto hrefNl = format("<a href=\"%s\" target=\"_blank\"><b>%s</b></a>", link.target.nl, link.name.nl);
    auto hrefEn = format("<a href=\"%s\" target=\"_blank\"><b>%s</b></a>", link.target.en, link.name.en);
    foreach(ref item; items) {
      item.content.nl = item.content.nl.replace(link.name.nl, hrefNl);
      item.content.en = item.content.en.replace(link.name.en, hrefEn);
    }
  }
  return items;
}

auto replaceNewLines(Item[][string] items) {
  foreach(ref item; items) {
    item.replaceNewLines();
  }
}

auto replaceNewLines(Item[] items) {
  foreach(ref item; items) {
    item.content.nl = item.content.nl.replace("\n","<br>");
    item.content.en = item.content.en.replace("\n","<br>");
  }
}

auto loadDefinitions(string filename)
{
  auto node = Loader.fromFile(filename).load;
  auto def = node.decode!Definition;
  def.items.replaceLinks(def.links).replaceNewLines();
  return def;
}
